import HealthKit
import XCTest
@testable import PathTrio

final class HealthKitWorkoutBuilderTests: XCTestCase {
    func testMapsWorkoutTypesToHealthKitActivityTypes() {
        XCTAssertEqual(HealthKitWorkoutBuilder.activityType(for: .walk), .walking)
        XCTAssertEqual(HealthKitWorkoutBuilder.activityType(for: .run), .running)
        XCTAssertEqual(HealthKitWorkoutBuilder.activityType(for: .ride), .cycling)
    }

    func testShareTypesIncludeWorkoutDistanceAndActiveEnergy() throws {
        let identifiers = HealthKitWorkoutBuilder.shareTypes.map(\.identifier)

        XCTAssertTrue(identifiers.contains(HKWorkoutType.workoutType().identifier))
        XCTAssertTrue(identifiers.contains(try XCTUnwrap(HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)).identifier))
        XCTAssertTrue(identifiers.contains(try XCTUnwrap(HKQuantityType.quantityType(forIdentifier: .distanceCycling)).identifier))
        XCTAssertTrue(identifiers.contains(try XCTUnwrap(HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)).identifier))
    }

    func testBuildsWorkoutConfigurationAndSamples() throws {
        let session = WorkoutSessionModel(
            type: .run,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 1_900),
            duration: 1_800,
            distanceMeters: 5_000,
            averageSpeedMetersPerSecond: 2.78,
            estimatedCalories: 343,
            smartAssistEnabledAtStart: false
        )

        let configuration = HealthKitWorkoutBuilder.configuration(for: session)
        let samples = HealthKitWorkoutBuilder.samples(for: session)
        let distanceSample = try XCTUnwrap(samples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue })
        let energySample = try XCTUnwrap(samples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue })

        XCTAssertEqual(configuration.activityType, .running)
        XCTAssertEqual(samples.count, 2)
        XCTAssertEqual(distanceSample.startDate, session.startedAt)
        XCTAssertEqual(distanceSample.endDate, session.endedAt)
        XCTAssertEqual(distanceSample.quantity.doubleValue(for: HKUnit.meter()), 5_000, accuracy: 0.1)
        XCTAssertEqual(energySample.quantity.doubleValue(for: HKUnit.kilocalorie()), 343, accuracy: 0.1)
    }

    func testCyclingUsesCyclingDistanceSample() throws {
        let session = WorkoutSessionModel(
            type: .ride,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 1_000),
            duration: 900,
            distanceMeters: 3_000,
            averageSpeedMetersPerSecond: 3.33,
            smartAssistEnabledAtStart: false
        )

        let samples = HealthKitWorkoutBuilder.samples(for: session)

        XCTAssertNotNil(samples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.distanceCycling.rawValue })
        XCTAssertNil(samples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue })
    }
}
