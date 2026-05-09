import CoreLocation
import Foundation

struct DistanceCalculator {
    var maximumHorizontalAccuracy: CLLocationAccuracy = 65
    var minimumMovementDistance: CLLocationDistance = 8
    var maximumSegmentDistance: CLLocationDistance = 500
    var maximumSegmentSpeedMetersPerSecond: CLLocationSpeed = 35

    func filteredLocations(from locations: [CLLocation]) -> [CLLocation] {
        locations.filter { location in
            CLLocationCoordinate2DIsValid(location.coordinate)
                && location.horizontalAccuracy >= 0
                && location.horizontalAccuracy <= maximumHorizontalAccuracy
        }
    }

    func cleanedLocations(from locations: [CLLocation]) -> [CLLocation] {
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
            guard segment >= movementThreshold(from: previous, to: location) else { continue }

            let timeDelta = location.timestamp.timeIntervalSince(previous.timestamp)
            if timeDelta > 0, segment / timeDelta > maximumSegmentSpeedMetersPerSecond {
                continue
            }

            cleaned.append(location)
        }

        return cleaned
    }

    func totalDistanceMeters(for locations: [CLLocation]) -> Double {
        let cleaned = cleanedLocations(from: locations)
        guard cleaned.count > 1 else { return 0 }

        return zip(cleaned, cleaned.dropFirst()).reduce(0) { total, pair in
            let segment = pair.0.distance(from: pair.1)
            return total + segment
        }
    }

    private func movementThreshold(from previous: CLLocation, to location: CLLocation) -> CLLocationDistance {
        let accuracyBasedThreshold = max(previous.horizontalAccuracy, location.horizontalAccuracy) * 0.6
        return max(minimumMovementDistance, min(25, accuracyBasedThreshold))
    }
}
