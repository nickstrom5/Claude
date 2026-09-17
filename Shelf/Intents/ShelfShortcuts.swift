import AppIntents

/// Exposes the intent to Siri, Spotlight and the Shortcuts app. App target only.
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
