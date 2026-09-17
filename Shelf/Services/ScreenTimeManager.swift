import Combine
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

    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("shelf"))
    private let defaults = AppGroup.defaults

    init() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        if let data = AppGroup.defaults.data(forKey: AppGroup.Key.activitySelection),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        } else {
            selection = FamilyActivitySelection(includeEntireCategory: true)
        }
    }

    /// Number of things the user chose to shelve, for copy like "6 apps locked".
    var selectedCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    var hasSelection: Bool { selectedCount > 0 }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
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
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    // MARK: - Shield

    /// Puts the chosen apps behind the Shelf block screen.
    func applyShield() {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens, except: Set())
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens, except: Set())
    }

    /// Removes every restriction Shelf set.
    func clearShield() {
        store.clearAllSettings()
    }

    // MARK: - Private

    private func persistSelection() {
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: AppGroup.Key.activitySelection)
        }
    }
}
