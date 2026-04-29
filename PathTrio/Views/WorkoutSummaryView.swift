import SwiftUI

struct WorkoutSummaryView: View {
    let draft: WorkoutSessionDraft
    let done: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                RouteMapView(locations: draft.locations)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    MetricTile(title: "Distance", value: WorkoutMetricsFormatter.distance(draft.metrics.distanceMeters), systemImage: "map")
                    MetricTile(title: "Duration", value: WorkoutMetricsFormatter.duration(draft.metrics.duration), systemImage: "timer")
                }

                MetricTile(
                    title: draft.type.emphasizesPace ? "Average Pace" : "Average Speed",
                    value: draft.type.emphasizesPace ? WorkoutMetricsFormatter.pace(draft.metrics.paceSecondsPerKilometer) : WorkoutMetricsFormatter.speed(draft.metrics.averageSpeedMetersPerSecond),
                    systemImage: "speedometer"
                )

                Spacer()
            }
            .padding()
            .navigationTitle("Workout Saved")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: done)
                }
            }
        }
    }
}
