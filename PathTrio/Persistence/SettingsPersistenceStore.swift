import Foundation
import SwiftData

@MainActor
struct SettingsPersistenceStore {
    let context: ModelContext

    func load(into settings: SettingsStore) throws {
        let model = try currentSettingsModel()
        try migrateIfNeeded(model)
        settings.preferredUnits = model.preferredUnits
        settings.smartActivityAlertsEnabled = model.smartActivityAlertsEnabled
        settings.autoPauseEnabled = model.autoPauseEnabled
        settings.speedAnomalyAlertsEnabled = model.speedAnomalyAlertsEnabled
        settings.backgroundRecordingEnabled = model.backgroundRecordingEnabled
        settings.autoStartRemindersEnabled = model.autoStartRemindersEnabled ?? false
        settings.bodyWeightKilograms = model.bodyWeightKilograms
        settings.healthKitSyncEnabled = model.healthKitSyncEnabled
        settings.weeklyDistanceGoalMeters = model.weeklyDistanceGoalMeters ?? 10_000
        settings.monthlyWorkoutGoalCount = model.monthlyWorkoutGoalCount ?? 12
        settings.preferredMapStyleRawValue = model.preferredMapStyleRawValue ?? PathTrioMapStyle.standard.rawValue
    }

    func save(_ settings: SettingsStore) throws {
        let model = try currentSettingsModel()
        model.settingsSchemaVersion = SettingsSchema.currentVersion
        model.preferredUnits = settings.preferredUnits
        model.smartActivityAlertsEnabled = settings.smartActivityAlertsEnabled
        model.autoPauseEnabled = settings.autoPauseEnabled
        model.speedAnomalyAlertsEnabled = settings.speedAnomalyAlertsEnabled
        model.backgroundRecordingEnabled = settings.backgroundRecordingEnabled
        model.autoStartRemindersEnabled = settings.autoStartRemindersEnabled
        model.bodyWeightKilograms = settings.bodyWeightKilograms
        model.healthKitSyncEnabled = settings.healthKitSyncEnabled
        model.weeklyDistanceGoalMeters = settings.weeklyDistanceGoalMeters
        model.monthlyWorkoutGoalCount = settings.monthlyWorkoutGoalCount
        model.preferredMapStyleRawValue = settings.preferredMapStyle.rawValue
        try context.save()
    }

    private func currentSettingsModel() throws -> UserSettingsModel {
        var descriptor = FetchDescriptor<UserSettingsModel>()
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let model = UserSettingsModel()
        context.insert(model)
        try context.save()
        return model
    }

    private func migrateIfNeeded(_ model: UserSettingsModel) throws {
        guard (model.settingsSchemaVersion ?? 1) < SettingsSchema.currentVersion else { return }

        model.backgroundRecordingEnabled = false
        model.settingsSchemaVersion = SettingsSchema.currentVersion
        try context.save()
    }
}
