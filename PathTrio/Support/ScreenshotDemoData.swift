import CoreLocation
import Foundation
import SwiftData

#if DEBUG
@MainActor
enum ScreenshotDemoData {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-PathTrioScreenshotMode")
    }

    static var targetTab: AppTab? {
        switch argument(after: "-PathTrioScreenshotTab") {
        case "history": .history
        case "settings": .settings
        default: nil
        }
    }

    static var shouldOpenActiveWorkout: Bool {
        argument(after: "-PathTrioScreenshotScene") == "active"
    }

    static func prepare(appModel: AppModel, context: ModelContext) {
        guard isEnabled else { return }
        appModel.entitlementStore.isProUnlocked = true
        appModel.settingsStore.weeklyDistanceGoalMeters = 12_000
        appModel.settingsStore.monthlyWorkoutGoalCount = 18
        appModel.settingsStore.autoStartRemindersEnabled = false
        appModel.settingsStore.smartActivityAlertsEnabled = false
        appModel.settingsStore.autoPauseEnabled = false
        appModel.settingsStore.speedAnomalyAlertsEnabled = false
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

    static func activeWorkoutDraft(now: Date = Date()) -> WorkoutSessionDraft {
        let startedAt = now.addingTimeInterval(-1_645)
        let locations = previewLocations(startedAt: startedAt, duration: 1_645, speed: 2.95)

        return WorkoutSessionDraft(
            type: .run,
            startedAt: startedAt,
            state: .recording,
            locations: locations,
            metrics: WorkoutMetrics(
                duration: 1_645,
                distanceMeters: 4_860,
                averageSpeedMetersPerSecond: 2.95
            )
        )
    }

    static func previewLocations(
        startedAt: Date = Date().addingTimeInterval(-1_200),
        duration: TimeInterval = 1_200,
        speed: Double = 2.6
    ) -> [CLLocation] {
        routePoints(startedAt: startedAt, duration: duration, speed: speed).map {
            CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude),
                altitude: $0.altitude,
                horizontalAccuracy: $0.horizontalAccuracy,
                verticalAccuracy: 12,
                course: $0.course,
                speed: $0.speedMetersPerSecond,
                timestamp: $0.timestamp
            )
        }
    }

    private static func argument(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else { return nil }
        return arguments[valueIndex]
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
