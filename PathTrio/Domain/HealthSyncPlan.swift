import Foundation

enum HealthSyncPlan {
    struct Status: Equatable {
        enum Kind {
            case disabled
            case permissionNeeded
        }

        let kind: Kind
        let titleKey: String
        let messageKey: String
        let systemImage: String
    }

    static let plannedWriteTypeKeys = [
        "health.data.workouts",
        "health.data.walkRunDistance",
        "health.data.cyclingDistance",
        "health.data.activeEnergy"
    ]

    static func status(syncEnabled: Bool) -> Status {
        if syncEnabled {
            return Status(
                kind: .permissionNeeded,
                titleKey: "health.status.permissionNeeded.title",
                messageKey: "health.status.permissionNeeded.message",
                systemImage: "heart.text.square"
            )
        }

        return Status(
            kind: .disabled,
            titleKey: "health.status.off.title",
            messageKey: "health.status.off.message",
            systemImage: "heart.slash"
        )
    }
}
