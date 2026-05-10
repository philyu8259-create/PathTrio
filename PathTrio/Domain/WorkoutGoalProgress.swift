import Foundation

struct WorkoutGoalProgress: Equatable {
    let titleKey: String
    let value: String
    let target: String
    let progress: Double
    let systemImage: String
}

struct WorkoutGoalProgressCalculator {
    func progress(
        for workouts: [WorkoutSessionModel],
        weeklyDistanceGoalMeters: Double,
        monthlyWorkoutGoalCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [WorkoutGoalProgress] {
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
        let monthInterval = calendar.dateInterval(of: .month, for: now)

        let weeklyDistance = workouts
            .filter { workout in
                guard let weekInterval else { return false }
                return workout.startedAt >= weekInterval.start && workout.startedAt < weekInterval.end
            }
            .reduce(0) { $0 + $1.distanceMeters }

        let monthlyCount = workouts
            .filter { workout in
                guard let monthInterval else { return false }
                return workout.startedAt >= monthInterval.start && workout.startedAt < monthInterval.end
            }
            .count

        return [
            WorkoutGoalProgress(
                titleKey: "goals.weeklyDistance",
                value: WorkoutMetricsFormatter.distance(weeklyDistance),
                target: WorkoutMetricsFormatter.distance(weeklyDistanceGoalMeters),
                progress: clampedProgress(current: weeklyDistance, target: weeklyDistanceGoalMeters),
                systemImage: "target"
            ),
            WorkoutGoalProgress(
                titleKey: "goals.monthlyWorkouts",
                value: "\(monthlyCount)",
                target: "\(monthlyWorkoutGoalCount)",
                progress: clampedProgress(current: Double(monthlyCount), target: Double(monthlyWorkoutGoalCount)),
                systemImage: "calendar.badge.checkmark"
            )
        ]
    }

    private func clampedProgress(current: Double, target: Double) -> Double {
        guard target > 0, current.isFinite, target.isFinite else { return 0 }
        return min(max(current / target, 0), 1)
    }
}
