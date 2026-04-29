import CoreLocation
import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutSessionModel

    private var locations: [CLLocation] {
        workout.locations
            .sorted { $0.timestamp < $1.timestamp }
            .map {
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude),
                    altitude: $0.altitude,
                    horizontalAccuracy: $0.horizontalAccuracy,
                    verticalAccuracy: -1,
                    course: $0.course,
                    speed: $0.speedMetersPerSecond,
                    timestamp: $0.timestamp
                )
            }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                RouteMapView(locations: locations)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    MetricTile(title: L10n.string("metric.distance"), value: WorkoutMetricsFormatter.distance(workout.distanceMeters), systemImage: "map")
                    MetricTile(title: L10n.string("metric.duration"), value: WorkoutMetricsFormatter.duration(workout.duration), systemImage: "timer")
                }

                MetricTile(
                    title: workout.type.emphasizesPace ? L10n.string("metric.pace") : L10n.string("metric.speed"),
                    value: workout.type.emphasizesPace ? WorkoutMetricsFormatter.pace(workout.distanceMeters > 0 ? workout.duration / (workout.distanceMeters / 1_000) : nil) : WorkoutMetricsFormatter.speed(workout.averageSpeedMetersPerSecond),
                    systemImage: "speedometer"
                )
            }
            .padding()
        }
        .navigationTitle(workout.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
