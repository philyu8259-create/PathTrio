import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isConfirmingBackgroundRecording = false
    @State private var isConfirmingHealthSync = false

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
                    Toggle("settings.recording.recordWhenLocked", isOn: backgroundRecordingBinding)
                    Text("settings.recording.backgroundDescription")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("settings.health") {
                    Toggle("settings.health.syncToAppleHealth", isOn: healthSyncBinding)

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
            .onDisappear {
                saveSettings()
            }
            .confirmationDialog(
                "settings.recording.backgroundConfirm.title",
                isPresented: $isConfirmingBackgroundRecording,
                titleVisibility: .visible
            ) {
                Button("settings.recording.backgroundConfirm.enable") {
                    appModel.settingsStore.backgroundRecordingEnabled = true
                    saveSettings()
                }
                Button("action.cancel", role: .cancel) {}
            } message: {
                Text("settings.recording.backgroundConfirm.message")
            }
            .confirmationDialog(
                "settings.health.confirm.title",
                isPresented: $isConfirmingHealthSync,
                titleVisibility: .visible
            ) {
                Button("settings.health.confirm.enable") {
                    appModel.settingsStore.healthKitSyncEnabled = true
                    saveSettings()
                }
                Button("action.cancel", role: .cancel) {}
            } message: {
                Text("settings.health.confirm.message")
            }
        }
    }

    private var backgroundRecordingBinding: Binding<Bool> {
        Binding {
            appModel.settingsStore.backgroundRecordingEnabled
        } set: { isEnabled in
            if isEnabled {
                isConfirmingBackgroundRecording = true
            } else {
                appModel.settingsStore.backgroundRecordingEnabled = false
                saveSettings()
            }
        }
    }

    private var healthSyncBinding: Binding<Bool> {
        Binding {
            appModel.settingsStore.healthKitSyncEnabled
        } set: { isEnabled in
            if isEnabled {
                isConfirmingHealthSync = true
            } else {
                appModel.settingsStore.healthKitSyncEnabled = false
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
