import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSessionModel.startedAt, order: .reverse) private var workouts: [WorkoutSessionModel]

    var body: some View {
        NavigationStack {
            List(workouts) { workout in
                NavigationLink {
                    WorkoutDetailView(workout: workout)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.type.displayName)
                            .font(.headline)
                        Text("\(WorkoutMetricsFormatter.distance(workout.distanceMeters)) · \(WorkoutMetricsFormatter.duration(workout.duration))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if workouts.isEmpty {
                    ContentUnavailableView("history.empty.title", systemImage: "figure.walk", description: Text("history.empty.description"))
                }
            }
            .navigationTitle("history.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("action.done") { dismiss() }
                }
            }
        }
    }
}
