import CoreLocation
import Foundation
import Observation

@Observable
final class WorkoutRecorder {
    private let distanceCalculator: DistanceCalculator
    private(set) var draft: WorkoutSessionDraft?

    init(distanceCalculator: DistanceCalculator) {
        self.distanceCalculator = distanceCalculator
    }

    @discardableResult
    func start(type: WorkoutType, at date: Date = Date()) -> WorkoutSessionDraft {
        let next = WorkoutSessionDraft(type: type, startedAt: date, state: .recording)
        draft = next
        return next
    }

    @discardableResult
    func pause(at date: Date = Date()) -> WorkoutState {
        guard var current = draft else { return .idle }
        guard current.state == .recording else { return current.state }
        current.state = .paused
        current.pausedStartedAt = date
        current.metrics = metrics(for: current, now: date)
        draft = current
        return current.state
    }

    @discardableResult
    func autoPause(at date: Date = Date()) -> WorkoutState {
        guard var current = draft else { return .idle }
        guard current.state == .recording else { return current.state }
        current.state = .autoPaused
        current.pausedStartedAt = date
        current.metrics = metrics(for: current, now: date)
        draft = current
        return current.state
    }

    @discardableResult
    func resume(at date: Date = Date()) -> WorkoutState {
        guard var current = draft else { return .idle }
        if let pausedStartedAt = current.pausedStartedAt {
            current.accumulatedPausedDuration += max(0, date.timeIntervalSince(pausedStartedAt))
        }
        current.state = .recording
        current.pausedStartedAt = nil
        current.metrics = metrics(for: current, now: date)
        draft = current
        return current.state
    }

    @discardableResult
    func changeType(to type: WorkoutType) -> WorkoutSessionDraft? {
        guard let current = draft, current.type != type else { return draft }
        let updated = WorkoutSessionDraft(
            id: current.id,
            type: type,
            startedAt: current.startedAt,
            endedAt: current.endedAt,
            state: current.state,
            pausedStartedAt: current.pausedStartedAt,
            accumulatedPausedDuration: current.accumulatedPausedDuration,
            locations: current.locations,
            metrics: current.metrics
        )
        draft = updated
        return updated
    }

    @discardableResult
    func addLocations(_ locations: [CLLocation], now: Date = Date()) -> WorkoutSessionDraft? {
        guard var current = draft, current.state == .recording else { return draft }
        current.locations = distanceCalculator.cleanedLocations(from: current.locations + locations, for: current.type)
        current.metrics = metrics(for: current, now: now)
        draft = current
        return current
    }

    @discardableResult
    func refresh(now: Date = Date()) -> WorkoutSessionDraft? {
        guard var current = draft else { return nil }
        current.metrics = metrics(for: current, now: now)
        draft = current
        return current
    }

    @discardableResult
    func end(at date: Date = Date()) -> WorkoutSessionDraft? {
        guard var current = draft else { return nil }
        if let pausedStartedAt = current.pausedStartedAt {
            current.accumulatedPausedDuration += max(0, date.timeIntervalSince(pausedStartedAt))
            current.pausedStartedAt = nil
        }
        current.endedAt = date
        current.state = .ended
        current.metrics = metrics(for: current, now: date)
        draft = nil
        return current
    }

    private func metrics(for draft: WorkoutSessionDraft, now: Date) -> WorkoutMetrics {
        var pausedDuration = draft.accumulatedPausedDuration
        if let pausedStartedAt = draft.pausedStartedAt {
            pausedDuration += max(0, now.timeIntervalSince(pausedStartedAt))
        }
        let duration = max(0, now.timeIntervalSince(draft.startedAt) - pausedDuration)
        let distance = distanceCalculator.totalDistanceMeters(for: draft.locations, type: draft.type)
        let speed = duration > 0 ? distance / duration : 0
        return WorkoutMetrics(duration: duration, distanceMeters: distance, averageSpeedMetersPerSecond: speed)
    }
}
