import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndConfirmation = false
    @State private var completedDraft: WorkoutSessionDraft?
    @State private var consumedLocationCount = 0

    private var routeRecordingStatus: RouteRecordingStatus? {
        RouteRecordingStatus.evaluate(
            authorizationStatus: appModel.locationService.authorizationStatus,
            latestHorizontalAccuracy: appModel.locationService.latestHorizontalAccuracy,
            latestErrorMessage: appModel.locationService.latestErrorMessage,
            backgroundRecordingEnabled: appModel.settingsStore.backgroundRecordingEnabled
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            RouteMapView(locations: appModel.recorder.draft?.locations ?? [])
                .frame(maxHeight: .infinity)

            VStack(spacing: 16) {
                let draft = appModel.recorder.draft ?? appModel.activeDraft
                let metrics = draft?.metrics ?? WorkoutMetrics(duration: 0, distanceMeters: 0, averageSpeedMetersPerSecond: 0)
                let type = draft?.type ?? appModel.selectedWorkoutType

                if let routeRecordingStatus {
                    RouteRecordingStatusBanner(status: routeRecordingStatus)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label(type.displayName, systemImage: type.systemImage)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(PathTrioTheme.tint(for: type))

                    Text(statusText(draft?.state))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PathTrioTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 14) {
                    LiveMetric(
                        title: L10n.string("metric.time"),
                        value: WorkoutMetricsFormatter.duration(metrics.duration),
                        systemImage: "timer",
                        tint: PathTrioTheme.action,
                        isPrimary: true
                    )
                    LiveMetric(
                        title: L10n.string("metric.distance"),
                        value: WorkoutMetricsFormatter.distance(metrics.distanceMeters),
                        systemImage: "map",
                        tint: PathTrioTheme.teal,
                        isPrimary: true
                    )
                }

                LiveMetric(
                    title: type.emphasizesPace ? L10n.string("metric.pace") : L10n.string("metric.speed"),
                    value: type.emphasizesPace ? WorkoutMetricsFormatter.pace(metrics.paceSecondsPerKilometer) : WorkoutMetricsFormatter.speed(metrics.averageSpeedMetersPerSecond),
                    systemImage: type.emphasizesPace ? "speedometer" : "gauge.with.dots.needle.67percent",
                    tint: PathTrioTheme.tint(for: type),
                    isPrimary: false
                )

                HStack(spacing: 12) {
                    Button {
                        if appModel.recorder.draft?.state == .recording {
                            _ = appModel.recorder.pause()
                        } else {
                            _ = appModel.recorder.resume()
                        }
                    } label: {
                        Label(appModel.recorder.draft?.state == .recording ? L10n.string("action.pause") : L10n.string("action.resume"), systemImage: appModel.recorder.draft?.state == .recording ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(PathTrioTheme.ink)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(PathTrioTheme.line, lineWidth: 1)
                    }

                    Button(role: .destructive) {
                        showingEndConfirmation = true
                    } label: {
                        Label("action.end", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(.red, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(PathTrioTheme.line)
                    .frame(height: 1)
            }
        }
        .navigationBarBackButtonHidden()
        .confirmationDialog("active.endConfirmation.title", isPresented: $showingEndConfirmation, titleVisibility: .visible) {
            Button("active.endConfirmation.endWorkout", role: .destructive) {
                appModel.locationService.stop()
                appModel.motionService.stop()
                completedDraft = appModel.recorder.end()
                appModel.activeDraft = nil
            }
            Button("action.cancel", role: .cancel) {}
        }
        .sheet(item: $completedDraft) { draft in
            WorkoutSummaryView(draft: draft) {
                dismiss()
            }
        }
        .onChange(of: appModel.locationService.latestLocations.count) { _, count in
            guard count > consumedLocationCount else { return }
            let newLocations = Array(appModel.locationService.latestLocations[consumedLocationCount..<count])
            consumedLocationCount = count
            appModel.activeDraft = appModel.recorder.addLocations(newLocations)

            if let draft = appModel.recorder.draft {
                appModel.activeSuggestion = appModel.smartAssistEngine.evaluate(
                    workoutType: draft.type,
                    currentSpeedMetersPerSecond: draft.metrics.averageSpeedMetersPerSecond,
                    detectedActivity: appModel.motionService.detectedActivity,
                    settings: appModel.smartAssistSettings
                )
            }
        }
        .alert(item: Binding(
            get: { appModel.activeSuggestion },
            set: { appModel.activeSuggestion = $0 }
        )) { suggestion in
            Alert(
                title: Text(suggestion.title),
                message: Text(suggestion.message),
                dismissButton: .default(Text("action.ok"))
            )
        }
    }

    private func statusText(_ state: WorkoutState?) -> String {
        switch state {
        case .recording: L10n.string("workoutState.recording")
        case .paused: L10n.string("workoutState.paused")
        case .autoPaused: L10n.string("workoutState.autoPaused")
        case .ended: L10n.string("workoutState.ended")
        case .idle, .none: L10n.string("workoutState.ready")
        }
    }
}

private struct LiveMetric: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)

            Text(value)
                .font(.system(isPrimary ? .largeTitle : .title2, design: .rounded, weight: .black))
                .foregroundStyle(PathTrioTheme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.64)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .pathTrioCard()
    }
}

private struct RouteRecordingStatusBanner: View {
    let status: RouteRecordingStatus

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.string(status.titleKey))
                    .font(.subheadline.weight(.semibold))
                Text(L10n.string(status.messageKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        }
    }

    private var tint: Color {
        switch status.kind {
        case .info: .blue
        case .warning: .orange
        case .blocked: .red
        }
    }
}
