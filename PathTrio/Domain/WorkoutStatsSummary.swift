import Foundation

struct WorkoutStatsSummary: Equatable {
    let periodKey: String
    let workoutCount: Int
    let distanceMeters: Double
    let duration: TimeInterval
    let estimatedCalories: Double
}

struct WorkoutStatsSummaryBuilder {
    func summaries(
        for workouts: [WorkoutSessionModel],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [WorkoutStatsSummary] {
        [
            summary(periodKey: "stats.thisMonth", workouts: filteredWorkouts(in: .month, from: workouts, now: now, calendar: calendar)),
            summary(periodKey: "stats.thisYear", workouts: filteredWorkouts(in: .year, from: workouts, now: now, calendar: calendar)),
            summary(periodKey: "stats.allTime", workouts: workouts)
        ]
    }

    private func filteredWorkouts(
        in component: Calendar.Component,
        from workouts: [WorkoutSessionModel],
        now: Date,
        calendar: Calendar
    ) -> [WorkoutSessionModel] {
        guard let interval = calendar.dateInterval(of: component, for: now) else { return [] }
        return workouts.filter { $0.startedAt >= interval.start && $0.startedAt < interval.end }
    }

    private func summary(periodKey: String, workouts: [WorkoutSessionModel]) -> WorkoutStatsSummary {
        WorkoutStatsSummary(
            periodKey: periodKey,
            workoutCount: workouts.count,
            distanceMeters: workouts.reduce(0) { $0 + $1.distanceMeters },
            duration: workouts.reduce(0) { $0 + $1.duration },
            estimatedCalories: workouts.reduce(0) {
                $0 + ($1.effectiveEstimatedCalories ?? WorkoutCaloriesEstimator.estimate(
                    type: $1.type,
                    duration: $1.duration,
                    bodyWeightKilograms: nil
                ) ?? 0)
            }
        )
    }
}
