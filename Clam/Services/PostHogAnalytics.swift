import Foundation
import PostHog

/// Sends every `AnalyticsEvent` to PostHog. Anonymous: no user identification, no session
/// replay, no autocapture of screens. Just the funnel events we defined.
struct PostHogAnalytics: AnalyticsSink {
    static func start() -> PostHogAnalytics? {
        guard Config.analyticsEnabled, !Analytics.isOptedOut else { return nil }
        let config = PostHogConfig(projectToken: Config.postHogKey, host: Config.postHogHost)
        // Off deliberately. Anything the SDK captures by itself would bypass the opt-out gate
        // in `Analytics.track`, and the privacy policy promises the switch stops everything.
        // Our own `appOpen` event covers opens and goes through the gate.
        config.captureApplicationLifecycleEvents = false
        config.captureScreenViews = false
        config.sessionReplay = false
        PostHogSDK.shared.setup(config)
        return PostHogAnalytics()
    }

    func track(_ event: AnalyticsEvent, _ properties: [String: Any]) {
        PostHogSDK.shared.capture(event.rawValue, properties: properties)
    }
}

/// Fans one event out to several sinks (console in debug, PostHog in the wild).
struct CompositeAnalytics: AnalyticsSink {
    let sinks: [AnalyticsSink]
    func track(_ event: AnalyticsEvent, _ properties: [String: Any]) {
        sinks.forEach { $0.track(event, properties) }
    }
}
