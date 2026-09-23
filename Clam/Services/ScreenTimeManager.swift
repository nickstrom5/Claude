import Combine
import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// Wraps Apple's Screen Time APIs: authorization, the user's app selection, and the shield.
///
/// Requires the `com.apple.developer.family-controls` entitlement. Development builds work with
/// the entitlement in Xcode; App Store distribution needs Apple's approval (see docs/04).
@MainActor
final class ScreenTimeManager: ObservableObject {
    @Published private(set) var isAuthorized: Bool
    @Published var selection: FamilyActivitySelection {
        didSet { persistSelection() }
    }

    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("clam"))
    private let defaults = AppGroup.defaults

    /// Screen Time APIs don't work in the simulator: authorization fails, the picker is empty and
    /// shields do nothing. In the simulator we pretend, so the full onboarding, paywall and session
    /// loop can be clicked through. Everything under `isSimulator` is compiled out on device.
    #if targetEnvironment(simulator)
    static let isSimulator = true
    #else
    static let isSimulator = false
    #endif

    /// Stand-in for the number of picked apps when running in the simulator.
    @Published var simulatedSelectionCount: Int = AppGroup.defaults.integer(forKey: "simulatedSelectionCount") {
        didSet { defaults.set(simulatedSelectionCount, forKey: "simulatedSelectionCount") }
    }

    init() {
        isAuthorized = Self.isSimulator || AuthorizationCenter.shared.authorizationStatus == .approved
        if let data = AppGroup.defaults.data(forKey: AppGroup.Key.activitySelection),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        } else {
            selection = FamilyActivitySelection(includeEntireCategory: true)
        }
    }

    /// Number of things the user chose to shelve, for copy like "6 apps locked".
    var selectedCount: Int {
        if Self.isSimulator { return simulatedSelectionCount }
        return selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    var hasSelection: Bool { selectedCount > 0 }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        if Self.isSimulator {
            isAuthorized = true
            return true
        }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        } catch {
            isAuthorized = false
            Analytics.track(.screenTimeDenied, ["error": String(describing: error)])
        }
        if isAuthorized { Analytics.track(.screenTimeAuthorized) }
        return isAuthorized
    }

    func refreshAuthorization() {
        isAuthorized = Self.isSimulator || AuthorizationCenter.shared.authorizationStatus == .approved
    }

    // MARK: - Shield

    /// Puts the chosen apps behind the Clam block screen.
    func applyShield() {
        guard !Self.isSimulator else { return }
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens, except: Set())
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens, except: Set())
    }

    /// Removes every restriction Clam set.
    func clearShield() {
        guard !Self.isSimulator else { return }
        store.clearAllSettings()
    }

    // MARK: - Safety net

    private static let monitorName = DeviceActivityName("clam.session")
    /// DeviceActivity refuses schedules shorter than this. Shorter sessions rely on the in-app timer only.
    static let minimumMonitoredMinutes = 15

    /// Asks iOS to call the monitor extension when the session ends, so the shield is cleared even
    /// if the app is suspended or killed before the timer fires.
    /// The monitor extension is what clears the shield when the app is dead. DeviceActivity
    /// refuses windows shorter than 15 minutes, so a short session gets a 15-minute window
    /// instead of none: the app clears the shield on time in the normal case, and this caps
    /// how long a shield can survive when it doesn't.
    func scheduleShieldRemoval(start: Date, end: Date) {
        guard !Self.isSimulator else { return }
        let floor = start.addingTimeInterval(Double(Self.minimumMonitoredMinutes * 60))
        let monitoredEnd = max(end, floor)
        let units: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let cal = Calendar.current
        let schedule = DeviceActivitySchedule(
            intervalStart: cal.dateComponents(units, from: start),
            intervalEnd: cal.dateComponents(units, from: monitoredEnd),
            repeats: false
        )
        do {
            try DeviceActivityCenter().startMonitoring(Self.monitorName, during: schedule)
        } catch {
            Analytics.track(.monitorScheduleFailed, ["error": String(describing: error)])
        }
    }

    func cancelShieldRemoval() {
        guard !Self.isSimulator else { return }
        DeviceActivityCenter().stopMonitoring([Self.monitorName])
    }

    // MARK: - Private

    private func persistSelection() {
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: AppGroup.Key.activitySelection)
        }
    }
}
