import XCTest
@testable import PathTrio

final class SmartAssistEngineTests: XCTestCase {
    func testDoesNotSuggestWhenSettingsAreOff() {
        let engine = SmartAssistEngine()

        let suggestion = engine.evaluate(
            workoutType: .walk,
            currentSpeedMetersPerSecond: 12,
            detectedActivity: .cycling,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: false,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: false
            )
        )

        XCTAssertNil(suggestion)
    }

    func testSuggestsActivityChangeWhenEnabled() {
        let engine = SmartAssistEngine()

        let suggestion = engine.evaluate(
            workoutType: .run,
            currentSpeedMetersPerSecond: 5,
            detectedActivity: .cycling,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: true,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: false
            )
        )

        XCTAssertEqual(suggestion, .activityChange(from: .run, to: .ride))
    }

    func testSuggestsSpeedAnomalyForWalkAtCarSpeed() {
        let engine = SmartAssistEngine()

        let suggestion = engine.evaluate(
            workoutType: .walk,
            currentSpeedMetersPerSecond: 14,
            detectedActivity: .unknown,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: false,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: true
            )
        )

        XCTAssertEqual(suggestion, .speedAnomaly(currentSpeedMetersPerSecond: 14, workoutType: .walk))
    }
}
