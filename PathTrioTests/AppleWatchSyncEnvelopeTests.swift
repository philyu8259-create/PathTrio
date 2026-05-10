import XCTest
@testable import PathTrio

final class AppleWatchSyncEnvelopeTests: XCTestCase {
    func testRoundTripsApplicationContextPayload() throws {
        let workout = AppleWatchWorkoutSnapshot(
            id: UUID().uuidString,
            typeRawValue: "run",
            startedAt: 1_700_000_000,
            duration: 1_800,
            distanceMeters: 5_000,
            averageSpeedMetersPerSecond: 2.78,
            estimatedCalories: 320
        )
        let envelope = AppleWatchSyncEnvelope(
            isProUnlocked: true,
            activeWorkout: AppleWatchWorkoutSnapshot(
                id: UUID().uuidString,
                typeRawValue: "walk",
                startedAt: 1_700_001_000,
                duration: 120,
                distanceMeters: 180,
                averageSpeedMetersPerSecond: 1.5,
                estimatedCalories: 8,
                stateRawValue: "recording",
                isActive: true
            ),
            latestWorkout: workout,
            updatedAt: 1_700_001_800
        )

        let restored = try XCTUnwrap(AppleWatchSyncEnvelope(dictionary: envelope.dictionary))

        XCTAssertEqual(restored, envelope)
    }
}
