import XCTest
@testable import Clam

/// The privacy policy promises a working off switch, so the gate in front of the sink is
/// tested rather than assumed.
final class AnalyticsTests: XCTestCase {
    private final class SpySink: AnalyticsSink {
        var events: [AnalyticsEvent] = []
        func track(_ event: AnalyticsEvent, _ properties: [String: Any]) { events.append(event) }
    }

    private var previousSink: AnalyticsSink!
    private var previousOptOut = false
    private var spy: SpySink!

    override func setUp() {
        super.setUp()
        previousSink = Analytics.sink
        previousOptOut = Analytics.isOptedOut
        spy = SpySink()
        Analytics.sink = spy
    }

    override func tearDown() {
        Analytics.sink = previousSink
        Analytics.isOptedOut = previousOptOut
        super.tearDown()
    }

    func testEventsReachTheSinkByDefault() {
        Analytics.isOptedOut = false
        Analytics.track(.sessionStarted)
        XCTAssertEqual(spy.events, [.sessionStarted])
    }

    func testOptingOutStopsEveryEvent() {
        Analytics.isOptedOut = true
        for event in [AnalyticsEvent.appOpen, .sessionStarted, .paid, .manualUnlock] {
            Analytics.track(event)
        }
        XCTAssertTrue(spy.events.isEmpty)
    }

    func testOptingBackInResumes() {
        Analytics.isOptedOut = true
        Analytics.track(.sessionStarted)
        Analytics.isOptedOut = false
        Analytics.track(.sessionCompleted)
        XCTAssertEqual(spy.events, [.sessionCompleted])
    }
}
