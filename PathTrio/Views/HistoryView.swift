import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSessionModel.startedAt, order: .reverse) private var workouts: [WorkoutSessionModel]
    @State private var grouping: WorkoutHistoryGrouping = .day
    @State private var typeFilter: WorkoutTypeFilter = .all
    @State private var shareItem: ExportShareItem?
    @State private var lockedProFeature: ProFeature?
    @State private var exportErrorMessage: String?
    @State private var clearHistoryErrorMessage: String?
    @State private var isConfirmingClearHistory = false
    let showsDoneButton: Bool

    private let organizer = WorkoutHistoryOrganizer()
    private let insightEngine = WorkoutInsightEngine()
    private let statsBuilder = WorkoutStatsSummaryBuilder()

    private var sections: [WorkoutHistorySection] {
        organizer.sections(for: workouts, grouping: grouping, filter: typeFilter)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        PathTrioPageHeader(
                            titleKey: "history.title",
                            subtitleKey: "history.subtitle",
                            systemImage: "clock.arrow.circlepath",
                            tint: PathTrioTheme.action
                        )

                        if workouts.isEmpty {
                            HistoryEmptyState()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 34)
                        } else {
                            HistoryControls(grouping: $grouping, typeFilter: $typeFilter)

                            Button {
                                exportHistory()
                            } label: {
                                Label("export.history", systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(PathTrioTheme.action)
                            .pathTrioCard()

                            Button {
                                isConfirmingClearHistory = true
                            } label: {
                                Label("history.clearAll", systemImage: "trash")
                                    .font(.subheadline.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                            .pathTrioCard()

                            if appModel.entitlementStore.canUse(.advancedStats) {
                                HistoryStatsPanel(summaries: statsBuilder.summaries(for: workouts))
                            } else {
                                HistoryLockedProPanel(feature: .advancedStats)
                            }

                            if appModel.entitlementStore.canUse(.trendReview) {
                                HistoryInsightsPanel(insights: insightEngine.insights(for: workouts))
                            } else {
                                HistoryLockedProPanel(feature: .trendReview)
                            }

                            if sections.isEmpty {
                                HistoryFilteredEmptyState()
                            } else {
                                ForEach(sections) { section in
                                    HistorySectionView(section: section, grouping: grouping)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("action.done") { dismiss() }
                    }
                }
            }
            .toolbar(showsDoneButton ? .visible : .hidden, for: .navigationBar)
            .sheet(item: $shareItem) { item in
                ShareSheet(activityItems: [item.url])
            }
            .alert("pro.locked.title", isPresented: lockedProFeatureAlertBinding) {
                Button("action.ok") {
                    lockedProFeature = nil
                }
            } message: {
                if let lockedProFeature {
                    Text(L10n.string("pro.locked.message", L10n.string(lockedProFeature.titleKey)))
                }
            }
            .alert("export.error.title", isPresented: exportErrorAlertBinding) {
                Button("action.ok") {
                    exportErrorMessage = nil
                }
            } message: {
                Text(exportErrorMessage ?? "")
            }
            .confirmationDialog("history.clearAll.confirm.title", isPresented: $isConfirmingClearHistory, titleVisibility: .visible) {
                Button("action.delete", role: .destructive) {
                    clearAllHistory()
                }
                Button("action.cancel", role: .cancel) {}
            } message: {
                Text(L10n.string("history.clearAll.confirm.message"))
            }
            .alert("history.clearAll.error.title", isPresented: clearHistoryErrorAlertBinding) {
                Button("action.ok") {
                    clearHistoryErrorMessage = nil
                }
            } message: {
                Text(clearHistoryErrorMessage ?? "")
            }
        }
    }

    private var lockedProFeatureAlertBinding: Binding<Bool> {
        Binding {
            lockedProFeature != nil
        } set: { isPresented in
            if !isPresented {
                lockedProFeature = nil
            }
        }
    }

    private var exportErrorAlertBinding: Binding<Bool> {
        Binding {
            exportErrorMessage != nil
        } set: { isPresented in
            if !isPresented {
                exportErrorMessage = nil
            }
        }
    }

    private var clearHistoryErrorAlertBinding: Binding<Bool> {
        Binding {
            clearHistoryErrorMessage != nil
        } set: { isPresented in
            if !isPresented {
                clearHistoryErrorMessage = nil
            }
        }
    }

    private func exportHistory() {
        guard appModel.entitlementStore.canUse(.dataExport) else {
            lockedProFeature = .dataExport
            return
        }

        do {
            let builder = WorkoutExportBuilder()
            let url = try builder.writeTemporaryFile(
                contents: builder.csv(for: workouts),
                filename: "PeachMove-Workouts.csv"
            )
            shareItem = ExportShareItem(url: url)
        } catch {
            exportErrorMessage = L10n.string("export.error.message")
        }
    }

    private func clearAllHistory() {
        do {
            try WorkoutStore(context: modelContext).delete(Array(workouts))
        } catch {
            clearHistoryErrorMessage = L10n.string("history.clearAll.error.message")
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

private struct HistoryStatsPanel: View {
    let summaries: [WorkoutStatsSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("stats.title", systemImage: "chart.bar.xaxis")
                .font(.headline.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)

            ForEach(summaries, id: \.periodKey) { summary in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.string(summary.periodKey))
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(PathTrioTheme.ink)
                        Text(L10n.string("stats.workouts", summary.workoutCount))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PathTrioTheme.muted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(WorkoutMetricsFormatter.distance(summary.distanceMeters))
                            .font(.footnote.weight(.black))
                            .foregroundStyle(PathTrioTheme.action)
                        Text(WorkoutMetricsFormatter.calories(summary.estimatedCalories))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PathTrioTheme.muted)
                    }
                }

                if summary.periodKey != summaries.last?.periodKey {
                    Rectangle()
                        .fill(PathTrioTheme.line)
                        .frame(height: 1)
                }
            }
        }
        .padding(14)
        .pathTrioCard()
    }
}

private struct HistoryLockedProPanel: View {
    let feature: ProFeature

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.warm)
                .frame(width: 30, height: 30)
                .background(PathTrioTheme.warm.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(L10n.string(feature.titleKey))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(PathTrioTheme.ink)
                    Text("pro.badge")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(PathTrioTheme.warm)
                }

                Text(L10n.string(feature.messageKey))
                    .font(.footnote)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
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
