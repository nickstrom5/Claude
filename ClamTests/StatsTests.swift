import XCTest
@testable import Clam

final class StatsTests: XCTestCase {
    private let cal = Calendar.current

    private func session(daysAgo: Int, minutes: Int = 25, completed: Bool = true, isTaste: Bool = false) -> FocusSession {
        let end = cal.date(byAdding: .day, value: -daysAgo, to: cal.startOfDay(for: Date()))!.addingTimeInterval(12 * 3600)
        let start = end.addingTimeInterval(-TimeInterval(minutes * 60))
        return FocusSession(start: start, plannedMinutes: minutes, end: end, completed: completed, isTaste: isTaste)
    }

    func testFirstCompletedSessionStartsStreakAtOne() {
        var stats = Stats()
        stats.registerCompleted(session(daysAgo: 0))
        XCTAssertEqual(stats.streak, 1)
        XCTAssertEqual(stats.longestStreak, 1)
        XCTAssertEqual(stats.sessionsCompleted, 1)
        XCTAssertEqual(stats.totalMinutes, 25)
    }

    func testConsecutiveDaysIncrementStreak() {
        var stats = Stats()
        stats.registerCompleted(session(daysAgo: 2))
        stats.registerCompleted(session(daysAgo: 1))
        stats.registerCompleted(session(daysAgo: 0))
        XCTAssertEqual(stats.streak, 3)
        XCTAssertEqual(stats.longestStreak, 3)
    }

    func testTwoSessionsSameDayCountOnce() {
        var stats = Stats()
        stats.registerCompleted(session(daysAgo: 0))
        stats.registerCompleted(session(daysAgo: 0))
        XCTAssertEqual(stats.streak, 1)
        XCTAssertEqual(stats.sessionsCompleted, 2)
    }

    func testGapResetsStreakToOne() {
        var stats = Stats()
        stats.registerCompleted(session(daysAgo: 3))
        stats.registerCompleted(session(daysAgo: 2))
        stats.registerCompleted(session(daysAgo: 0))
        XCTAssertEqual(stats.streak, 1)
        XCTAssertEqual(stats.longestStreak, 2)
    }

    func testAbandonResetsStreakButKeepsMinutes() {
        var stats = Stats()
        stats.registerCompleted(session(daysAgo: 1))
        stats.registerCompleted(session(daysAgo: 0))
        stats.registerAbandoned(session(daysAgo: 0, minutes: 10, completed: false))
        XCTAssertEqual(stats.streak, 0)
        XCTAssertEqual(stats.longestStreak, 2)
        XCTAssertEqual(stats.totalMinutes, 60)
    }

    func testTasteSessionDoesNotAffectStreak() {
        var stats = Stats()
        stats.registerCompleted(session(daysAgo: 0, minutes: 1, isTaste: true))
        XCTAssertEqual(stats.streak, 0)
        XCTAssertEqual(stats.sessionsCompleted, 1)
        stats.registerAbandoned(session(daysAgo: 0, minutes: 1, completed: false, isTaste: true))
        XCTAssertEqual(stats.streak, 0)
    }

    func testTotalFormatted() {
        var stats = Stats()
        stats.totalMinutes = 59
        XCTAssertEqual(stats.totalFormatted, "59m")
        stats.totalMinutes = 135
        XCTAssertEqual(stats.totalFormatted, "2h 15m")
    }
}
