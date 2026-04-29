import CoreLocation
import XCTest
@testable import PathTrio

final class RouteRecordingStatusTests: XCTestCase {
    func testDeniedLocationAuthorizationBlocksRouteRecording() {
        let status = RouteRecordingStatus.evaluate(
            authorizationStatus: .denied,
            latestHorizontalAccuracy: nil,
            latestErrorMessage: nil,
            backgroundRecordingEnabled: false
        )

        XCTAssertEqual(status, RouteRecordingStatus(
            kind: .blocked,
            titleKey: "location.status.permissionBlocked.title",
            messageKey: "location.status.permissionBlocked.message",
            systemImage: "location.slash"
        ))
    }

    func testPoorHorizontalAccuracyShowsWeakSignalWarning() {
        let status = RouteRecordingStatus.evaluate(
            authorizationStatus: .authorizedWhenInUse,
            latestHorizontalAccuracy: 120,
            latestErrorMessage: nil,
            backgroundRecordingEnabled: false
        )

        XCTAssertEqual(status?.kind, .warning)
        XCTAssertEqual(status?.titleKey, "location.status.weakSignal.title")
    }

    func testBackgroundRecordingEnabledShowsBatteryNoticeAfterAuthorization() {
        let status = RouteRecordingStatus.evaluate(
            authorizationStatus: .authorizedAlways,
            latestHorizontalAccuracy: 10,
            latestErrorMessage: nil,
            backgroundRecordingEnabled: true
        )

        XCTAssertEqual(status?.kind, .info)
        XCTAssertEqual(status?.titleKey, "location.status.background.title")
    }

    func testBackgroundRecordingNeedsAlwaysAuthorization() {
        let status = RouteRecordingStatus.evaluate(
            authorizationStatus: .authorizedWhenInUse,
            latestHorizontalAccuracy: 10,
            latestErrorMessage: nil,
            backgroundRecordingEnabled: true
        )

        XCTAssertEqual(status?.kind, .warning)
        XCTAssertEqual(status?.titleKey, "location.status.backgroundPermission.title")
    }
}
