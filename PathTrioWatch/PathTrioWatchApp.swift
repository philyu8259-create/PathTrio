import SwiftUI

@main
struct PathTrioWatchApp: App {
    @StateObject private var connectivityModel = WatchConnectivityModel()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(model: connectivityModel)
                .task {
                    connectivityModel.activate()
                    connectivityModel.requestSnapshot()
                }
        }
    }
}
