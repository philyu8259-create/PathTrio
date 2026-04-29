import CoreLocation
import Foundation

struct RouteRecordingStatus: Equatable {
    enum Kind {
        case info
        case warning
        case blocked
    }

    let kind: Kind
    let titleKey: String
    let messageKey: String
    let systemImage: String

    static func evaluate(
        authorizationStatus: CLAuthorizationStatus,
        latestHorizontalAccuracy: CLLocationAccuracy?,
        latestErrorMessage: String?,
        backgroundRecordingEnabled: Bool
    ) -> RouteRecordingStatus? {
        if latestErrorMessage != nil {
            return RouteRecordingStatus(
                kind: .warning,
                titleKey: "location.status.error.title",
                messageKey: "location.status.error.message",
                systemImage: "exclamationmark.triangle"
            )
        }

        switch authorizationStatus {
        case .denied, .restricted:
            return RouteRecordingStatus(
                kind: .blocked,
                titleKey: "location.status.permissionBlocked.title",
                messageKey: "location.status.permissionBlocked.message",
                systemImage: "location.slash"
            )
        case .notDetermined:
            return RouteRecordingStatus(
                kind: .info,
                titleKey: "location.status.permissionNeeded.title",
                messageKey: "location.status.permissionNeeded.message",
                systemImage: "location"
            )
        case .authorizedWhenInUse:
            if backgroundRecordingEnabled {
                return RouteRecordingStatus(
                    kind: .warning,
                    titleKey: "location.status.backgroundPermission.title",
                    messageKey: "location.status.backgroundPermission.message",
                    systemImage: "lock.open.trianglebadge.exclamationmark"
                )
            }
        case .authorizedAlways:
            break
        @unknown default:
            return nil
        }

        if let latestHorizontalAccuracy, latestHorizontalAccuracy > 65 {
            return RouteRecordingStatus(
                kind: .warning,
                titleKey: "location.status.weakSignal.title",
                messageKey: "location.status.weakSignal.message",
                systemImage: "dot.radiowaves.left.and.right"
            )
        }

        if backgroundRecordingEnabled {
            return RouteRecordingStatus(
                kind: .info,
                titleKey: "location.status.background.title",
                messageKey: "location.status.background.message",
                systemImage: "battery.75percent"
            )
        }

        return nil
    }
}
