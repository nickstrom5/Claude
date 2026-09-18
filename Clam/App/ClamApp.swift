import SwiftUI

@main
@MainActor
struct ClamApp: App {
    @StateObject private var appState: AppState
    @StateObject private var screenTime: ScreenTimeManager
    @StateObject private var store: StoreManager
    @StateObject private var sessions: SessionManager

    init() {
        var sinks: [AnalyticsSink] = [ConsoleAnalytics()]
        if let postHog = PostHogAnalytics.start() { sinks.append(postHog) }
        Analytics.sink = CompositeAnalytics(sinks: sinks)

        let state = AppState()
        let screenTime = ScreenTimeManager()
        _appState = StateObject(wrappedValue: state)
        _screenTime = StateObject(wrappedValue: screenTime)
        _store = StateObject(wrappedValue: StoreManager())
        _sessions = StateObject(wrappedValue: SessionManager(screenTime: screenTime, appState: state))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(screenTime)
                .environmentObject(store)
                .environmentObject(sessions)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .task {
                    Analytics.track(.appOpen)
                    sessions.restoreIfNeeded()
                    await store.load()
                }
        }
    }
}

/// Routes between onboarding and the main app.
struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var sessions: SessionManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if appState.hasCompletedOnboarding {
                HomeView()
                    .transition(.opacity)
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                sessions.refresh()
                appState.consumePendingIntent()
            }
        }
    }
}
