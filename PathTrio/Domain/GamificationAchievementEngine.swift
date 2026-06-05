import Foundation

struct GamificationAchievementEngine {
    var definitions: [AchievementDefinition] {
        [
            AchievementDefinition(
                kind: .firstWorkout,
                threshold: 1,
                titleKey: "achievement.firstWorkout.title",
                detailKey: "achievement.firstWorkout.detail",
                systemImage: "figure.walk",
                metric: .totalWorkouts
            ),
            AchievementDefinition(
                kind: .steadyStarter,
                threshold: 3,
                titleKey: "achievement.steadyStarter.title",
                detailKey: "achievement.steadyStarter.detail",
                systemImage: "flame",
                metric: .currentStreak
            ),
            AchievementDefinition(
                kind: .weekWarmup,
                threshold: 5,
                titleKey: "achievement.weekWarmup.title",
                detailKey: "achievement.weekWarmup.detail",
                systemImage: "figure.walk.circle",
                metric: .totalWorkouts
            ),
            AchievementDefinition(
                kind: .weekWarrior,
                threshold: 7,
                titleKey: "achievement.weekWarrior.title",
                detailKey: "achievement.weekWarrior.detail",
                systemImage: "rosette",
                metric: .currentStreak
            )
        ]
    }

    func cards(for snapshot: GamificationSnapshot) -> [AchievementCardModel] {
        definitions.map { definition in
            AchievementCardModel(
                definition: definition,
                currentValue: value(for: definition.metric, snapshot: snapshot)
            )
        }
    }

    func newlyUnlockedCards(
        before previousSnapshot: GamificationSnapshot,
        after currentSnapshot: GamificationSnapshot
    ) -> [AchievementCardModel] {
        let definitionLookup = Dictionary(uniqueKeysWithValues: definitions.map { ($0.kind, $0) })
        let previouslyUnlocked = unlockedKinds(for: previousSnapshot)
        return cards(for: currentSnapshot)
            .filter { card in
                card.isUnlocked && !previouslyUnlocked.contains(card.kind)
            }
            .compactMap { card in
                guard let definition = definitionLookup[card.kind] else { return nil }
                return AchievementCardModel(
                    definition: definition,
                    currentValue: card.currentValue,
                    isNewlyUnlocked: true
                )
            }
    }

    private func unlockedKinds(for snapshot: GamificationSnapshot) -> Set<AchievementKind> {
        Set(
            cards(for: snapshot)
                .filter(\.isUnlocked)
                .map(\.kind)
        )
    }

    private func value(for metric: AchievementMetric, snapshot: GamificationSnapshot) -> Int {
        switch metric {
        case .totalWorkouts:
            return snapshot.totalWorkouts
        case .currentStreak:
            return snapshot.currentStreak
        case .longestStreak:
            return snapshot.longestStreak
        }
    }
}
