import SwiftData
import XCTest
@testable import PathTrio

@MainActor
final class SettingsPersistenceStoreTests: XCTestCase {
    func testSavesAndLoadsSettings() throws {
        let context = try makeContext()
        let persistenceStore = SettingsPersistenceStore(context: context)
        let settings = SettingsStore()
        settings.preferredUnits = "metric"
        settings.smartActivityAlertsEnabled = true
        settings.autoPauseEnabled = true
        settings.speedAnomalyAlertsEnabled = true
        settings.backgroundRecordingEnabled = true
        settings.healthKitSyncEnabled = true

        try persistenceStore.save(settings)

        let loaded = SettingsStore()
        try persistenceStore.load(into: loaded)

        XCTAssertEqual(loaded.preferredUnits, "metric")
        XCTAssertTrue(loaded.smartActivityAlertsEnabled)
        XCTAssertTrue(loaded.autoPauseEnabled)
        XCTAssertTrue(loaded.speedAnomalyAlertsEnabled)
        XCTAssertTrue(loaded.backgroundRecordingEnabled)
        XCTAssertTrue(loaded.healthKitSyncEnabled)
    }

    func testLoadCreatesDefaultSettingsWhenMissing() throws {
        let context = try makeContext()
        let persistenceStore = SettingsPersistenceStore(context: context)
        let settings = SettingsStore()

        try persistenceStore.load(into: settings)

        XCTAssertEqual(settings.preferredUnits, "metric")
        XCTAssertFalse(settings.smartActivityAlertsEnabled)
        XCTAssertFalse(settings.backgroundRecordingEnabled)
    }

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: WorkoutSessionModel.self,
            LocationPointModel.self,
            UserSettingsModel.self,
            configurations: configuration
        )
        return ModelContext(container)
    }
}
