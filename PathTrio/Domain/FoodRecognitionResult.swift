import Foundation

struct FoodRecognitionResult: Equatable {
    let foodName: String
    let estimatedCalories: Int

    init(foodName: String, estimatedCalories: Int) {
        self.foodName = foodName
        self.estimatedCalories = max(0, estimatedCalories)
    }

    static var unavailable: FoodRecognitionResult {
        FoodRecognitionResult(foodName: "Unknown food", estimatedCalories: 0)
    }
}
