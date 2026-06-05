import SwiftData
import SwiftUI

@main
struct PathTrioApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appModel)
        }
        .modelContainer(for: [
            WorkoutSessionModel.self,
            LocationPointModel.self,
            UserSettingsModel.self,
            DailyCheckInModel.self,
            FoodLogModel.self,
            AIUsageModel.self,
        ])
    }
}
