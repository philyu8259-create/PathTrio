import Foundation

enum WorkoutInsightKind: String {
    case starter
    case weeklyProgress
    case consistency
    case dominantType
}

struct WorkoutInsight: Identifiable, Equatable {
    let kind: WorkoutInsightKind
    let titleKey: String
    let messageKey: String
    let value: String?
    let systemImage: String

    var id: String { kind.rawValue }
}

struct WorkoutInsightEngine {
    func insights(
        for workouts: [WorkoutSessionModel],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [WorkoutInsight] {
        guard !workouts.isEmpty else {
            return [
                WorkoutInsight(
                    kind: .starter,
                    titleKey: "insights.starter.title",
                    messageKey: "insights.starter.message",
                    value: nil,
                    systemImage: "sparkles"
                )
            ]
        }

        var insights: [WorkoutInsight] = []
        let currentWeekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let previousWeekStart = calendar.date(byAdding: .day, value: -14, to: now) ?? currentWeekStart
        let currentWeekWorkouts = workouts.filter { $0.startedAt >= currentWeekStart && $0.startedAt <= now }
        let previousWeekWorkouts = workouts.filter { $0.startedAt >= previousWeekStart && $0.startedAt < currentWeekStart }
        let currentDistance = currentWeekWorkouts.reduce(0) { $0 + $1.distanceMeters }
        let previousDistance = previousWeekWorkouts.reduce(0) { $0 + $1.distanceMeters }

        if currentDistance > 0 {
            let value: String
            let messageKey: String
            if previousDistance > 0 {
                let percentChange = ((currentDistance - previousDistance) / previousDistance) * 100
                value = String(format: "%+.0f%%", percentChange)
                messageKey = percentChange >= 0 ? "insights.weeklyProgress.up.message" : "insights.weeklyProgress.down.message"
            } else {
                value = WorkoutMetricsFormatter.distance(currentDistance)
                messageKey = "insights.weeklyProgress.new.message"
            }

            insights.append(
                WorkoutInsight(
                    kind: .weeklyProgress,
                    titleKey: "insights.weeklyProgress.title",
                    messageKey: messageKey,
                    value: value,
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            )
        }

        if let dominantType = dominantWorkoutType(in: workouts) {
            insights.append(
                WorkoutInsight(
                    kind: .dominantType,
                    titleKey: "insights.dominantType.title",
                    messageKey: "insights.dominantType.message",
                    value: dominantType.displayName,
                    systemImage: dominantType.systemImage
                )
            )
        }

        let activeDays = Set(currentWeekWorkouts.map { calendar.startOfDay(for: $0.startedAt) }).count
        if activeDays > 0 {
            insights.append(
                WorkoutInsight(
                    kind: .consistency,
                    titleKey: "insights.consistency.title",
                    messageKey: "insights.consistency.message",
                    value: "\(activeDays)/7",
                    systemImage: "calendar.badge.checkmark"
                )
            )
        }

        return Array(insights.prefix(3))
    }

    private func dominantWorkoutType(in workouts: [WorkoutSessionModel]) -> WorkoutType? {
        let distancesByType = Dictionary(grouping: workouts, by: \.type).mapValues { sessions in
            sessions.reduce(0) { $0 + $1.distanceMeters }
        }

        return distancesByType.max { lhs, rhs in
            lhs.value < rhs.value
        }?.key
    }
}
