import SwiftUI

enum AppTab: Hashable {
    case home
    case history
    case settings
}

struct AppRootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .home

    var body: some View {
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
        .task {
            appModel.loadSettings(from: modelContext)
            #if DEBUG
            ScreenshotDemoData.prepare(appModel: appModel, context: modelContext)
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
}
