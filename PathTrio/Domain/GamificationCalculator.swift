import Foundation

struct DailyCheckInRecord: Hashable {
    let date: Date
    let workoutCount: Int
    let streakShieldCount: Int

    var hasWorkout: Bool { workoutCount > 0 }
}

enum TrioPalState: String {
    case resting
    case warmUp
    case steady
    case blazing
    case protected

    var labelKey: String {
        switch self {
        case .resting:
            return "gamification.trioPal.state.resting"
        case .warmUp:
            return "gamification.trioPal.state.warmUp"
        case .steady:
            return "gamification.trioPal.state.steady"
        case .blazing:
            return "gamification.trioPal.state.blazing"
        case .protected:
            return "gamification.trioPal.state.protected"
        }
    }

    var systemImage: String {
        switch self {
        case .resting:
            return "moon"
        case .warmUp:
            return "figure.walk.motion"
        case .steady:
            return "flame"
        case .blazing:
            return "flame.fill"
        case .protected:
            return "shield.fill"
        }
    }
}

struct StreakComputation {
    let currentStreak: Int
    let longestStreak: Int
    let wasProtectedToday: Bool
}

struct GamificationSnapshot: Equatable {
    let totalWorkouts: Int
    let currentStreak: Int
    let longestStreak: Int
    let availableShields: Int
    let wasProtectedToday: Bool
    let trioPalState: TrioPalState
}

struct GamificationCalculator {
    func snapshot(
        from checkIns: [DailyCheckInRecord],
        at referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> GamificationSnapshot {
        let normalized = checkIns.map {
            DailyCheckInRecord(
                date: dayStart(for: $0.date, calendar: calendar),
                workoutCount: $0.workoutCount,
                streakShieldCount: $0.streakShieldCount
            )
        }

        let totalWorkouts = normalized.reduce(0) { $0 + max($1.workoutCount, 0) }
        let streak = streakComputation(from: normalized, at: referenceDate, calendar: calendar)
        let totalShields = normalized.reduce(0) { $0 + max($1.streakShieldCount, 0) }

        return GamificationSnapshot(
            totalWorkouts: totalWorkouts,
            currentStreak: streak.currentStreak,
            longestStreak: streak.longestStreak,
            availableShields: totalShields,
            wasProtectedToday: streak.wasProtectedToday,
            trioPalState: trioPalState(for: totalWorkouts, streak: streak)
        )
    }

    func streakComputation(
        from checkIns: [DailyCheckInRecord],
        at referenceDate: Date,
        calendar: Calendar = .current
    ) -> StreakComputation {
        guard !checkIns.isEmpty else {
            return StreakComputation(currentStreak: 0, longestStreak: 0, wasProtectedToday: false)
        }

        let normalized = checkIns.map {
            DailyCheckInRecord(
                date: dayStart(for: $0.date, calendar: calendar),
                workoutCount: $0.workoutCount,
                streakShieldCount: $0.streakShieldCount
            )
        }
        let records: [Date: DailyCheckInRecord] = normalized.reduce(into: [:]) { result, record in
            if let existing = result[record.date] {
                result[record.date] = DailyCheckInRecord(
                    date: record.date,
                    workoutCount: existing.workoutCount + record.workoutCount,
                    streakShieldCount: max(existing.streakShieldCount, record.streakShieldCount)
                )
                return
            }
            result[record.date] = record
        }

        return StreakComputation(
            currentStreak: computeCurrentStreak(from: records, at: referenceDate, calendar: calendar),
            longestStreak: computeLongestStreak(from: records, calendar: calendar),
            wasProtectedToday: wasCurrentStreakProtected(from: records, at: referenceDate, calendar: calendar)
        )
    }

    func wasCurrentStreakProtected(
        from records: [Date: DailyCheckInRecord],
        at referenceDate: Date,
        calendar: Calendar = .current
    ) -> Bool {
        var cursor = dayStart(for: referenceDate, calendar: calendar)
        var shieldBalance = 0
        var daysChecked = 0

        while daysChecked < 370 {
            if let checkIn = records[cursor] {
                shieldBalance += max(checkIn.streakShieldCount, 0)

                if checkIn.hasWorkout {
                    guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { return false }
                    cursor = previous
                    daysChecked += 1
                    continue
                }

                return shieldBalance > 0
            }

            return shieldBalance > 0
        }
        return false
    }

    private func computeCurrentStreak(
        from records: [Date: DailyCheckInRecord],
        at referenceDate: Date,
        calendar: Calendar = .current
    ) -> Int {
        var streak = 0
        var shieldBalance = 0
        var cursor = dayStart(for: referenceDate, calendar: calendar)
        var daysChecked = 0

        while daysChecked < 370 {
            if let checkIn = records[cursor] {
                shieldBalance += max(checkIn.streakShieldCount, 0)
                if checkIn.hasWorkout {
                    streak += 1
                } else if shieldBalance > 0 {
                    shieldBalance -= 1
                } else {
                    break
                }
            } else if shieldBalance > 0 {
                shieldBalance -= 1
            } else {
                break
            }

            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
            daysChecked += 1
        }

        return streak
    }

    private func computeLongestStreak(from records: [Date: DailyCheckInRecord], calendar: Calendar = .current) -> Int {
        let workoutDays = records.keys.sorted()
        guard let first = workoutDays.first, let last = workoutDays.last else { return 0 }

        var longest = 0
        var cursor = first
        var steps = 0

        while cursor <= last && steps <= 5_000 {
            let streak = computeCurrentStreak(from: records, at: cursor, calendar: calendar)
            longest = max(longest, streak)

            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            steps += 1
        }

        return longest
    }

    private func trioPalState(for totalWorkouts: Int, streak: StreakComputation) -> TrioPalState {
        guard totalWorkouts > 0 else { return .resting }

        if streak.currentStreak >= 7 {
            return .blazing
        }
        if streak.wasProtectedToday {
            return .protected
        }
        if streak.currentStreak >= 3 {
            return .steady
        }
        return .warmUp
    }

    private func dayStart(for date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }
}
