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

    func testEnabledHealthSyncReturnsPermissionNeededStatusMessage() {
        let status = HealthSyncPlan.status(syncEnabled: true)

        XCTAssertEqual(status.messageKey, "health.status.permissionNeeded.message")
        XCTAssertEqual(status.systemImage, "heart.text.square")
    }
}
