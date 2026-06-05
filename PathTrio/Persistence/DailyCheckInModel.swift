import Foundation
import SwiftData

@Model
final class DailyCheckInModel {
    @Attribute(.unique) var date: Date
    var workoutCount: Int
    var streakShieldCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        date: Date,
        workoutCount: Int = 1,
        streakShieldCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.date = DailyCheckInModel.startOfDay(for: date)
        self.workoutCount = workoutCount
        self.streakShieldCount = streakShieldCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var hasWorkout: Bool {
        workoutCount > 0
    }

    func asRecord() -> DailyCheckInRecord {
        DailyCheckInRecord(
            date: date,
            workoutCount: workoutCount,
            streakShieldCount: streakShieldCount
        )
    }

    static func startOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }
}
