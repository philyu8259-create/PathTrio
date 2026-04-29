import HealthKit

enum HealthKitWorkoutBuilder {
    static var shareTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKWorkoutType.workoutType()]

        if let walkingRunningDistance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(walkingRunningDistance)
        }

        if let cyclingDistance = HKQuantityType.quantityType(forIdentifier: .distanceCycling) {
            types.insert(cyclingDistance)
        }

        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }

        return types
    }

    static func activityType(for type: WorkoutType) -> HKWorkoutActivityType {
        switch type {
        case .walk:
            return .walking
        case .run:
            return .running
        case .ride:
            return .cycling
        }
    }

    static func configuration(for session: WorkoutSessionModel) -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType(for: session.type)
        return configuration
    }

    static func metadata(for session: WorkoutSessionModel) -> [String: Any] {
        [
            HKMetadataKeyExternalUUID: session.id.uuidString,
            HKMetadataKeyWasUserEntered: true
        ]
    }

    static func samples(for session: WorkoutSessionModel) -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = []

        if let distanceType = distanceQuantityType(for: session.type), session.distanceMeters > 0 {
            samples.append(HKQuantitySample(
                type: distanceType,
                quantity: HKQuantity(unit: .meter(), doubleValue: session.distanceMeters),
                start: session.startedAt,
                end: session.endedAt
            ))
        }

        if let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           let estimatedCalories = session.estimatedCalories,
           estimatedCalories > 0 {
            samples.append(HKQuantitySample(
                type: activeEnergyType,
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: estimatedCalories),
                start: session.startedAt,
                end: session.endedAt
            ))
        }

        return samples
    }

    private static func distanceQuantityType(for type: WorkoutType) -> HKQuantityType? {
        switch type {
        case .walk, .run:
            return HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        case .ride:
            return HKQuantityType.quantityType(forIdentifier: .distanceCycling)
        }
    }
}
