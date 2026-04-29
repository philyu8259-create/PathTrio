import SwiftUI

@main
struct PathTrioApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appModel)
        }
    }
}
