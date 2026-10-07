import DeviceActivity
import Foundation
import ManagedSettings

/// Safety net. iOS calls this extension when the scheduled session window ends, even if the app
/// was suspended or killed, so the shield never outlives the timer.
final class ClamMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("clam"))

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.clearAllSettings()
        DeviceActivityCenter().stopMonitoring([activity])

        // Hand the session to the app rather than erasing it. If we just deleted these keys,
        // the app would find nothing on next launch and the session would never be recorded:
        // no streak, no result card, no analytics. That is the case this extension exists for.
        let defaults = AppGroup.defaults
        if let end = defaults.string(forKey: AppGroup.Key.activeSessionEnd) {
            defaults.set([
                "end": end,
                "start": defaults.string(forKey: AppGroup.Key.activeSessionStart) ?? "",
                "minutes": defaults.integer(forKey: AppGroup.Key.activeSessionMinutes),
                "isTaste": defaults.bool(forKey: AppGroup.Key.activeSessionIsTaste),
            ] as [String: Any], forKey: AppGroup.Key.finishedWhileAway)
        }
        defaults.removeObject(forKey: AppGroup.Key.activeSessionEnd)
        defaults.removeObject(forKey: AppGroup.Key.activeSessionMinutes)
        defaults.removeObject(forKey: AppGroup.Key.activeSessionStart)
        defaults.removeObject(forKey: AppGroup.Key.activeSessionIsTaste)
    }
}
