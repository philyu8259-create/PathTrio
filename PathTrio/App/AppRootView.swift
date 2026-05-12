import SwiftUI

enum AppTab: Hashable {
    case home
    case history
    case settings
}

struct AppRootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab

    init() {
        #if DEBUG
        _selectedTab = State(initialValue: ScreenshotDemoData.targetTab ?? .home)
        #else
        _selectedTab = State(initialValue: .home)
        #endif
    }

    var body: some View {
        rootContent
            .task {
                appModel.loadSettings(from: modelContext)
                #if DEBUG
                ScreenshotDemoData.prepare(appModel: appModel, context: modelContext)
                if ScreenshotDemoData.shouldOpenActiveWorkout {
                    appModel.selectedWorkoutType = .run
                    let draft = ScreenshotDemoData.activeWorkoutDraft()
                    _ = appModel.recorder.start(type: draft.type, at: draft.startedAt)
                    appModel.activeDraft = appModel.recorder.addLocations(draft.locations, now: Date()) ?? draft
                }
                #endif
                #if DEBUG
                if ScreenshotDemoData.isEnabled {
                    appModel.entitlementStore.isProUnlocked = true
                } else {
                    await appModel.entitlementStore.refreshPurchasedEntitlements()
                }
                #else
                await appModel.entitlementStore.refreshPurchasedEntitlements()
                #endif
                #if DEBUG
                ScreenshotDemoData.prepare(appModel: appModel, context: modelContext)
                #endif
                appModel.reconcileLockedProSettings(in: modelContext)
                if appModel.entitlementStore.canUse(.appleWatch) {
                    appModel.appleWatchSupportService.activate()
                }
                appModel.appleWatchSupportService.publishProStatus(isUnlocked: appModel.entitlementStore.canUse(.appleWatch))
            }
            .onChange(of: appModel.entitlementStore.isProUnlocked) { _, isProUnlocked in
                appModel.reconcileLockedProSettings(in: modelContext)
                if isProUnlocked {
                    appModel.appleWatchSupportService.activate()
                }
                appModel.appleWatchSupportService.publishProStatus(isUnlocked: isProUnlocked)
            }
    }

    @ViewBuilder
    private var rootContent: some View {
        #if DEBUG
        if ScreenshotDemoData.shouldOpenActiveWorkout {
            ActiveWorkoutView()
        } else {
            tabContent
        }
        #else
        tabContent
        #endif
    }

    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                openHistory: { selectedTab = .history }
            )
            .tabItem {
                Label("tab.home", systemImage: "figure.walk")
            }
            .tag(AppTab.home)

            HistoryView(showsDoneButton: false)
                .tabItem {
                    Label("tab.history", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppTab.history)

            SettingsView(showsDoneButton: false)
                .tabItem {
                    Label("tab.settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(PathTrioTheme.action)
        .toolbarBackground(PathTrioTheme.pageBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
