import XCTest
@testable import PathTrio

final class HealthSyncPlanTests: XCTestCase {
    func testDisabledHealthSyncShowsDisabledStatus() {
        let status = HealthSyncPlan.status(syncEnabled: false)

        XCTAssertEqual(status.kind, .disabled)
        XCTAssertEqual(status.titleKey, "health.status.off.title")
    }

    func testEnabledHealthSyncShowsPermissionNeededStatus() {
        let status = HealthSyncPlan.status(syncEnabled: true)

        XCTAssertEqual(status.kind, .permissionNeeded)
        XCTAssertEqual(status.titleKey, "health.status.permissionNeeded.title")
    }

    func testPlannedWriteTypesCoverCoreWorkoutData() {
        XCTAssertEqual(
            HealthSyncPlan.plannedWriteTypeKeys,
            [
                "health.data.workouts",
                "health.data.walkRunDistance",
                "health.data.cyclingDistance",
                "health.data.activeEnergy"
            ]
        )
    }
}
