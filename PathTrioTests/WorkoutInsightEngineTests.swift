import XCTest
@testable import PathTrio

final class WorkoutInsightEngineTests: XCTestCase {
    func testBuildsWeeklyImprovementInsight() {
        let engine = WorkoutInsightEngine()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_728_000)
        let workouts = [
            makeWorkout(type: .walk, daysBeforeNow: 1, now: now, distanceMeters: 3_000),
            makeWorkout(type: .run, daysBeforeNow: 3, now: now, distanceMeters: 6_000),
            makeWorkout(type: .walk, daysBeforeNow: 8, now: now, distanceMeters: 2_000)
        ]

        let insights = engine.insights(for: workouts, now: now, calendar: calendar)

        XCTAssertTrue(insights.contains { $0.kind == .weeklyProgress })
        XCTAssertTrue(insights.contains { $0.kind == .dominantType && $0.systemImage == WorkoutType.run.systemImage })
    }

    func testBuildsStarterInsightWhenHistoryIsEmpty() {
        let engine = WorkoutInsightEngine()

        let insights = engine.insights(for: [], now: Date(timeIntervalSince1970: 1_728_000))

        XCTAssertEqual(insights, [
            WorkoutInsight(kind: .starter, titleKey: "insights.starter.title", messageKey: "insights.starter.message", value: nil, systemImage: "sparkles")
        ])
    }

    private func makeWorkout(type: WorkoutType, daysBeforeNow: Int, now: Date, distanceMeters: Double) -> WorkoutSessionModel {
        let startedAt = now.addingTimeInterval(TimeInterval(-daysBeforeNow * 86_400))
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
