import Foundation

struct AppleWatchWorkoutSnapshot: Codable, Equatable {
    var id: String
    var typeRawValue: String
    var startedAt: TimeInterval
    var duration: TimeInterval
    var distanceMeters: Double
    var averageSpeedMetersPerSecond: Double
    var estimatedCalories: Double?
    var stateRawValue: String?
    var isActive: Bool

    var dictionary: [String: Any] {
        var payload: [String: Any] = [
            "id": id,
            "type": typeRawValue,
            "startedAt": startedAt,
            "duration": duration,
            "distanceMeters": distanceMeters,
            "averageSpeedMetersPerSecond": averageSpeedMetersPerSecond,
            "isActive": isActive
        ]
        if let estimatedCalories {
            payload["estimatedCalories"] = estimatedCalories
        }
        if let stateRawValue {
            payload["state"] = stateRawValue
        }
        return payload
    }

    init(
        id: String,
        typeRawValue: String,
        startedAt: TimeInterval,
        duration: TimeInterval,
        distanceMeters: Double,
        averageSpeedMetersPerSecond: Double,
        estimatedCalories: Double?,
        stateRawValue: String? = nil,
        isActive: Bool = false
    ) {
        self.id = id
        self.typeRawValue = typeRawValue
        self.startedAt = startedAt
        self.duration = duration
        self.distanceMeters = distanceMeters
        self.averageSpeedMetersPerSecond = averageSpeedMetersPerSecond
        self.estimatedCalories = estimatedCalories
        self.stateRawValue = stateRawValue
        self.isActive = isActive
    }

    init?(dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let typeRawValue = dictionary["type"] as? String,
            let startedAt = dictionary["startedAt"] as? TimeInterval,
            let duration = dictionary["duration"] as? TimeInterval,
            let distanceMeters = dictionary["distanceMeters"] as? Double,
            let averageSpeedMetersPerSecond = dictionary["averageSpeedMetersPerSecond"] as? Double
        else {
            return nil
        }

        self.id = id
        self.typeRawValue = typeRawValue
        self.startedAt = startedAt
        self.duration = duration
        self.distanceMeters = distanceMeters
        self.averageSpeedMetersPerSecond = averageSpeedMetersPerSecond
        self.estimatedCalories = dictionary["estimatedCalories"] as? Double
        self.stateRawValue = dictionary["state"] as? String
        self.isActive = dictionary["isActive"] as? Bool ?? false
    }
}

struct AppleWatchSyncEnvelope: Codable, Equatable {
    static let applicationContextKey = "pathTrioWatch"
    static let requestSnapshotKey = "requestPathTrioSnapshot"

    var isProUnlocked: Bool
    var activeWorkout: AppleWatchWorkoutSnapshot?
    var latestWorkout: AppleWatchWorkoutSnapshot?
    var updatedAt: TimeInterval

    var dictionary: [String: Any] {
        var payload: [String: Any] = [
            "isProUnlocked": isProUnlocked,
            "updatedAt": updatedAt
        ]
        if let activeWorkout {
            payload["activeWorkout"] = activeWorkout.dictionary
        }
        if let latestWorkout {
            payload["latestWorkout"] = latestWorkout.dictionary
        }
        return payload
    }

    init(
        isProUnlocked: Bool,
        activeWorkout: AppleWatchWorkoutSnapshot? = nil,
        latestWorkout: AppleWatchWorkoutSnapshot? = nil,
        updatedAt: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.isProUnlocked = isProUnlocked
        self.activeWorkout = activeWorkout
        self.latestWorkout = latestWorkout
        self.updatedAt = updatedAt
    }

    init?(dictionary: [String: Any]) {
        guard
            let isProUnlocked = dictionary["isProUnlocked"] as? Bool,
            let updatedAt = dictionary["updatedAt"] as? TimeInterval
        else {
            return nil
        }

        self.isProUnlocked = isProUnlocked
        if let workoutDictionary = dictionary["activeWorkout"] as? [String: Any] {
            self.activeWorkout = AppleWatchWorkoutSnapshot(dictionary: workoutDictionary)
        } else {
            self.activeWorkout = nil
        }
        if let workoutDictionary = dictionary["latestWorkout"] as? [String: Any] {
            self.latestWorkout = AppleWatchWorkoutSnapshot(dictionary: workoutDictionary)
        } else {
            self.latestWorkout = nil
        }
        self.updatedAt = updatedAt
    }
}
