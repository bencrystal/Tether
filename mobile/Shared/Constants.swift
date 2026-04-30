import Foundation
import CoreBluetooth

// MARK: - App Group
let appGroupID = "group.com.tether.app"

// MARK: - UserDefaults Keys (shared between app and monitor extension)
enum SharedKeys {
    static let rules           = "tether_rules"
    static let pendingCommand  = "tether_pending_command"
    static let commandTimestamp = "tether_command_timestamp"
}

// MARK: - BLE UUIDs (must match firmware)
let TETHER_SERVICE_UUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
let COMMAND_CHAR_UUID   = CBUUID(string: "12345678-1234-1234-1234-123456789ABD")

// MARK: - Command bytes
enum TetherCommand: UInt8 {
    case off  = 0x00
    case warn = 0x01
    case zap  = 0x02
}

// MARK: - Darwin notification (extension → main app)
let kPendingCommandNotification = "com.tether.app.pendingCommand"
