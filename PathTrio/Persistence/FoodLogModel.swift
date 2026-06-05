import Foundation
import SwiftData

@Model
final class FoodLogModel {
    @Attribute(.unique) var id: UUID
    var loggedAt: Date
    var foodName: String
    var estimatedCalories: Int

    init(
        id: UUID = UUID(),
        loggedAt: Date = Date(),
        foodName: String,
        estimatedCalories: Int
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.foodName = foodName
        self.estimatedCalories = max(0, estimatedCalories)
    }

    var displayDate: String {
        DateFormatter.localizedString(from: loggedAt, dateStyle: .medium, timeStyle: .short)
    }
}
