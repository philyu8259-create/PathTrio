import Foundation
import SwiftData

enum SettingsSchema {
    static let currentVersion = 2
}

@Model
final class UserSettingsModel {
    @Attribute(.unique) var id: UUID
    var settingsSchemaVersion: Int?
    var preferredUnits: String
    var smartActivityAlertsEnabled: Bool
    var autoPauseEnabled: Bool
    var speedAnomalyAlertsEnabled: Bool
    var backgroundRecordingEnabled: Bool
    var autoStartRemindersEnabled: Bool?
    var bodyWeightKilograms: Double?
    var healthKitSyncEnabled: Bool
    var weeklyDistanceGoalMeters: Double?
    var monthlyWorkoutGoalCount: Int?
    var preferredMapStyleRawValue: String?

    init(
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        settingsSchemaVersion: Int? = SettingsSchema.currentVersion,
        preferredUnits: String = "metric",
        smartActivityAlertsEnabled: Bool = false,
        autoPauseEnabled: Bool = false,
        speedAnomalyAlertsEnabled: Bool = false,
        backgroundRecordingEnabled: Bool = true,
        autoStartRemindersEnabled: Bool? = false,
        bodyWeightKilograms: Double? = nil,
        healthKitSyncEnabled: Bool = false,
        weeklyDistanceGoalMeters: Double? = 10_000,
        monthlyWorkoutGoalCount: Int? = 12,
        preferredMapStyleRawValue: String? = PathTrioMapStyle.standard.rawValue
    ) {
        self.id = id
        self.settingsSchemaVersion = settingsSchemaVersion
        self.preferredUnits = preferredUnits
        self.smartActivityAlertsEnabled = smartActivityAlertsEnabled
        self.autoPauseEnabled = autoPauseEnabled
        self.speedAnomalyAlertsEnabled = speedAnomalyAlertsEnabled
        self.backgroundRecordingEnabled = backgroundRecordingEnabled
        self.autoStartRemindersEnabled = autoStartRemindersEnabled
        self.bodyWeightKilograms = bodyWeightKilograms
        self.healthKitSyncEnabled = healthKitSyncEnabled
        self.weeklyDistanceGoalMeters = weeklyDistanceGoalMeters
        self.monthlyWorkoutGoalCount = monthlyWorkoutGoalCount
        self.preferredMapStyleRawValue = preferredMapStyleRawValue
    }
}
