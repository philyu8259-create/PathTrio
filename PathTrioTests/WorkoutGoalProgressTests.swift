import XCTest
@testable import PathTrio

final class WorkoutGoalProgressTests: XCTestCase {
    func testCalculatesWeeklyDistanceAndMonthlyWorkoutProgress() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_706_918_400) // Feb 5 2024
        let workouts = [
            makeWorkout(startedAt: Date(timeIntervalSince1970: 1_706_832_000), distanceMeters: 2_000),
            makeWorkout(startedAt: Date(timeIntervalSince1970: 1_706_860_800), distanceMeters: 3_000),
            makeWorkout(startedAt: Date(timeIntervalSince1970: 1_704_067_200), distanceMeters: 9_000)
        ]

        let progress = WorkoutGoalProgressCalculator().progress(
            for: workouts,
            weeklyDistanceGoalMeters: 10_000,
            monthlyWorkoutGoalCount: 4,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(progress[0].progress, 0.5, accuracy: 0.001)
        XCTAssertEqual(progress[0].value, "5.00 km")
        XCTAssertEqual(progress[1].progress, 0.5, accuracy: 0.001)
        XCTAssertEqual(progress[1].value, "2")
    }

    private func makeWorkout(startedAt: Date, distanceMeters: Double) -> WorkoutSessionModel {
        WorkoutSessionModel(
            type: .walk,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(600),
            duration: 600,
            distanceMeters: distanceMeters,
            averageSpeedMetersPerSecond: distanceMeters / 600,
            smartAssistEnabledAtStart: false
        )
    }
}
