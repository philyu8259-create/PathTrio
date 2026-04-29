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
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("app.name")
                        .font(.largeTitle.bold())
                    Text("app.subtitle")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    MetricTile(title: L10n.string("metric.today"), value: WorkoutMetricsFormatter.distance(todayTotals.distanceMeters), systemImage: "map")
                    MetricTile(title: L10n.string("metric.time"), value: WorkoutMetricsFormatter.duration(todayTotals.duration), systemImage: "timer")
                }

                WorkoutTypePicker(selection: $appModel.selectedWorkoutType)

                Button {
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
                } label: {
                    Label("action.start", systemImage: "play.fill")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()

                HStack {
                    Button {
                        showingHistory = true
                    } label: {
                        Label("history.title", systemImage: "clock.arrow.circlepath")
                    }

                    Spacer()

                    Button {
                        showingSettings = true
                    } label: {
                        Label("settings.title", systemImage: "gearshape")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
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
