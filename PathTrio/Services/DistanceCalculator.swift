import CoreLocation
import Foundation

struct DistanceCalculator {
    var maximumHorizontalAccuracy: CLLocationAccuracy = 65
    var minimumMovementDistance: CLLocationDistance = 8
    var maximumSegmentDistance: CLLocationDistance = 500
    var maximumSegmentSpeedMetersPerSecond: CLLocationSpeed = 22

    func filteredLocations(from locations: [CLLocation]) -> [CLLocation] {
        locations.filter { location in
            CLLocationCoordinate2DIsValid(location.coordinate)
                && location.horizontalAccuracy >= 0
                && location.horizontalAccuracy <= maximumHorizontalAccuracy
        }
    }

    func cleanedLocations(from locations: [CLLocation], for type: WorkoutType = .walk) -> [CLLocation] {
        let filtered = filteredLocations(from: locations)
        guard let first = filtered.first else { return [] }

        var cleaned = [first]

        for location in filtered.dropFirst() {
            guard let previous = cleaned.last else {
                cleaned.append(location)
                continue
            }

            let segment = previous.distance(from: location)
            guard segment <= maximumSegmentDistance else { continue }
            guard segment >= movementThreshold(from: previous, to: location, type: type) else { continue }

            let timeDelta = location.timestamp.timeIntervalSince(previous.timestamp)
            if timeDelta > 0, segment / timeDelta > maximumSegmentSpeed(for: type) {
                continue
            }

            if isLikelyStationaryDrift(from: previous, to: location, segment: segment, type: type) {
                continue
            }

            cleaned.append(location)
        }

        return cleaned
    }

    func totalDistanceMeters(for locations: [CLLocation], type: WorkoutType = .walk) -> Double {
        let cleaned = cleanedLocations(from: locations, for: type)
        guard cleaned.count > 1 else { return 0 }

        return zip(cleaned, cleaned.dropFirst()).reduce(0) { total, pair in
            let segment = pair.0.distance(from: pair.1)
            return total + segment
        }
    }

    private func movementThreshold(from previous: CLLocation, to location: CLLocation, type: WorkoutType) -> CLLocationDistance {
        let combinedAccuracyThreshold = (previous.horizontalAccuracy + location.horizontalAccuracy) * movementAccuracyMultiplier(for: type)
        return max(minimumMovementDistance(for: type), min(45, combinedAccuracyThreshold))
    }

    private func minimumMovementDistance(for type: WorkoutType) -> CLLocationDistance {
        switch type {
        case .walk:
            max(minimumMovementDistance, 10)
        case .run:
            max(minimumMovementDistance, 12)
        case .ride:
            max(minimumMovementDistance, 16)
        }
    }

    private func movementAccuracyMultiplier(for type: WorkoutType) -> Double {
        switch type {
        case .walk, .run:
            1.1
        case .ride:
            0.9
        }
    }

    private func maximumSegmentSpeed(for type: WorkoutType) -> CLLocationSpeed {
        switch type {
        case .walk:
            min(maximumSegmentSpeedMetersPerSecond, 4.5)
        case .run:
            min(maximumSegmentSpeedMetersPerSecond, 8.5)
        case .ride:
            maximumSegmentSpeedMetersPerSecond
        }
    }

    private func minimumReliableSpeed(for type: WorkoutType) -> CLLocationSpeed {
        switch type {
        case .walk:
            0.35
        case .run:
            0.7
        case .ride:
            1.2
        }
    }

    private func isLikelyStationaryDrift(
        from previous: CLLocation,
        to location: CLLocation,
        segment: CLLocationDistance,
        type: WorkoutType
    ) -> Bool {
        let validSpeeds = [previous.speed, location.speed].filter { $0 >= 0 }
        guard !validSpeeds.isEmpty else { return false }

        let fastestReportedSpeed = validSpeeds.max() ?? -1
        guard fastestReportedSpeed < minimumReliableSpeed(for: type) else { return false }

        if previous.speed >= 0, location.speed >= 0 {
            return true
        }

        let driftEnvelope = max(35, (previous.horizontalAccuracy + location.horizontalAccuracy) * 2.0)
        return segment <= driftEnvelope
    }
}
