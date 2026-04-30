import Foundation

#if os(iOS) && canImport(DeviceActivity) && canImport(ManagedSettings)
import DeviceActivity
import FamilyControls
import ManagedSettings

/// Registers DeviceActivity monitoring schedules for each app rule.
/// Call `scheduleAll()` after rules change.
@available(iOS 16.0, *)
class ActivityScheduler {

    private let center = DeviceActivityCenter()

    private let dailySchedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: 0, minute: 0),
        intervalEnd: DateComponents(hour: 23, minute: 59),
        repeats: true
    )

    func scheduleAll(rules: [AppRule]) {
        center.stopMonitoring()

        for rule in rules {
            guard let tokenData = rule.appTokenData,
                  let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData)
            else { continue }

            let activityName = DeviceActivityName(rule.id.uuidString)

            let warnEvent = DeviceActivityEvent(
                applications: [token],
                threshold: DateComponents(minute: rule.warnMinutes)
            )
            let zapEvent = DeviceActivityEvent(
                applications: [token],
                threshold: DateComponents(minute: rule.zapMinutes)
            )

            let warnKey = DeviceActivityEvent.Name("\(rule.id.uuidString)_warn")
            let zapKey = DeviceActivityEvent.Name("\(rule.id.uuidString)_zap")

            do {
                try center.startMonitoring(
                    activityName,
                    during: dailySchedule,
                    events: [warnKey: warnEvent, zapKey: zapEvent]
                )
                print("[Schedule] Monitoring \(rule.displayName): warn=\(rule.warnMinutes)m, zap=\(rule.zapMinutes)m")
            } catch {
                print("[Schedule] Failed to monitor \(rule.displayName): \(error)")
            }
        }
    }

    func stopAll() {
        center.stopMonitoring()
    }
}

#else

class ActivityScheduler {
    func scheduleAll(rules: [AppRule]) {
        print("[Schedule] DeviceActivity not available — skipping")
    }
    func stopAll() {}
}
#endif
