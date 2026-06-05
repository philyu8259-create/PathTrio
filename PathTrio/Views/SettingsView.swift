import SwiftData
import StoreKit
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isConfirmingBackgroundRecording = false
    @State private var isConfirmingHealthSync = false
    @State private var lockedProFeature: ProFeature?
    let showsDoneButton: Bool
    static let localeSuffix: String = Locale.current.identifier.hasPrefix("zh") ? "zh-Hans" : "en"
    static let supportURL = URL(string: "https://philyu8259-create.github.io/PathTrio/support-\(localeSuffix).html")!
    static let privacyPolicyURL = URL(string: "https://philyu8259-create.github.io/PathTrio/privacy-policy-\(localeSuffix).html")!
    static let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/appstore/dev/stdeula/")!

    var body: some View {
        @Bindable var settings = appModel.settingsStore

        NavigationStack {
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        PathTrioPageHeader(
                            titleKey: "settings.title",
                            subtitleKey: "settings.subtitle",
                            systemImage: "gearshape.fill",
                            tint: PathTrioTheme.ink.opacity(0.86)
                        )

                        SettingsPanel(titleKey: "pro.title", systemImage: "crown") {
                            NavigationLink {
                                ProSettingsView(
                                    weeklyDistanceGoalMeters: weeklyDistanceGoalBinding,
                                    monthlyWorkoutGoalCount: monthlyWorkoutGoalBinding,
                                    mapStyle: mapStyleBinding
                                ) { product in
                                    Task {
                                        await appModel.entitlementStore.purchase(product)
                                    }
                                }
                            } label: {
                                ProSettingsNavigationRow(isUnlocked: appModel.entitlementStore.isProUnlocked)
                            }
                            .buttonStyle(.plain)
                        }

                        SettingsPanel(titleKey: "settings.smartAssist", systemImage: "sparkles") {
                            SettingsToggleRow(titleKey: "settings.smartAssist.activityAlerts", systemImage: "figure.walk.motion", isOn: $settings.smartActivityAlertsEnabled)
                            SettingsDivider()
                            SettingsToggleRow(titleKey: "settings.smartAssist.autoPause", systemImage: "pause.circle", isOn: $settings.autoPauseEnabled)
                            SettingsDivider()
                            SettingsToggleRow(titleKey: "settings.smartAssist.speedAnomalyAlerts", systemImage: "speedometer", isOn: $settings.speedAnomalyAlertsEnabled)
                        }

                        SettingsPanel(titleKey: "settings.recording", systemImage: "location") {
                            SettingsToggleRow(titleKey: "settings.recording.autoStartReminders", systemImage: "figure.walk.motion", accessoryKey: "pro.badge", isOn: autoStartRemindersBinding)
                            SettingsDescription(textKey: "settings.recording.autoStartDescription")
                            SettingsDivider()
                            SettingsToggleRow(titleKey: "settings.recording.recordWhenLocked", systemImage: "lock.open", isOn: backgroundRecordingBinding)
                            SettingsDescription(textKey: "settings.recording.backgroundDescription")
                        }

                        SettingsPanel(titleKey: "settings.health", systemImage: "heart.text.square") {
                            HealthFrameworkDisclosureRow()
                            SettingsDivider()
                            SettingsToggleRow(titleKey: "settings.health.syncToAppleHealth", systemImage: "heart", accessoryKey: "pro.badge", isOn: healthSyncBinding)
                            SettingsDescription(textKey: "settings.health.healthKitDescription")
                            SettingsDivider()
                            HealthSyncStatusRow(status: HealthSyncPlan.status(syncEnabled: settings.healthKitSyncEnabled && appModel.entitlementStore.canUse(.advancedHealthSync)))
                        }

                        SettingsPanel(titleKey: "settings.privacy", systemImage: "hand.raised") {
                            SettingsDescription(textKey: "settings.privacy.description")
                            SettingsDivider()
                            SettingsLinkRow(
                                titleKey: "settings.privacy.policy",
                                systemImage: "doc.text",
                                destination: Self.privacyPolicyURL
                            )
                            SettingsDivider()
                            SettingsLinkRow(
                                titleKey: "settings.privacy.support",
                                systemImage: "envelope.fill",
                                destination: Self.supportURL
                            )
                            SettingsDivider()
                            SettingsLinkRow(
                                titleKey: "settings.privacy.eula",
                                systemImage: "doc.plaintext",
                                destination: Self.eulaURL,
                            )
                            SettingsDivider()
                            NavigationLink {
                                HistoryView(showsDoneButton: false)
                            } label: {
                                HStack(spacing: 10) {
                                    Label("history.clearAll", systemImage: "trash")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.red)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(PathTrioTheme.muted)
                                        .font(.subheadline.weight(.semibold))
                                }
                                .padding(.top, 4)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer(minLength: 18)
                    }
                    .padding(16)
                }
            }
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("action.done") {
                            appModel.saveSettings(to: modelContext)
                            dismiss()
                        }
                    }
                }
            }
            .toolbar(showsDoneButton ? .visible : .hidden, for: .navigationBar)
            .task {
                appModel.loadSettings(from: modelContext)
                #if DEBUG
                if ScreenshotDemoData.isEnabled {
                    ScreenshotDemoData.prepare(appModel: appModel, context: modelContext)
                    return
                }
                #endif
                await appModel.entitlementStore.refreshPurchasedEntitlements()
                await appModel.entitlementStore.loadProducts()
                appModel.reconcileLockedProSettings(in: modelContext)
                if appModel.entitlementStore.canUse(.appleWatch) {
                    appModel.appleWatchSupportService.activate()
                }
                appModel.appleWatchSupportService.publishProStatus(isUnlocked: appModel.entitlementStore.canUse(.appleWatch))
            }
            .onChange(of: settings.smartActivityAlertsEnabled) { _, _ in appModel.saveSettings(to: modelContext) }
            .onChange(of: settings.autoPauseEnabled) { _, _ in appModel.saveSettings(to: modelContext) }
            .onChange(of: settings.speedAnomalyAlertsEnabled) { _, _ in appModel.saveSettings(to: modelContext) }
            .onChange(of: settings.autoStartRemindersEnabled) { _, _ in appModel.saveSettings(to: modelContext) }
            .onChange(of: settings.weeklyDistanceGoalMeters) { _, _ in appModel.saveSettings(to: modelContext) }
            .onChange(of: settings.monthlyWorkoutGoalCount) { _, _ in appModel.saveSettings(to: modelContext) }
            .onChange(of: settings.preferredMapStyleRawValue) { _, _ in appModel.saveSettings(to: modelContext) }
            .onChange(of: appModel.entitlementStore.isProUnlocked) { _, _ in
                appModel.reconcileLockedProSettings(in: modelContext)
            }
            .onDisappear {
                appModel.saveSettings(to: modelContext)
            }
            .confirmationDialog(
                "settings.recording.backgroundConfirm.title",
                isPresented: $isConfirmingBackgroundRecording,
                titleVisibility: .visible
            ) {
                Button("settings.recording.backgroundConfirm.enable") {
                    appModel.settingsStore.backgroundRecordingEnabled = true
                    appModel.saveSettings(to: modelContext)
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
                    guard appModel.entitlementStore.canUse(.advancedHealthSync) else {
                        appModel.settingsStore.healthKitSyncEnabled = false
                        lockedProFeature = .advancedHealthSync
                        appModel.saveSettings(to: modelContext)
                        return
                    }
                    appModel.settingsStore.healthKitSyncEnabled = true
                    appModel.saveSettings(to: modelContext)
                }
                Button("action.cancel", role: .cancel) {}
            } message: {
                Text("settings.health.confirm.message")
            }
            .alert("pro.locked.title", isPresented: lockedProFeatureAlertBinding) {
                Button("action.ok") {
                    lockedProFeature = nil
                }
            } message: {
                if let lockedProFeature {
                    Text(L10n.string("pro.locked.message", L10n.string(lockedProFeature.titleKey)))
                }
            }
        }
    }

    private var lockedProFeatureAlertBinding: Binding<Bool> {
        Binding {
            lockedProFeature != nil
        } set: { isPresented in
            if !isPresented {
                lockedProFeature = nil
            }
        }
    }

    private var autoStartRemindersBinding: Binding<Bool> {
        Binding {
            appModel.settingsStore.autoStartRemindersEnabled
        } set: { isEnabled in
            if isEnabled && !appModel.entitlementStore.canUse(.autoRecording) {
                appModel.settingsStore.autoStartRemindersEnabled = false
                lockedProFeature = .autoRecording
            } else {
                appModel.settingsStore.autoStartRemindersEnabled = isEnabled
                appModel.saveSettings(to: modelContext)
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
                appModel.saveSettings(to: modelContext)
            }
        }
    }

    private var weeklyDistanceGoalBinding: Binding<Double> {
        Binding {
            appModel.settingsStore.weeklyDistanceGoalMeters
        } set: { value in
            guard appModel.entitlementStore.canUse(.goals) else {
                lockedProFeature = .goals
                return
            }
            appModel.settingsStore.weeklyDistanceGoalMeters = min(max(value, 1_000), 200_000)
            appModel.saveSettings(to: modelContext)
        }
    }

    private var monthlyWorkoutGoalBinding: Binding<Int> {
        Binding {
            appModel.settingsStore.monthlyWorkoutGoalCount
        } set: { value in
            guard appModel.entitlementStore.canUse(.goals) else {
                lockedProFeature = .goals
                return
            }
            appModel.settingsStore.monthlyWorkoutGoalCount = min(max(value, 1), 100)
            appModel.saveSettings(to: modelContext)
        }
    }

    private var mapStyleBinding: Binding<PathTrioMapStyle> {
        Binding {
            appModel.settingsStore.preferredMapStyle
        } set: { style in
            if style != .standard && !appModel.entitlementStore.canUse(.mapStyles) {
                appModel.settingsStore.preferredMapStyle = .standard
                lockedProFeature = .mapStyles
            } else {
                appModel.settingsStore.preferredMapStyle = style
            }
            appModel.saveSettings(to: modelContext)
        }
    }

    private var healthSyncBinding: Binding<Bool> {
        Binding {
            appModel.settingsStore.healthKitSyncEnabled
        } set: { isEnabled in
            if isEnabled {
                guard appModel.entitlementStore.canUse(.advancedHealthSync) else {
                    appModel.settingsStore.healthKitSyncEnabled = false
                    lockedProFeature = .advancedHealthSync
                    appModel.saveSettings(to: modelContext)
                    return
                }
                isConfirmingHealthSync = true
            } else {
                appModel.settingsStore.healthKitSyncEnabled = false
                appModel.saveSettings(to: modelContext)
            }
        }
    }
}

private struct GoalSettingsRows: View {
    @Binding var weeklyDistanceGoalMeters: Double
    @Binding var monthlyWorkoutGoalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(value: $weeklyDistanceGoalMeters, in: 1_000...200_000, step: 1_000) {
                SettingsValueRow(
                    titleKey: "goals.weeklyDistance",
                    value: WorkoutMetricsFormatter.distance(weeklyDistanceGoalMeters),
                    systemImage: "target"
                )
            }

            SettingsDivider()

            Stepper(value: $monthlyWorkoutGoalCount, in: 1...100, step: 1) {
                SettingsValueRow(
                    titleKey: "goals.monthlyWorkouts",
                    value: "\(monthlyWorkoutGoalCount)",
                    systemImage: "calendar.badge.checkmark"
                )
            }
        }
    }
}

private struct ProSettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Binding var weeklyDistanceGoalMeters: Double
    @Binding var monthlyWorkoutGoalCount: Int
    @Binding var mapStyle: PathTrioMapStyle
    let purchase: (Product) -> Void

    var body: some View {
        ZStack {
            PathTrioTheme.pageBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SettingsPanel(titleKey: "pro.title", systemImage: "crown") {
                        ProStatusCard(isUnlocked: appModel.entitlementStore.isProUnlocked)

                        if !appModel.entitlementStore.isProUnlocked {
                            SettingsDivider()
                            ProPurchaseOptions(
                                products: appModel.entitlementStore.availableProducts,
                                state: appModel.entitlementStore.purchaseState,
                                purchase: purchase,
                                restore: {
                                    Task {
                                        await appModel.entitlementStore.restorePurchases()
                                    }
                                },
                                errorMessage: appModel.entitlementStore.lastErrorMessage
                            )
                        }
                    }

                    SettingsPanel(titleKey: "pro.controls.title", systemImage: "slider.horizontal.3") {
                        if appModel.entitlementStore.isProUnlocked {
                            GoalSettingsRows(
                                weeklyDistanceGoalMeters: $weeklyDistanceGoalMeters,
                                monthlyWorkoutGoalCount: $monthlyWorkoutGoalCount
                            )
                            SettingsDivider()
                            MapStylePicker(selection: $mapStyle)
                            SettingsDivider()
                            AppleWatchSupportStatusRow(status: appModel.appleWatchSupportService.status)
                        } else {
                            ProControlsLockedRows()
                        }
                    }

                    SettingsPanel(titleKey: "pro.features.title", systemImage: "sparkles") {
                        ForEach(ProFeature.allCases) { feature in
                            ProFeatureRow(feature: feature, isUnlocked: appModel.entitlementStore.canUse(feature))
                            if feature != ProFeature.allCases.last {
                                SettingsDivider()
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .task {
            if appModel.entitlementStore.canUse(.appleWatch) {
                appModel.appleWatchSupportService.activate()
            }
            appModel.appleWatchSupportService.publishProStatus(isUnlocked: appModel.entitlementStore.canUse(.appleWatch))
        }
    }
}

private struct ProSettingsNavigationRow: View {
    let isUnlocked: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: isUnlocked ? "crown.fill" : "crown")
                .font(.title3.weight(.bold))
                .foregroundStyle(PathTrioTheme.warm)
                .frame(width: 42, height: 42)
                .background(PathTrioTheme.warm.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(isUnlocked ? "pro.status.unlocked.title" : "pro.status.free.title")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(PathTrioTheme.ink)
                    if !isUnlocked {
                        Text("pro.badge")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(PathTrioTheme.warm)
                    }
                }

                Text("pro.settings.entry.message")
                    .font(.footnote)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)
        }
        .contentShape(Rectangle())
    }
}

private struct MapStylePicker: View {
    @Binding var selection: PathTrioMapStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("map.style.title", systemImage: "map")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PathTrioTheme.ink)

            Picker("map.style.title", selection: $selection) {
                ForEach(PathTrioMapStyle.allCases) { style in
                    Text(L10n.string(style.titleKey)).tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct SettingsValueRow: View {
    let titleKey: LocalizedStringKey
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Label(titleKey, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PathTrioTheme.ink)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(PathTrioTheme.action)
                .monospacedDigit()
        }
    }
}

private struct ProControlsLockedRows: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LockedControlRow(feature: .goals)
            SettingsDivider()
            LockedControlRow(feature: .mapStyles)
            SettingsDivider()
            LockedControlRow(feature: .dataExport)
            SettingsDivider()
            LockedControlRow(feature: .appleWatch)
        }
    }
}

private struct AppleWatchSupportStatusRow: View {
    let status: AppleWatchSupportStatus

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status.systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
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
        status == .ready ? PathTrioTheme.teal : PathTrioTheme.warm
    }
}

private struct LockedControlRow: View {
    let feature: ProFeature

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: feature.systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.warm)
                .frame(width: 30, height: 30)
                .background(PathTrioTheme.warm.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.string(feature.titleKey))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                Text(L10n.string(feature.messageKey))
                    .font(.footnote)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
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

private struct HealthFrameworkDisclosureRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("settings.health.frameworks.title", systemImage: "heart.text.square")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)

            VStack(alignment: .leading, spacing: 8) {
                DisclosureLine(textKey: "settings.health.frameworks.healthKit", systemImage: "heart.fill", tint: .red)
                DisclosureLine(textKey: "settings.health.frameworks.privacy", systemImage: "lock.shield", tint: PathTrioTheme.teal)
            }
        }
        .padding(12)
        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DisclosureLine: View {
    let textKey: LocalizedStringKey
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 18, height: 18)
            Text(textKey)
                .font(.footnote)
                .foregroundStyle(PathTrioTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
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
    var accessoryKey: LocalizedStringKey? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 8) {
                Label(titleKey, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.ink)
                    .labelStyle(.titleAndIcon)

                if let accessoryKey {
                    Text(accessoryKey)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(PathTrioTheme.warm)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(PathTrioTheme.warm.opacity(0.12), in: Capsule())
                }
            }
        }
        .tint(PathTrioTheme.action)
    }
}

private struct ProStatusCard: View {
    let isUnlocked: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: isUnlocked ? "crown.fill" : "crown")
                .font(.title3.weight(.bold))
                .foregroundStyle(PathTrioTheme.warm)
                .frame(width: 42, height: 42)
                .background(PathTrioTheme.warm.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(isUnlocked ? "pro.status.unlocked.title" : "pro.status.free.title")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                Text(isUnlocked ? "pro.status.unlocked.message" : "pro.status.free.message")
                    .font(.footnote)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct ProPurchaseOptions: View {
    let products: [Product]
    let state: ProPurchaseState
    let purchase: (Product) -> Void
    let restore: () -> Void
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("pro.products.title")
                .font(.footnote.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)

            if products.isEmpty {
                Text(state == .loading ? "pro.products.loading" : "pro.products.unavailable")
                    .font(.footnote)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(products) { product in
                    Button {
                        purchase(product)
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(product.localizedPathTrioName)
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(PathTrioTheme.ink)
                                Text(product.localizedPathTrioDescription)
                                    .font(.caption)
                                    .foregroundStyle(PathTrioTheme.muted)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Text(product.displayPrice)
                                .font(.footnote.weight(.black))
                                .foregroundStyle(PathTrioTheme.action)
                        }
                        .padding(12)
                        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(state == .purchasing)
                }
            }

            SettingsDivider()

            Button {
                restore()
            } label: {
                HStack(spacing: 10) {
                    Text("pro.products.restore")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(PathTrioTheme.ink)

                    Spacer(minLength: 0)

                    if state == .loading {
                        ProgressView()
                            .tint(PathTrioTheme.action)
                    } else {
                        Text("action.restore")
                            .font(.footnote.weight(.black))
                            .foregroundStyle(PathTrioTheme.warm)
                    }
                }
                .padding(12)
                .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(state == .loading || state == .purchasing)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if state == .purchased {
                Text("pro.products.restored")
                    .font(.caption)
                    .foregroundStyle(PathTrioTheme.teal)
            } else if state == .idle && products.isEmpty {
                Text("pro.products.restore.none")
                    .font(.caption)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private extension Product {
    var localizedPathTrioName: String {
        guard let product = ProProduct(rawValue: id) else {
            return displayName
        }
        return L10n.string(product.titleKey)
    }

    var localizedPathTrioDescription: String {
        guard let product = ProProduct(rawValue: id) else {
            return description
        }
        return L10n.string(product.descriptionKey)
    }
}

private extension ProProduct {
    var titleKey: String {
        switch self {
        case .lifetime: "pro.product.lifetime.title"
        }
    }

    var descriptionKey: String {
        switch self {
        case .lifetime: "pro.product.lifetime.description"
        }
    }
}

private struct ProFeatureRow: View {
    let feature: ProFeature
    let isUnlocked: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: feature.systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isUnlocked ? PathTrioTheme.teal : PathTrioTheme.warm)
                .frame(width: 30, height: 30)
                .background((isUnlocked ? PathTrioTheme.teal : PathTrioTheme.warm).opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(L10n.string(feature.titleKey))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(PathTrioTheme.ink)
                    if !isUnlocked {
                        Text("pro.badge")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(PathTrioTheme.warm)
                    }
                }

                Text(L10n.string(feature.messageKey))
                    .font(.footnote)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
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

private struct SettingsLinkRow: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    let destination: URL
    var fallbackDestination: URL? = nil

    @Environment(\.openURL) private var openURL
    @State private var isChecking = false
    @State private var showUnavailable = false

    var body: some View {
        Button {
            Task {
                isChecking = true
                defer { isChecking = false }

                if await Self.canOpen(destination) {
                    openURL(destination)
                    return
                }
                if let fallback = fallbackDestination, await Self.canOpen(fallback) {
                    openURL(fallback)
                    return
                }
                showUnavailable = true
            }
        } label: {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PathTrioTheme.action)
                        .frame(width: 22, height: 22)
                        .background(PathTrioTheme.action.opacity(0.12), in: Circle())

                    Text(titleKey)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PathTrioTheme.ink)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right.square")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.muted)
            }
                    .contentShape(Rectangle())
                    .padding(.vertical, 1)
        }
        .disabled(isChecking)
        .buttonStyle(.plain)
        .alert("settings.linkUnavailable.title", isPresented: $showUnavailable) {
            Button("action.ok", role: .cancel) {
                showUnavailable = false
            }
        } message: {
            Text("settings.linkUnavailable.message")
        }
    }

    private static func canOpen(_ url: URL) async -> Bool {
        if url.isFileURL {
            return FileManager.default.fileExists(atPath: url.path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 4
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return (200...399).contains(httpResponse.statusCode)
        } catch {
            return false
        }
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(PathTrioTheme.line)
            .frame(height: 1)
    }
}
