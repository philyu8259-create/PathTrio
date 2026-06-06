import XCTest
@testable import PathTrio

final class WorkoutExportBuilderTests: XCTestCase {
    func testBuildsWorkoutCsvWithHeaderAndRows() {
        let workout = WorkoutSessionModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            type: .run,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 700),
            duration: 600,
            distanceMeters: 1_500,
            averageSpeedMetersPerSecond: 2.5,
            estimatedCalories: 75,
            userCorrectedCalories: 82,
            smartAssistEnabledAtStart: true,
            recordingMode: .manualEntry,
            isManualEntry: true,
            notes: "Felt strong, sunny route"
        )

        let csv = WorkoutExportBuilder().csv(for: [workout])

        XCTAssertTrue(csv.contains("id,type,started_at,ended_at,duration_seconds,distance_meters,average_speed_mps,estimated_calories,recording_mode,is_manual_entry,notes,route_points"))
        XCTAssertTrue(csv.contains("00000000-0000-0000-0000-000000000123,run"))
        XCTAssertTrue(csv.contains("600,1500.00,2.500,82.0,manualEntry,true,\"Felt strong, sunny route\",0"))
    }

    func testBuildsGpxWithRoutePoints() {
        let workout = WorkoutSessionModel(
            type: .walk,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 700),
            duration: 600,
            distanceMeters: 500,
            averageSpeedMetersPerSecond: 0.8,
            smartAssistEnabledAtStart: false,
            locations: [
                LocationPointModel(
                    timestamp: Date(timeIntervalSince1970: 120),
                    latitude: 37.1,
                    longitude: -122.1,
                    horizontalAccuracy: 5,
                    altitude: 10,
                    speedMetersPerSecond: 0.8,
                    course: 90
                )
            ]
        )

        let gpx = WorkoutExportBuilder().gpx(for: workout)

        XCTAssertTrue(gpx.contains("<gpx version=\"1.1\" creator=\"PeachMove\""))
        XCTAssertTrue(gpx.contains("<trkpt lat=\"37.1\" lon=\"-122.1\">"))
        XCTAssertTrue(gpx.contains("<ele>10.0</ele>"))
    }
}
