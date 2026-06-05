import SwiftData
import XCTest
@testable import PathTrio

final class FoodModelsTests: XCTestCase {
    func testFoodRecognitionResultClampsNegativeCalories() {
        let result = FoodRecognitionResult(foodName: "Apple", estimatedCalories: -500)
        XCTAssertEqual(result.foodName, "Apple")
        XCTAssertEqual(result.estimatedCalories, 0)
    }

    func testFoodAIUsageTracksRemainingAndLimit() {
        let usage = FoodAIUsage(usedCount: 2, dailyLimit: 5)
        XCTAssertEqual(usage.remainingCount, 3)
        XCTAssertTrue(usage.canUseForRecognition)

        let exhausted = FoodAIUsage(usedCount: 5, dailyLimit: 5)
        XCTAssertEqual(exhausted.remainingCount, 0)
        XCTAssertFalse(exhausted.canUseForRecognition)
    }

    func testFoodLogModelNormalizesCalories() throws {
        let entry = FoodLogModel(foodName: "Banana", estimatedCalories: -200)
        XCTAssertEqual(entry.estimatedCalories, 0)
        XCTAssertFalse(entry.foodName.isEmpty)
    }

    func testAiUsageModelStoresDateStartOfDay() throws {
        let context = try makeContext()
        let date = Date(timeIntervalSince1970: 1_234_567_890)
        let expectedStart = AIUsageModel.startOfDay(for: date)
        context.insert(AIUsageModel(date: date, usedCount: 3))
        try context.save()

        let descriptor = FetchDescriptor<AIUsageModel>(predicate: #Predicate { $0.date == expectedStart })
        let all = try context.fetch(descriptor)

        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.usedCount, 3)
        XCTAssertEqual(all.first?.date, expectedStart)
    }

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FoodLogModel.self,
            AIUsageModel.self,
            configurations: configuration
        )
        return ModelContext(container)
    }
}
