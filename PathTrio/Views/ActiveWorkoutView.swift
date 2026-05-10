import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndConfirmation = false
    @State private var completedDraft: WorkoutSessionDraft?
    @State private var consumedLocationCount = 0
    private let metricsTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var routeRecordingStatus: RouteRecordingStatus? {
        RouteRecordingStatus.evaluate(
            authorizationStatus: appModel.locationService.authorizationStatus,
            latestHorizontalAccuracy: appModel.locationService.latestHorizontalAccuracy,
            latestErrorMessage: appModel.locationService.latestErrorMessage,
            backgroundRecordingEnabled: appModel.settingsStore.backgroundRecordingEnabled
        )
    }

    private var activeMapStyle: PathTrioMapStyle {
        appModel.entitlementStore.canUse(.mapStyles) ? appModel.settingsStore.preferredMapStyle : .standard
    }

    var body: some View {
        let draft = appModel.recorder.draft ?? appModel.activeDraft
        let metrics = draft?.metrics ?? WorkoutMetrics(duration: 0, distanceMeters: 0, averageSpeedMetersPerSecond: 0)
        let type = draft?.type ?? appModel.selectedWorkoutType
        let locations = draft?.locations ?? []

        ZStack(alignment: .bottom) {
            RouteMapView(
                locations: locations,
                followsLatestLocation: true,
                style: activeMapStyle
            )
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
                appModel.appleWatchSupportService.publishActiveWorkout(nil, isProUnlocked: appModel.entitlementStore.canUse(.appleWatch))
                appModel.activeDraft = nil
                appModel.smartAssistEngine.reset()
            }
            Button("action.cancel", role: .cancel) {}
        }
        .sheet(item: $completedDraft) { draft in
            WorkoutSummaryView(draft: draft) {
                dismiss()
            }
        }
        .onAppear {
            publishActiveWorkoutToWatch()
        }
        .onChange(of: appModel.locationService.latestLocations.count) { _, count in
            guard count > consumedLocationCount else { return }
            let newLocations = Array(appModel.locationService.latestLocations[consumedLocationCount..<count])
            consumedLocationCount = count
            appModel.activeDraft = appModel.recorder.addLocations(newLocations)
            publishActiveWorkoutToWatch()
            updateSmartAssist(now: Date())
        }
        .onChange(of: appModel.motionService.detectedActivity) { _, _ in
            updateSmartAssist(now: Date())
        }
        .onReceive(metricsTimer) { date in
            appModel.activeDraft = appModel.recorder.refresh(now: date)
            updateSmartAssist(now: date)
            publishActiveWorkoutToWatch()
        }
        .alert(
            appModel.activeSuggestion?.title ?? "",
            isPresented: activeSuggestionAlertIsPresented,
            presenting: appModel.activeSuggestion
        ) { suggestion in
            switch suggestion {
            case .activityChange(_, let suggestedType):
                Button("smartAssist.activityChange.confirm") {
                    appModel.selectedWorkoutType = suggestedType
                    appModel.activeDraft = appModel.recorder.changeType(to: suggestedType)
                    appModel.activeSuggestion = nil
                    publishActiveWorkoutToWatch()
                }
                Button("action.cancel", role: .cancel) {
                    appModel.activeSuggestion = nil
                }
            case .autoPause:
                Button("action.pause") {
                    _ = appModel.recorder.autoPause()
                    appModel.activeDraft = appModel.recorder.draft
                    appModel.activeSuggestion = nil
                    appModel.smartAssistEngine.reset()
                    publishActiveWorkoutToWatch()
                }
                Button("action.cancel", role: .cancel) {
                    appModel.activeSuggestion = nil
                }
            case .speedAnomaly:
                Button("action.pause") {
                    _ = appModel.recorder.pause()
                    appModel.activeDraft = appModel.recorder.draft
                    appModel.activeSuggestion = nil
                    appModel.smartAssistEngine.reset()
                    publishActiveWorkoutToWatch()
                }
                Button("active.keepRecording", role: .cancel) {
                    appModel.activeSuggestion = nil
                }
            }
        } message: { suggestion in
            Text(suggestion.message)
        }
    }

    private var activeSuggestionAlertIsPresented: Binding<Bool> {
        Binding(
            get: { appModel.activeSuggestion != nil },
            set: { isPresented in
                if !isPresented {
                    appModel.activeSuggestion = nil
                }
            }
        )
    }

    private func updateSmartAssist(now: Date) {
        guard appModel.activeSuggestion == nil else { return }
        guard let draft = appModel.recorder.draft else { return }

        if draft.state == .autoPaused {
            if appModel.smartAssistEngine.shouldResumeAutoPaused(
                workoutType: draft.type,
                currentSpeedMetersPerSecond: currentMotionSpeed(fallback: draft.metrics.averageSpeedMetersPerSecond),
                detectedActivity: appModel.motionService.detectedActivity,
                now: now
            ) {
                _ = appModel.recorder.resume(at: now)
                appModel.activeDraft = appModel.recorder.draft
                publishActiveWorkoutToWatch()
            }
            return
        }

        appModel.activeSuggestion = appModel.smartAssistEngine.evaluate(
            workoutType: draft.type,
            workoutStartedAt: draft.startedAt,
            workoutState: draft.state,
            currentSpeedMetersPerSecond: currentMotionSpeed(fallback: draft.metrics.averageSpeedMetersPerSecond),
            detectedActivity: appModel.motionService.detectedActivity,
            settings: appModel.smartAssistSettings,
            now: now
        )
    }

    private func currentMotionSpeed(fallback: Double) -> Double {
        guard let speed = appModel.locationService.latestLocations.last?.speed, speed >= 0 else {
            return fallback
        }
        return speed
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
            appModel.activeDraft = appModel.recorder.draft
            publishActiveWorkoutToWatch()
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

    private func publishActiveWorkoutToWatch() {
        guard appModel.entitlementStore.canUse(.appleWatch) else { return }
        appModel.appleWatchSupportService.activate()
        appModel.appleWatchSupportService.publishActiveWorkout(
            appModel.recorder.draft ?? appModel.activeDraft,
            isProUnlocked: true
        )
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
