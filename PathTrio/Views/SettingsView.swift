import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = appModel.settingsStore

        NavigationStack {
            Form {
                Section("settings.units") {
                    Picker("settings.units", selection: $settings.preferredUnits) {
                        Text("settings.units.metric").tag("metric")
                    }
                }

                Section("settings.smartAssist") {
                    Toggle("settings.smartAssist.activityAlerts", isOn: $settings.smartActivityAlertsEnabled)
                    Toggle("settings.smartAssist.autoPause", isOn: $settings.autoPauseEnabled)
                    Toggle("settings.smartAssist.speedAnomalyAlerts", isOn: $settings.speedAnomalyAlertsEnabled)
                }

                Section("settings.recording") {
                    Toggle("settings.recording.recordWhenLocked", isOn: $settings.backgroundRecordingEnabled)
                }

                Section("settings.privacy") {
                    Text("settings.privacy.description")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("settings.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("action.done") { dismiss() }
                }
            }
        }
    }
}
