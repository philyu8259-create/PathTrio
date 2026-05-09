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
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SettingsPanel(titleKey: "settings.units", systemImage: "ruler") {
                            Picker("settings.units", selection: $settings.preferredUnits) {
                                Text("settings.units.metric").tag("metric")
                            }
                            .pickerStyle(.menu)
                            .tint(PathTrioTheme.action)
                        }

                        SettingsPanel(titleKey: "settings.smartAssist", systemImage: "sparkles") {
                            SettingsToggleRow(titleKey: "settings.smartAssist.activityAlerts", systemImage: "figure.walk.motion", isOn: $settings.smartActivityAlertsEnabled)
                            SettingsDivider()
                            SettingsToggleRow(titleKey: "settings.smartAssist.autoPause", systemImage: "pause.circle", isOn: $settings.autoPauseEnabled)
                            SettingsDivider()
                            SettingsToggleRow(titleKey: "settings.smartAssist.speedAnomalyAlerts", systemImage: "speedometer", isOn: $settings.speedAnomalyAlertsEnabled)
                        }

                        SettingsPanel(titleKey: "settings.recording", systemImage: "location") {
                            SettingsToggleRow(titleKey: "settings.recording.recordWhenLocked", systemImage: "lock.open", isOn: backgroundRecordingBinding)
                            SettingsDescription(textKey: "settings.recording.backgroundDescription")
                        }

                        SettingsPanel(titleKey: "settings.health", systemImage: "heart.text.square") {
                            SettingsToggleRow(titleKey: "settings.health.syncToAppleHealth", systemImage: "heart", isOn: healthSyncBinding)
                            SettingsDivider()
                            HealthSyncStatusRow(status: HealthSyncPlan.status(syncEnabled: settings.healthKitSyncEnabled))
                            SettingsDivider()

                            VStack(alignment: .leading, spacing: 10) {
                                Text("settings.health.plannedData")
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(PathTrioTheme.ink)

                                ForEach(HealthSyncPlan.plannedWriteTypeKeys, id: \.self) { key in
                                    Label(L10n.string(key), systemImage: "checkmark.circle.fill")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(PathTrioTheme.muted)
                                }
                            }
                        }

                        SettingsPanel(titleKey: "settings.privacy", systemImage: "hand.raised") {
                            SettingsDescription(textKey: "settings.privacy.description")
                        }

                        Spacer(minLength: 18)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.large)
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
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.string(status.titleKey))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                Text(L10n.string(status.messageKey))
                    .font(.footnote)
                    .foregroundStyle(PathTrioTheme.muted)
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

private struct SettingsPanel<Content: View>: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(titleKey, systemImage: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .pathTrioCard()
    }
}

private struct SettingsToggleRow: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(titleKey, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PathTrioTheme.ink)
                .labelStyle(.titleAndIcon)
        }
        .tint(PathTrioTheme.action)
    }
}

private struct SettingsDescription: View {
    let textKey: LocalizedStringKey

    var body: some View {
        Text(textKey)
            .font(.footnote)
            .foregroundStyle(PathTrioTheme.muted)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 2)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(PathTrioTheme.line)
            .frame(height: 1)
    }
}
