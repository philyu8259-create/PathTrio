import Foundation
import WatchConnectivity

final class AppleWatchSupportService: NSObject, WCSessionDelegate {
    private var envelope = AppleWatchSyncEnvelope(isProUnlocked: false)

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    var status: AppleWatchSupportStatus {
        guard let session else { return .unsupported }
        if !session.isPaired { return .notPaired }
        if !session.isWatchAppInstalled { return .watchAppMissing }
        return .ready
    }

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    func publishProStatus(isUnlocked: Bool) {
        envelope.isProUnlocked = isUnlocked
        envelope.updatedAt = Date().timeIntervalSince1970
        publishEnvelopeIfPossible()
    }

    func publishLatestWorkout(_ workout: WorkoutSessionModel) {
        envelope.isProUnlocked = true
        envelope.activeWorkout = nil
        envelope.latestWorkout = AppleWatchWorkoutSnapshot(
            id: workout.id.uuidString,
            typeRawValue: workout.type.rawValue,
            startedAt: workout.startedAt.timeIntervalSince1970,
            duration: workout.duration,
            distanceMeters: workout.distanceMeters,
            averageSpeedMetersPerSecond: workout.averageSpeedMetersPerSecond,
            estimatedCalories: workout.effectiveEstimatedCalories
        )
        envelope.updatedAt = Date().timeIntervalSince1970
        publishEnvelopeIfPossible()
    }

    func publishActiveWorkout(_ draft: WorkoutSessionDraft?, isProUnlocked: Bool) {
        envelope.isProUnlocked = isProUnlocked
        guard isProUnlocked, let draft else {
            envelope.activeWorkout = nil
            envelope.updatedAt = Date().timeIntervalSince1970
            publishEnvelopeIfPossible()
            return
        }

        envelope.activeWorkout = AppleWatchWorkoutSnapshot(
            id: draft.id.uuidString,
            typeRawValue: draft.type.rawValue,
            startedAt: draft.startedAt.timeIntervalSince1970,
            duration: draft.metrics.duration,
            distanceMeters: draft.metrics.distanceMeters,
            averageSpeedMetersPerSecond: draft.metrics.averageSpeedMetersPerSecond,
            estimatedCalories: WorkoutCaloriesEstimator.estimate(
                type: draft.type,
                duration: draft.metrics.duration,
                bodyWeightKilograms: nil
            ),
            stateRawValue: watchStateRawValue(for: draft.state),
            isActive: draft.state == .recording || draft.state == .paused || draft.state == .autoPaused
        )
        envelope.updatedAt = Date().timeIntervalSince1970
        publishEnvelopeIfPossible()
    }

    private func publishEnvelopeIfPossible() {
        guard status == .ready, let session else { return }

        do {
            try session.updateApplicationContext([AppleWatchSyncEnvelope.applicationContextKey: envelope.dictionary])
        } catch {
            // Watch delivery is opportunistic; the workout remains saved locally.
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        publishEnvelopeIfPossible()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        if message[AppleWatchSyncEnvelope.requestSnapshotKey] as? Bool == true {
            replyHandler([AppleWatchSyncEnvelope.applicationContextKey: envelope.dictionary])
        } else {
            replyHandler([:])
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    private func watchStateRawValue(for state: WorkoutState) -> String {
        switch state {
        case .idle: "idle"
        case .recording: "recording"
        case .paused: "paused"
        case .autoPaused: "autoPaused"
        case .ended: "ended"
        }
    }
}

enum AppleWatchSupportStatus {
    case unsupported
    case notPaired
    case watchAppMissing
    case ready

    var titleKey: String {
        switch self {
        case .unsupported: "watch.status.unsupported.title"
        case .notPaired: "watch.status.notPaired.title"
        case .watchAppMissing: "watch.status.missing.title"
        case .ready: "watch.status.ready.title"
        }
    }

    var messageKey: String {
        switch self {
        case .unsupported: "watch.status.unsupported.message"
        case .notPaired: "watch.status.notPaired.message"
        case .watchAppMissing: "watch.status.missing.message"
        case .ready: "watch.status.ready.message"
        }
    }

    var systemImage: String {
        switch self {
        case .unsupported: "applewatch.slash"
        case .notPaired: "applewatch.slash"
        case .watchAppMissing: "square.and.arrow.down"
        case .ready: "applewatch"
        }
    }
}
