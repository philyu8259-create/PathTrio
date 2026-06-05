import Foundation
import SwiftData

@MainActor
struct GamificationStore {
    let context: ModelContext
    private let calculator = GamificationCalculator()
    private let achievementEngine = GamificationAchievementEngine()

    struct CompletionResult {
        let snapshot: GamificationSnapshot
        let allAchievementCards: [AchievementCardModel]
        let newlyUnlockedAchievements: [AchievementCardModel]
    }

    func loadSnapshot(at date: Date = Date(), calendar: Calendar = .current) throws -> GamificationSnapshot {
        let records = try allCheckInRecords()
        return calculator.snapshot(from: records, at: date, calendar: calendar)
    }

    func loadAchievementCards(at date: Date = Date(), calendar: Calendar = .current) throws -> [AchievementCardModel] {
        let snapshot = try loadSnapshot(at: date, calendar: calendar)
        return achievementEngine.cards(for: snapshot)
    }

    func processCompletedWorkout(_ workout: WorkoutSessionModel, calendar: Calendar = .current) throws -> CompletionResult {
        let workoutDate = DailyCheckInModel.startOfDay(for: workout.startedAt, calendar: calendar)
        let previousSnapshot = try loadSnapshot(at: workoutDate, calendar: calendar)

        try applyWorkoutCompletion(on: workoutDate)

        let updatedSnapshot = try loadSnapshot(at: workoutDate, calendar: calendar)
        let updatedCards = achievementEngine.cards(for: updatedSnapshot)
        let unlocked = achievementEngine.newlyUnlockedCards(before: previousSnapshot, after: updatedSnapshot)

        return CompletionResult(
            snapshot: updatedSnapshot,
            allAchievementCards: updatedCards,
            newlyUnlockedAchievements: unlocked
        )
    }

    func grantStreakShield(for date: Date, count: Int, calendar: Calendar = .current) throws -> DailyCheckInModel {
        let day = DailyCheckInModel.startOfDay(for: date, calendar: calendar)
        let record: DailyCheckInModel
        if let existing = try checkIn(for: day) {
            record = existing
        } else {
            let created = DailyCheckInModel(date: day, workoutCount: 0, streakShieldCount: 0)
            context.insert(created)
            record = created
        }

        record.streakShieldCount += max(count, 0)
        record.updatedAt = Date()
        try context.save()
        return record
    }

    private func applyWorkoutCompletion(on date: Date) throws {
        guard let record = try checkIn(for: date) else {
            let newRecord = DailyCheckInModel(date: date, workoutCount: 1)
            context.insert(newRecord)
            try context.save()
            return
        }

        record.workoutCount += 1
        record.updatedAt = Date()
        try context.save()
    }

    private func checkIn(for date: Date, calendar: Calendar = .current) throws -> DailyCheckInModel? {
        let day = DailyCheckInModel.startOfDay(for: date, calendar: calendar)
        var descriptor = FetchDescriptor<DailyCheckInModel>(
            predicate: #Predicate { $0.date == day }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func allCheckInRecords() throws -> [DailyCheckInRecord] {
        let descriptor = FetchDescriptor<DailyCheckInModel>(sortBy: [SortDescriptor(\.date)])
        return try context.fetch(descriptor).map { $0.asRecord() }
    }
}
