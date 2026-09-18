import Foundation

struct Stats: Codable, Equatable {
    var streak: Int = 0
    var longestStreak: Int = 0
    var totalMinutes: Int = 0
    var sessionsCompleted: Int = 0
    var lastCompletedDay: Date?

    // Personal records. Added in 1.1; decode with defaults so older saved stats still load.
    var longestSessionMinutes: Int = 0
    var bestDayMinutes: Int = 0
    var unlockedBadges: Set<String> = []

    /// A personal best that a completed session just set.
    enum Record: String, CaseIterable, Identifiable {
        case longestSession, longestStreak, bestDay
        var id: String { rawValue }
        var title: String {
            switch self {
            case .longestSession: return "Longest session"
            case .longestStreak: return "Longest streak"
            case .bestDay: return "Best day"
            }
        }
    }

    /// What the session just achieved. Shown once on the result screen.
    struct Achievements: Equatable {
        var records: [Record] = []
        var badges: [Badge] = []
        var isEmpty: Bool { records.isEmpty && badges.isEmpty }
    }

    init() {}

    // MARK: Codable (tolerant of missing keys from earlier versions)

    private enum CodingKeys: String, CodingKey {
        case streak, longestStreak, totalMinutes, sessionsCompleted, lastCompletedDay
        case longestSessionMinutes, bestDayMinutes, unlockedBadges
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        longestStreak = try c.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        totalMinutes = try c.decodeIfPresent(Int.self, forKey: .totalMinutes) ?? 0
        sessionsCompleted = try c.decodeIfPresent(Int.self, forKey: .sessionsCompleted) ?? 0
        lastCompletedDay = try c.decodeIfPresent(Date.self, forKey: .lastCompletedDay)
        longestSessionMinutes = try c.decodeIfPresent(Int.self, forKey: .longestSessionMinutes) ?? 0
        bestDayMinutes = try c.decodeIfPresent(Int.self, forKey: .bestDayMinutes) ?? 0
        unlockedBadges = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedBadges) ?? []
    }

    // MARK: Updates

    /// Registers a completed session. `todayMinutes` is the day's total including this session.
    /// Returns the records and badges the session just earned.
    @discardableResult
    mutating func registerCompleted(_ session: FocusSession, todayMinutes: Int = 0) -> Achievements {
        totalMinutes += session.actualMinutes
        sessionsCompleted += 1
        var earned = Achievements()
        guard !session.isTaste else { return earned }

        let cal = Calendar.current
        let today = cal.startOfDay(for: session.end ?? Date())
        let previousLongestStreak = longestStreak

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

        // Records. A first-ever value counts only once it's meaningful (more than one session).
        if session.actualMinutes > longestSessionMinutes {
            if longestSessionMinutes > 0 { earned.records.append(.longestSession) }
            longestSessionMinutes = session.actualMinutes
        }
        if longestStreak > previousLongestStreak, longestStreak >= 2 {
            earned.records.append(.longestStreak)
        }
        if todayMinutes > bestDayMinutes {
            if bestDayMinutes > 0, sessionsCompleted > 1 { earned.records.append(.bestDay) }
            bestDayMinutes = todayMinutes
        }

        // Badges.
        for badge in Badge.allCases where !unlockedBadges.contains(badge.rawValue) && badge.isEarned(by: self) {
            unlockedBadges.insert(badge.rawValue)
            earned.badges.append(badge)
        }
        return earned
    }

    /// Early exit: the streak resets. This is the whole point of the friction.
    mutating func registerAbandoned(_ session: FocusSession) {
        totalMinutes += session.actualMinutes
        guard !session.isTaste else { return }
        streak = 0
    }

    var totalFormatted: String { Self.format(minutes: totalMinutes) }

    static func format(minutes: Int) -> String {
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}

/// Milestones. Earned once, kept forever. Each one is a share-card moment.
enum Badge: String, CaseIterable, Identifiable {
    case firstSession, streak3, streak7, streak30, streak100
    case hours10, hours100, session2h, session4h, hundredSessions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstSession: return "First clam"
        case .streak3: return "3-day streak"
        case .streak7: return "One week"
        case .streak30: return "One month"
        case .streak100: return "100 days"
        case .hours10: return "10 hours"
        case .hours100: return "100 hours"
        case .session2h: return "2-hour session"
        case .session4h: return "4-hour session"
        case .hundredSessions: return "100 sessions"
        }
    }

    var detail: String {
        switch self {
        case .firstSession: return "Your first real session."
        case .streak3: return "Three days in a row."
        case .streak7: return "Seven days in a row."
        case .streak30: return "Thirty days in a row."
        case .streak100: return "A hundred days in a row."
        case .hours10: return "10 hours clammed up in total."
        case .hours100: return "100 hours clammed up in total."
        case .session2h: return "One session of two hours or more."
        case .session4h: return "One session of four hours or more."
        case .hundredSessions: return "100 sessions completed."
        }
    }

    var symbol: String {
        switch self {
        case .firstSession: return "sparkles"
        case .streak3, .streak7, .streak30, .streak100: return "flame.fill"
        case .hours10, .hours100: return "hourglass"
        case .session2h, .session4h: return "timer"
        case .hundredSessions: return "checkmark.seal.fill"
        }
    }

    func isEarned(by stats: Stats) -> Bool {
        switch self {
        case .firstSession: return stats.sessionsCompleted >= 1
        case .streak3: return stats.longestStreak >= 3
        case .streak7: return stats.longestStreak >= 7
        case .streak30: return stats.longestStreak >= 30
        case .streak100: return stats.longestStreak >= 100
        case .hours10: return stats.totalMinutes >= 10 * 60
        case .hours100: return stats.totalMinutes >= 100 * 60
        case .session2h: return stats.longestSessionMinutes >= 120
        case .session4h: return stats.longestSessionMinutes >= 240
        case .hundredSessions: return stats.sessionsCompleted >= 100
        }
    }
}
