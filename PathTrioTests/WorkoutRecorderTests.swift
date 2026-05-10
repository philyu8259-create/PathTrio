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

    func testRefreshUpdatesDurationWithoutLocationChanges() {
        let recorder = WorkoutRecorder(distanceCalculator: DistanceCalculator())
        let start = Date(timeIntervalSince1970: 100)
        _ = recorder.start(type: .walk, at: start)

        let draft = recorder.refresh(now: start.addingTimeInterval(31))

        XCTAssertEqual(draft?.metrics.duration, 31)
        XCTAssertEqual(draft?.metrics.distanceMeters, 0)
    }

    func testPausedTimeDoesNotCountTowardDuration() {
        let recorder = WorkoutRecorder(distanceCalculator: DistanceCalculator())
        let start = Date(timeIntervalSince1970: 100)
        _ = recorder.start(type: .run, at: start)

        _ = recorder.pause(at: start.addingTimeInterval(10))
        _ = recorder.refresh(now: start.addingTimeInterval(40))
        _ = recorder.resume(at: start.addingTimeInterval(70))
        let draft = recorder.refresh(now: start.addingTimeInterval(100))

        XCTAssertEqual(draft?.metrics.duration, 40)
    }

    func testStationaryGpsDriftDoesNotIncreaseDistanceForAllWorkoutTypes() {
        let start = Date(timeIntervalSince1970: 100)
        let points = [
            movingLocation(latitude: 31.184000, longitude: 121.603000, speed: 0, timestamp: start),
            movingLocation(latitude: 31.184115, longitude: 121.603040, speed: 0, timestamp: start.addingTimeInterval(10)),
            movingLocation(latitude: 31.184245, longitude: 121.603090, speed: 0, timestamp: start.addingTimeInterval(22)),
            movingLocation(latitude: 31.184370, longitude: 121.603120, speed: 0, timestamp: start.addingTimeInterval(34)),
            movingLocation(latitude: 31.184510, longitude: 121.603180, speed: 0, timestamp: start.addingTimeInterval(50))
        ]

        for type in WorkoutType.allCases {
            let recorder = WorkoutRecorder(distanceCalculator: DistanceCalculator())
            _ = recorder.start(type: type, at: start)

            let draft = recorder.addLocations(points, now: start.addingTimeInterval(51))

            XCTAssertEqual(draft?.metrics.distanceMeters ?? -1, 0, accuracy: 0.5, "\(type) should ignore stationary GPS drift")
            XCTAssertEqual(draft?.metrics.duration, 51)
            XCTAssertLessThanOrEqual(draft?.locations.count ?? 0, 1)
        }
    }

    func testChangeTypePreservesCurrentWorkoutData() {
        let recorder = WorkoutRecorder(distanceCalculator: DistanceCalculator())
        let start = Date(timeIntervalSince1970: 100)
        let first = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: start)
        let second = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7759, longitude: -122.4194), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: start.addingTimeInterval(60))
        let original = recorder.start(type: .walk, at: start)
        _ = recorder.addLocations([first, second], now: start.addingTimeInterval(60))

        let updated = recorder.changeType(to: .run)

        XCTAssertEqual(updated?.id, original.id)
        XCTAssertEqual(updated?.type, .run)
        XCTAssertEqual(updated?.startedAt, start)
        XCTAssertEqual(updated?.locations.count, 2)
        XCTAssertGreaterThan(updated?.metrics.distanceMeters ?? 0, 100)
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

    private func movingLocation(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        speed: CLLocationSpeed,
        timestamp: Date
    ) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: -1,
            speed: speed,
            timestamp: timestamp
        )
    }
}
