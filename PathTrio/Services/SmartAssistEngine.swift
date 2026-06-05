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
    var workoutStartGraceDuration: TimeInterval = 25
    var activityChangeStableDuration: TimeInterval = 18
    var autoPauseStableDuration: TimeInterval = 35
    var speedAnomalyStableDuration: TimeInterval = 8
    var autoResumeStableDuration: TimeInterval = 6
    var suggestionCooldownDuration: TimeInterval = 120

    private var candidate: Candidate?
    private var autoResumeStartedAt: Date?
    private var lastSuggestion: LastSuggestion?

    mutating func evaluate(
        workoutType: WorkoutType,
        workoutStartedAt: Date,
        workoutState: WorkoutState,
        currentSpeedMetersPerSecond: Double,
        detectedActivity: DetectedMotionActivity,
        settings: SmartAssistSettings,
        now: Date = Date()
    ) -> SmartAssistSuggestion? {
        guard workoutState == .recording else {
            candidate = nil
            return nil
        }

        guard now.timeIntervalSince(workoutStartedAt) >= workoutStartGraceDuration else {
            candidate = nil
            return nil
        }

        guard let proposed = proposedSuggestion(
            workoutType: workoutType,
            currentSpeedMetersPerSecond: currentSpeedMetersPerSecond,
            detectedActivity: detectedActivity,
            settings: settings
        ) else {
            candidate = nil
            return nil
        }

        if let lastSuggestion,
           lastSuggestion.kind == proposed.kind,
           now.timeIntervalSince(lastSuggestion.suggestedAt) < suggestionCooldownDuration {
            return nil
        }

        if candidate?.kind != proposed.kind {
            candidate = Candidate(kind: proposed.kind, startedAt: now)
            return nil
        }

        guard let candidate else { return nil }
        guard now.timeIntervalSince(candidate.startedAt) >= proposed.stableDuration else { return nil }

        self.candidate = nil
        lastSuggestion = LastSuggestion(kind: proposed.kind, suggestedAt: now)
        return proposed.suggestion
    }

    mutating func shouldResumeAutoPaused(
        workoutType: WorkoutType,
        currentSpeedMetersPerSecond: Double,
        detectedActivity: DetectedMotionActivity,
        now: Date = Date()
    ) -> Bool {
        guard isMovingAgain(
            workoutType: workoutType,
            currentSpeedMetersPerSecond: currentSpeedMetersPerSecond,
            detectedActivity: detectedActivity
        ) else {
            autoResumeStartedAt = nil
            return false
        }

        if autoResumeStartedAt == nil {
            autoResumeStartedAt = now
            return false
        }

        guard let autoResumeStartedAt else { return false }
        guard now.timeIntervalSince(autoResumeStartedAt) >= autoResumeStableDuration else { return false }

        self.autoResumeStartedAt = nil
        return true
    }

    mutating func reset() {
        candidate = nil
        autoResumeStartedAt = nil
        lastSuggestion = nil
    }

    private func proposedSuggestion(
        workoutType: WorkoutType,
        currentSpeedMetersPerSecond: Double,
        detectedActivity: DetectedMotionActivity,
        settings: SmartAssistSettings
    ) -> ProposedSuggestion? {
        if settings.autoPauseEnabled,
           isAutoPauseCandidate(
               workoutType: workoutType,
               currentSpeedMetersPerSecond: currentSpeedMetersPerSecond,
               detectedActivity: detectedActivity
           ) {
            return ProposedSuggestion(
                kind: .autoPause,
                suggestion: .autoPause,
                stableDuration: autoPauseStableDuration
            )
        }

        if detectedActivity == .stationary {
            return nil
        }

        if settings.speedAnomalyAlertsEnabled,
           currentSpeedMetersPerSecond > 0,
           isSpeedAnomalous(currentSpeedMetersPerSecond, for: workoutType) {
            return ProposedSuggestion(
                kind: .speedAnomaly(workoutType),
                suggestion: .speedAnomaly(currentSpeedMetersPerSecond: currentSpeedMetersPerSecond, workoutType: workoutType),
                stableDuration: speedAnomalyStableDuration
            )
        }

        if settings.smartActivityAlertsEnabled,
           let detectedType = detectedActivity.workoutType,
           detectedType != workoutType,
           isPlausibleActivityChange(
               from: workoutType,
               to: detectedType,
               currentSpeedMetersPerSecond: currentSpeedMetersPerSecond
           ) {
            return ProposedSuggestion(
                kind: .activityChange(detectedType),
                suggestion: .activityChange(from: workoutType, to: detectedType),
                stableDuration: activityChangeStableDuration
            )
        }

        return nil
    }

    private func isPlausibleActivityChange(
        from currentType: WorkoutType,
        to detectedType: WorkoutType,
        currentSpeedMetersPerSecond: Double
    ) -> Bool {
        if currentType.category == .cycling && detectedType.category != .cycling {
            return false
        }

        if currentType.category == .running && detectedType.category == .walking {
            return false
        }

        if currentType.category == .walking && detectedType.category == .running {
            return currentSpeedMetersPerSecond >= runningSuggestionSpeed
        }

        return currentSpeedMetersPerSecond >= minimumMovingSpeed(for: detectedType)
    }

    private func isSpeedAnomalous(_ speed: Double, for type: WorkoutType) -> Bool {
        speed > type.speedAnomalyThreshold
    }

    private func minimumMovingSpeed(for type: WorkoutType) -> Double {
        type.minimumMovingSpeed
    }

    private var runningSuggestionSpeed: Double {
        1.8
    }

    private func stationarySpeedThreshold(for type: WorkoutType) -> Double {
        type.stationarySpeedThreshold
    }

    private func isAutoPauseCandidate(
        workoutType: WorkoutType,
        currentSpeedMetersPerSecond: Double,
        detectedActivity: DetectedMotionActivity
    ) -> Bool {
        guard currentSpeedMetersPerSecond < stationarySpeedThreshold(for: workoutType) else { return false }

        switch detectedActivity {
        case .stationary, .unknown:
            return true
        case .walking, .running, .cycling, .automotive:
            return false
        }
    }

    private func isMovingAgain(
        workoutType: WorkoutType,
        currentSpeedMetersPerSecond: Double,
        detectedActivity: DetectedMotionActivity
    ) -> Bool {
        if let detectedType = detectedActivity.workoutType,
           detectedType == workoutType || currentSpeedMetersPerSecond >= minimumMovingSpeed(for: detectedType) {
            return true
        }

        return currentSpeedMetersPerSecond >= minimumMovingSpeed(for: workoutType)
    }
}

private struct Candidate {
    let kind: SmartAssistCandidateKind
    let startedAt: Date
}

private struct LastSuggestion {
    let kind: SmartAssistCandidateKind
    let suggestedAt: Date
}

private struct ProposedSuggestion {
    let kind: SmartAssistCandidateKind
    let suggestion: SmartAssistSuggestion
    let stableDuration: TimeInterval
}

private enum SmartAssistCandidateKind: Equatable {
    case activityChange(WorkoutType)
    case autoPause
    case speedAnomaly(WorkoutType)
}
