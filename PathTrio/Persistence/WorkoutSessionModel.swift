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
    var userCorrectedCalories: Double?
    var smartAssistEnabledAtStart: Bool
    var healthSyncResultRawValue: String?
    var recordingModeRawValue: String?
    var isManualEntry: Bool = false
    var notes: String?
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
        userCorrectedCalories: Double? = nil,
        smartAssistEnabledAtStart: Bool,
        healthSyncResult: WorkoutHealthSyncResult? = nil,
        recordingMode: WorkoutRecordingMode? = nil,
        isManualEntry: Bool = false,
        notes: String? = nil,
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
        self.userCorrectedCalories = userCorrectedCalories
        self.smartAssistEnabledAtStart = smartAssistEnabledAtStart
        self.healthSyncResultRawValue = healthSyncResult?.rawValue
        self.recordingModeRawValue = recordingMode?.rawValue
        self.isManualEntry = isManualEntry
        self.notes = notes
        self.locations = locations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var type: WorkoutType {
        WorkoutType(rawValue: typeRawValue) ?? .walk
    }

    var recordingMode: WorkoutRecordingMode {
        get {
            guard let recordingModeRawValue,
                  let recordingMode = WorkoutRecordingMode(rawValue: recordingModeRawValue) else {
                return isManualEntry ? .manualEntry : type.recordingMode
            }
            return recordingMode
        }
        set {
            recordingModeRawValue = newValue.rawValue
            isManualEntry = newValue == .manualEntry
        }
    }

    var effectiveEstimatedCalories: Double? {
        userCorrectedCalories ?? estimatedCalories
    }

    var healthSyncResult: WorkoutHealthSyncResult? {
        get {
            guard let healthSyncResultRawValue else { return nil }
            return WorkoutHealthSyncResult(rawValue: healthSyncResultRawValue)
        }
        set {
            healthSyncResultRawValue = newValue?.rawValue
        }
    }
}
