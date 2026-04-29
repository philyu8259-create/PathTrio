import Foundation

struct SmartAssistSettings {
    var smartActivityAlertsEnabled: Bool
    var autoPauseEnabled: Bool
    var speedAnomalyAlertsEnabled: Bool
}

enum DetectedMotionActivity: Equatable {
    case stationary
    case walking
    case running
    case cycling
    case automotive
    case unknown

    var workoutType: WorkoutType? {
        switch self {
        case .walking: .walk
        case .running: .run
        case .cycling: .ride
        case .stationary, .automotive, .unknown: nil
        }
    }
}

struct SmartAssistEngine {
    func evaluate(
        workoutType: WorkoutType,
        currentSpeedMetersPerSecond: Double,
        detectedActivity: DetectedMotionActivity,
        settings: SmartAssistSettings
    ) -> SmartAssistSuggestion? {
        if settings.speedAnomalyAlertsEnabled, isSpeedAnomalous(currentSpeedMetersPerSecond, for: workoutType) {
            return .speedAnomaly(currentSpeedMetersPerSecond: currentSpeedMetersPerSecond, workoutType: workoutType)
        }

        if settings.autoPauseEnabled, detectedActivity == .stationary, currentSpeedMetersPerSecond < 0.4 {
            return .autoPause
        }

        if settings.smartActivityAlertsEnabled,
           let detectedType = detectedActivity.workoutType,
           detectedType != workoutType {
            return .activityChange(from: workoutType, to: detectedType)
        }

        return nil
    }

    private func isSpeedAnomalous(_ speed: Double, for type: WorkoutType) -> Bool {
        switch type {
        case .walk:
            speed > 4.5
        case .run:
            speed > 8.5
        case .ride:
            speed > 22
        }
    }
}
