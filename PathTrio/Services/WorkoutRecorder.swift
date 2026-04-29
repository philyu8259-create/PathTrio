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
    func pause() -> WorkoutState {
        guard var current = draft else { return .idle }
        current.state = .paused
        draft = current
        return current.state
    }

    @discardableResult
    func autoPause() -> WorkoutState {
        guard var current = draft else { return .idle }
        current.state = .autoPaused
        draft = current
        return current.state
    }

    @discardableResult
    func resume() -> WorkoutState {
        guard var current = draft else { return .idle }
        current.state = .recording
        draft = current
        return current.state
    }

    @discardableResult
    func addLocations(_ locations: [CLLocation], now: Date = Date()) -> WorkoutSessionDraft? {
        guard var current = draft, current.state == .recording else { return draft }
        current.locations.append(contentsOf: locations)
        current.metrics = metrics(for: current, now: now)
        draft = current
        return current
    }

    @discardableResult
    func end(at date: Date = Date()) -> WorkoutSessionDraft? {
        guard var current = draft else { return nil }
        current.endedAt = date
        current.state = .ended
        current.metrics = metrics(for: current, now: date)
        draft = nil
        return current
    }

    private func metrics(for draft: WorkoutSessionDraft, now: Date) -> WorkoutMetrics {
        let duration = max(0, now.timeIntervalSince(draft.startedAt))
        let distance = distanceCalculator.totalDistanceMeters(for: draft.locations)
        let speed = duration > 0 ? distance / duration : 0
        return WorkoutMetrics(duration: duration, distanceMeters: distance, averageSpeedMetersPerSecond: speed)
    }
}
