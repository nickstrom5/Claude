import XCTest
@testable import Shelf

final class OnboardingAnswersTests: XCTestCase {
    func testDefaultIsAverageUser() {
        let answers = OnboardingAnswers()
        XCTAssertEqual(answers.hoursPerDay, 4.5)
        XCTAssertEqual(answers.daysPerYear, 68)
        XCTAssertEqual(answers.daysBackPerYear, 27)
        XCTAssertEqual(answers.hoursBackPerWeek, 13)
    }

    func testHeavyUser() {
        var answers = OnboardingAnswers()
        answers.hoursPerDay = 8
        XCTAssertEqual(answers.daysPerYear, 122)
        XCTAssertEqual(answers.daysBackPerYear, 49)
    }

    func testLightUser() {
        var answers = OnboardingAnswers()
        answers.hoursPerDay = 1
        XCTAssertEqual(answers.daysPerYear, 15)
        XCTAssertEqual(answers.daysBackPerYear, 6)
    }

    func testRoundTripsThroughJSON() throws {
        var answers = OnboardingAnswers()
        answers.hoursPerDay = 6
        answers.triggers = [.inBed, .bored]
        let data = try JSONEncoder().encode(answers)
        let decoded = try JSONDecoder().decode(OnboardingAnswers.self, from: data)
        XCTAssertEqual(decoded, answers)
    }
}
