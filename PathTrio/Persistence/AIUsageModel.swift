import Foundation
import SwiftData

@Model
final class AIUsageModel {
    @Attribute(.unique) var date: Date
    var usedCount: Int
    var dailyLimit: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        date: Date,
        usedCount: Int = 0,
        dailyLimit: Int = FoodAIUsage.defaultDailyLimit,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.date = Self.startOfDay(for: date)
        self.usedCount = usedCount
        self.dailyLimit = dailyLimit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func startOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }
}
