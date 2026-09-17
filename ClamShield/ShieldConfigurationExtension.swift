import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Customizes the block screen iOS shows when the user opens a shielded app during a session.
/// This screen is part of the marketing: it is what people screen-record and post.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        clamConfiguration(appName: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        clamConfiguration(appName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        clamConfiguration(appName: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        clamConfiguration(appName: webDomain.domain)
    }

    // MARK: - Private

    private func clamConfiguration(appName: String?) -> ShieldConfiguration {
        let defaults = AppGroup.defaults
        let streak = defaults.integer(forKey: AppGroup.Key.streak)

        var subtitle = "Fold it back up. Your future self says thanks."
        if let endString = defaults.string(forKey: AppGroup.Key.activeSessionEnd),
           let end = ISO8601DateFormatter().date(from: endString) {
            let remaining = max(0, Int(end.timeIntervalSinceNow / 60))
            subtitle = remaining > 0
                ? "\(remaining) min left. Streak: \(streak) day\(streak == 1 ? "" : "s")."
                : "Session is wrapping up."
        }

        let name = appName ?? "This app"

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1),
            icon: UIImage(systemName: "flipphone"),
            title: ShieldConfiguration.Label(text: "\(name) is clammed up", color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: UIColor.white.withAlphaComponent(0.7)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK, I'll wait", color: .black),
            primaryButtonBackgroundColor: UIColor(red: 0.98, green: 0.82, blue: 0.35, alpha: 1),
            secondaryButtonLabel: nil
        )
    }
}
