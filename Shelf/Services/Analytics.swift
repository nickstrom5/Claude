import Foundation
import os

/// Every funnel event the business is judged on. Names are stable so the backend can change.
enum AnalyticsEvent: String {
    case appOpen = "app_open"
    case onboardingStarted = "onboarding_started"
    case onboardingStep = "onboarding_step"
    case onboardingCompleted = "onboarding_completed"
    case screenTimeAuthorized = "screen_time_authorized"
    case screenTimeDenied = "screen_time_denied"
    case appsSelected = "apps_selected"
    case tasteSessionStarted = "taste_session_started"
    case tasteSessionCompleted = "taste_session_completed"
    case paywallShown = "paywall_shown"
    case paywallDismissed = "paywall_dismissed"
    case planSelected = "plan_selected"
    case trialStarted = "trial_started"
    case paid = "paid"
    case purchaseCancelled = "purchase_cancelled"
    case purchaseFailed = "purchase_failed"
    case restoreTapped = "restore_tapped"
    case storeLoadFailed = "store_load_failed"
    case sessionStarted = "session_started"
    case sessionStartedFromIntent = "session_started_from_intent"
    case sessionCompleted = "session_completed"
    case sessionAbandoned = "session_abandoned"
    case shareTapped = "share_tapped"
    case liveActivityFailed = "live_activity_failed"
}

protocol AnalyticsSink {
    func track(_ event: AnalyticsEvent, _ properties: [String: Any])
}

/// Swap `sink` for PostHog / Mixpanel / Amplitude when the app goes live. Same event names.
enum Analytics {
    static var sink: AnalyticsSink = ConsoleAnalytics()

    static func track(_ event: AnalyticsEvent, _ properties: [String: Any] = [:]) {
        sink.track(event, properties)
    }
}

struct ConsoleAnalytics: AnalyticsSink {
    private let log = Logger(subsystem: "com.shelfapp.ios", category: "analytics")

    func track(_ event: AnalyticsEvent, _ properties: [String: Any]) {
        let props = properties.isEmpty ? "" : " \(properties)"
        log.info("\(event.rawValue, privacy: .public)\(props, privacy: .public)")
    }
}
