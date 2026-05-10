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
        settings.autoStartRemindersEnabled = true
        settings.healthKitSyncEnabled = true
        settings.weeklyDistanceGoalMeters = 21_000
        settings.monthlyWorkoutGoalCount = 16
        settings.preferredMapStyle = .hybrid

        try persistenceStore.save(settings)

        let loaded = SettingsStore()
        try persistenceStore.load(into: loaded)

        XCTAssertEqual(loaded.preferredUnits, "metric")
        XCTAssertTrue(loaded.smartActivityAlertsEnabled)
        XCTAssertTrue(loaded.autoPauseEnabled)
        XCTAssertTrue(loaded.speedAnomalyAlertsEnabled)
        XCTAssertTrue(loaded.backgroundRecordingEnabled)
        XCTAssertTrue(loaded.autoStartRemindersEnabled)
        XCTAssertTrue(loaded.healthKitSyncEnabled)
        XCTAssertEqual(loaded.weeklyDistanceGoalMeters, 21_000)
        XCTAssertEqual(loaded.monthlyWorkoutGoalCount, 16)
        XCTAssertEqual(loaded.preferredMapStyle, .hybrid)
    }

    func testLoadCreatesDefaultSettingsWhenMissing() throws {
        let context = try makeContext()
        let persistenceStore = SettingsPersistenceStore(context: context)
        let settings = SettingsStore()

        try persistenceStore.load(into: settings)

        XCTAssertEqual(settings.preferredUnits, "metric")
        XCTAssertFalse(settings.smartActivityAlertsEnabled)
        XCTAssertFalse(settings.backgroundRecordingEnabled)
        XCTAssertFalse(settings.autoStartRemindersEnabled)
        XCTAssertEqual(settings.weeklyDistanceGoalMeters, 10_000)
        XCTAssertEqual(settings.monthlyWorkoutGoalCount, 12)
        XCTAssertEqual(settings.preferredMapStyle, .standard)
    }

    func testReconcileLockedProSettingsPersistsSanitizedValues() throws {
        let context = try makeContext()
        let persistenceStore = SettingsPersistenceStore(context: context)
        let savedSettings = SettingsStore()
        savedSettings.backgroundRecordingEnabled = true
        savedSettings.autoStartRemindersEnabled = true
        savedSettings.healthKitSyncEnabled = true
        savedSettings.preferredMapStyle = .imagery
        try persistenceStore.save(savedSettings)

        let appModel = AppModel(
            settingsStore: SettingsStore(),
            entitlementStore: EntitlementStore(isProUnlocked: false)
        )

        appModel.loadSettings(from: context)
        appModel.reconcileLockedProSettings(in: context)

        let reloaded = SettingsStore()
        try persistenceStore.load(into: reloaded)

        XCTAssertTrue(reloaded.backgroundRecordingEnabled)
        XCTAssertFalse(reloaded.autoStartRemindersEnabled)
        XCTAssertFalse(reloaded.healthKitSyncEnabled)
        XCTAssertEqual(reloaded.preferredMapStyle, .standard)
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
