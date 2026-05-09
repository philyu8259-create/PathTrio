import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSessionModel.startedAt, order: .reverse) private var workouts: [WorkoutSessionModel]
    @State private var grouping: WorkoutHistoryGrouping = .day
    @State private var typeFilter: WorkoutTypeFilter = .all

    private let organizer = WorkoutHistoryOrganizer()
    private let insightEngine = WorkoutInsightEngine()

    private var sections: [WorkoutHistorySection] {
        organizer.sections(for: workouts, grouping: grouping, filter: typeFilter)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                if workouts.isEmpty {
                    HistoryEmptyState()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            HistoryControls(grouping: $grouping, typeFilter: $typeFilter)

                            HistoryInsightsPanel(insights: insightEngine.insights(for: workouts))

                            if sections.isEmpty {
                                HistoryFilteredEmptyState()
                            } else {
                                ForEach(sections) { section in
                                    HistorySectionView(section: section, grouping: grouping)
                                }
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

private struct HistoryControls: View {
    @Binding var grouping: WorkoutHistoryGrouping
    @Binding var typeFilter: WorkoutTypeFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("history.group.title", selection: $grouping) {
                ForEach(WorkoutHistoryGrouping.allCases) { option in
                    Text(L10n.string(option.titleKey)).tag(option)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WorkoutTypeFilter.allCases) { filter in
                        Button {
                            typeFilter = filter
                        } label: {
                            Text(L10n.string(filter.titleKey))
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(typeFilter == filter ? .white : PathTrioTheme.ink)
                                .padding(.horizontal, 12)
                                .frame(height: 34)
                                .background(typeFilter == filter ? PathTrioTheme.action : .white, in: Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(typeFilter == filter ? PathTrioTheme.action : PathTrioTheme.line, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct HistoryInsightsPanel: View {
    let insights: [WorkoutInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("insights.title", systemImage: "sparkles")
                .font(.headline.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)

            ForEach(insights) { insight in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: insight.systemImage)
                        .font(.body.weight(.bold))
                        .foregroundStyle(PathTrioTheme.action)
                        .frame(width: 26, height: 26)
                        .background(PathTrioTheme.action.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(L10n.string(insight.titleKey))
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(PathTrioTheme.ink)
                            if let value = insight.value {
                                Text(value)
                                    .font(.footnote.weight(.black))
                                    .foregroundStyle(PathTrioTheme.action)
                            }
                        }

                        Text(L10n.string(insight.messageKey))
                            .font(.footnote)
                            .foregroundStyle(PathTrioTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .pathTrioCard()
    }
}

private struct HistorySectionView: View {
    let section: WorkoutHistorySection
    let grouping: WorkoutHistoryGrouping

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)

                Spacer()

                Text("\(WorkoutMetricsFormatter.distance(section.totalDistanceMeters)) · \(WorkoutMetricsFormatter.duration(section.totalDuration))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PathTrioTheme.muted)
            }

            ForEach(section.workouts) { workout in
                NavigationLink {
                    WorkoutDetailView(workout: workout)
                } label: {
                    HistoryWorkoutRow(workout: workout)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var title: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        if grouping == .month {
            formatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        }
        return formatter.string(from: section.startDate)
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
                Text(timeText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted.opacity(0.82))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)
        }
        .padding(14)
        .pathTrioCard()
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: workout.startedAt)
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

private struct HistoryFilteredEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)
            Text("history.empty.filtered")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PathTrioTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}
