import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

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
                    Text("settings.recording.backgroundDescription")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                    Button("action.done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .task {
                loadSettings()
            }
            .onChange(of: settings.preferredUnits) { _, _ in saveSettings() }
            .onChange(of: settings.smartActivityAlertsEnabled) { _, _ in saveSettings() }
            .onChange(of: settings.autoPauseEnabled) { _, _ in saveSettings() }
            .onChange(of: settings.speedAnomalyAlertsEnabled) { _, _ in saveSettings() }
            .onChange(of: settings.backgroundRecordingEnabled) { _, _ in saveSettings() }
            .onChange(of: settings.healthKitSyncEnabled) { _, _ in saveSettings() }
            .onDisappear {
                saveSettings()
            }
        }
    }

    private func loadSettings() {
        do {
            try SettingsPersistenceStore(context: modelContext).load(into: appModel.settingsStore)
        } catch {
            // Settings remain editable with in-memory defaults if loading fails.
        }
    }

    private func saveSettings() {
        do {
            try SettingsPersistenceStore(context: modelContext).save(appModel.settingsStore)
        } catch {
            // The next app launch will fall back to defaults if saving fails.
        }
    }
}
