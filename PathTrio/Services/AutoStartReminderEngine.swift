import Foundation

struct AutoStartReminder: Equatable, Identifiable {
    let workoutType: WorkoutType

    var id: String { workoutType.rawValue }
}

struct AutoStartReminderEngine {
    private struct Candidate {
        let workoutType: WorkoutType
        let startedAt: Date
    }

    var requiredDuration: TimeInterval = 120
    private var candidate: Candidate?
    private var lastSuggestedWorkoutType: WorkoutType?

    init(requiredDuration: TimeInterval = 120) {
        self.requiredDuration = requiredDuration
    }

    mutating func evaluate(
        detectedActivity: DetectedMotionActivity,
        now: Date = Date(),
        isWorkoutActive: Bool
    ) -> AutoStartReminder? {
        guard !isWorkoutActive, let workoutType = detectedActivity.workoutType else {
            reset()
            return nil
        }

        if candidate?.workoutType != workoutType {
            candidate = Candidate(workoutType: workoutType, startedAt: now)
            lastSuggestedWorkoutType = nil
            return nil
        }

        guard let candidate else { return nil }
        guard now.timeIntervalSince(candidate.startedAt) >= requiredDuration else { return nil }
        guard lastSuggestedWorkoutType != workoutType else { return nil }

        lastSuggestedWorkoutType = workoutType
        return AutoStartReminder(workoutType: workoutType)
    }

    mutating func reset() {
        candidate = nil
        lastSuggestedWorkoutType = nil
    }
}
