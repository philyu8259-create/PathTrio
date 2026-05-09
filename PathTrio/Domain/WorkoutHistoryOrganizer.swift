import Foundation

enum WorkoutHistoryGrouping: String, CaseIterable, Identifiable {
    case day
    case month

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .day: "history.group.day"
        case .month: "history.group.month"
        }
    }
}

enum WorkoutTypeFilter: String, CaseIterable, Identifiable {
    case all
    case walk
    case run
    case ride

    var id: String { rawValue }

    var workoutType: WorkoutType? {
        switch self {
        case .all: nil
        case .walk: .walk
        case .run: .run
        case .ride: .ride
        }
    }

    var titleKey: String {
        switch self {
        case .all: "history.filter.all"
        case .walk: "workout.walk"
        case .run: "workout.run"
        case .ride: "workout.ride"
        }
    }
}

struct WorkoutHistorySection: Identifiable, Equatable {
    let startDate: Date
    let workouts: [WorkoutSessionModel]
    let totalDistanceMeters: Double
    let totalDuration: TimeInterval

    var id: Date { startDate }
}

struct WorkoutHistoryOrganizer {
    func sections(
        for workouts: [WorkoutSessionModel],
        grouping: WorkoutHistoryGrouping,
        filter: WorkoutTypeFilter,
        calendar: Calendar = .current
    ) -> [WorkoutHistorySection] {
        let filteredWorkouts = workouts.filter { workout in
            guard let workoutType = filter.workoutType else { return true }
            return workout.type == workoutType
        }

        let grouped = Dictionary(grouping: filteredWorkouts) { workout in
            sectionStartDate(for: workout.startedAt, grouping: grouping, calendar: calendar)
        }

        return grouped.map { startDate, workouts in
            let sortedWorkouts = workouts.sorted { $0.startedAt > $1.startedAt }
            return WorkoutHistorySection(
                startDate: startDate,
                workouts: sortedWorkouts,
                totalDistanceMeters: sortedWorkouts.reduce(0) { $0 + $1.distanceMeters },
                totalDuration: sortedWorkouts.reduce(0) { $0 + $1.duration }
            )
        }
        .sorted { $0.startDate > $1.startDate }
    }

    private func sectionStartDate(for date: Date, grouping: WorkoutHistoryGrouping, calendar: Calendar) -> Date {
        switch grouping {
        case .day:
            calendar.startOfDay(for: date)
        case .month:
            calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? calendar.startOfDay(for: date)
        }
    }
}
