import CoreLocation
import Foundation

struct WorkoutSessionDraft: Identifiable {
    let id: UUID
    let type: WorkoutType
    let startedAt: Date
    var endedAt: Date?
    var state: WorkoutState
    var locations: [CLLocation]
    var metrics: WorkoutMetrics

    init(
        id: UUID = UUID(),
        type: WorkoutType,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        state: WorkoutState = .recording,
        locations: [CLLocation] = [],
        metrics: WorkoutMetrics = WorkoutMetrics(duration: 0, distanceMeters: 0, averageSpeedMetersPerSecond: 0)
    ) {
        self.id = id
        self.type = type
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.state = state
        self.locations = locations
        self.metrics = metrics
    }
}
