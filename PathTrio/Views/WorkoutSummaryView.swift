import SwiftData
import SwiftUI

struct WorkoutSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppModel.self) private var appModel
    let draft: WorkoutSessionDraft
    let done: () -> Void
    @State private var saveErrorMessage: String?
    @State private var healthSyncResult: WorkoutHealthSyncResult?
    @State private var hasSaved = false
    private let metricColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var estimatedCalories: Double? {
        WorkoutCaloriesEstimator.estimate(
            type: draft.type,
            duration: draft.metrics.duration,
            bodyWeightKilograms: appModel.settingsStore.bodyWeightKilograms
        )
    }

    private var activeMapStyle: PathTrioMapStyle {
        appModel.entitlementStore.canUse(.mapStyles) ? appModel.settingsStore.preferredMapStyle : .standard
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryHeader
                    routeCard
                    metricsPanel
                    routeConfidenceCard
                    healthSyncCard

                    if let saveErrorMessage {
                        Text(saveErrorMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .pathTrioCard()
                    }
                }
                .padding(16)
            }
            .background(PathTrioTheme.pageBackground.ignoresSafeArea())
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
                    if appModel.entitlementStore.canUse(.appleWatch) {
                        appModel.appleWatchSupportService.activate()
                        appModel.appleWatchSupportService.publishLatestWorkout(saved)
                    }
                    healthSyncResult = await WorkoutHealthSyncCoordinator.syncIfNeeded(
                        saved,
                        syncEnabled: appModel.settingsStore.healthKitSyncEnabled && appModel.entitlementStore.canUse(.advancedHealthSync),
                        syncer: appModel.healthSyncer
                    )
                    if let healthSyncResult {
                        try store.updateHealthSyncResult(healthSyncResult, for: saved)
                    }
                } catch {
                    saveErrorMessage = L10n.string("summary.saveError")
                }
            }
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: draft.type.systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(PathTrioTheme.tint(for: draft.type), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.string("summary.subtitle", draft.type.displayName))
                    .font(.headline.weight(.black))
                    .foregroundStyle(PathTrioTheme.ink)
                Text(draft.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
            }

            Spacer()
        }
        .padding(16)
        .pathTrioCard()
    }

    private var routeCard: some View {
        RouteMapView(locations: draft.locations, style: activeMapStyle)
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PathTrioTheme.line, lineWidth: 1)
            }
    }

    private var metricsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("summary.metrics.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            LazyVGrid(columns: metricColumns, spacing: 10) {
                MetricTile(title: L10n.string("metric.distance"), value: WorkoutMetricsFormatter.distance(draft.metrics.distanceMeters), systemImage: "map", tint: PathTrioTheme.teal)
                MetricTile(title: L10n.string("metric.duration"), value: WorkoutMetricsFormatter.duration(draft.metrics.duration), systemImage: "timer", tint: PathTrioTheme.action)
                MetricTile(
                    title: draft.type.emphasizesPace ? L10n.string("metric.averagePace") : L10n.string("metric.averageSpeed"),
                    value: draft.type.emphasizesPace ? WorkoutMetricsFormatter.pace(draft.metrics.paceSecondsPerKilometer) : WorkoutMetricsFormatter.speed(draft.metrics.averageSpeedMetersPerSecond),
                    systemImage: "speedometer",
                    tint: PathTrioTheme.tint(for: draft.type)
                )
                MetricTile(title: L10n.string("metric.calories"), value: WorkoutMetricsFormatter.calories(estimatedCalories), systemImage: "flame", tint: .red)
            }
        }
    }

    private var routeConfidenceCard: some View {
        SummaryInfoCard(
            titleKey: "detail.insights.route.title",
            message: draft.locations.isEmpty
                ? L10n.string("summary.route.empty")
                : L10n.string("summary.route.saved", draft.locations.count),
            systemImage: draft.locations.isEmpty ? "location.slash" : "point.topleft.down.curvedto.point.bottomright.up",
            tint: draft.locations.isEmpty ? .orange : PathTrioTheme.teal
        )
    }

    private var healthSyncCard: some View {
        let message: String = {
            if let healthSyncResult, let messageKey = healthSyncResult.messageKey {
                return L10n.string(messageKey)
            }
            if saveErrorMessage != nil {
                return L10n.string("summary.saveError")
            }
            return L10n.string("summary.health.saving")
        }()

        let hasSaveError = saveErrorMessage != nil
        let isError = healthSyncResult?.isError ?? hasSaveError

        return SummaryInfoCard(
            titleKey: "summary.health.title",
            message: message,
            systemImage: isError ? "exclamationmark.triangle" : "heart.text.square",
            tint: isError ? .orange : PathTrioTheme.action
        )
    }
}

private struct SummaryInfoCard: View {
    let titleKey: LocalizedStringKey
    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(titleKey)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .pathTrioCard()
    }
}
