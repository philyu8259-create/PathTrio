import XCTest
@testable import PathTrio

final class WorkoutHistoryOrganizerTests: XCTestCase {
    func testGroupsWorkoutsByDayAndFiltersByType() {
        let organizer = WorkoutHistoryOrganizer()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let workouts = [
            makeWorkout(type: .walk, timestamp: 86_400 + 60, distanceMeters: 1_000),
            makeWorkout(type: .ride, timestamp: 86_400 + 3_600, distanceMeters: 10_000),
            makeWorkout(type: .ride, timestamp: 172_800 + 60, distanceMeters: 12_000)
        ]

        let sections = organizer.sections(
            for: workouts,
            grouping: .day,
            filter: .ride,
            calendar: calendar
        )

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].workouts.count, 1)
        XCTAssertEqual(sections[0].totalDistanceMeters, 12_000)
        XCTAssertEqual(sections[1].workouts.count, 1)
        XCTAssertEqual(sections[1].totalDistanceMeters, 10_000)
    }

    func testGroupsWorkoutsByMonth() {
        let organizer = WorkoutHistoryOrganizer()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let workouts = [
            makeWorkout(type: .walk, timestamp: 1_706_745_600, distanceMeters: 1_000),
            makeWorkout(type: .run, timestamp: 1_706_832_000, distanceMeters: 5_000),
            makeWorkout(type: .ride, timestamp: 1_709_424_000, distanceMeters: 20_000)
        ]

        let sections = organizer.sections(
            for: workouts,
            grouping: .month,
            filter: .all,
            calendar: calendar
        )

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].workouts.count, 1)
        XCTAssertEqual(sections[0].totalDistanceMeters, 20_000)
        XCTAssertEqual(sections[1].workouts.count, 2)
        XCTAssertEqual(sections[1].totalDistanceMeters, 6_000)
    }

    private func makeWorkout(type: WorkoutType, timestamp: TimeInterval, distanceMeters: Double) -> WorkoutSessionModel {
        let startedAt = Date(timeIntervalSince1970: timestamp)
        return WorkoutSessionModel(
            type: type,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(1_800),
            duration: 1_800,
            distanceMeters: distanceMeters,
            averageSpeedMetersPerSecond: distanceMeters / 1_800,
            smartAssistEnabledAtStart: false
        )
    }
}
