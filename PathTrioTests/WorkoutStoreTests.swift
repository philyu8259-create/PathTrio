import SwiftData
import XCTest
@testable import PathTrio

@MainActor
final class WorkoutStoreTests: XCTestCase {
    func testTotalsOnlyIncludeWorkoutsInsideDateRange() throws {
        let context = try makeContext()
        let store = WorkoutStore(context: context)
        let start = Date(timeIntervalSince1970: 1_000)
        let end = Date(timeIntervalSince1970: 2_000)

        context.insert(makeWorkout(startedAt: Date(timeIntervalSince1970: 1_100), duration: 600, distanceMeters: 1_200))
        context.insert(makeWorkout(startedAt: Date(timeIntervalSince1970: 1_900), duration: 300, distanceMeters: 800))
        context.insert(makeWorkout(startedAt: Date(timeIntervalSince1970: 900), duration: 999, distanceMeters: 9_999))
        context.insert(makeWorkout(startedAt: Date(timeIntervalSince1970: 2_000), duration: 999, distanceMeters: 9_999))
        try context.save()

        let totals = try store.totals(from: start, to: end)

        XCTAssertEqual(totals.distanceMeters, 2_000)
        XCTAssertEqual(totals.duration, 900)
    }

    func testTotalsForDayUsesCalendarDayBoundaries() throws {
        let context = try makeContext()
        let store = WorkoutStore(context: context)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let target = Date(timeIntervalSince1970: 86_400)

        context.insert(makeWorkout(startedAt: Date(timeIntervalSince1970: 86_400 + 60), duration: 120, distanceMeters: 500))
        context.insert(makeWorkout(startedAt: Date(timeIntervalSince1970: 86_400 - 60), duration: 120, distanceMeters: 500))
        try context.save()

        let totals = try store.totals(forDayContaining: target, calendar: calendar)

        XCTAssertEqual(totals.distanceMeters, 500)
        XCTAssertEqual(totals.duration, 120)
    }

    func testSaveCompletedWorkoutStoresEstimatedCalories() throws {
        let context = try makeContext()
        let store = WorkoutStore(context: context)
        let draft = WorkoutSessionDraft(
            type: .run,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 1_900),
            state: .ended,
            metrics: WorkoutMetrics(duration: 1_800, distanceMeters: 5_000, averageSpeedMetersPerSecond: 2.78)
        )

        let saved = try store.saveCompletedWorkout(
            draft,
            smartAssistEnabledAtStart: false,
            bodyWeightKilograms: 70
        )

        let estimatedCalories = try XCTUnwrap(saved.estimatedCalories)
        XCTAssertEqual(estimatedCalories, 343, accuracy: 0.1)
    }

    func testSaveCompletedWorkoutStartsWithoutHealthSyncResult() throws {
        let context = try makeContext()
        let store = WorkoutStore(context: context)
        let draft = WorkoutSessionDraft(
            type: .run,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 1_900),
            state: .ended,
            metrics: WorkoutMetrics(duration: 1_800, distanceMeters: 5_000, averageSpeedMetersPerSecond: 2.78)
        )

        let saved = try store.saveCompletedWorkout(
            draft,
            smartAssistEnabledAtStart: false,
            bodyWeightKilograms: 70
        )

        XCTAssertNil(saved.healthSyncResult)
    }

    func testUpdateHealthSyncResultPersistsSyncOutcome() throws {
        let context = try makeContext()
        let store = WorkoutStore(context: context)
        let workout = makeWorkout(startedAt: Date(timeIntervalSince1970: 100), duration: 600, distanceMeters: 1_000)
        context.insert(workout)
        try context.save()

        try store.updateHealthSyncResult(.synced, for: workout)

        let descriptor = FetchDescriptor<WorkoutSessionModel>()
        let saved = try XCTUnwrap(try context.fetch(descriptor).first)
        XCTAssertEqual(saved.healthSyncResult, .synced)
    }

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: WorkoutSessionModel.self,
            LocationPointModel.self,
            UserSettingsModel.self,
            configurations: configuration
        )
        return ModelContext(container)
    }

    private func makeWorkout(startedAt: Date, duration: TimeInterval, distanceMeters: Double) -> WorkoutSessionModel {
        WorkoutSessionModel(
            type: .walk,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(duration),
            duration: duration,
            distanceMeters: distanceMeters,
            averageSpeedMetersPerSecond: distanceMeters / max(duration, 1),
            smartAssistEnabledAtStart: false
        )
    }
}
