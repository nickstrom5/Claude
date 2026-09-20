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
        if ScreenshotMode.isActive { ScreenshotMode.seed(state, screenTime: screenTime) }
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
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Group {
                if let screen = ScreenshotMode.screen {
                    ScreenshotRouter(screen: screen)
                } else if appState.hasCompletedOnboarding {
                    HomeView()
                        .transition(.opacity)
                } else {
                    OnboardingFlow()
                        .transition(.opacity)
                }
            }
            // iPhone Duo's inner display reports a regular width class. Keep the one-column
            // layout readable there by capping its width, per Apple's Duo guidance.
            .frame(maxWidth: sizeClass == .regular ? Theme.regularWidthMax : .infinity)
            .frame(maxWidth: .infinity)
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

/// Renders exactly one screen for `-screenshot <name>` launches.
private struct ScreenshotRouter: View {
    @EnvironmentObject private var sessions: SessionManager
    @EnvironmentObject private var appState: AppState
    let screen: ScreenshotMode.Screen

    var body: some View {
        Group {
            switch screen {
            case .hook:       OnboardingFlow(initialStep: .hook)
            case .hours:      OnboardingFlow(initialStep: .hours)
            case .apps:       OnboardingFlow(initialStep: .apps)
            case .triggers:   OnboardingFlow(initialStep: .triggers)
            case .reveal:     OnboardingFlow(initialStep: .reveal)
            case .permission: OnboardingFlow(initialStep: .permission)
            case .taste:      OnboardingFlow(initialStep: .taste)
            case .result:     OnboardingFlow(initialStep: .result)
            case .paywall:    PaywallView(context: .onboarding, onFinished: {})
            case .home:       HomeView()
            case .session:    HomeView()
            case .settings:   SettingsView()
            case .share:      SessionResultView(session: ScreenshotMode.sampleFinishedSession)
            }
        }
        .onAppear {
            switch screen {
            case .taste: sessions.start(minutes: 1, isTaste: true)
            case .session: sessions.start(minutes: 25)
            default: break
            }
        }
    }
}
