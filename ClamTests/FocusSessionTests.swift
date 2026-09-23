import XCTest
@testable import Clam

final class FocusSessionTests: XCTestCase {
    /// Every duration a user can pick has to be one the monitor extension can guarantee to
    /// unlock. DeviceActivity refuses windows under 15 minutes, so anything shorter would rely
    /// on the app being alive at the end, and a killed app would leave the shield up.
    func testEverySelectableDurationIsMonitorable() {
        for minutes in DurationPickerSheet.options {
            XCTAssertGreaterThanOrEqual(minutes, ScreenTimeManager.minimumMonitoredMinutes,
                                        "\(minutes)m is shorter than the monitor's minimum window")
        }
        for preset in [25, 50, 90] {
            XCTAssertGreaterThanOrEqual(preset, ScreenTimeManager.minimumMonitoredMinutes)
        }
    }

    func testPlannedEnd() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let session = FocusSession(start: start, plannedMinutes: 25)
        XCTAssertEqual(session.plannedEnd, start.addingTimeInterval(1500))
    }

    func testActualMinutesRoundsToNearest() {
        let start = Date(timeIntervalSince1970: 0)
        var session = FocusSession(start: start, plannedMinutes: 1)
        session.end = start.addingTimeInterval(59.6)
        XCTAssertEqual(session.actualMinutes, 1)
        session.end = start.addingTimeInterval(29)
        XCTAssertEqual(session.actualMinutes, 0)
    }

    func testFormattedDuration() {
        let start = Date(timeIntervalSince1970: 0)
        var session = FocusSession(start: start, plannedMinutes: 90)
        session.end = start.addingTimeInterval(90 * 60)
        XCTAssertEqual(session.formattedDuration, "1h 30m")
        session.end = start.addingTimeInterval(45 * 60)
        XCTAssertEqual(session.formattedDuration, "45m")
    }

    func testNeverNegative() {
        let start = Date()
        var session = FocusSession(start: start, plannedMinutes: 10)
        session.end = start.addingTimeInterval(-100)
        XCTAssertEqual(session.actualMinutes, 0)
    }
}
