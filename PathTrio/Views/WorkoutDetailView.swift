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
        workout.effectiveEstimatedCalories ?? WorkoutCaloriesEstimator.estimate(
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
                if locations.isEmpty {
                    WorkoutNoRouteCard(recordingMode: workout.recordingMode)
                } else {
                    RouteMapView(locations: locations, style: activeMapStyle)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(PathTrioTheme.line, lineWidth: 1)
                        }
                }

                LazyVGrid(columns: metricColumns, spacing: 12) {
                    MetricTile(title: L10n.string("metric.distance"), value: WorkoutMetricsFormatter.distance(workout.distanceMeters), systemImage: "map")
                    MetricTile(title: L10n.string("metric.duration"), value: WorkoutMetricsFormatter.duration(workout.duration), systemImage: "timer")
                    MetricTile(title: L10n.string("metric.averagePace"), value: WorkoutMetricsFormatter.pace(paceSecondsPerKilometer), systemImage: "gauge.with.dots.needle.50percent")
                    MetricTile(title: L10n.string("metric.averageSpeed"), value: WorkoutMetricsFormatter.speed(workout.averageSpeedMetersPerSecond), systemImage: "speedometer")
                    MetricTile(title: L10n.string("metric.calories"), value: WorkoutMetricsFormatter.calories(estimatedCalories), systemImage: "flame")
                }

                WorkoutDetailInsightsPanel(insights: insights)

                WorkoutRecordingInfoCard(workout: workout)

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

private struct WorkoutRecordingInfoCard: View {
    let workout: WorkoutSessionModel

    private var trimmedNotes: String? {
        guard let notes = workout.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty else {
            return nil
        }
        return notes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("detail.recording.title", systemImage: workout.isManualEntry ? "pencil.circle.fill" : "dot.radiowaves.left.and.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)

            HStack(spacing: 8) {
                Text(L10n.string(workout.recordingMode.titleKey))
                    .font(.caption.weight(.black))
                    .foregroundStyle(workout.isManualEntry ? PathTrioTheme.warm : PathTrioTheme.action)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background((workout.isManualEntry ? PathTrioTheme.warm : PathTrioTheme.action).opacity(0.12), in: Capsule())

                if workout.userCorrectedCalories != nil {
                    Text("detail.recording.correctedCalories")
                        .font(.caption.weight(.black))
                        .foregroundStyle(PathTrioTheme.hawk)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(PathTrioTheme.hawk.opacity(0.12), in: Capsule())
                }
            }

            if let trimmedNotes {
                VStack(alignment: .leading, spacing: 6) {
                    Text("detail.recording.notes")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PathTrioTheme.muted)
                    Text(trimmedNotes)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PathTrioTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PathTrioTheme.peach.opacity(0.13), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(14)
        .pathTrioCard()
    }
}

private struct WorkoutNoRouteCard: View {
    let recordingMode: WorkoutRecordingMode

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: recordingMode == .manualEntry ? "pencil.circle.fill" : "timer")
                .font(.title3.weight(.black))
                .foregroundStyle(PathTrioTheme.action)
                .frame(width: 44, height: 44)
                .background(PathTrioTheme.action.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("detail.route.empty.title")
                    .font(.headline.weight(.black))
                    .foregroundStyle(PathTrioTheme.ink)
                Text("detail.route.empty.message")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
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
