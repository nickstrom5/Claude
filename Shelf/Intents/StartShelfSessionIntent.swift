import AppIntents
import Foundation

/// Lets Siri, Shortcuts and the Action Button start a session. "Press the Action Button to brick
/// your phone" is a demo in itself, and it removes the last bit of friction from the core loop.
struct StartShelfSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Shelf my phone"
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

struct ShelfShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartShelfSessionIntent(),
            phrases: [
                "Shelf my phone in \(.applicationName)",
                "Start a \(.applicationName) session",
                "Lock my apps with \(.applicationName)"
            ],
            shortTitle: "Shelf it",
            systemImageName: "books.vertical.fill"
        )
    }
}
