import Foundation
import HealthKit

enum WorkoutType: String, CaseIterable, Codable, Identifiable {
    case walk
    case run
    case ride
    case hike
    case trailRun
    case treadmillRun
    case roadRide
    case mountainRide
    case indoorRide
    case eBikeRide
    case swim
    case openWaterSwim
    case row
    case paddle
    case kayak
    case canoe
    case standUpPaddleboard
    case rowingMachine
    case elliptical
    case stairClimb
    case skiing
    case snowshoe
    case yoga
    case strengthTraining
    case coreTraining
    case hiit
    case dance

    var id: String { rawValue }

    var category: WorkoutCategory {
        switch self {
        case .walk, .hike:
            .walking
        case .run, .trailRun, .treadmillRun:
            .running
        case .ride, .roadRide, .mountainRide, .indoorRide, .eBikeRide:
            .cycling
        case .swim, .openWaterSwim:
            .swimming
        case .row, .rowingMachine, .paddle, .kayak, .canoe, .standUpPaddleboard:
            .water
        case .elliptical, .skiing, .snowshoe, .stairClimb:
            .outdoorAdventure
        case .yoga, .strengthTraining, .coreTraining, .hiit, .dance:
            .studio
        }
    }

    var displayName: String {
        let key = "workout.\(rawValue)"
        let value = L10n.string(key)
        if value == key {
            return rawValue
                .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
                .replacingOccurrences(of: "_", with: " ")
                .split(separator: " ")
                .map { $0.prefix(1).capitalized + $0.dropFirst() }
                .joined(separator: " ")
        }
        return value
    }

    var recordingMode: WorkoutRecordingMode {
        supportsGPS ? .routeTracking : .durationOnly
    }

    var supportsGPS: Bool {
        switch self {
        case .walk, .run, .hike, .trailRun, .roadRide, .mountainRide, .ride, .eBikeRide, .swim, .openWaterSwim, .skiing, .snowshoe, .stairClimb:
            true
        case .treadmillRun, .indoorRide, .row, .paddle, .kayak, .canoe, .standUpPaddleboard, .rowingMachine, .elliptical, .yoga, .strengthTraining, .coreTraining, .hiit, .dance:
            false
        }
    }

    var systemImage: String {
        switch self {
        case .walk, .hike, .trailRun:
            "figure.walk"
        case .run, .treadmillRun:
            "figure.run"
        case .ride, .roadRide, .mountainRide, .indoorRide, .eBikeRide, .stairClimb:
            "bicycle"
        case .swim, .openWaterSwim:
            "figure.pool.swim"
        case .row, .rowingMachine, .paddle, .kayak, .canoe, .standUpPaddleboard:
            "figure.open.water.sports"
        case .elliptical:
            "figure.archery"
        case .skiing, .snowshoe:
            "snowflake"
        case .yoga, .strengthTraining, .coreTraining, .hiit, .dance:
            "figure.flexibility"
        }
    }

    var tintToken: WorkoutTintToken {
        switch category {
        case .walking:
            .teal
        case .running:
            .warm
        case .cycling:
            .action
        case .swimming:
            .blue
        case .water:
            .teal
        case .outdoorAdventure:
            .green
        case .studio:
            .orange
        }
    }

    var emphasizesPace: Bool {
        switch category {
        case .walking, .running, .outdoorAdventure, .swimming:
            true
        case .cycling, .water, .studio:
            false
        }
    }

    var movementProfile: WorkoutMovementProfile {
        switch category {
        case .walking:
            .walking
        case .running:
            .running
        case .cycling:
            .cycling
        case .swimming:
            .swimming
        case .water, .outdoorAdventure, .studio:
            supportsGPS ? .adventure : .indoor
        }
    }

    var minimumMovingSpeed: Double {
        movementProfile.minimumMovingSpeed
    }

    var stationarySpeedThreshold: Double {
        movementProfile.stationarySpeedThreshold
    }

    var metabolicEquivalent: Double {
        switch self {
        case .walk, .hike:
            3.5
        case .run, .trailRun, .treadmillRun:
            9.8
        case .ride, .roadRide, .mountainRide, .indoorRide, .eBikeRide:
            7.5
        case .swim, .openWaterSwim:
            8.0
        case .row, .rowingMachine, .paddle, .kayak, .canoe, .standUpPaddleboard:
            5.8
        case .elliptical:
            4.8
        case .stairClimb:
            6.0
        case .skiing, .snowshoe:
            6.5
        case .yoga:
            2.6
        case .strengthTraining:
            5.0
        case .coreTraining:
            5.5
        case .hiit:
            8.5
        case .dance:
            4.2
        }
    }

    var healthKitActivityType: HKWorkoutActivityType {
        switch self {
        case .walk, .hike, .trailRun:
            .walking
        case .run, .treadmillRun:
            .running
        case .ride, .roadRide, .mountainRide, .indoorRide, .eBikeRide:
            .cycling
        case .swim, .openWaterSwim:
            .swimming
        case .row, .rowingMachine, .paddle, .kayak, .canoe, .standUpPaddleboard:
            .other
        case .elliptical, .stairClimb, .skiing, .snowshoe:
            .other
        case .yoga, .strengthTraining, .coreTraining, .hiit, .dance:
            .other
        }
    }

    var distanceQuantityKind: HKQuantityTypeIdentifier? {
        switch self {
        case .walk, .hike, .run, .trailRun, .treadmillRun:
            .distanceWalkingRunning
        case .ride, .roadRide, .mountainRide, .eBikeRide:
            .distanceCycling
        case .swim, .openWaterSwim:
            .distanceSwimming
        case .indoorRide:
            nil
        case .yoga, .strengthTraining, .coreTraining, .hiit, .dance:
            nil
        case .row, .rowingMachine, .paddle, .kayak, .canoe, .standUpPaddleboard, .elliptical, .stairClimb, .skiing, .snowshoe:
            nil
        }
    }

    var speedAnomalyThreshold: Double {
        movementProfile.speedAnomalyThreshold
    }
}

enum WorkoutCategory: String, Codable {
    case walking
    case running
    case cycling
    case swimming
    case water
    case outdoorAdventure
    case studio
}

enum WorkoutRecordingMode {
    case routeTracking
    case durationOnly
}

enum WorkoutTintToken: String {
    case teal
    case warm
    case action
    case blue
    case green
    case orange
}

struct WorkoutMovementProfile {
    let minimumMovementDistance: Double
    let movementAccuracyMultiplier: Double
    let maximumSegmentSpeed: Double
    let minimumReliableSpeed: Double
    let minimumMovingSpeed: Double
    let stationarySpeedThreshold: Double
    let speedAnomalyThreshold: Double

    static let walking = WorkoutMovementProfile(
        minimumMovementDistance: 6,
        movementAccuracyMultiplier: 0.85,
        maximumSegmentSpeed: 4.5,
        minimumReliableSpeed: 0.35,
        minimumMovingSpeed: 0.35,
        stationarySpeedThreshold: 0.35,
        speedAnomalyThreshold: 4.5
    )

    static let running = WorkoutMovementProfile(
        minimumMovementDistance: 8,
        movementAccuracyMultiplier: 0.85,
        maximumSegmentSpeed: 8.5,
        minimumReliableSpeed: 0.7,
        minimumMovingSpeed: 0.9,
        stationarySpeedThreshold: 0.6,
        speedAnomalyThreshold: 8.5
    )

    static let cycling = WorkoutMovementProfile(
        minimumMovementDistance: 10,
        movementAccuracyMultiplier: 0.7,
        maximumSegmentSpeed: 22,
        minimumReliableSpeed: 1.2,
        minimumMovingSpeed: 2.0,
        stationarySpeedThreshold: 1.0,
        speedAnomalyThreshold: 22
    )

    static let swimming = WorkoutMovementProfile(
        minimumMovementDistance: 4,
        movementAccuracyMultiplier: 0.9,
        maximumSegmentSpeed: 4,
        minimumReliableSpeed: 0.4,
        minimumMovingSpeed: 0.25,
        stationarySpeedThreshold: 0.45,
        speedAnomalyThreshold: 4.5
    )

    static let adventure = WorkoutMovementProfile(
        minimumMovementDistance: 5,
        movementAccuracyMultiplier: 1.0,
        maximumSegmentSpeed: 12,
        minimumReliableSpeed: 0.5,
        minimumMovingSpeed: 0.8,
        stationarySpeedThreshold: 0.45,
        speedAnomalyThreshold: 12
    )

    static let indoor = WorkoutMovementProfile(
        minimumMovementDistance: 9999,
        movementAccuracyMultiplier: 0.0,
        maximumSegmentSpeed: 0,
        minimumReliableSpeed: 0.35,
        minimumMovingSpeed: 0.35,
        stationarySpeedThreshold: 0.35,
        speedAnomalyThreshold: 6
    )
}
