# TetherApp — Xcode Setup Guide

## Prerequisites

- Xcode 15+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Physical iOS device (Family Controls doesn't work on Simulator)

## Setup

```bash
cd mobile
xcodegen generate
open TetherApp.xcodeproj
```

This generates the full Xcode project from `project.yml` with both targets, entitlements, and build settings pre-configured.

## After Opening in Xcode

1. Select the **TetherApp** target → Signing & Capabilities → set your **Team**
2. Select the **TetherActivityMonitor** target → do the same
3. Select your physical iOS device as the run destination
4. Build & Run

## What's Pre-Configured

The `project.yml` handles all of this automatically:

| Setting | Value |
|---|---|
| Bundle ID (app) | `com.tether.app` |
| Bundle ID (extension) | `com.tether.app.activity-monitor` |
| iOS Deployment Target | 16.0 |
| Family Controls entitlement | Both targets |
| App Groups | `group.com.tether.app` (both targets) |
| Background Modes | Bluetooth LE |
| Bluetooth usage description | Set in Info.plist |

## Notes

- If the Family Controls entitlement isn't approved yet, the app still builds — `#if canImport(FamilyControls)` guards provide stub fallbacks
- Debug buttons on the Home screen let you test BLE commands (Warn/Zap/Off) without DeviceActivity
- After changing `project.yml`, close Xcode and re-run `xcodegen generate`

## File Structure

```
mobile/
├── project.yml                        # xcodegen project definition
├── SETUP.md
├── Shared/
│   └── Constants.swift                # BLE UUIDs, command bytes, shared keys (both targets)
├── TetherApp/
│   ├── TetherApp.entitlements
│   ├── App/
│   │   └── TetherApp.swift            # @main entry point
│   ├── Models/
│   │   ├── AppRule.swift              # Data model + App Group persistence
│   │   ├── BLEManager.swift           # CoreBluetooth central manager
│   │   └── ActivityScheduler.swift    # DeviceActivity registration
│   └── Views/
│       ├── HomeView.swift             # Main screen: BLE status + rules list
│       ├── AppPickerView.swift        # FamilyActivityPicker (or manual fallback)
│       └── RuleEditView.swift         # Threshold sliders
└── TetherActivityMonitor/
    ├── TetherActivityMonitor.entitlements
    └── TetherMonitor.swift            # DeviceActivityMonitor subclass
```
