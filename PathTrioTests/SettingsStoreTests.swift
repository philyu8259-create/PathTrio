import XCTest
@testable import PathTrio

final class SettingsStoreTests: XCTestCase {
    func testBackgroundRecordingDefaultsToOff() {
        let store = SettingsStore()

        XCTAssertFalse(store.backgroundRecordingEnabled)
        XCTAssertFalse(store.autoStartRemindersEnabled)
    }

    func testSmartAssistSummaryDoesNotIncludeBackgroundRecording() {
        let store = SettingsStore()
        store.backgroundRecordingEnabled = true
        store.autoStartRemindersEnabled = true

        XCTAssertFalse(store.isAnySmartAssistEnabled)
    }
}
