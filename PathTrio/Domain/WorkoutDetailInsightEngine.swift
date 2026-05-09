import Foundation

enum WorkoutDetailInsightKind: String {
    case effort
    case route
    case energy
}

struct WorkoutDetailInsight: Identifiable, Equatable {
    let kind: WorkoutDetailInsightKind
    let titleKey: String
    let messageKey: String
    let value: String
    let systemImage: String

    var id: String { kind.rawValue }
}

struct WorkoutDetailInsightEngine {
    func insights(for workout: WorkoutSessionModel) -> [WorkoutDetailInsight] {
        var insights: [WorkoutDetailInsight] = []
        insights.append(effortInsight(for: workout))
        insights.append(routeInsight(for: workout))

        if let energyInsight = energyInsight(for: workout) {
            insights.append(energyInsight)
        }

        return insights
    }

    private func effortInsight(for workout: WorkoutSessionModel) -> WorkoutDetailInsight {
        let usesPace = workout.type.emphasizesPace
        let value = usesPace
            ? WorkoutMetricsFormatter.pace(paceSecondsPerKilometer(for: workout))
            : WorkoutMetricsFormatter.speed(workout.averageSpeedMetersPerSecond)

        return WorkoutDetailInsight(
            kind: .effort,
            titleKey: usesPace ? "detail.insights.effort.pace.title" : "detail.insights.effort.speed.title",
            messageKey: usesPace ? "detail.insights.effort.pace.message" : "detail.insights.effort.speed.message",
            value: value,
            systemImage: usesPace ? "gauge.with.dots.needle.50percent" : "speedometer"
        )
    }

    private func routeInsight(for workout: WorkoutSessionModel) -> WorkoutDetailInsight {
        let routePointCount = workout.locations.count
        return WorkoutDetailInsight(
            kind: .route,
            titleKey: "detail.insights.route.title",
            messageKey: routePointCount > 1 ? "detail.insights.route.tracked.message" : "detail.insights.route.empty.message",
            value: "\(routePointCount)",
            systemImage: routePointCount > 1 ? "point.topleft.down.curvedto.point.bottomright.up" : "location.slash"
        )
    }

    private func energyInsight(for workout: WorkoutSessionModel) -> WorkoutDetailInsight? {
        let calories = workout.estimatedCalories ?? WorkoutCaloriesEstimator.estimate(
            type: workout.type,
            duration: workout.duration,
            bodyWeightKilograms: nil
        )
        guard let calories, calories.isFinite, calories > 0 else { return nil }

        return WorkoutDetailInsight(
            kind: .energy,
            titleKey: "detail.insights.energy.title",
            messageKey: "detail.insights.energy.message",
            value: WorkoutMetricsFormatter.calories(calories),
            systemImage: "flame"
        )
    }

    private func paceSecondsPerKilometer(for workout: WorkoutSessionModel) -> Double? {
        guard workout.distanceMeters > 0 else { return nil }
        return workout.duration / (workout.distanceMeters / 1_000)
    }
}
