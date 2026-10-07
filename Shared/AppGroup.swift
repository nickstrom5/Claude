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
        /// True while the active session is the 60-second onboarding taste. Without this the
        /// session cannot be rebuilt correctly after the app is killed.
        static let activeSessionIsTaste = "activeSessionIsTaste"
        /// ISO-8601 start date of the active session, so a restore uses the real start rather
        /// than inferring one from the end and the planned length.
        static let activeSessionStart = "activeSessionStart"
        /// Written by the monitor extension when it ends a session the app was not alive for.
        /// The app consumes it on next launch and records the session properly.
        static let finishedWhileAway = "finishedWhileAway"
    }
}
