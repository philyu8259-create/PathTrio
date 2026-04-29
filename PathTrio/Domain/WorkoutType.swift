import Foundation

enum WorkoutType: String, CaseIterable, Codable, Identifiable {
    case walk
    case run
    case ride

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .walk: L10n.string("workout.walk")
        case .run: L10n.string("workout.run")
        case .ride: L10n.string("workout.ride")
        }
    }

    var systemImage: String {
        switch self {
        case .walk: "figure.walk"
        case .run: "figure.run"
        case .ride: "bicycle"
        }
    }

    var emphasizesPace: Bool {
        self == .walk || self == .run
    }
}
