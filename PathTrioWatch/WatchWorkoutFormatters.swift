import Foundation
import SwiftUI

enum WatchWorkoutFormatters {
    private enum WatchWorkoutCategory {
        case walking
        case running
        case cycling
        case swimming
        case water
        case outdoorAdventure
        case studio
    }

    static func displayName(for typeRawValue: String) -> String {
        let value = NSLocalizedString("watch.workout.\(typeRawValue)", comment: "")
        return value != "watch.workout.\(typeRawValue)" ? value : NSLocalizedString("watch.workout.walk", comment: "")
    }

    static func systemImage(for typeRawValue: String) -> String {
        switch workoutCategory(for: typeRawValue) {
        case .walking: "figure.walk"
        case .running: "figure.run"
        case .cycling: "bicycle"
        case .swimming: "figure.pool.swim"
        case .water: "figure.open.water.sports"
        case .outdoorAdventure: "snowflake"
        case .studio: "figure.flexibility"
        }
    }

    static func stateName(for stateRawValue: String) -> String {
        switch stateRawValue {
        case "paused", "autoPaused": NSLocalizedString("watch.state.paused", comment: "")
        case "recording": NSLocalizedString("watch.state.recording", comment: "")
        default: NSLocalizedString("watch.state.ready", comment: "")
        }
    }

    static func usesSpeedMetric(for typeRawValue: String) -> Bool {
        workoutCategory(for: typeRawValue) == .cycling
    }

    static func typeColor(for typeRawValue: String) -> Color {
        switch workoutCategory(for: typeRawValue) {
        case .walking:
            .teal
        case .running:
            .orange
        case .cycling:
            .blue
        case .swimming, .water, .outdoorAdventure, .studio:
            .green
        }
    }

    static func metricTitleKey(for typeRawValue: String) -> LocalizedStringKey {
        usesSpeedMetric(for: typeRawValue) ? "watch.metric.speed" : "watch.metric.pace"
    }

    static func metricValue(
        for typeRawValue: String,
        duration: TimeInterval,
        distanceMeters: Double,
        averageSpeedMetersPerSecond: Double
    ) -> String {
        if usesSpeedMetric(for: typeRawValue) {
            return speed(averageSpeedMetersPerSecond)
        }
        return pace(duration: duration, distanceMeters: distanceMeters)
    }

    private static func workoutCategory(for typeRawValue: String) -> WatchWorkoutCategory {
        switch typeRawValue {
        case "walk", "hike":
            .walking
        case "run", "trailRun", "treadmillRun":
            .running
        case "ride", "roadRide", "mountainRide", "indoorRide", "eBikeRide":
            .cycling
        case "swim", "openWaterSwim":
            .swimming
        case "row", "paddle", "kayak", "canoe", "standUpPaddleboard", "rowingMachine":
            .water
        case "elliptical", "skiing", "snowshoe", "stairClimb":
            .outdoorAdventure
        case "yoga", "strengthTraining", "coreTraining", "hiit", "dance":
            .studio
        default:
            .walking
        }
    }

    static func distance(_ meters: Double) -> String {
        if meters < 1_000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.2f km", meters / 1_000)
    }

    static func duration(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded()))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func speed(_ metersPerSecond: Double) -> String {
        String(format: "%.1f km/h", metersPerSecond * 3.6)
    }

    static func pace(duration: TimeInterval, distanceMeters: Double) -> String {
        guard distanceMeters > 0 else { return "-- /km" }
        let secondsPerKilometer = duration / (distanceMeters / 1_000)
        guard secondsPerKilometer.isFinite else { return "-- /km" }
        let minutes = Int(secondsPerKilometer) / 60
        let seconds = Int(secondsPerKilometer) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    static func calories(_ calories: Double?) -> String {
        guard let calories, calories.isFinite, calories > 0 else {
            return "-- kcal"
        }
        return "\(Int(calories.rounded())) kcal"
    }
}
