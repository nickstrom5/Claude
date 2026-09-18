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

    func testRecordsAreReportedOnceMeaningful() {
        var stats = Stats()
        let first = stats.registerCompleted(session(daysAgo: 1, minutes: 25), todayMinutes: 25)
        XCTAssertTrue(first.records.isEmpty, "a first value isn't a record yet")
        XCTAssertEqual(first.badges, [.firstSession])
        XCTAssertEqual(stats.longestSessionMinutes, 25)

        let second = stats.registerCompleted(session(daysAgo: 0, minutes: 90), todayMinutes: 90)
        XCTAssertEqual(Set(second.records), [.longestSession, .longestStreak, .bestDay])
        XCTAssertEqual(stats.longestSessionMinutes, 90)
        XCTAssertEqual(stats.bestDayMinutes, 90)

        let shorter = stats.registerCompleted(session(daysAgo: 0, minutes: 10), todayMinutes: 100)
        XCTAssertEqual(shorter.records, [.bestDay])
    }

    func testBadgesUnlockOnce() {
        var stats = Stats()
        for day in stride(from: 6, through: 0, by: -1) {
            _ = stats.registerCompleted(session(daysAgo: day, minutes: 25), todayMinutes: 25)
        }
        XCTAssertEqual(stats.longestStreak, 7)
        XCTAssertTrue(stats.unlockedBadges.contains(Badge.streak7.rawValue))
        XCTAssertTrue(stats.unlockedBadges.contains(Badge.streak3.rawValue))
        let again = stats.registerCompleted(session(daysAgo: 0, minutes: 25), todayMinutes: 50)
        XCTAssertTrue(again.badges.isEmpty, "badges are earned once")
    }

    func testDecodesStatsSavedBeforeRecordsExisted() throws {
        let legacy = #"{"streak":4,"longestStreak":9,"totalMinutes":300,"sessionsCompleted":12}"#
        let stats = try JSONDecoder().decode(Stats.self, from: Data(legacy.utf8))
        XCTAssertEqual(stats.streak, 4)
        XCTAssertEqual(stats.longestSessionMinutes, 0)
        XCTAssertTrue(stats.unlockedBadges.isEmpty)
    }
}
