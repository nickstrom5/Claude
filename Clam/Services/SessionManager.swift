import ActivityKit
import Combine
import Foundation
import UserNotifications
import WidgetKit

/// The core loop: start a session → shield up + Live Activity → end → shield down + result.
@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var active: FocusSession?
    @Published private(set) var lastFinished: FocusSession?
    /// True while the user is holding the early-exit button.
    @Published var isHoldingToExit = false

    private let screenTime: ScreenTimeManager
    private let appState: AppState
    private let defaults = AppGroup.defaults
    private var activity: Activity<ClamActivityAttributes>?
    private var completionTask: Task<Void, Never>?

    /// How long the user must hold to abandon a session. Long enough to be a decision.
    static let earlyExitHoldSeconds: Double = 10

    init(screenTime: ScreenTimeManager, appState: AppState) {
        self.screenTime = screenTime
        self.appState = appState
    }

    var isActive: Bool { active != nil }

    // MARK: - Start / end

    func start(minutes: Int, isTaste: Bool = false) {
        guard active == nil else { return }
        let session = FocusSession(start: Date(), plannedMinutes: minutes, isTaste: isTaste)
        active = session
        lastFinished = nil

        screenTime.applyShield()
        screenTime.scheduleShieldRemoval(start: session.start, end: session.plannedEnd)
        defaults.set(ISO8601DateFormatter().string(from: session.plannedEnd), forKey: AppGroup.Key.activeSessionEnd)
        defaults.set(minutes, forKey: AppGroup.Key.activeSessionMinutes)

        startLiveActivity(for: session)
        scheduleCompletionNotification(at: session.plannedEnd)
        scheduleCompletion(at: session.plannedEnd)
        WidgetCenter.shared.reloadAllTimelines()

        Analytics.track(isTaste ? .tasteSessionStarted : .sessionStarted, ["minutes": minutes])
    }

    /// Called when the timer runs out.
    func complete() {
        guard var session = active else { return }
        session.end = Date()
        session.completed = true
        finish(session)
        Analytics.track(session.isTaste ? .tasteSessionCompleted : .sessionCompleted, ["minutes": session.actualMinutes])
    }

    /// Called after the user held the exit button for the full duration.
    func abandon() {
        guard var session = active else { return }
        session.end = Date()
        session.completed = false
        finish(session)
        Analytics.track(.sessionAbandoned, ["elapsedMinutes": session.actualMinutes, "planned": session.plannedMinutes])
    }

    /// Call whenever the app comes to the foreground. The in-app timer can't fire while the app
    /// is suspended, so this closes out any session whose time has passed.
    func refresh() {
        if let session = active, session.plannedEnd <= Date() {
            complete()
        } else if active == nil {
            restoreIfNeeded()
        }
    }

    /// If the app was killed mid-session, pick up where we left off (or close it out).
    func restoreIfNeeded() {
        guard !ScreenshotMode.isActive, active == nil else { return }
        guard let endString = defaults.string(forKey: AppGroup.Key.activeSessionEnd),
              let end = ISO8601DateFormatter().date(from: endString) else {
            // No session is stored, so nothing should be shielded. If something still is, a
            // previous run died before it could clean up: clear it rather than leave apps locked.
            screenTime.clearShield()
            screenTime.cancelShieldRemoval()
            return
        }

        let minutes = defaults.integer(forKey: AppGroup.Key.activeSessionMinutes)
        let start = end.addingTimeInterval(-TimeInterval(minutes * 60))
        var session = FocusSession(start: start, plannedMinutes: minutes)

        if end <= Date() {
            session.end = end
            session.completed = true
            finish(session)
        } else {
            active = session
            screenTime.applyShield()
            activity = Activity<ClamActivityAttributes>.activities.first
            scheduleCompletion(at: end)
        }
    }

    // MARK: - Private

    private func finish(_ session: FocusSession) {
        completionTask?.cancel()
        completionTask = nil
        screenTime.clearShield()
        screenTime.cancelShieldRemoval()
        defaults.removeObject(forKey: AppGroup.Key.activeSessionEnd)
        defaults.removeObject(forKey: AppGroup.Key.activeSessionMinutes)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["clam.sessionEnd"])
        endLiveActivity()
        appState.record(session)
        active = nil
        lastFinished = session
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func scheduleCompletion(at end: Date) {
        completionTask?.cancel()
        completionTask = Task { [weak self] in
            let interval = end.timeIntervalSinceNow
            if interval > 0 {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            self?.complete()
        }
    }

    // MARK: Live Activity

    private func startLiveActivity(for session: FocusSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = ClamActivityAttributes(startDate: session.start, plannedMinutes: session.plannedMinutes)
        let state = ClamActivityAttributes.ContentState(
            endDate: session.plannedEnd,
            shieldedCount: screenTime.selectedCount,
            streak: appState.stats.streak
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: session.plannedEnd.addingTimeInterval(60)),
                pushType: nil
            )
        } catch {
            Analytics.track(.liveActivityFailed, ["error": String(describing: error)])
        }
    }

    private func endLiveActivity() {
        let current = activity
        activity = nil
        Task {
            if let current {
                await current.end(nil, dismissalPolicy: .immediate)
            }
            // Also clean up any stragglers from a previous process.
            for stale in Activity<ClamActivityAttributes>.activities {
                await stale.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: Notification

    private func scheduleCompletionNotification(at end: Date) {
        guard !ScreenshotMode.isActive else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Clam session done"
            content.body = "Your apps are back. Nice work."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, end.timeIntervalSinceNow), repeats: false)
            center.add(UNNotificationRequest(identifier: "clam.sessionEnd", content: content, trigger: trigger))
        }
    }
}
