import Foundation

/// Constants shared between the app, the shield extension and the widget extension.
enum AppGroup {
    static let identifier = "group.app.getclam.clam"

    /// UserDefaults suite shared across the app and its extensions.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    enum Key {
        /// ISO-8601 end date of the currently running session, if any. Read by the shield extension.
        static let activeSessionEnd = "activeSessionEnd"
        /// Planned minutes of the active session.
        static let activeSessionMinutes = "activeSessionMinutes"
        /// Encoded `FamilyActivitySelection` chosen in onboarding.
        static let activitySelection = "activitySelection"
        /// Current streak in days.
        static let streak = "streak"
        /// Minutes requested by the Siri / Shortcuts / Action Button intent, consumed on next foreground.
        static let pendingSessionMinutes = "pendingSessionMinutes"
    }
}
