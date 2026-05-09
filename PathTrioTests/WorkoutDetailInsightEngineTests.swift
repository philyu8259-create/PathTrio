import XCTest
@testable import PathTrio

final class WorkoutDetailInsightEngineTests: XCTestCase {
    func testBuildsRunWorkoutReviewInsights() {
        let engine = WorkoutDetailInsightEngine()
        let workout = makeWorkout(
            type: .run,
            duration: 1_800,
            distanceMeters: 5_000,
            averageSpeedMetersPerSecond: 5_000 / 1_800,
            locations: [
                makeLocation(seconds: 0),
                makeLocation(seconds: 1_800)
            ]
        )

        let insights = engine.insights(for: workout)

        XCTAssertEqual(insights.map(\.kind), [.effort, .route, .energy])
        XCTAssertEqual(insights[0].value, "6:00 /km")
        XCTAssertEqual(insights[1].value, "2")
        XCTAssertEqual(insights[2].value, "343 kcal")
    }

    func testUsesSpeedForRideReview() {
        let engine = WorkoutDetailInsightEngine()
        let workout = makeWorkout(
            type: .ride,
            duration: 3_600,
            distanceMeters: 20_000,
            averageSpeedMetersPerSecond: 20_000 / 3_600
        )

        let insights = engine.insights(for: workout)

        XCTAssertEqual(insights.first?.kind, .effort)
        XCTAssertEqual(insights.first?.value, "20.0 km/h")
    }

    private func makeWorkout(
        type: WorkoutType,
        duration: TimeInterval,
        distanceMeters: Double,
        averageSpeedMetersPerSecond: Double,
        locations: [LocationPointModel] = []
    ) -> WorkoutSessionModel {
        let startedAt = Date(timeIntervalSince1970: 1_728_000)
        return WorkoutSessionModel(
            type: type,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(duration),
            duration: duration,
            distanceMeters: distanceMeters,
            averageSpeedMetersPerSecond: averageSpeedMetersPerSecond,
            smartAssistEnabledAtStart: false,
            locations: locations
        )
    }

    private func makeLocation(seconds: TimeInterval) -> LocationPointModel {
        LocationPointModel(
            timestamp: Date(timeIntervalSince1970: 1_728_000 + seconds),
            latitude: 37.3349,
            longitude: -122.0090,
            horizontalAccuracy: 5,
            altitude: 0,
            speedMetersPerSecond: 2.8,
            course: 0
        )
    }
}
