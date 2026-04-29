import XCTest
@testable import PathTrio

final class WorkoutCaloriesEstimatorTests: XCTestCase {
    func testEstimatesCaloriesFromWorkoutTypeDurationAndBodyWeight() throws {
        let calories = try XCTUnwrap(WorkoutCaloriesEstimator.estimate(
            type: .run,
            duration: 1_800,
            bodyWeightKilograms: 70
        ))

        XCTAssertEqual(calories, 343, accuracy: 0.1)
    }

    func testReturnsNilForZeroDuration() {
        let calories = WorkoutCaloriesEstimator.estimate(
            type: .walk,
            duration: 0,
            bodyWeightKilograms: 70
        )

        XCTAssertNil(calories)
    }
}
