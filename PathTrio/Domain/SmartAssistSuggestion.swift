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
            return L10n.string("smartAssist.activityChange.title", to.displayName)
        case .autoPause:
            return L10n.string("smartAssist.autoPause.title")
        case .speedAnomaly:
            return L10n.string("smartAssist.speedAnomaly.title")
        }
    }

    var message: String {
        switch self {
        case .activityChange(let from, let to):
            return L10n.string(
                "smartAssist.activityChange.message",
                to.displayName.localizedLowercase,
                from.displayName.localizedLowercase
            )
        case .autoPause:
            return L10n.string("smartAssist.autoPause.message")
        case .speedAnomaly:
            return L10n.string("smartAssist.speedAnomaly.message")
        }
    }
}
