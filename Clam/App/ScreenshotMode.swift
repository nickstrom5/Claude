import Foundation
import UIKit

/// Launch the app with `-screenshot <screen>` to open one screen with seeded data.
/// Used by `.github/workflows/screenshots.yml` to capture every screen in the simulator, and
/// handy for App Store screenshots. Never active in a normal launch.
enum ScreenshotMode {
    enum Screen: String, CaseIterable {
        case hook, hours, apps, triggers, reveal, permission, taste, result, paywall
        case home, session, settings, share
    }

    static let screen: Screen? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return Screen(rawValue: args[i + 1])
    }()

    static var isActive: Bool { screen != nil }

    /// Fills the app with believable data so screens don't look empty.
    @MainActor
    static func seed(_ appState: AppState, screenTime: ScreenTimeManager) {
        UIView.setAnimationsEnabled(false)
        // Each screen is a fresh launch; never inherit a session from the previous capture.
        AppGroup.defaults.removeObject(forKey: AppGroup.Key.activeSessionEnd)
        AppGroup.defaults.removeObject(forKey: AppGroup.Key.activeSessionMinutes)
        appState.answers.hoursPerDay = 4.5
        appState.answers.triggers = [.bored, .inBed, .justChecking]
        appState.preferredMinutes = 25
        screenTime.simulatedSelectionCount = 4

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let minutesByDay = [50, 25, 90, 0, 75, 50, 134]
        var history: [FocusSession] = []
        for (offset, minutes) in minutesByDay.enumerated() where minutes > 0 {
            let day = cal.date(byAdding: .day, value: offset - 6, to: today)!
            let start = day.addingTimeInterval(9 * 3600)
            history.append(FocusSession(start: start, plannedMinutes: minutes,
                                        end: start.addingTimeInterval(Double(minutes) * 60), completed: true))
        }
        appState.history = history
        appState.stats = Stats(streak: 12, longestStreak: 19, totalMinutes: 1_830, sessionsCompleted: 41,
                               lastCompletedDay: today)
        appState.hasCompletedOnboarding = {
            switch screen {
            case .home, .session, .settings, .share: return true
            default: return false
            }
        }()
    }

    /// A finished session for the result / share screen.
    static var sampleFinishedSession: FocusSession {
        let start = Date().addingTimeInterval(-134 * 60)
        return FocusSession(start: start, plannedMinutes: 134, end: Date(), completed: true)
    }
}
