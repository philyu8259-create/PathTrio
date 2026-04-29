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

                Section("settings.health") {
                    Toggle("settings.health.syncToAppleHealth", isOn: $settings.healthKitSyncEnabled)

                    HealthSyncStatusRow(status: HealthSyncPlan.status(syncEnabled: settings.healthKitSyncEnabled))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings.health.plannedData")
                            .font(.footnote.weight(.semibold))

                        ForEach(HealthSyncPlan.plannedWriteTypeKeys, id: \.self) { key in
                            Label(L10n.string(key), systemImage: "checkmark.circle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
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

private struct HealthSyncStatusRow: View {
    let status: HealthSyncPlan.Status

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status.systemImage)
                .foregroundStyle(tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.string(status.titleKey))
                    .font(.footnote.weight(.semibold))
                Text(L10n.string(status.messageKey))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var tint: Color {
        switch status.kind {
        case .disabled: .secondary
        case .permissionNeeded: .blue
        }
    }
}
