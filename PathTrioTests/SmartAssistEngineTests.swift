import XCTest
@testable import PathTrio

final class SmartAssistEngineTests: XCTestCase {
    func testDoesNotSuggestWhenSettingsAreOff() {
        var engine = SmartAssistEngine()
        let start = Date(timeIntervalSince1970: 100)

        let suggestion = engine.evaluate(
            workoutType: .walk,
            workoutStartedAt: start,
            workoutState: .recording,
            currentSpeedMetersPerSecond: 12,
            detectedActivity: .cycling,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: false,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: false
            ),
            now: start.addingTimeInterval(200)
        )

        XCTAssertNil(suggestion)
    }

    func testSuggestsActivityChangeOnlyAfterStableDetection() {
        var engine = SmartAssistEngine()
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertNil(engine.evaluate(
            workoutType: .run,
            workoutStartedAt: start,
            workoutState: .recording,
            currentSpeedMetersPerSecond: 5,
            detectedActivity: .cycling,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: true,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: false
            ),
            now: start.addingTimeInterval(26)
        ))

        let suggestion = engine.evaluate(
            workoutType: .run,
            workoutStartedAt: start,
            workoutState: .recording,
            currentSpeedMetersPerSecond: 5,
            detectedActivity: .cycling,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: true,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: false
            ),
            now: start.addingTimeInterval(45)
        )

        XCTAssertEqual(suggestion, .activityChange(from: .run, to: .ride))
    }

    func testSuggestsSpeedAnomalyForWalkAtCarSpeedAfterStableDetection() {
        var engine = SmartAssistEngine()
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertNil(engine.evaluate(
            workoutType: .walk,
            workoutStartedAt: start,
            workoutState: .recording,
            currentSpeedMetersPerSecond: 14,
            detectedActivity: .unknown,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: false,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: true
            ),
            now: start.addingTimeInterval(26)
        ))

        let suggestion = engine.evaluate(
            workoutType: .walk,
            workoutStartedAt: start,
            workoutState: .recording,
            currentSpeedMetersPerSecond: 14,
            detectedActivity: .unknown,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: false,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: true
            ),
            now: start.addingTimeInterval(35)
        )

        XCTAssertEqual(suggestion, .speedAnomaly(currentSpeedMetersPerSecond: 14, workoutType: .walk))
    }

    func testDoesNotSuggestSpeedAnomalyWhenMotionIsStationary() {
        var engine = SmartAssistEngine()
        let start = Date(timeIntervalSince1970: 100)

        let suggestion = engine.evaluate(
            workoutType: .walk,
            workoutStartedAt: start,
            workoutState: .recording,
            currentSpeedMetersPerSecond: 6,
            detectedActivity: .stationary,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: false,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: true
            ),
            now: start.addingTimeInterval(200)
        )

        XCTAssertNil(suggestion)
    }

    func testDoesNotAutoPauseImmediatelyAtWorkoutStart() {
        var engine = SmartAssistEngine()
        let start = Date(timeIntervalSince1970: 100)

        let suggestion = engine.evaluate(
            workoutType: .walk,
            workoutStartedAt: start,
            workoutState: .recording,
            currentSpeedMetersPerSecond: 0,
            detectedActivity: .stationary,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: false,
                autoPauseEnabled: true,
                speedAnomalyAlertsEnabled: false
            ),
            now: start.addingTimeInterval(10)
        )

        XCTAssertNil(suggestion)
    }

    func testSuggestsAutoPauseAfterStableStationaryDetection() {
        var engine = SmartAssistEngine()
        let start = Date(timeIntervalSince1970: 100)
        let settings = SmartAssistSettings(
            smartActivityAlertsEnabled: false,
            autoPauseEnabled: true,
            speedAnomalyAlertsEnabled: false
        )

        XCTAssertNil(engine.evaluate(
            workoutType: .walk,
            workoutStartedAt: start,
            workoutState: .recording,
            currentSpeedMetersPerSecond: 0,
            detectedActivity: .stationary,
            settings: settings,
            now: start.addingTimeInterval(30)
        ))

        XCTAssertEqual(
            engine.evaluate(
                workoutType: .walk,
                workoutStartedAt: start,
                workoutState: .recording,
                currentSpeedMetersPerSecond: 0,
                detectedActivity: .stationary,
                settings: settings,
                now: start.addingTimeInterval(66)
            ),
            .autoPause
        )
    }

    func testSuggestsAutoPauseForUnknownMotionWhenSpeedStaysLowForAllWorkoutTypes() {
        let settings = SmartAssistSettings(
            smartActivityAlertsEnabled: false,
            autoPauseEnabled: true,
            speedAnomalyAlertsEnabled: false
        )

        for workoutType in WorkoutType.allCases {
            var engine = SmartAssistEngine()
            let start = Date(timeIntervalSince1970: 100)

            XCTAssertNil(engine.evaluate(
                workoutType: workoutType,
                workoutStartedAt: start,
                workoutState: .recording,
                currentSpeedMetersPerSecond: 0,
                detectedActivity: .unknown,
                settings: settings,
                now: start.addingTimeInterval(30)
            ), "\(workoutType) should wait for stable low-speed detection before auto pause")

            XCTAssertEqual(
                engine.evaluate(
                    workoutType: workoutType,
                    workoutStartedAt: start,
                    workoutState: .recording,
                    currentSpeedMetersPerSecond: 0,
                    detectedActivity: .unknown,
                    settings: settings,
                    now: start.addingTimeInterval(66)
                ),
                .autoPause,
                "\(workoutType) should suggest auto pause after stable unknown low-speed detection"
            )
        }
    }

    func testAutoPausedWorkoutResumesOnlyAfterStableMovement() {
        var engine = SmartAssistEngine()
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertFalse(engine.shouldResumeAutoPaused(
            workoutType: .walk,
            currentSpeedMetersPerSecond: 0.1,
            detectedActivity: .stationary,
            now: start
        ))
        XCTAssertFalse(engine.shouldResumeAutoPaused(
            workoutType: .walk,
            currentSpeedMetersPerSecond: 1.0,
            detectedActivity: .walking,
            now: start.addingTimeInterval(1)
        ))
        XCTAssertTrue(engine.shouldResumeAutoPaused(
            workoutType: .walk,
            currentSpeedMetersPerSecond: 1.0,
            detectedActivity: .walking,
            now: start.addingTimeInterval(8)
        ))
    }
}
