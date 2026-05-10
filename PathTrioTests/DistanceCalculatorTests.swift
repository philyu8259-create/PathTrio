import CoreLocation
import XCTest
@testable import PathTrio

final class DistanceCalculatorTests: XCTestCase {
    func testCalculatesDistanceBetweenAccuratePoints() {
        let calculator = DistanceCalculator()
        let start = Date(timeIntervalSince1970: 100)
        let points = [
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: start),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7759, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: start.addingTimeInterval(60))
        ]

        let distance = calculator.totalDistanceMeters(for: points)

        XCTAssertGreaterThan(distance, 100)
        XCTAssertLessThan(distance, 130)
    }

    func testIgnoresPoorAccuracyPoints() {
        let calculator = DistanceCalculator()
        let start = Date(timeIntervalSince1970: 100)
        let accurateStart = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: start)
        let inaccurateJump = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 38.7749, longitude: -122.4194), altitude: 0, horizontalAccuracy: 250, verticalAccuracy: 10, timestamp: start.addingTimeInterval(30))
        let accurateEnd = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7759, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: start.addingTimeInterval(60))

        let distance = calculator.totalDistanceMeters(for: [accurateStart, inaccurateJump, accurateEnd])

        XCTAssertGreaterThan(distance, 100)
        XCTAssertLessThan(distance, 130)
    }

    func testIgnoresStationaryGpsJitterWithinAccuracyRadius() {
        let calculator = DistanceCalculator()
        let start = Date(timeIntervalSince1970: 100)
        let points = [
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.774900, longitude: -122.419400), altitude: 0, horizontalAccuracy: 18, verticalAccuracy: 10, timestamp: start),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.774935, longitude: -122.419405), altitude: 0, horizontalAccuracy: 18, verticalAccuracy: 10, timestamp: start.addingTimeInterval(10)),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.774890, longitude: -122.419450), altitude: 0, horizontalAccuracy: 18, verticalAccuracy: 10, timestamp: start.addingTimeInterval(20))
        ]

        let distance = calculator.totalDistanceMeters(for: points)

        XCTAssertEqual(distance, 0, accuracy: 0.5)
    }

    func testIgnoresStationaryGpsDriftForAllWorkoutTypes() {
        let calculator = DistanceCalculator()
        let start = Date(timeIntervalSince1970: 100)
        let points = [
            movingLocation(latitude: 31.184000, longitude: 121.603000, accuracy: 10, speed: 0.0, timestamp: start),
            movingLocation(latitude: 31.184115, longitude: 121.603040, accuracy: 10, speed: 0.0, timestamp: start.addingTimeInterval(10)),
            movingLocation(latitude: 31.184245, longitude: 121.603090, accuracy: 12, speed: 0.0, timestamp: start.addingTimeInterval(22)),
            movingLocation(latitude: 31.184370, longitude: 121.603120, accuracy: 11, speed: 0.0, timestamp: start.addingTimeInterval(34)),
            movingLocation(latitude: 31.184510, longitude: 121.603180, accuracy: 12, speed: 0.0, timestamp: start.addingTimeInterval(50))
        ]

        for type in WorkoutType.allCases {
            XCTAssertEqual(calculator.totalDistanceMeters(for: points, type: type), 0, accuracy: 0.5, "\(type) should ignore stationary GPS drift")
        }
    }

    func testCountsLegitimateMovementForAllWorkoutTypes() {
        let calculator = DistanceCalculator()
        let start = Date(timeIntervalSince1970: 100)

        let scenarios: [(WorkoutType, [CLLocation], Double)] = [
            (
                .walk,
                [
                    movingLocation(latitude: 31.184000, longitude: 121.603000, accuracy: 8, speed: 1.2, timestamp: start),
                    movingLocation(latitude: 31.184540, longitude: 121.603000, accuracy: 8, speed: 1.2, timestamp: start.addingTimeInterval(60))
                ],
                50
            ),
            (
                .run,
                [
                    movingLocation(latitude: 31.184000, longitude: 121.603000, accuracy: 8, speed: 3.0, timestamp: start),
                    movingLocation(latitude: 31.184810, longitude: 121.603000, accuracy: 8, speed: 3.0, timestamp: start.addingTimeInterval(30))
                ],
                80
            ),
            (
                .ride,
                [
                    movingLocation(latitude: 31.184000, longitude: 121.603000, accuracy: 8, speed: 6.0, timestamp: start),
                    movingLocation(latitude: 31.187240, longitude: 121.603000, accuracy: 8, speed: 6.0, timestamp: start.addingTimeInterval(60))
                ],
                300
            )
        ]

        for (type, points, minimumExpectedDistance) in scenarios {
            XCTAssertGreaterThan(
                calculator.totalDistanceMeters(for: points, type: type),
                minimumExpectedDistance,
                "\(type) should count legitimate movement"
            )
        }
    }

    func testRejectsInvalidHorizontalAccuracy() {
        let calculator = DistanceCalculator()
        let start = Date(timeIntervalSince1970: 100)
        let points = [
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), altitude: 0, horizontalAccuracy: -1, verticalAccuracy: 10, timestamp: start),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7759, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: start.addingTimeInterval(60))
        ]

        let filtered = calculator.filteredLocations(from: points)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.coordinate.latitude, 37.7759)
    }

    func testInitialRouteLocationRequiresBetterAccuracy() {
        let policy = LocationAcceptancePolicy()
        let start = Date(timeIntervalSince1970: 100)
        let coarseInitial = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 0,
            horizontalAccuracy: 50,
            verticalAccuracy: 10,
            timestamp: start.addingTimeInterval(1)
        )
        let preciseInitial = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            altitude: 0,
            horizontalAccuracy: 12,
            verticalAccuracy: 10,
            timestamp: start.addingTimeInterval(2)
        )

        let accepted = policy.acceptedLocations(
            from: [coarseInitial, preciseInitial],
            existingAcceptedCount: 0,
            trackingStartedAt: start,
            now: start.addingTimeInterval(3)
        )

        XCTAssertEqual(accepted.count, 1)
        XCTAssertEqual(accepted.first?.coordinate.latitude, 37.7750)
    }

    func testRejectsCachedLocationsFromBeforeWorkoutStart() {
        let policy = LocationAcceptancePolicy()
        let start = Date(timeIntervalSince1970: 100)
        let cached = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 0,
            horizontalAccuracy: 8,
            verticalAccuracy: 10,
            timestamp: start.addingTimeInterval(-20)
        )
        let live = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            altitude: 0,
            horizontalAccuracy: 8,
            verticalAccuracy: 10,
            timestamp: start.addingTimeInterval(1)
        )

        let accepted = policy.acceptedLocations(
            from: [cached, live],
            existingAcceptedCount: 0,
            trackingStartedAt: start,
            now: start.addingTimeInterval(2)
        )

        XCTAssertEqual(accepted.count, 1)
        XCTAssertEqual(accepted.first?.coordinate.latitude, 37.7750)
    }

    private func movingLocation(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        accuracy: CLLocationAccuracy,
        speed: CLLocationSpeed,
        timestamp: Date
    ) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: 10,
            course: -1,
            speed: speed,
            timestamp: timestamp
        )
    }
}
