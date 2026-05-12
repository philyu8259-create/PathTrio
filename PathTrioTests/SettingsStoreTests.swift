import XCTest
@testable import PathTrio

final class SettingsStoreTests: XCTestCase {
    func testBackgroundRecordingDefaultsToOff() {
        let store = SettingsStore()

        XCTAssertFalse(store.backgroundRecordingEnabled)
        XCTAssertFalse(store.autoStartRemindersEnabled)
        XCTAssertEqual(store.weeklyDistanceGoalMeters, 10_000)
        XCTAssertEqual(store.monthlyWorkoutGoalCount, 12)
        XCTAssertEqual(store.preferredMapStyle, .standard)
    }

    func testSmartAssistSummaryDoesNotIncludeBackgroundRecording() {
        let store = SettingsStore()
        store.backgroundRecordingEnabled = true
        store.autoStartRemindersEnabled = true

        XCTAssertFalse(store.isAnySmartAssistEnabled)
    }

    func testProFeaturesRemainLockedUntilEntitlementIsUnlocked() {
        let store = EntitlementStore()

        XCTAssertFalse(store.canUse(.autoRecording))
        XCTAssertFalse(store.canUse(.dataExport))
        XCTAssertFalse(store.canUse(.goals))
        XCTAssertFalse(store.canUse(.appleWatch))

        store.isProUnlocked = true

        XCTAssertTrue(store.canUse(.autoRecording))
        XCTAssertTrue(store.canUse(.dataExport))
        XCTAssertTrue(store.canUse(.goals))
        XCTAssertTrue(store.canUse(.appleWatch))
    }

    func testAppleWatchIsDeclaredAsAProFeature() {
        XCTAssertTrue(ProFeature.allCases.contains(.appleWatch))
        XCTAssertEqual(ProFeature.appleWatch.systemImage, "applewatch")
        XCTAssertEqual(ProFeature.appleWatch.titleKey, "pro.feature.appleWatch.title")
    }

    func testProUsesOnlyLifetimePurchaseProduct() {
        XCTAssertEqual(ProProduct.allCases, [.lifetime])
        XCTAssertEqual(ProProduct.lifetime.rawValue, "pathtrio.pro.lifetime")
    }

    func testLockedProSettingsDisableAdvancedHealthSyncUntilUnlocked() {
        let store = SettingsStore()
        store.healthKitSyncEnabled = true

        store.reconcileLockedProSettings(isProUnlocked: false)

        XCTAssertFalse(store.healthKitSyncEnabled)

        store.healthKitSyncEnabled = true
        store.reconcileLockedProSettings(isProUnlocked: true)

        XCTAssertTrue(store.healthKitSyncEnabled)
    }
}
