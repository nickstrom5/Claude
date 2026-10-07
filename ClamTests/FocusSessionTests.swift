import XCTest
@testable import Clam

final class FocusSessionTests: XCTestCase {
    /// The intent is the one path that can produce an arbitrary duration, so it needs the same
    /// floor as the picker. A 2-minute Siri session used to be startable.
    func testShortRequestsAreRaisedToTheMonitorableFloor() {
        XCTAssertEqual(SessionManager.monitorableMinutes(2, isTaste: false),
                       SessionLimits.minimumMonitoredMinutes)
        XCTAssertEqual(SessionManager.monitorableMinutes(1, isTaste: false),
                       SessionLimits.minimumMonitoredMinutes)
        XCTAssertEqual(SessionManager.monitorableMinutes(50, isTaste: false), 50)
        XCTAssertEqual(SessionManager.monitorableMinutes(9999, isTaste: false), 240)
    }

    /// The 60-second onboarding taste runs with the user watching, so it keeps its length.
    func testTasteSessionKeepsItsShortLength() {
        XCTAssertEqual(SessionManager.monitorableMinutes(1, isTaste: true), 1)
    }

    /// A session saved before a field existed must still decode, or upgrading wipes history.
    func testDecodesSessionSavedBeforeIsTasteExisted() throws {
        let json = Data("""
        {"id":"\(UUID().uuidString)","start":0,"plannedMinutes":25,"completed":true}
        """.utf8)
        let decoder = JSONDecoder()
        let session = try decoder.decode(FocusSession.self, from: json)
        XCTAssertEqual(session.plannedMinutes, 25)
        XCTAssertTrue(session.completed)
        XCTAssertFalse(session.isTaste)
    }

    /// Every duration a user can pick has to be one the monitor extension can guarantee to
    /// unlock. DeviceActivity refuses windows under 15 minutes, so anything shorter would rely
    /// on the app being alive at the end, and a killed app would leave the shield up.
    func testEverySelectableDurationIsMonitorable() {
        for minutes in DurationPickerSheet.options {
            XCTAssertGreaterThanOrEqual(minutes, SessionLimits.minimumMonitoredMinutes,
                                        "\(minutes)m is shorter than the monitor's minimum window")
        }
        for preset in [25, 50, 90] {
            XCTAssertGreaterThanOrEqual(preset, SessionLimits.minimumMonitoredMinutes)
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
