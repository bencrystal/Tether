import Foundation
#if canImport(DeviceActivity)
import DeviceActivity

class TetherMonitor: DeviceActivityMonitor {

    let sharedDefaults = UserDefaults(suiteName: "group.com.tether.app")

    override func intervalDidStart(for activity: DeviceActivityName) {
        // Daily interval started — nothing to do
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        // Daily interval ended — thresholds reset automatically
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        let commandByte: UInt8

        // Event names are formatted as "<ruleID>_warn" or "<ruleID>_zap"
        let eventStr = event.rawValue
        if eventStr.hasSuffix("_warn") {
            commandByte = 0x01
        } else if eventStr.hasSuffix("_zap") {
            commandByte = 0x02
        } else {
            return
        }

        // Write to shared container for main app to pick up
        sharedDefaults?.set(commandByte, forKey: "tether_pending_command")
        sharedDefaults?.set(Date(), forKey: "tether_command_timestamp")

        // Post Darwin notification to wake main app
        let name = "com.tether.app.pendingCommand" as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name),
            nil, nil, true
        )
    }
}
#else
// Stub when DeviceActivity framework is unavailable
import Foundation
class TetherMonitor {
    init() {
        print("[Monitor] DeviceActivity not available — stub loaded")
    }
}
#endif
