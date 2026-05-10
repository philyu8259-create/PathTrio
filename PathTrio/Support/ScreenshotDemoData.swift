import Foundation
import SwiftData

#if DEBUG
@MainActor
enum ScreenshotDemoData {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-PathTrioScreenshotMode")
    }

    static func prepare(appModel: AppModel, context: ModelContext) {
        guard isEnabled else { return }
        appModel.entitlementStore.isProUnlocked = true
        appModel.settingsStore.weeklyDistanceGoalMeters = 12_000
        appModel.settingsStore.monthlyWorkoutGoalCount = 18
        appModel.settingsStore.autoStartRemindersEnabled = true
        appModel.settingsStore.smartActivityAlertsEnabled = true
        appModel.settingsStore.autoPauseEnabled = true
        appModel.settingsStore.speedAnomalyAlertsEnabled = true
        appModel.settingsStore.preferredMapStyle = .standard

        do {
            let descriptor = FetchDescriptor<WorkoutSessionModel>()
            let existingWorkouts = try context.fetch(descriptor)
            guard existingWorkouts.isEmpty else { return }
            for workout in sampleWorkouts() {
                context.insert(workout)
            }
            try context.save()
        } catch {
            // Screenshots should continue even if the demo store cannot be seeded.
        }
    }

    private static func sampleWorkouts() -> [WorkoutSessionModel] {
        let now = Date()
        return [
            makeWorkout(type: .run, daysAgo: 0, hour: 7, distance: 4_820, duration: 1_742, calories: 286, now: now),
            makeWorkout(type: .walk, daysAgo: 1, hour: 19, distance: 2_140, duration: 1_830, calories: 126, now: now),
            makeWorkout(type: .ride, daysAgo: 3, hour: 8, distance: 12_650, duration: 2_210, calories: 358, now: now),
            makeWorkout(type: .run, daysAgo: 5, hour: 7, distance: 3_920, duration: 1_504, calories: 232, now: now),
            makeWorkout(type: .walk, daysAgo: 8, hour: 20, distance: 1_680, duration: 1_360, calories: 92, now: now),
            makeWorkout(type: .ride, daysAgo: 12, hour: 9, distance: 8_760, duration: 1_740, calories: 252, now: now)
        ]
    }

    private static func makeWorkout(
        type: WorkoutType,
        daysAgo: Int,
        hour: Int,
        distance: Double,
        duration: TimeInterval,
        calories: Double,
        now: Date
    ) -> WorkoutSessionModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        let startOfDay = calendar.startOfDay(for: day)
        let startedAt = calendar.date(byAdding: .hour, value: hour, to: startOfDay) ?? day
        let endedAt = startedAt.addingTimeInterval(duration)
        let speed = distance / max(duration, 1)
        let locations = routePoints(startedAt: startedAt, duration: duration, speed: speed)

        return WorkoutSessionModel(
            type: type,
            startedAt: startedAt,
            endedAt: endedAt,
            duration: duration,
            distanceMeters: distance,
            averageSpeedMetersPerSecond: speed,
            estimatedCalories: calories,
            smartAssistEnabledAtStart: true,
            healthSyncResult: .synced,
            locations: locations
        )
    }

    private static func routePoints(startedAt: Date, duration: TimeInterval, speed: Double) -> [LocationPointModel] {
        let baseLatitude = 31.1588
        let baseLongitude = 121.3684
        return (0..<14).map { index in
            let t = Double(index) / 13
            let latitude = baseLatitude + sin(t * .pi * 1.35) * 0.006 + t * 0.012
            let longitude = baseLongitude + cos(t * .pi * 1.15) * 0.004 + t * 0.014
            return LocationPointModel(
                timestamp: startedAt.addingTimeInterval(duration * t),
                latitude: latitude,
                longitude: longitude,
                horizontalAccuracy: 8,
                altitude: 4,
                speedMetersPerSecond: speed,
                course: 52
            )
        }
    }
}
#endif
