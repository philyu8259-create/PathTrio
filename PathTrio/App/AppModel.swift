import Foundation
import Observation

@Observable
final class AppModel {
    var selectedWorkoutType: WorkoutType = .walk
    var activeDraft: WorkoutSessionDraft?
    var latestCompletedWorkoutID: UUID?
    var activeSuggestion: SmartAssistSuggestion?

    let recorder: WorkoutRecorder
    let settingsStore: SettingsStore
    let smartAssistEngine: SmartAssistEngine
    let locationService: LocationTrackingService
    let motionService: MotionActivityService
    let healthSyncer: any HealthSyncing

    init(
        recorder: WorkoutRecorder = WorkoutRecorder(distanceCalculator: DistanceCalculator()),
        settingsStore: SettingsStore = SettingsStore(),
        smartAssistEngine: SmartAssistEngine = SmartAssistEngine(),
        locationService: LocationTrackingService = LocationTrackingService(),
        motionService: MotionActivityService = MotionActivityService(),
        healthSyncer: any HealthSyncing = HealthKitWorkoutSyncer()
    ) {
        self.recorder = recorder
        self.settingsStore = settingsStore
        self.smartAssistEngine = smartAssistEngine
        self.locationService = locationService
        self.motionService = motionService
        self.healthSyncer = healthSyncer
    }

    var smartAssistSettings: SmartAssistSettings {
        SmartAssistSettings(
            smartActivityAlertsEnabled: settingsStore.smartActivityAlertsEnabled,
            autoPauseEnabled: settingsStore.autoPauseEnabled,
            speedAnomalyAlertsEnabled: settingsStore.speedAnomalyAlertsEnabled
        )
    }
}
