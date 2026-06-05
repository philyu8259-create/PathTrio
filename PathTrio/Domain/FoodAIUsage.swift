import Foundation

struct FoodAIUsage: Equatable {
    let usedCount: Int
    let dailyLimit: Int

    /// Default daily free recognition limit used by the food tab.
    static let defaultDailyLimit = 5

    init(usedCount: Int, dailyLimit: Int = FoodAIUsage.defaultDailyLimit) {
        self.usedCount = usedCount
        self.dailyLimit = dailyLimit
    }

    var remainingCount: Int {
        max(0, dailyLimit - usedCount)
    }

    var canUseForRecognition: Bool {
        usedCount < dailyLimit
    }

    static let zero: FoodAIUsage = FoodAIUsage(usedCount: 0)
}
