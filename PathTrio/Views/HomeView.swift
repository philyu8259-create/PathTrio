import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showingActiveWorkout = false
    @State private var showingHistory = false
    @State private var showingSettings = false

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PathTrio")
                        .font(.largeTitle.bold())
                    Text("Walk, Run & Ride Tracker")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    MetricTile(title: "Today", value: "0.00 km", systemImage: "map")
                    MetricTile(title: "Time", value: "00:00", systemImage: "timer")
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
                    Label("Start", systemImage: "play.fill")
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
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }

                    Spacer()

                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
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
        }
    }
}
