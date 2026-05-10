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
        let draft = appModel.recorder.draft ?? appModel.activeDraft
        let metrics = draft?.metrics ?? WorkoutMetrics(duration: 0, distanceMeters: 0, averageSpeedMetersPerSecond: 0)
        let type = draft?.type ?? appModel.selectedWorkoutType
        let locations = draft?.locations ?? []

        ZStack(alignment: .bottom) {
            RouteMapView(locations: locations, followsLatestLocation: true)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                activeHeader(type: type, state: draft?.state, routePointCount: locations.count)

                Spacer()

                if locations.isEmpty {
                    Label("active.map.empty", systemImage: "location.magnifyingglass")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(PathTrioTheme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 12)
                }

                recordingPanel(type: type, metrics: metrics)
            }
        }
        .background(PathTrioTheme.pageBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
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

    private func activeHeader(type: WorkoutType, state: WorkoutState?, routePointCount: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: type.systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(PathTrioTheme.tint(for: type), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("active.title")
                    .font(.headline.weight(.black))
                    .foregroundStyle(PathTrioTheme.ink)
                HStack(spacing: 8) {
                    Text(type.displayName)
                    Text(statusText(state))
                    Text(L10n.string("active.route.points", routePointCount))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(PathTrioTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            }

            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func recordingPanel(type: WorkoutType, metrics: WorkoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let routeRecordingStatus {
                RouteRecordingStatusBanner(status: routeRecordingStatus)
            }

            HStack(alignment: .top, spacing: 12) {
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

            VStack(alignment: .leading, spacing: 10) {
                Text("active.controls.title")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PathTrioTheme.muted)

                HStack(spacing: 12) {
                    pauseResumeButton
                    endButton
                }
            }
        }
        .padding(16)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(PathTrioTheme.line)
                .frame(height: 1)
        }
    }

    private var pauseResumeButton: some View {
        Button {
            if appModel.recorder.draft?.state == .recording {
                _ = appModel.recorder.pause()
            } else {
                _ = appModel.recorder.resume()
            }
        } label: {
            Label(
                appModel.recorder.draft?.state == .recording ? L10n.string("action.pause") : L10n.string("action.resume"),
                systemImage: appModel.recorder.draft?.state == .recording ? "pause.fill" : "play.fill"
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .font(.headline.weight(.bold))
        .foregroundStyle(PathTrioTheme.ink)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PathTrioTheme.line, lineWidth: 1)
        }
    }

    private var endButton: some View {
        Button(role: .destructive) {
            showingEndConfirmation = true
        } label: {
            Label("action.end", systemImage: "stop.fill")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .font(.headline.weight(.bold))
        .foregroundStyle(.white)
        .background(.red, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
