import Foundation
import SwiftData

@Model
final class LocationPointModel {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var horizontalAccuracy: Double
    var altitude: Double
    var speedMetersPerSecond: Double
    var course: Double
    var workout: WorkoutSessionModel?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double,
        altitude: Double,
        speedMetersPerSecond: Double,
        course: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.altitude = altitude
        self.speedMetersPerSecond = speedMetersPerSecond
        self.course = course
    }
}
