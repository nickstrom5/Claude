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
        let defaults = AppGroup.defaults
        defaults.removeObject(forKey: AppGroup.Key.activeSessionEnd)
        defaults.removeObject(forKey: AppGroup.Key.activeSessionMinutes)
    }
}
