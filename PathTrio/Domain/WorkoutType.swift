import Foundation

enum WorkoutType: String, CaseIterable, Codable, Identifiable {
    case walk
    case run
    case ride

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .walk: "Walk"
        case .run: "Run"
        case .ride: "Ride"
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
