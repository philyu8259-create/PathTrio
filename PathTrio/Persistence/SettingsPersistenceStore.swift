import Foundation
import SwiftData

@MainActor
struct SettingsPersistenceStore {
    let context: ModelContext

    func load(into settings: SettingsStore) throws {
        let model = try currentSettingsModel()
        settings.preferredUnits = model.preferredUnits
        settings.smartActivityAlertsEnabled = model.smartActivityAlertsEnabled
        settings.autoPauseEnabled = model.autoPauseEnabled
        settings.speedAnomalyAlertsEnabled = model.speedAnomalyAlertsEnabled
        settings.backgroundRecordingEnabled = model.backgroundRecordingEnabled
        settings.bodyWeightKilograms = model.bodyWeightKilograms
        settings.healthKitSyncEnabled = model.healthKitSyncEnabled
    }

    func save(_ settings: SettingsStore) throws {
        let model = try currentSettingsModel()
        model.preferredUnits = settings.preferredUnits
        model.smartActivityAlertsEnabled = settings.smartActivityAlertsEnabled
        model.autoPauseEnabled = settings.autoPauseEnabled
        model.speedAnomalyAlertsEnabled = settings.speedAnomalyAlertsEnabled
        model.backgroundRecordingEnabled = settings.backgroundRecordingEnabled
        model.bodyWeightKilograms = settings.bodyWeightKilograms
        model.healthKitSyncEnabled = settings.healthKitSyncEnabled
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
}
