import Foundation

enum WatchWorkoutFormatters {
    static func displayName(for typeRawValue: String) -> String {
        switch typeRawValue {
        case "run": NSLocalizedString("watch.workout.run", comment: "")
        case "ride": NSLocalizedString("watch.workout.ride", comment: "")
        default: NSLocalizedString("watch.workout.walk", comment: "")
        }
    }

    static func systemImage(for typeRawValue: String) -> String {
        switch typeRawValue {
        case "run": "figure.run"
        case "ride": "bicycle"
        default: "figure.walk"
        }
    }

    static func stateName(for stateRawValue: String) -> String {
        switch stateRawValue {
        case "paused", "autoPaused": NSLocalizedString("watch.state.paused", comment: "")
        case "recording": NSLocalizedString("watch.state.recording", comment: "")
        default: NSLocalizedString("watch.state.ready", comment: "")
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
