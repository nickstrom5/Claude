import Foundation

struct FocusSession: Codable, Identifiable, Equatable {
    var id = UUID()
    var start: Date
    var plannedMinutes: Int
    var end: Date?
    var completed: Bool = false
    /// True for the 60-second onboarding session, so it doesn't count toward the streak.
    var isTaste: Bool = false

    var plannedEnd: Date {
        start.addingTimeInterval(TimeInterval(plannedMinutes * 60))
    }

    /// Rounded to the nearest minute so a 59.8s taste session reads as 1m, not 0m.
    var actualMinutes: Int {
        let finish = end ?? Date()
        return max(0, Int((finish.timeIntervalSince(start) / 60).rounded()))
    }

    var formattedDuration: String {
        let minutes = actualMinutes
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}
