import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingActiveWorkout = false
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var todayTotals = WorkoutTotals()

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack {
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.string("metric.today"))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(PathTrioTheme.muted)

                            HStack(spacing: 12) {
                                MetricTile(
                                    title: L10n.string("metric.distance"),
                                    value: WorkoutMetricsFormatter.distance(todayTotals.distanceMeters),
                                    systemImage: "map",
                                    tint: PathTrioTheme.teal
                                )
                                MetricTile(
                                    title: L10n.string("metric.time"),
                                    value: WorkoutMetricsFormatter.duration(todayTotals.duration),
                                    systemImage: "timer",
                                    tint: PathTrioTheme.action
                                )
                            }
                        }

                        WorkoutTypePicker(selection: $appModel.selectedWorkoutType)

                        startButton

                        bottomActions

                        Spacer(minLength: 18)
                    }
                    .padding(16)
                }
            }
            .navigationDestination(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView()
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                loadSettings()
                refreshTodayTotals()
            }
            .onChange(of: appModel.latestCompletedWorkoutID) { _, _ in
                refreshTodayTotals()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                Text("app.name")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(PathTrioTheme.ink)
                Text("app.subtitle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
            }

            Spacer()

            Image(systemName: "location.north.line.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(PathTrioTheme.action, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.top, 8)
    }

    private var startButton: some View {
        Button {
            startWorkout()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.headline.weight(.bold))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.22), in: Circle())

                Text("action.start")
                    .font(.title3.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(PathTrioTheme.action, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .shadow(color: PathTrioTheme.action.opacity(0.25), radius: 12, x: 0, y: 8)
    }

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button {
                showingHistory = true
            } label: {
                Label("history.title", systemImage: "clock.arrow.circlepath")
                    .frame(maxWidth: .infinity)
            }

            Button {
                showingSettings = true
            } label: {
                Label("settings.title", systemImage: "gearshape")
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.callout.weight(.semibold))
        .buttonStyle(.plain)
        .foregroundStyle(PathTrioTheme.ink)
        .labelStyle(.titleAndIcon)
        .frame(maxWidth: .infinity)
        .padding(4)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PathTrioTheme.line, lineWidth: 1)
        }
    }

    private func startWorkout() {
        if appModel.settingsStore.backgroundRecordingEnabled {
            appModel.locationService.requestAlwaysPermission()
        } else {
            appModel.locationService.requestWhenInUsePermission()
        }
        appModel.activeDraft = appModel.recorder.start(type: appModel.selectedWorkoutType)
        appModel.locationService.start(backgroundAllowed: appModel.settingsStore.backgroundRecordingEnabled)
        if appModel.settingsStore.isAnySmartAssistEnabled {
            appModel.motionService.start()
        }
        showingActiveWorkout = true
    }

    private func loadSettings() {
        do {
            try SettingsPersistenceStore(context: modelContext).load(into: appModel.settingsStore)
        } catch {
            // Keep in-memory defaults if settings cannot be loaded.
        }
    }

    private func refreshTodayTotals() {
        do {
            todayTotals = try WorkoutStore(context: modelContext).totals(forDayContaining: Date())
        } catch {
            todayTotals = WorkoutTotals()
        }
    }
}
