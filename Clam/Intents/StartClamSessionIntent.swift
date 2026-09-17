import AppIntents
import Foundation

/// Lets Siri, Shortcuts and the Action Button start a session. "Press the Action Button to brick
/// your phone" is a demo in itself, and it removes the last bit of friction from the core loop.
struct StartClamSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Clam up"
    static var description = IntentDescription("Locks your chosen apps for a focus session.")
    static var openAppWhenRun = true

    @Parameter(title: "Minutes", default: 25)
    var minutes: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        let clamped = min(max(minutes, 1), 240)
        AppGroup.defaults.set(clamped, forKey: AppGroup.Key.pendingSessionMinutes)
        return .result()
    }
}
