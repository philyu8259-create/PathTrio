import SwiftUI

enum AppTab: Hashable {
    case today
    case workouts
    case food
    case profile
}

struct AppRootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab

    init() {
        #if DEBUG
        _selectedTab = State(initialValue: ScreenshotDemoData.targetTab ?? .today)
        #else
        _selectedTab = State(initialValue: .today)
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
                openWorkouts: { selectedTab = .workouts },
                openProfile: { selectedTab = .profile }
            )
            .tabItem {
                Label("tab.today", systemImage: "sparkles")
            }
            .tag(AppTab.today)

            WorkoutsView()
                .tabItem {
                    Label("tab.workouts", systemImage: "figure.run")
                }
                .tag(AppTab.workouts)

            FoodView()
                .tabItem {
                    Label("tab.food", systemImage: "fork.knife")
                }
                .tag(AppTab.food)

            ProfileView()
                .tabItem {
                    Label("tab.profile", systemImage: "person.crop.circle")
                }
                .tag(AppTab.profile)
        }
        .tint(PathTrioTheme.action)
        .toolbarBackground(PathTrioTheme.tabBarFill, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
