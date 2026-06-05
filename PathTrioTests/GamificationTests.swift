import SwiftData
import XCTest
@testable import PathTrio

@MainActor
final class GamificationTests: XCTestCase {
    func testStreakComputationCountsProtectedGaps() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let records: [DailyCheckInRecord] = [
            .init(date: today, workoutCount: 1, streakShieldCount: 1),
            .init(date: yesterday, workoutCount: 0, streakShieldCount: 0),
            .init(date: twoDaysAgo, workoutCount: 1, streakShieldCount: 0)
        ]

        let snapshot = GamificationCalculator().snapshot(
            from: records,
            at: today,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.currentStreak, 2)
        XCTAssertEqual(snapshot.longestStreak, 2)
        XCTAssertEqual(snapshot.totalWorkouts, 2)
        XCTAssertTrue(snapshot.wasProtectedToday)
        XCTAssertEqual(snapshot.trioPalState, .protected)
    }

    func testStreakComputationUsesShieldOnNonWorkoutDay() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let records: [DailyCheckInRecord] = [
            .init(date: today, workoutCount: 1, streakShieldCount: 0),
            .init(date: yesterday, workoutCount: 0, streakShieldCount: 1),
            .init(date: twoDaysAgo, workoutCount: 1, streakShieldCount: 0)
        ]

        let snapshot = GamificationCalculator().snapshot(
            from: records,
            at: today,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.currentStreak, 2)
        XCTAssertEqual(snapshot.longestStreak, 2)
        XCTAssertEqual(snapshot.wasProtectedToday, true)
    }

    func testTrioPalStateEscalatesWithConsistency() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let records = (0..<7).map { index in
            DailyCheckInRecord(
                date: calendar.date(byAdding: .day, value: -index, to: today)!,
                workoutCount: 1,
                streakShieldCount: 0
            )
        }

        let computed = GamificationCalculator().snapshot(
            from: records,
            at: today,
            calendar: calendar
        )

        XCTAssertEqual(computed.currentStreak, 7)
        XCTAssertEqual(computed.longestStreak, 7)
        XCTAssertEqual(computed.trioPalState, .blazing)

        XCTAssertEqual(
            GamificationAchievementEngine().cards(for: computed)
                .first(where: { $0.kind == .weekWarrior })?
                .isUnlocked,
            true
        )
    }

    func testAchievementUnlockEngineFlagsNewCards() {
        let calculator = GamificationCalculator()
        let engine = GamificationAchievementEngine()

        let before = calculator.snapshot(
            from: [DailyCheckInRecord(date: Date(), workoutCount: 1, streakShieldCount: 0)],
            at: Date()
        )
        let after = calculator.snapshot(
            from: [
                .init(date: Date(), workoutCount: 1, streakShieldCount: 0),
                .init(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, workoutCount: 1, streakShieldCount: 0),
                .init(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, workoutCount: 1, streakShieldCount: 0)
            ],
            at: Date()
        )

        let newCards = engine.newlyUnlockedCards(before: before, after: after)
        let newlyUnlockedKinds = Set(newCards.map(\.kind))

        XCTAssertTrue(newlyUnlockedKinds.contains(.steadyStarter))
        XCTAssertFalse(newlyUnlockedKinds.contains(.firstWorkout))
    }

    func testStoreRecordsWorkoutCompletionAndUpdatesAchievementState() throws {
        let context = try makeContext()
        let store = GamificationStore(context: context)
        let workout = makeWorkout(
            startedAt: Date(),
            duration: 1_200,
            distanceMeters: 1_000
        )

        let firstResult = try store.processCompletedWorkout(workout)

        let firstCards = firstResult.allAchievementCards
        let unlockedKinds = Set(firstCards.filter(\.isUnlocked).map(\.kind))

        XCTAssertTrue(unlockedKinds.contains(.firstWorkout))
        XCTAssertEqual(firstResult.snapshot.totalWorkouts, 1)
        XCTAssertTrue(firstResult.newlyUnlockedAchievements.contains(where: { $0.kind == .firstWorkout }))

        let second = makeWorkout(
            startedAt: workout.startedAt.addingTimeInterval(60),
            duration: 1_200,
            distanceMeters: 1_000
        )
        let secondResult = try store.processCompletedWorkout(second)

        XCTAssertEqual(secondResult.snapshot.totalWorkouts, 2)
        XCTAssertEqual(secondResult.snapshot.currentStreak, 1)
        XCTAssertTrue(secondResult.newlyUnlockedAchievements.isEmpty)
    }

    func testStoreCanGrantShields() throws {
        let context = try makeContext()
        let store = GamificationStore(context: context)
        let referenceDate = Date()

        _ = try store.grantStreakShield(for: referenceDate, count: 1)
        let first = try store.loadSnapshot(at: referenceDate)
        XCTAssertEqual(first.availableShields, 1)

        _ = try store.grantStreakShield(for: referenceDate, count: 2)
        let second = try store.loadSnapshot(at: referenceDate)
        XCTAssertEqual(second.availableShields, 3)
    }

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for:
            DailyCheckInModel.self,
            WorkoutSessionModel.self,
            LocationPointModel.self,
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
            averageSpeedMetersPerSecond: distanceMeters / duration,
            smartAssistEnabledAtStart: false
        )
    }
}
