import HealthKit

final class HealthKitWorkoutSyncer: HealthSyncing {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw HealthSyncError.healthDataUnavailable
        }

        try await healthStore.requestAuthorization(
            toShare: HealthKitWorkoutBuilder.shareTypes,
            read: []
        )
    }

    func save(workout session: WorkoutSessionModel) async throws {
        guard isHealthDataAvailable else {
            throw HealthSyncError.healthDataUnavailable
        }

        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: HealthKitWorkoutBuilder.configuration(for: session),
            device: .local()
        )

        try await builder.beginCollection(at: session.startedAt)
        try await builder.addMetadata(HealthKitWorkoutBuilder.metadata(for: session))

        let samples = HealthKitWorkoutBuilder.samples(for: session)
        if !samples.isEmpty {
            try await builder.addSamples(samples)
        }

        try await builder.endCollection(at: session.endedAt)
        try await finishWorkout(using: builder)
    }

    private func finishWorkout(using builder: HKWorkoutBuilder) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.finishWorkout { workout, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if workout == nil {
                    continuation.resume(throwing: HealthSyncError.workoutUnavailable)
                    return
                }

                continuation.resume()
            }
        }
    }
}

enum HealthSyncError: Error {
    case healthDataUnavailable
    case workoutUnavailable
}
