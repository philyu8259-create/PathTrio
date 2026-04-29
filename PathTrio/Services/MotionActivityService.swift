import CoreMotion
import Foundation
import Observation

@Observable
final class MotionActivityService {
    private let manager = CMMotionActivityManager()
    private let queue = OperationQueue()
    private(set) var detectedActivity: DetectedMotionActivity = .unknown

    var isAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    func start() {
        guard isAvailable else {
            detectedActivity = .unknown
            return
        }

        manager.startActivityUpdates(to: queue) { [weak self] activity in
            guard let activity else { return }
            Task { @MainActor in
                self?.detectedActivity = Self.map(activity)
            }
        }
    }

    func stop() {
        manager.stopActivityUpdates()
    }

    private static func map(_ activity: CMMotionActivity) -> DetectedMotionActivity {
        if activity.automotive { return .automotive }
        if activity.cycling { return .cycling }
        if activity.running { return .running }
        if activity.walking { return .walking }
        if activity.stationary { return .stationary }
        return .unknown
    }
}
