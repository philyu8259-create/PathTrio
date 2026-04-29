import CoreLocation
import Foundation
import SwiftData

@MainActor
struct WorkoutStore {
    let context: ModelContext

    func saveCompletedWorkout(_ draft: WorkoutSessionDraft, smartAssistEnabledAtStart: Bool) throws -> WorkoutSessionModel {
        guard let endedAt = draft.endedAt else {
            throw WorkoutStoreError.missingEndDate
        }

        let points = draft.locations.map {
            LocationPointModel(
                timestamp: $0.timestamp,
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                horizontalAccuracy: $0.horizontalAccuracy,
                altitude: $0.altitude,
                speedMetersPerSecond: max(0, $0.speed),
                course: $0.course
            )
        }

        let session = WorkoutSessionModel(
            id: draft.id,
            type: draft.type,
            startedAt: draft.startedAt,
            endedAt: endedAt,
            duration: draft.metrics.duration,
            distanceMeters: draft.metrics.distanceMeters,
            averageSpeedMetersPerSecond: draft.metrics.averageSpeedMetersPerSecond,
            estimatedCalories: nil,
            smartAssistEnabledAtStart: smartAssistEnabledAtStart,
            locations: points
        )

        context.insert(session)
        try context.save()
        return session
    }
}

enum WorkoutStoreError: Error {
    case missingEndDate
}
