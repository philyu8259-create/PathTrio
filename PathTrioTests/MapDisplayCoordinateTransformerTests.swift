import CoreLocation
import XCTest
@testable import PathTrio

final class MapDisplayCoordinateTransformerTests: XCTestCase {
    func testMainlandChinaCoordinateUsesMapDisplayOffset() {
        let rawShanghaiCoordinate = CLLocationCoordinate2D(latitude: 31.1503, longitude: 121.3709)

        XCTAssertTrue(MapDisplayCoordinateTransformer.shouldApplyMainlandChinaOffset(to: rawShanghaiCoordinate))

        let displayCoordinate = MapDisplayCoordinateTransformer.displayCoordinate(for: rawShanghaiCoordinate)
        let rawLocation = CLLocation(latitude: rawShanghaiCoordinate.latitude, longitude: rawShanghaiCoordinate.longitude)
        let displayLocation = CLLocation(latitude: displayCoordinate.latitude, longitude: displayCoordinate.longitude)
        let displayShift = rawLocation.distance(from: displayLocation)

        XCTAssertGreaterThan(displayShift, 300)
        XCTAssertLessThan(displayShift, 800)
    }

    func testNonMainlandCoordinatesKeepRawDisplayCoordinate() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
            CLLocationCoordinate2D(latitude: 22.1987, longitude: 113.5439),
            CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654)
        ]

        for coordinate in coordinates {
            XCTAssertFalse(MapDisplayCoordinateTransformer.shouldApplyMainlandChinaOffset(to: coordinate))
            let displayCoordinate = MapDisplayCoordinateTransformer.displayCoordinate(for: coordinate)
            XCTAssertEqual(displayCoordinate.latitude, coordinate.latitude, accuracy: 0.000_001)
            XCTAssertEqual(displayCoordinate.longitude, coordinate.longitude, accuracy: 0.000_001)
        }
    }
}
