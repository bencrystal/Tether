import Foundation
import CoreBluetooth
import Combine

enum BLEConnectionState: String {
    case disconnected = "Disconnected"
    case scanning     = "Scanning..."
    case connecting   = "Connecting..."
    case connected    = "Connected"
}

class BLEManager: NSObject, ObservableObject {
    @Published var connectionState: BLEConnectionState = .disconnected
    @Published var deviceName: String?

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?

    // Persist last peripheral UUID for auto-reconnect
    private let lastPeripheralKey = "tether_last_peripheral_uuid"

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil,
                                          options: [CBCentralManagerOptionRestoreIdentifierKey: "TetherBLECentral"])
        setupDarwinNotificationObserver()
    }

    // MARK: - Public API

    func scan() {
        guard centralManager.state == .poweredOn else { return }
        connectionState = .scanning
        centralManager.scanForPeripherals(withServices: [TETHER_SERVICE_UUID], options: nil)
    }

    func disconnect() {
        guard let peripheral = peripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    func sendCommand(_ command: TetherCommand) {
        guard let char = commandCharacteristic, let peripheral = peripheral else {
            print("[BLE] Cannot send — not connected")
            return
        }
        let data = Data([command.rawValue])
        peripheral.writeValue(data, for: char, type: .withoutResponse)
        print("[BLE] Sent command: 0x\(String(format: "%02X", command.rawValue))")
    }

    // MARK: - Auto-reconnect

    private func attemptReconnectToKnown() {
        guard let uuidString = UserDefaults.standard.string(forKey: lastPeripheralKey),
              let uuid = UUID(uuidString: uuidString) else {
            scan()
            return
        }
        let knownPeripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
        if let known = knownPeripherals.first {
            connectionState = .connecting
            peripheral = known
            peripheral?.delegate = self
            centralManager.connect(known, options: nil)
        } else {
            scan()
        }
    }

    private func savePeripheralUUID(_ uuid: UUID) {
        UserDefaults.standard.set(uuid.uuidString, forKey: lastPeripheralKey)
    }

    // MARK: - Darwin notification (from DeviceActivity extension)

    private func setupDarwinNotificationObserver() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()

        CFNotificationCenterAddObserver(center, observer, { (_, observer, _, _, _) in
            guard let observer = observer else { return }
            let manager = Unmanaged<BLEManager>.fromOpaque(observer).takeUnretainedValue()
            manager.handlePendingCommand()
        }, kPendingCommandNotification as CFString, nil, .deliverImmediately)
    }

    private func handlePendingCommand() {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        guard let cmdByte = defaults.object(forKey: SharedKeys.pendingCommand) as? UInt8,
              let command = TetherCommand(rawValue: cmdByte) else { return }

        // Clear the pending command
        defaults.removeObject(forKey: SharedKeys.pendingCommand)
        defaults.removeObject(forKey: SharedKeys.commandTimestamp)

        DispatchQueue.main.async {
            self.sendCommand(command)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            attemptReconnectToKnown()
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        // State restoration for background BLE
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral],
           let restored = peripherals.first {
            peripheral = restored
            peripheral?.delegate = self
        }
    }

    func centralManager(_ central: CBCentralManager,
                         didDiscover peripheral: CBPeripheral,
                         advertisementData: [String: Any],
                         rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        centralManager.stopScan()
        connectionState = .connecting
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionState = .connected
        deviceName = peripheral.name ?? "Tether"
        savePeripheralUUID(peripheral.identifier)
        peripheral.discoverServices([TETHER_SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager,
                         didDisconnectPeripheral peripheral: CBPeripheral,
                         error: Error?) {
        connectionState = .disconnected
        commandCharacteristic = nil
        // Auto-reconnect after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.attemptReconnectToKnown()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == TETHER_SERVICE_UUID }) else { return }
        peripheral.discoverCharacteristics([COMMAND_CHAR_UUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral,
                     didDiscoverCharacteristicsFor service: CBService,
                     error: Error?) {
        guard let char = service.characteristics?.first(where: { $0.uuid == COMMAND_CHAR_UUID }) else { return }
        commandCharacteristic = char
        print("[BLE] Ready — command characteristic discovered")
    }
}
