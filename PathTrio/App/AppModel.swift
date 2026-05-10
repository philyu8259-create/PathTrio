import Foundation
import Observation
import SwiftData

@Observable
final class AppModel {
    var selectedWorkoutType: WorkoutType = .walk
    var activeDraft: WorkoutSessionDraft?
    var latestCompletedWorkoutID: UUID?
    var activeSuggestion: SmartAssistSuggestion?
    var autoStartReminder: AutoStartReminder?
    var autoStartReminderEngine = AutoStartReminderEngine()

    let recorder: WorkoutRecorder
    let settingsStore: SettingsStore
    var smartAssistEngine: SmartAssistEngine
    let locationService: LocationTrackingService
    let motionService: MotionActivityService
    let healthSyncer: any HealthSyncing
    let entitlementStore: EntitlementStore
    let appleWatchSupportService: AppleWatchSupportService

    init(
        recorder: WorkoutRecorder = WorkoutRecorder(distanceCalculator: DistanceCalculator()),
        settingsStore: SettingsStore = SettingsStore(),
        smartAssistEngine: SmartAssistEngine = SmartAssistEngine(),
        locationService: LocationTrackingService = LocationTrackingService(),
        motionService: MotionActivityService = MotionActivityService(),
        healthSyncer: any HealthSyncing = HealthKitWorkoutSyncer(),
        entitlementStore: EntitlementStore = EntitlementStore(),
        appleWatchSupportService: AppleWatchSupportService = AppleWatchSupportService()
    ) {
        self.recorder = recorder
        self.settingsStore = settingsStore
        self.smartAssistEngine = smartAssistEngine
        self.locationService = locationService
        self.motionService = motionService
        self.healthSyncer = healthSyncer
        self.entitlementStore = entitlementStore
        self.appleWatchSupportService = appleWatchSupportService
    }

    var smartAssistSettings: SmartAssistSettings {
        SmartAssistSettings(
            smartActivityAlertsEnabled: settingsStore.smartActivityAlertsEnabled,
            autoPauseEnabled: settingsStore.autoPauseEnabled,
            speedAnomalyAlertsEnabled: settingsStore.speedAnomalyAlertsEnabled
        )
    }

    @MainActor
    func loadSettings(from context: ModelContext) {
        do {
            try SettingsPersistenceStore(context: context).load(into: settingsStore)
        } catch {
            // Keep in-memory defaults if settings cannot be loaded.
        }
    }

    @MainActor
    func saveSettings(to context: ModelContext) {
        do {
            try SettingsPersistenceStore(context: context).save(settingsStore)
        } catch {
            // The next app launch will fall back to defaults if saving fails.
        }
    }

    @MainActor
    func reconcileLockedProSettings(in context: ModelContext) {
        if settingsStore.reconcileLockedProSettings(isProUnlocked: entitlementStore.isProUnlocked) {
            saveSettings(to: context)
        }
    }
}
