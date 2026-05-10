import SwiftUI

enum AppTab: Hashable {
    case home
    case history
    case settings
}

struct AppRootView: View {
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
    }
}
