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
}
