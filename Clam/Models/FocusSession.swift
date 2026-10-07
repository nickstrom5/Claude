import Foundation

struct FocusSession: Codable, Identifiable, Equatable {
    var id = UUID()
    var start: Date
    var plannedMinutes: Int
    var end: Date?
    var completed: Bool = false
    /// True for the 60-second onboarding session, so it doesn't count toward the streak.
    var isTaste: Bool = false

    init(id: UUID = UUID(), start: Date, plannedMinutes: Int, end: Date? = nil,
         completed: Bool = false, isTaste: Bool = false) {
        self.id = id
        self.start = start
        self.plannedMinutes = plannedMinutes
        self.end = end
        self.completed = completed
        self.isTaste = isTaste
    }

    // Tolerant decode, like Stats. Swift's synthesised version throws on a missing key rather
    // than using the property default, so adding one field in a later version would make the
    // whole stored history array fail to decode and every past session would vanish.
    private enum CodingKeys: String, CodingKey {
        case id, start, plannedMinutes, end, completed, isTaste
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        start = try c.decode(Date.self, forKey: .start)
        plannedMinutes = try c.decodeIfPresent(Int.self, forKey: .plannedMinutes) ?? 0
        end = try c.decodeIfPresent(Date.self, forKey: .end)
        completed = try c.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        isTaste = try c.decodeIfPresent(Bool.self, forKey: .isTaste) ?? false
    }

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
