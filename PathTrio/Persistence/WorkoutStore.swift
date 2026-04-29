import CoreLocation
import Foundation
import SwiftData

@MainActor
struct WorkoutStore {
    let context: ModelContext

    func totals(forDayContaining date: Date = Date(), calendar: Calendar = .current) throws -> WorkoutTotals {
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return WorkoutTotals()
        }
        return try totals(from: startOfDay, to: endOfDay)
    }

    func totals(from startDate: Date, to endDate: Date) throws -> WorkoutTotals {
        let descriptor = FetchDescriptor<WorkoutSessionModel>(
            predicate: #Predicate { workout in
                workout.startedAt >= startDate && workout.startedAt < endDate
            }
        )
        let workouts = try context.fetch(descriptor)
        return workouts.reduce(into: WorkoutTotals()) { totals, workout in
            totals.distanceMeters += workout.distanceMeters
            totals.duration += workout.duration
        }
    }

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

struct WorkoutTotals: Equatable {
    var distanceMeters: Double = 0
    var duration: TimeInterval = 0
}
