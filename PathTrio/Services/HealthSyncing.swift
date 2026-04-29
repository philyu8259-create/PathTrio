import Foundation

protocol HealthSyncing: AnyObject {
    var isHealthDataAvailable: Bool { get }

    func requestAuthorization() async throws
    func save(workout: WorkoutSessionModel) async throws
}

enum WorkoutHealthSyncResult: Equatable {
    case skipped
    case synced
    case unavailable
    case failed

    var messageKey: String? {
        switch self {
        case .skipped:
            return nil
        case .synced:
            return "summary.health.synced"
        case .unavailable:
            return "summary.health.unavailable"
        case .failed:
            return "summary.health.failed"
        }
    }

    var isError: Bool {
        self == .unavailable || self == .failed
    }
}

enum WorkoutHealthSyncCoordinator {
    static func syncIfNeeded(
        _ session: WorkoutSessionModel,
        syncEnabled: Bool,
        syncer: any HealthSyncing
    ) async -> WorkoutHealthSyncResult {
        guard syncEnabled else {
            return .skipped
        }

        guard syncer.isHealthDataAvailable else {
            return .unavailable
        }

        do {
            try await syncer.requestAuthorization()
            try await syncer.save(workout: session)
            return .synced
        } catch {
            return .failed
        }
    }
}
