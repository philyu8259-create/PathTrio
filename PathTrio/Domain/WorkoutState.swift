import Foundation

enum WorkoutState: Equatable {
    case idle
    case recording
    case paused
    case autoPaused
    case ended
}
