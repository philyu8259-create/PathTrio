import Foundation

struct WorkoutMetrics: Equatable {
    var duration: TimeInterval
    var distanceMeters: Double
    var averageSpeedMetersPerSecond: Double

    var paceSecondsPerKilometer: Double? {
        guard distanceMeters > 0 else { return nil }
        return duration / (distanceMeters / 1_000)
    }
}

enum WorkoutCaloriesEstimator {
    static let defaultBodyWeightKilograms: Double = 70

    static func estimate(type: WorkoutType, duration: TimeInterval, bodyWeightKilograms: Double?) -> Double? {
        guard duration > 0 else { return nil }
        let weight = bodyWeightKilograms ?? defaultBodyWeightKilograms
        guard weight > 0 else { return nil }

        return type.metabolicEquivalent * weight * (duration / 3_600)
    }
}

enum WorkoutMetricsFormatter {
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

    static func pace(_ secondsPerKilometer: Double?) -> String {
        guard let secondsPerKilometer, secondsPerKilometer.isFinite else {
            return "-- /km"
        }
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
