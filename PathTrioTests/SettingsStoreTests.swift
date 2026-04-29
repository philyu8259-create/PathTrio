import XCTest
@testable import PathTrio

final class SettingsStoreTests: XCTestCase {
    func testBackgroundRecordingDefaultsToOff() {
        let store = SettingsStore()

        XCTAssertFalse(store.backgroundRecordingEnabled)
    }

    func testSmartAssistSummaryDoesNotIncludeBackgroundRecording() {
        let store = SettingsStore()
        store.backgroundRecordingEnabled = true

        XCTAssertFalse(store.isAnySmartAssistEnabled)
    }
}
