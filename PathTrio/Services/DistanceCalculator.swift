import CoreLocation
import Foundation

struct DistanceCalculator {
    var maximumHorizontalAccuracy: CLLocationAccuracy = 100
    var maximumSegmentDistance: CLLocationDistance = 500

    func filteredLocations(from locations: [CLLocation]) -> [CLLocation] {
        locations.filter { location in
            location.horizontalAccuracy < 0 || location.horizontalAccuracy <= maximumHorizontalAccuracy
        }
    }

    func totalDistanceMeters(for locations: [CLLocation]) -> Double {
        let filtered = filteredLocations(from: locations)
        guard filtered.count > 1 else { return 0 }

        return zip(filtered, filtered.dropFirst()).reduce(0) { total, pair in
            let segment = pair.0.distance(from: pair.1)
            guard segment <= maximumSegmentDistance else { return total }
            return total + segment
        }
    }
}
