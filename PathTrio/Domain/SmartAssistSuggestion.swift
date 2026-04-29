import Foundation

enum SmartAssistSuggestion: Equatable, Identifiable {
    case activityChange(from: WorkoutType, to: WorkoutType)
    case autoPause
    case speedAnomaly(currentSpeedMetersPerSecond: Double, workoutType: WorkoutType)

    var id: String {
        switch self {
        case .activityChange(let from, let to):
            return "activity-\(from.rawValue)-\(to.rawValue)"
        case .autoPause:
            return "auto-pause"
        case .speedAnomaly(_, let workoutType):
            return "speed-anomaly-\(workoutType.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .activityChange(_, let to):
            return "Switch to \(to.displayName)?"
        case .autoPause:
            return "Pause workout?"
        case .speedAnomaly:
            return "Unusual speed detected"
        }
    }

    var message: String {
        switch self {
        case .activityChange(let from, let to):
            return "PathTrio detected movement that looks more like \(to.displayName.lowercased()) than \(from.displayName.lowercased())."
        case .autoPause:
            return "You appear to be still. PathTrio can pause this workout until movement resumes."
        case .speedAnomaly:
            return "Your speed is unusually high for this workout type. You may want to pause recording."
        }
    }
}
