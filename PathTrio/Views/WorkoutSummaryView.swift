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
                    MetricTile(title: L10n.string("metric.distance"), value: WorkoutMetricsFormatter.distance(draft.metrics.distanceMeters), systemImage: "map")
                    MetricTile(title: L10n.string("metric.duration"), value: WorkoutMetricsFormatter.duration(draft.metrics.duration), systemImage: "timer")
                }

                MetricTile(
                    title: draft.type.emphasizesPace ? L10n.string("metric.averagePace") : L10n.string("metric.averageSpeed"),
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
            .navigationTitle("summary.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("action.done", action: done)
                }
            }
            .task {
                guard !hasSaved else { return }
                hasSaved = true
                do {
                    let store = WorkoutStore(context: modelContext)
                    let saved = try store.saveCompletedWorkout(
                        draft,
                        smartAssistEnabledAtStart: appModel.settingsStore.isAnySmartAssistEnabled,
                        bodyWeightKilograms: appModel.settingsStore.bodyWeightKilograms
                    )
                    appModel.latestCompletedWorkoutID = saved.id
                } catch {
                    saveErrorMessage = L10n.string("summary.saveError")
                }
            }
        }
    }
}
