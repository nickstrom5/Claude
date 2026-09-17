import AppIntents

/// Exposes the intent to Siri, Spotlight and the Shortcuts app. App target only.
struct ClamShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartClamSessionIntent(),
            phrases: [
                "Clam up with \(.applicationName)",
                "Start a \(.applicationName) session",
                "Lock my apps with \(.applicationName)"
            ],
            shortTitle: "Clam up",
            systemImageName: "flipphone"
        )
    }
}
