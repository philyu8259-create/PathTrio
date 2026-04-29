import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = appModel.settingsStore

        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Units", selection: $settings.preferredUnits) {
                        Text("Metric").tag("metric")
                    }
                }

                Section("Smart Assist") {
                    Toggle("Smart Activity Alerts", isOn: $settings.smartActivityAlertsEnabled)
                    Toggle("Auto Pause", isOn: $settings.autoPauseEnabled)
                    Toggle("Speed Anomaly Alerts", isOn: $settings.speedAnomalyAlertsEnabled)
                }

                Section("Privacy") {
                    Text("PathTrio stores workouts locally by default and uses location only to record active workout routes, distance, and speed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
