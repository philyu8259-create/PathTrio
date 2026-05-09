import XCTest
@testable import PathTrio

final class AutoStartReminderEngineTests: XCTestCase {
    func testSuggestsWorkoutAfterSustainedDetectedActivity() {
        var engine = AutoStartReminderEngine(requiredDuration: 120)
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertNil(engine.evaluate(detectedActivity: .walking, now: start, isWorkoutActive: false))
        XCTAssertNil(engine.evaluate(detectedActivity: .walking, now: start.addingTimeInterval(119), isWorkoutActive: false))

        let suggestion = engine.evaluate(detectedActivity: .walking, now: start.addingTimeInterval(120), isWorkoutActive: false)

        XCTAssertEqual(suggestion, AutoStartReminder(workoutType: .walk))
    }

    func testResetsCandidateWhenActivityStops() {
        var engine = AutoStartReminderEngine(requiredDuration: 120)
        let start = Date(timeIntervalSince1970: 100)

        _ = engine.evaluate(detectedActivity: .running, now: start, isWorkoutActive: false)
        XCTAssertNil(engine.evaluate(detectedActivity: .stationary, now: start.addingTimeInterval(60), isWorkoutActive: false))
        XCTAssertNil(engine.evaluate(detectedActivity: .running, now: start.addingTimeInterval(121), isWorkoutActive: false))
    }

    func testDoesNotSuggestWhenWorkoutIsAlreadyActive() {
        var engine = AutoStartReminderEngine(requiredDuration: 120)
        let start = Date(timeIntervalSince1970: 100)

        _ = engine.evaluate(detectedActivity: .cycling, now: start, isWorkoutActive: true)
        let suggestion = engine.evaluate(detectedActivity: .cycling, now: start.addingTimeInterval(180), isWorkoutActive: true)

        XCTAssertNil(suggestion)
    }
}
