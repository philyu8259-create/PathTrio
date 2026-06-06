import HealthKit

enum HealthKitWorkoutBuilder {
    static var shareTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKWorkoutType.workoutType()]

        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }

        let distanceKinds = Set(WorkoutType.allCases.compactMap(\.distanceQuantityKind))
        for kind in distanceKinds {
            if let quantityType = HKQuantityType.quantityType(forIdentifier: kind) {
                types.insert(quantityType)
            }
        }

        return types
    }

    static func activityType(for type: WorkoutType) -> HKWorkoutActivityType {
        type.healthKitActivityType
    }

    static func configuration(for session: WorkoutSessionModel) -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType(for: session.type)
        return configuration
    }

    static func metadata(for session: WorkoutSessionModel) -> [String: Any] {
        [
            HKMetadataKeyExternalUUID: session.id.uuidString,
            HKMetadataKeyWasUserEntered: session.isManualEntry
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
           let estimatedCalories = session.effectiveEstimatedCalories,
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
        guard let distanceQuantityKind = type.distanceQuantityKind else { return nil }
        return HKQuantityType.quantityType(forIdentifier: distanceQuantityKind)
    }
}
