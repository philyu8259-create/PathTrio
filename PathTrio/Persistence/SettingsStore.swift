import Foundation
import Observation

@Observable
final class SettingsStore {
    var preferredUnits: String = "metric"
    var smartActivityAlertsEnabled: Bool = false
    var autoPauseEnabled: Bool = false
    var speedAnomalyAlertsEnabled: Bool = false
    var bodyWeightKilograms: Double?
    var healthKitSyncEnabled: Bool = false

    var isAnySmartAssistEnabled: Bool {
        smartActivityAlertsEnabled || autoPauseEnabled || speedAnomalyAlertsEnabled
    }
}
