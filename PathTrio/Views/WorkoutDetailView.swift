import CoreLocation
import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppModel.self) private var appModel
    let workout: WorkoutSessionModel
    @State private var isRetryingHealthSync = false
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

                if let healthSyncResult = workout.healthSyncResult {
                    Label(L10n.string(healthSyncResult.detailMessageKey), systemImage: healthSyncResult.isError ? "exclamationmark.triangle" : "heart.text.square")
                        .font(.subheadline)
                        .foregroundStyle(healthSyncResult.isError ? .orange : .secondary)
                }

                if workout.healthSyncResult?.canRetry ?? true {
                    Button {
                        Task {
                            await retryHealthSync()
                        }
                    } label: {
                        Label(
                            L10n.string(isRetryingHealthSync ? "detail.healthSync.retrying" : "detail.healthSync.retry"),
                            systemImage: "arrow.clockwise"
                        )
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRetryingHealthSync)
                }
            }
            .padding()
        }
        .navigationTitle(workout.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func retryHealthSync() async {
        guard !isRetryingHealthSync else { return }
        isRetryingHealthSync = true
        defer { isRetryingHealthSync = false }

        let result = await WorkoutHealthSyncCoordinator.retry(workout, syncer: appModel.healthSyncer)
        do {
            try WorkoutStore(context: modelContext).updateHealthSyncResult(result, for: workout)
        } catch {
            workout.healthSyncResult = .failed
        }
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
