import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndConfirmation = false
    @State private var completedDraft: WorkoutSessionDraft?
    @State private var consumedLocationCount = 0

    var body: some View {
        VStack(spacing: 0) {
            RouteMapView(locations: appModel.recorder.draft?.locations ?? [])
                .frame(maxHeight: .infinity)

            VStack(spacing: 14) {
                let draft = appModel.recorder.draft ?? appModel.activeDraft
                let metrics = draft?.metrics ?? WorkoutMetrics(duration: 0, distanceMeters: 0, averageSpeedMetersPerSecond: 0)
                let type = draft?.type ?? appModel.selectedWorkoutType

                HStack(spacing: 12) {
                    MetricTile(title: L10n.string("metric.time"), value: WorkoutMetricsFormatter.duration(metrics.duration), systemImage: "timer")
                    MetricTile(title: L10n.string("metric.distance"), value: WorkoutMetricsFormatter.distance(metrics.distanceMeters), systemImage: "map")
                }

                HStack(spacing: 12) {
                    MetricTile(
                        title: type.emphasizesPace ? L10n.string("metric.pace") : L10n.string("metric.speed"),
                        value: type.emphasizesPace ? WorkoutMetricsFormatter.pace(metrics.paceSecondsPerKilometer) : WorkoutMetricsFormatter.speed(metrics.averageSpeedMetersPerSecond),
                        systemImage: type.emphasizesPace ? "speedometer" : "gauge.with.dots.needle.67percent"
                    )
                    MetricTile(title: L10n.string("metric.status"), value: statusText(draft?.state), systemImage: "waveform.path.ecg")
                }

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
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        showingEndConfirmation = true
                    } label: {
                        Label("action.end", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(.regularMaterial)
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
