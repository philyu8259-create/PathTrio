import CoreLocation
import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppModel.self) private var appModel
    let workout: WorkoutSessionModel
    @State private var isRetryingHealthSync = false
    @State private var shareItem: ExportShareItem?
    @State private var lockedProFeature: ProFeature?
    @State private var exportErrorMessage: String?
    private let insightEngine = WorkoutDetailInsightEngine()
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

    private var insights: [WorkoutDetailInsight] {
        insightEngine.insights(for: workout)
    }

    private var activeMapStyle: PathTrioMapStyle {
        appModel.entitlementStore.canUse(.mapStyles) ? appModel.settingsStore.preferredMapStyle : .standard
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RouteMapView(locations: locations, style: activeMapStyle)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(PathTrioTheme.line, lineWidth: 1)
                    }

                LazyVGrid(columns: metricColumns, spacing: 12) {
                    MetricTile(title: L10n.string("metric.distance"), value: WorkoutMetricsFormatter.distance(workout.distanceMeters), systemImage: "map")
                    MetricTile(title: L10n.string("metric.duration"), value: WorkoutMetricsFormatter.duration(workout.duration), systemImage: "timer")
                    MetricTile(title: L10n.string("metric.averagePace"), value: WorkoutMetricsFormatter.pace(paceSecondsPerKilometer), systemImage: "gauge.with.dots.needle.50percent")
                    MetricTile(title: L10n.string("metric.averageSpeed"), value: WorkoutMetricsFormatter.speed(workout.averageSpeedMetersPerSecond), systemImage: "speedometer")
                    MetricTile(title: L10n.string("metric.calories"), value: WorkoutMetricsFormatter.calories(estimatedCalories), systemImage: "flame")
                }

                WorkoutDetailInsightsPanel(insights: insights)

                Button {
                    exportWorkout()
                } label: {
                    Label("export.workout", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(PathTrioTheme.action)
                .pathTrioCard()

                VStack(alignment: .leading, spacing: 10) {
                    DetailDateRow(title: L10n.string("detail.started"), date: workout.startedAt)
                    DetailDateRow(title: L10n.string("detail.ended"), date: workout.endedAt)
                }
                .font(.subheadline)
                .foregroundStyle(PathTrioTheme.muted)
                .padding(14)
                .pathTrioCard()

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
        .background(PathTrioTheme.pageBackground.ignoresSafeArea())
        .navigationTitle(workout.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exportWorkout()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(Text("export.workout"))
            }
        }
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

    private func exportWorkout() {
        guard appModel.entitlementStore.canUse(.dataExport) else {
            lockedProFeature = .dataExport
            return
        }

        do {
            let builder = WorkoutExportBuilder()
            let filename = "PeachMove-\(workout.type.rawValue)-\(workout.id.uuidString.prefix(8)).gpx"
            let url = try builder.writeTemporaryFile(contents: builder.gpx(for: workout), filename: filename)
            shareItem = ExportShareItem(url: url)
        } catch {
            exportErrorMessage = L10n.string("export.error.message")
        }
    }

    @MainActor
    private func retryHealthSync() async {
        guard !isRetryingHealthSync else { return }
        guard appModel.entitlementStore.canUse(.advancedHealthSync) else {
            lockedProFeature = .advancedHealthSync
            return
        }
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

private struct WorkoutDetailInsightsPanel: View {
    let insights: [WorkoutDetailInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("detail.insights.title", systemImage: "sparkles")
                .font(.headline.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)

            ForEach(insights) { insight in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: insight.systemImage)
                        .font(.body.weight(.bold))
                        .foregroundStyle(PathTrioTheme.action)
                        .frame(width: 28, height: 28)
                        .background(PathTrioTheme.action.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(L10n.string(insight.titleKey))
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(PathTrioTheme.ink)
                            Text(insight.value)
                                .font(.footnote.weight(.black))
                                .foregroundStyle(PathTrioTheme.action)
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
