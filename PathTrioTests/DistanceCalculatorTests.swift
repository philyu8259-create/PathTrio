import CoreLocation
import XCTest
@testable import PathTrio

final class DistanceCalculatorTests: XCTestCase {
    func testCalculatesDistanceBetweenAccuratePoints() {
        let calculator = DistanceCalculator()
        let points = [
            CLLocation(latitude: 37.7749, longitude: -122.4194),
            CLLocation(latitude: 37.7759, longitude: -122.4194)
        ]

        let distance = calculator.totalDistanceMeters(for: points)

        XCTAssertGreaterThan(distance, 100)
        XCTAssertLessThan(distance, 130)
    }

    func testIgnoresPoorAccuracyPoints() {
        let calculator = DistanceCalculator()
        let accurateStart = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date())
        let inaccurateJump = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 38.7749, longitude: -122.4194), altitude: 0, horizontalAccuracy: 250, verticalAccuracy: 10, timestamp: Date())
        let accurateEnd = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7759, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date())

        let distance = calculator.totalDistanceMeters(for: [accurateStart, inaccurateJump, accurateEnd])

        XCTAssertGreaterThan(distance, 100)
        XCTAssertLessThan(distance, 130)
    }
}
