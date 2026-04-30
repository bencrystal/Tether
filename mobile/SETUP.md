# TetherApp — Xcode Setup Guide

## 1. Create the Xcode Project

1. Open Xcode → File → New → Project
2. Choose **App** (iOS), click Next
3. Product Name: `TetherApp`
4. Bundle Identifier: `com.tether.app`
5. Interface: **SwiftUI**
6. Language: **Swift**
7. Save into the `mobile/` directory

## 2. Add Source Files

Drag the following folders into the Xcode project navigator (check "Copy items if needed"):
- `TetherApp/App/`
- `TetherApp/Models/`
- `TetherApp/Views/`
- `TetherApp/Shared/`

Delete the auto-generated `ContentView.swift` and `TetherAppApp.swift` (our `TetherApp.swift` replaces both).

## 3. Add the DeviceActivity Monitor Extension

1. File → New → Target → **DeviceActivity Monitor Extension**
2. Product Name: `TetherActivityMonitor`
3. Bundle Identifier: `com.tether.app.activity-monitor`
4. Add `TetherActivityMonitor/TetherMonitor.swift` to this target
5. Add `TetherApp/Shared/Constants.swift` to **both** targets

## 4. Capabilities

### Main App Target (`TetherApp`)
- **Family Controls** (requires approved entitlement)
- **App Groups** → add `group.com.tether.app`
- **Background Modes** → check "Uses Bluetooth LE accessories"

### Extension Target (`TetherActivityMonitor`)
- **Family Controls**
- **App Groups** → add `group.com.tether.app`

## 5. Build & Run

- Must use a **physical iOS device** (Family Controls doesn't work on Simulator)
- If the Family Controls entitlement isn't approved yet, the app will still build — the `#if canImport(FamilyControls)` guards provide stub fallbacks
- Debug buttons on the Home screen let you test BLE commands without DeviceActivity

## File Structure

```
mobile/
├── SETUP.md
├── TetherApp/
│   ├── App/
│   │   └── TetherApp.swift           # @main entry point
│   ├── Models/
│   │   ├── AppRule.swift              # Data model + persistence
│   │   ├── BLEManager.swift           # CoreBluetooth central manager
│   │   └── ActivityScheduler.swift    # DeviceActivity registration
│   ├── Views/
│   │   ├── HomeView.swift             # Main screen: status + rules list
│   │   ├── AppPickerView.swift        # FamilyActivityPicker (or manual fallback)
│   │   └── RuleEditView.swift         # Threshold sliders
│   └── Shared/
│       └── Constants.swift            # UUIDs, keys, command bytes (shared with extension)
└── TetherActivityMonitor/
    └── TetherMonitor.swift            # DeviceActivityMonitor subclass
```
