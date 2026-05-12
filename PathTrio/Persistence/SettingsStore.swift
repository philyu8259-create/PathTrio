import Foundation
import Observation

@Observable
final class SettingsStore {
    var preferredUnits: String = "metric"
    var smartActivityAlertsEnabled: Bool = false
    var autoPauseEnabled: Bool = false
    var speedAnomalyAlertsEnabled: Bool = false
    var backgroundRecordingEnabled: Bool = true
    var autoStartRemindersEnabled: Bool = false
    var bodyWeightKilograms: Double?
    var healthKitSyncEnabled: Bool = false
    var weeklyDistanceGoalMeters: Double = 10_000
    var monthlyWorkoutGoalCount: Int = 12
    var preferredMapStyleRawValue: String = PathTrioMapStyle.standard.rawValue

    var isAnySmartAssistEnabled: Bool {
        smartActivityAlertsEnabled || autoPauseEnabled || speedAnomalyAlertsEnabled
    }

    var preferredMapStyle: PathTrioMapStyle {
        get {
            PathTrioMapStyle(rawValue: preferredMapStyleRawValue) ?? .standard
        }
        set {
            preferredMapStyleRawValue = newValue.rawValue
        }
    }

    @discardableResult
    func reconcileLockedProSettings(isProUnlocked: Bool) -> Bool {
        guard !isProUnlocked else { return false }

        var changed = false
        if autoStartRemindersEnabled {
            autoStartRemindersEnabled = false
            changed = true
        }
        if healthKitSyncEnabled {
            healthKitSyncEnabled = false
            changed = true
        }
        if preferredMapStyle != .standard {
            preferredMapStyle = .standard
            changed = true
        }
        return changed
    }
}
