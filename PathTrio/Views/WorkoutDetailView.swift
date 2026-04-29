import CoreLocation
import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutSessionModel
    private let metricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

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

    private var paceSecondsPerKilometer: Double? {
        guard workout.distanceMeters > 0 else { return nil }
        return workout.duration / (workout.distanceMeters / 1_000)
    }

    private var estimatedCalories: Double? {
        workout.estimatedCalories ?? WorkoutCaloriesEstimator.estimate(
            type: workout.type,
            duration: workout.duration,
            bodyWeightKilograms: nil
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RouteMapView(locations: locations)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                LazyVGrid(columns: metricColumns, spacing: 12) {
                    MetricTile(title: L10n.string("metric.distance"), value: WorkoutMetricsFormatter.distance(workout.distanceMeters), systemImage: "map")
                    MetricTile(title: L10n.string("metric.duration"), value: WorkoutMetricsFormatter.duration(workout.duration), systemImage: "timer")
                    MetricTile(title: L10n.string("metric.averagePace"), value: WorkoutMetricsFormatter.pace(paceSecondsPerKilometer), systemImage: "gauge.with.dots.needle.50percent")
                    MetricTile(title: L10n.string("metric.averageSpeed"), value: WorkoutMetricsFormatter.speed(workout.averageSpeedMetersPerSecond), systemImage: "speedometer")
                    MetricTile(title: L10n.string("metric.calories"), value: WorkoutMetricsFormatter.calories(estimatedCalories), systemImage: "flame")
                }

                VStack(alignment: .leading, spacing: 10) {
                    DetailDateRow(title: L10n.string("detail.started"), date: workout.startedAt)
                    DetailDateRow(title: L10n.string("detail.ended"), date: workout.endedAt)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(workout.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DetailDateRow: View {
    let title: String
    let date: Date

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .foregroundStyle(.primary)
        }
    }
}
