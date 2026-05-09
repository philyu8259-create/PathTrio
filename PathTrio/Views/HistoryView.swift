import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSessionModel.startedAt, order: .reverse) private var workouts: [WorkoutSessionModel]

    var body: some View {
        NavigationStack {
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                if workouts.isEmpty {
                    HistoryEmptyState()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(workouts) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workout: workout)
                                } label: {
                                    HistoryWorkoutRow(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
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

private struct HistoryWorkoutRow: View {
    let workout: WorkoutSessionModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.type.systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(PathTrioTheme.tint(for: workout.type), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(workout.type.displayName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                Text("\(WorkoutMetricsFormatter.distance(workout.distanceMeters)) · \(WorkoutMetricsFormatter.duration(workout.duration))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)
        }
        .padding(14)
        .pathTrioCard()
    }
}

private struct HistoryEmptyState: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(PathTrioTheme.teal)
                .frame(width: 88, height: 88)
                .background(PathTrioTheme.teal.opacity(0.12), in: Circle())

            VStack(spacing: 8) {
                Text("history.empty.title")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                Text("history.empty.description")
                    .font(.subheadline)
                    .foregroundStyle(PathTrioTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 280)
        }
        .padding(24)
    }
}
