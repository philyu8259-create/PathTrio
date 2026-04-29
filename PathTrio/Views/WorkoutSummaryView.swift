import SwiftData
import SwiftUI

struct WorkoutSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppModel.self) private var appModel
    let draft: WorkoutSessionDraft
    let done: () -> Void
    @State private var saveErrorMessage: String?
    @State private var hasSaved = false

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

                if let saveErrorMessage {
                    Text(saveErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Workout Saved")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: done)
                }
            }
            .task {
                guard !hasSaved else { return }
                hasSaved = true
                do {
                    let store = WorkoutStore(context: modelContext)
                    let saved = try store.saveCompletedWorkout(
                        draft,
                        smartAssistEnabledAtStart: appModel.settingsStore.isAnySmartAssistEnabled
                    )
                    appModel.latestCompletedWorkoutID = saved.id
                } catch {
                    saveErrorMessage = "This workout could not be saved. Please try again."
                }
            }
        }
    }
}
