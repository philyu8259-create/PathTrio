import XCTest
@testable import PathTrio

final class WorkoutHealthSyncCoordinatorTests: XCTestCase {
    func testSkipsSyncWhenSettingIsDisabled() async {
        let syncer = RecordingHealthSyncer()
        let session = makeSession()

        let result = await WorkoutHealthSyncCoordinator.syncIfNeeded(
            session,
            syncEnabled: false,
            syncer: syncer
        )

        XCTAssertEqual(result, .skipped)
        XCTAssertEqual(syncer.requestAuthorizationCallCount, 0)
        XCTAssertEqual(syncer.savedWorkoutIDs, [])
    }

    func testRequestsAuthorizationAndSavesWorkoutWhenEnabled() async {
        let syncer = RecordingHealthSyncer()
        let session = makeSession()

        let result = await WorkoutHealthSyncCoordinator.syncIfNeeded(
            session,
            syncEnabled: true,
            syncer: syncer
        )

        XCTAssertEqual(result, .synced)
        XCTAssertEqual(syncer.requestAuthorizationCallCount, 1)
        XCTAssertEqual(syncer.savedWorkoutIDs, [session.id])
    }

    func testReportsUnavailableWithoutRequestingAuthorization() async {
        let syncer = RecordingHealthSyncer(isHealthDataAvailable: false)
        let session = makeSession()

        let result = await WorkoutHealthSyncCoordinator.syncIfNeeded(
            session,
            syncEnabled: true,
            syncer: syncer
        )

        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(syncer.requestAuthorizationCallCount, 0)
        XCTAssertEqual(syncer.savedWorkoutIDs, [])
    }

    func testReportsFailedWhenAuthorizationOrSaveThrows() async {
        let syncer = RecordingHealthSyncer(errorToThrow: HealthSyncTestError.expected)
        let session = makeSession()

        let result = await WorkoutHealthSyncCoordinator.syncIfNeeded(
            session,
            syncEnabled: true,
            syncer: syncer
        )

        XCTAssertEqual(result, .failed)
    }

    private func makeSession() -> WorkoutSessionModel {
        WorkoutSessionModel(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            type: .run,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 1_000),
            duration: 900,
            distanceMeters: 2_500,
            averageSpeedMetersPerSecond: 2.7,
            estimatedCalories: 180,
            smartAssistEnabledAtStart: false
        )
    }
}

private enum HealthSyncTestError: Error {
    case expected
}

private final class RecordingHealthSyncer: HealthSyncing {
    let isHealthDataAvailable: Bool
    let errorToThrow: Error?
    private(set) var requestAuthorizationCallCount = 0
    private(set) var savedWorkoutIDs: [UUID] = []

    init(isHealthDataAvailable: Bool = true, errorToThrow: Error? = nil) {
        self.isHealthDataAvailable = isHealthDataAvailable
        self.errorToThrow = errorToThrow
    }

    func requestAuthorization() async throws {
        requestAuthorizationCallCount += 1
        if let errorToThrow {
            throw errorToThrow
        }
    }

    func save(workout: WorkoutSessionModel) async throws {
        if let errorToThrow {
            throw errorToThrow
        }
        savedWorkoutIDs.append(workout.id)
    }
}
