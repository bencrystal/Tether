# Tether — Prototype PRD
**Version:** 1.0
**Goal:** LED fires on XIAO nRF52840 when user-configured app hits user-configured time threshold
**Stack:** Swift (iOS 16+), Zephyr or Arduino firmware (nRF52840), BLE 5.0

---

## 1. Overview

Tether is a wrist-worn device that delivers a physical stimulus when the user exceeds a configurable time limit on specific apps. This PRD covers the v1 prototype: an iOS companion app + nRF52840 firmware where the "stimulus" is an LED, validating the full software pipeline before the shock circuit is introduced.

---

## 2. Scope

**In scope (prototype)**
- iOS app: app selection, threshold configuration, BLE connection management
- DeviceActivity integration: monitoring selected apps, firing threshold events
- BLE communication: sending command bytes to the nRF52840 on threshold events
- nRF52840 firmware: receiving BLE writes, driving LED for warning and zap patterns

**Out of scope (prototype)**
- Shock/TENS circuit
- Subscription or account system
- Analytics or usage history
- Apple Watch or Android support

---

## 3. User Flow

1. User installs app, grants Family Controls authorization
2. User pairs Tether bracelet via BLE in the app
3. User selects one or more apps to monitor
4. User sets two thresholds per app: Warning (default 10 min) and Zap (default 15 min)
5. User locks phone and goes about their day
6. When a monitored app hits the Warning threshold → bracelet LED slow-blinks (3x)
7. When a monitored app hits the Zap threshold → bracelet LED fast-blinks (10x rapid)
8. Thresholds reset at midnight (matching DeviceActivity's daily window)

---

## 4. iOS App

### 4.1 Architecture

```
TetherApp/
├── App/
│   └── TetherApp.swift            # @main, requests FamilyControls auth
├── Models/
│   ├── AppRule.swift               # { bundleID, displayName, warnMins, zapMins }
│   └── BLEManager.swift           # CBCentralManager, connection state, write commands
├── Views/
│   ├── HomeView.swift             # Connection status + rules list
│   ├── AppPickerView.swift        # FamilyActivityPicker sheet
│   └── RuleEditView.swift         # Sliders for warn/zap thresholds
├── ActivityMonitor/               # Separate app extension target
│   └── TetherMonitor.swift        # DeviceActivityMonitor subclass
└── Shared/
    └── AppGroup.swift             # UserDefaults(suiteName:) shared container key constants
```

### 4.2 Screens

**Home screen**
- BLE status indicator (connected / scanning / disconnected) with device name
- List of configured app rules — app icon, name, warn threshold, zap threshold
- "Add App" button → opens AppPickerView
- Tap rule → opens RuleEditView

**App picker**
- Uses `FamilyActivityPicker` from FamilyControls framework
- Saves selected `ActivitySelection` to AppGroup shared container

**Rule edit**
- App name + icon (header)
- Warning threshold slider: 1–60 min, default 10
- Zap threshold slider: 1–60 min, default 15 (enforced >= warn + 1)
- Save / Delete buttons

### 4.3 BLE Manager

```swift
// BLE characteristic UUIDs (define once, share between app and firmware)
let TETHER_SERVICE_UUID    = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
let COMMAND_CHAR_UUID      = CBUUID(string: "12345678-1234-1234-1234-123456789ABD")

// Command bytes
enum TetherCommand: UInt8 {
    case warn = 0x01   // slow blink
    case zap  = 0x02   // fast blink
    case off  = 0x00
}
```

- Scans for peripherals advertising `TETHER_SERVICE_UUID`
- Auto-reconnects on app foreground and after disconnect
- Persists last known peripheral UUID in UserDefaults for reconnect without re-scan
- Writes command byte as `.withoutResponse` for low latency
- Publishes `@Published var connectionState` for UI binding

### 4.4 DeviceActivity Integration

The `TetherMonitor` extension target subclasses `DeviceActivityMonitor`:

```swift
override func intervalDidStart(for activity: DeviceActivityName) { }

override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                      activity: DeviceActivityName) {
    // Read which threshold was hit from AppGroup shared container
    // Write BLE command to shared container → main app picks it up via notification
}
```

**Important constraint:** The `DeviceActivityMonitor` extension runs in a sandboxed process — it cannot directly call CoreBluetooth. The workaround:

1. Extension writes `pendingCommand: UInt8` + `commandTimestamp: Date` to the shared AppGroup `UserDefaults`
2. Extension posts a `Darwin notification` (notify_post) to wake the main app
3. Main app's `BLEManager` observes the Darwin notification, reads the command, sends the BLE write

This is the standard pattern for bridging DeviceActivity → CoreBluetooth.

### 4.5 Entitlements & Capabilities

| Capability | Reason |
|---|---|
| Family Controls | Required for DeviceActivityMonitor and FamilyActivityPicker |
| App Groups | Shared container between main app and monitor extension |
| Background Modes → Bluetooth LE | Maintain BLE connection when app is backgrounded |

**Note:** Family Controls requires a provisioning profile with the entitlement explicitly enabled. You cannot test this on Simulator — requires a physical device.

---

## 5. Firmware (nRF52840)

### 5.1 Recommended environment

Arduino-style using the **Adafruit nRF52 Arduino core** (easiest path with the XIAO nRF52840). Alternatively Zephyr RTOS for production but overkill for prototype.

### 5.2 BLE Setup

```cpp
BLEService        tetherService("12345678-1234-1234-1234-123456789ABC");
BLEByteCharacteristic commandChar("12345678-1234-1234-1234-123456789ABD",
                                   BLEWrite);

void setup() {
  Bluefruit.begin();
  Bluefruit.setName("Tether");
  tetherService.begin();
  commandChar.begin();
  commandChar.setWriteCallback(onCommandReceived);
  Bluefruit.Advertising.addService(tetherService);
  Bluefruit.Advertising.start();
}
```

### 5.3 LED Patterns

```cpp
void onCommandReceived(BLECharacteristic* chr, uint8_t* data, uint16_t len) {
  uint8_t cmd = data[0];
  if (cmd == 0x01) warnBlink();   // slow: 3 x (500ms on / 500ms off)
  if (cmd == 0x02) zapBlink();    // fast: 10 x (80ms on / 80ms off)
  if (cmd == 0x00) digitalWrite(LED_PIN, LOW);
}
```

LED pin: use the onboard LED (PIN_LED1 on XIAO nRF52840 = P0.26).

### 5.4 Bond / Auto-reconnect

```cpp
Bluefruit.Security.setSecureMode(true);  // enables bonding
// After first pairing, nRF stores bond key in flash
// iOS reconnects automatically using stored peripheral UUID
```

---

## 6. Data Model

```swift
struct AppRule: Codable, Identifiable {
    let id: UUID
    var bundleID: String
    var displayName: String
    var appToken: ApplicationToken   // FamilyControls opaque token
    var warnMinutes: Int             // default 10
    var zapMinutes: Int              // default 15
}
```

Stored in AppGroup shared UserDefaults as JSON array. Both the main app and the monitor extension read/write this key.

---

## 7. DeviceActivity Schedule

```swift
let schedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 0, minute: 0),
    intervalEnd:   DateComponents(hour: 23, minute: 59),
    repeats: true
)

// Per rule, register two events:
let warnEvent = DeviceActivityEvent(
    applications: [rule.appToken],
    threshold: DateComponents(minute: rule.warnMinutes)
)
let zapEvent = DeviceActivityEvent(
    applications: [rule.appToken],
    threshold: DateComponents(minute: rule.zapMinutes)
)

DeviceActivityCenter().startMonitoring(
    activityName,
    during: schedule,
    events: [.warn: warnEvent, .zap: zapEvent]
)
```

Each rule gets its own `DeviceActivityName` (keyed by rule UUID string) so events can be disambiguated in the monitor extension.

---

## 8. Build Order

1. **Firmware first** — flash LED blink patterns, verify with LightBlue manually writing 0x01 and 0x02. No iOS code yet.
2. **BLEManager** — build connection + write pipeline, test with LightBlue replaced by a Swift playground.
3. **Home + RuleEdit views** — UI only, mock data, no DeviceActivity yet.
4. **AppPicker + DeviceActivity** — add FamilyControls, verify monitor extension fires (log to AppGroup, check in main app).
5. **Bridge** — connect Darwin notification → BLEManager → LED. Full pipeline working.
6. **Polish** — reconnect edge cases, threshold enforcement, reset at midnight.

---

## 9. Open Questions

| # | Question | Decision needed by |
|---|---|---|
| 1 | Does the DeviceActivity threshold fire if the phone is locked mid-session? (It should — test to confirm) | Step 4 |
| 2 | What happens if BLE is disconnected when threshold fires? Queue the command and send on reconnect, or drop it? | Step 5 |
| 3 | Should warn and zap thresholds be per-app or global? PRD assumes per-app. | Before Step 3 |
| 4 | App name for App Store (affects bundle ID, Family Controls entitlement request) | Before TestFlight |

---

## 10. Success Criteria

Prototype is complete when:
- User adds Instagram with warn=10min, zap=15min
- Uses Instagram for 10 minutes on a real device
- Bracelet LED slow-blinks without any manual interaction
- Uses Instagram for 15 minutes
- Bracelet LED fast-blinks
- BLE reconnects automatically after airplane mode toggle
