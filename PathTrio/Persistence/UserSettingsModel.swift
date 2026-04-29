import Foundation
import SwiftData

@Model
final class UserSettingsModel {
    @Attribute(.unique) var id: UUID
    var preferredUnits: String
    var smartActivityAlertsEnabled: Bool
    var autoPauseEnabled: Bool
    var speedAnomalyAlertsEnabled: Bool
    var backgroundRecordingEnabled: Bool
    var bodyWeightKilograms: Double?
    var healthKitSyncEnabled: Bool

    init(
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        preferredUnits: String = "metric",
        smartActivityAlertsEnabled: Bool = false,
        autoPauseEnabled: Bool = false,
        speedAnomalyAlertsEnabled: Bool = false,
        backgroundRecordingEnabled: Bool = false,
        bodyWeightKilograms: Double? = nil,
        healthKitSyncEnabled: Bool = false
    ) {
        self.id = id
        self.preferredUnits = preferredUnits
        self.smartActivityAlertsEnabled = smartActivityAlertsEnabled
        self.autoPauseEnabled = autoPauseEnabled
        self.speedAnomalyAlertsEnabled = speedAnomalyAlertsEnabled
        self.backgroundRecordingEnabled = backgroundRecordingEnabled
        self.bodyWeightKilograms = bodyWeightKilograms
        self.healthKitSyncEnabled = healthKitSyncEnabled
    }
}
