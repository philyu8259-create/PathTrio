import Foundation
import SwiftData

@Model
final class WorkoutSessionModel {
    @Attribute(.unique) var id: UUID
    var typeRawValue: String
    var startedAt: Date
    var endedAt: Date
    var duration: TimeInterval
    var distanceMeters: Double
    var averageSpeedMetersPerSecond: Double
    var estimatedCalories: Double?
    var smartAssistEnabledAtStart: Bool
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \LocationPointModel.workout) var locations: [LocationPointModel]

    init(
        id: UUID = UUID(),
        type: WorkoutType,
        startedAt: Date,
        endedAt: Date,
        duration: TimeInterval,
        distanceMeters: Double,
        averageSpeedMetersPerSecond: Double,
        estimatedCalories: Double? = nil,
        smartAssistEnabledAtStart: Bool,
        locations: [LocationPointModel] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.distanceMeters = distanceMeters
        self.averageSpeedMetersPerSecond = averageSpeedMetersPerSecond
        self.estimatedCalories = estimatedCalories
        self.smartAssistEnabledAtStart = smartAssistEnabledAtStart
        self.locations = locations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var type: WorkoutType {
        WorkoutType(rawValue: typeRawValue) ?? .walk
    }
}
