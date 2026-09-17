import Foundation

struct Stats: Codable, Equatable {
    var streak: Int = 0
    var longestStreak: Int = 0
    var totalMinutes: Int = 0
    var sessionsCompleted: Int = 0
    var lastCompletedDay: Date?

    mutating func registerCompleted(_ session: FocusSession) {
        totalMinutes += session.actualMinutes
        sessionsCompleted += 1
        guard !session.isTaste else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: session.end ?? Date())

        if let last = lastCompletedDay {
            let lastDay = cal.startOfDay(for: last)
            if cal.isDate(lastDay, inSameDayAs: today) {
                // Already counted today.
            } else if let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                      cal.isDate(lastDay, inSameDayAs: yesterday) {
                streak += 1
            } else {
                streak = 1
            }
        } else {
            streak = 1
        }
        lastCompletedDay = today
        longestStreak = max(longestStreak, streak)
    }

    /// Early exit: the streak resets. This is the whole point of the friction.
    mutating func registerAbandoned(_ session: FocusSession) {
        totalMinutes += session.actualMinutes
        guard !session.isTaste else { return }
        streak = 0
    }

    var totalFormatted: String {
        if totalMinutes >= 60 {
            return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
        }
        return "\(totalMinutes)m"
    }
}
