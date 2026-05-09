import CoreLocation
import XCTest
@testable import PathTrio

final class WorkoutRecorderTests: XCTestCase {
    func testStartCreatesRecordingDraft() {
        let recorder = WorkoutRecorder(distanceCalculator: DistanceCalculator())

        let draft = recorder.start(type: .run, at: Date(timeIntervalSince1970: 100))

        XCTAssertEqual(draft.type, .run)
        XCTAssertEqual(draft.state, .recording)
        XCTAssertEqual(draft.startedAt, Date(timeIntervalSince1970: 100))
    }

    func testPauseAndResumeUpdateState() {
        let recorder = WorkoutRecorder(distanceCalculator: DistanceCalculator())
        _ = recorder.start(type: .walk, at: Date())

        XCTAssertEqual(recorder.pause(), .paused)
        XCTAssertEqual(recorder.resume(), .recording)
    }

    func testLocationUpdatesRefreshDistance() {
        let recorder = WorkoutRecorder(distanceCalculator: DistanceCalculator())
        _ = recorder.start(type: .walk, at: Date(timeIntervalSince1970: 100))
        let first = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date(timeIntervalSince1970: 100))
        let second = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7759, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date(timeIntervalSince1970: 160))

        let draft = recorder.addLocations([first, second], now: Date(timeIntervalSince1970: 160))

        XCTAssertGreaterThan(draft?.metrics.distanceMeters ?? 0, 100)
        XCTAssertEqual(draft?.metrics.duration, 60)
    }

    func testStationaryGpsJitterDoesNotIncreaseDistanceOrSpeed() {
        let recorder = WorkoutRecorder(distanceCalculator: DistanceCalculator())
        let start = Date(timeIntervalSince1970: 100)
        _ = recorder.start(type: .walk, at: start)
        let points = [
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.774900, longitude: -122.419400), altitude: 0, horizontalAccuracy: 18, verticalAccuracy: 10, timestamp: start),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.774935, longitude: -122.419405), altitude: 0, horizontalAccuracy: 18, verticalAccuracy: 10, timestamp: start.addingTimeInterval(10)),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.774890, longitude: -122.419450), altitude: 0, horizontalAccuracy: 18, verticalAccuracy: 10, timestamp: start.addingTimeInterval(20))
        ]

        let draft = recorder.addLocations(points, now: start.addingTimeInterval(20))

        XCTAssertEqual(draft?.metrics.distanceMeters ?? -1, 0, accuracy: 0.5)
        XCTAssertEqual(draft?.metrics.averageSpeedMetersPerSecond ?? -1, 0, accuracy: 0.05)
        XCTAssertEqual(draft?.locations.count, 1)
    }
}
