import Foundation

enum AchievementMetric {
    case totalWorkouts
    case currentStreak
    case longestStreak
}

enum AchievementKind: String, CaseIterable {
    case firstWorkout
    case steadyStarter
    case weekWarmup
    case weekWarrior
}

struct AchievementDefinition {
    let kind: AchievementKind
    let threshold: Int
    let titleKey: String
    let detailKey: String
    let systemImage: String
    let metric: AchievementMetric
}

struct AchievementCardModel: Identifiable, Equatable {
    let kind: AchievementKind
    let titleKey: String
    let detailKey: String
    let systemImage: String
    let threshold: Int
    let currentValue: Int
    let isUnlocked: Bool
    let isNewlyUnlocked: Bool

    var id: String { kind.rawValue }
    var progress: Double {
        guard threshold > 0 else { return 0 }
        return min(max(Double(currentValue) / Double(threshold), 0), 1)
    }

    init(
        definition: AchievementDefinition,
        currentValue: Int,
        isNewlyUnlocked: Bool = false
    ) {
        self.kind = definition.kind
        self.titleKey = definition.titleKey
        self.detailKey = definition.detailKey
        self.systemImage = definition.systemImage
        self.threshold = definition.threshold
        self.currentValue = currentValue
        self.isUnlocked = currentValue >= definition.threshold
        self.isNewlyUnlocked = isNewlyUnlocked
    }
}
