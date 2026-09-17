import Foundation
import SwiftUI

/// Small, persisted app state. Everything here is local; there is no backend in v1.
@MainActor
final class AppState: ObservableObject {
    private let defaults = AppGroup.defaults

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    @Published var answers: OnboardingAnswers {
        didSet { save(answers, forKey: "onboardingAnswers") }
    }

    @Published var stats: Stats {
        didSet {
            save(stats, forKey: "stats")
            // Mirror the streak for the shield extension's subtitle.
            defaults.set(stats.streak, forKey: AppGroup.Key.streak)
        }
    }

    @Published var history: [FocusSession] {
        didSet { save(history, forKey: "history") }
    }

    /// Set when the app comes to the foreground because of the "Shelf my phone" intent.
    @Published var pendingIntentMinutes: Int?

    /// Reads and clears the minutes left behind by `StartShelfSessionIntent`, if any.
    func consumePendingIntent() {
        let minutes = defaults.integer(forKey: AppGroup.Key.pendingSessionMinutes)
        guard minutes > 0 else { return }
        defaults.removeObject(forKey: AppGroup.Key.pendingSessionMinutes)
        pendingIntentMinutes = minutes
    }

    /// Default session length the user last picked.
    @Published var preferredMinutes: Int {
        didSet { defaults.set(preferredMinutes, forKey: "preferredMinutes") }
    }

    init() {
        hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        answers = Self.load(OnboardingAnswers.self, forKey: "onboardingAnswers", from: defaults) ?? OnboardingAnswers()
        stats = Self.load(Stats.self, forKey: "stats", from: defaults) ?? Stats()
        history = Self.load([FocusSession].self, forKey: "history", from: defaults) ?? []
        let minutes = defaults.integer(forKey: "preferredMinutes")
        preferredMinutes = minutes == 0 ? 25 : minutes
    }

    // MARK: - Session bookkeeping

    func record(_ session: FocusSession) {
        history.append(session)
        if history.count > 500 { history.removeFirst(history.count - 500) }

        if session.completed {
            stats.registerCompleted(session)
        } else {
            stats.registerAbandoned(session)
        }
    }

    var todayMinutes: Int {
        let cal = Calendar.current
        return history
            .filter { cal.isDateInToday($0.start) }
            .reduce(0) { $0 + $1.actualMinutes }
    }

    /// Minutes per day for the last 7 days, oldest first. Used by the home chart.
    var lastSevenDays: [(date: Date, minutes: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let minutes = history
                .filter { cal.isDate($0.start, inSameDayAs: day) }
                .reduce(0) { $0 + $1.actualMinutes }
            return (day, minutes)
        }
    }

    // MARK: - Persistence helpers

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, forKey key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
