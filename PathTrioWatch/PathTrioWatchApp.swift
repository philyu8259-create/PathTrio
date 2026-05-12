import SwiftUI

@main
struct PathTrioWatchApp: App {
    @StateObject private var connectivityModel = WatchConnectivityModel()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(model: connectivityModel)
                .task {
                    #if DEBUG
                    if WatchScreenshotDemoData.apply(to: connectivityModel) {
                        return
                    }
                    #endif
                    connectivityModel.activate()
                    connectivityModel.requestSnapshot()
                }
        }
    }
}

#if DEBUG
@MainActor
private enum WatchScreenshotDemoData {
    static func apply(to model: WatchConnectivityModel) -> Bool {
        guard ProcessInfo.processInfo.arguments.contains("-PathTrioWatchScreenshotMode") else {
            return false
        }

        model.connectionState = .synced
        model.envelope = envelope(for: argument(after: "-PathTrioWatchScreenshotScene") ?? "active")
        return true
    }

    private static func envelope(for scene: String) -> AppleWatchSyncEnvelope {
        let now = Date().timeIntervalSince1970
        switch scene {
        case "latest":
            return AppleWatchSyncEnvelope(
                isProUnlocked: true,
                latestWorkout: AppleWatchWorkoutSnapshot(
                    id: UUID().uuidString,
                    typeRawValue: "ride",
                    startedAt: now - 7_200,
                    duration: 2_210,
                    distanceMeters: 12_650,
                    averageSpeedMetersPerSecond: 5.72,
                    estimatedCalories: 358
                ),
                updatedAt: now
            )
        case "empty":
            return AppleWatchSyncEnvelope(isProUnlocked: true, updatedAt: now)
        default:
            return AppleWatchSyncEnvelope(
                isProUnlocked: true,
                activeWorkout: AppleWatchWorkoutSnapshot(
                    id: UUID().uuidString,
                    typeRawValue: "run",
                    startedAt: now - 1_580,
                    duration: 1_580,
                    distanceMeters: 5_210,
                    averageSpeedMetersPerSecond: 3.29,
                    estimatedCalories: 340,
                    stateRawValue: "recording",
                    isActive: true
                ),
                updatedAt: now
            )
        }
    }

    private static func argument(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else { return nil }
        return arguments[valueIndex]
    }
}
#endif
