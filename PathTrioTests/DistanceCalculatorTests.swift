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
}
