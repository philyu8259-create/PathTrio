import XCTest
@testable import PathTrio

final class WorkoutStatsSummaryTests: XCTestCase {
    func testBuildsMonthYearAndAllTimeSummaries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_706_918_400) // Feb 5 2024
        let workouts = [
            makeWorkout(startedAt: Date(timeIntervalSince1970: 1_706_832_000), distanceMeters: 2_000),
            makeWorkout(startedAt: Date(timeIntervalSince1970: 1_704_067_200), distanceMeters: 3_000),
            makeWorkout(startedAt: Date(timeIntervalSince1970: 1_672_531_200), distanceMeters: 4_000)
        ]

        let summaries = WorkoutStatsSummaryBuilder().summaries(for: workouts, now: now, calendar: calendar)

        XCTAssertEqual(summaries[0].workoutCount, 1)
        XCTAssertEqual(summaries[0].distanceMeters, 2_000)
        XCTAssertEqual(summaries[1].workoutCount, 2)
        XCTAssertEqual(summaries[1].distanceMeters, 5_000)
        XCTAssertEqual(summaries[2].workoutCount, 3)
        XCTAssertEqual(summaries[2].distanceMeters, 9_000)
    }

    private func makeWorkout(startedAt: Date, distanceMeters: Double) -> WorkoutSessionModel {
        WorkoutSessionModel(
            type: .ride,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(1_000),
            duration: 1_000,
            distanceMeters: distanceMeters,
            averageSpeedMetersPerSecond: distanceMeters / 1_000,
            smartAssistEnabledAtStart: false
        )
    }
}
