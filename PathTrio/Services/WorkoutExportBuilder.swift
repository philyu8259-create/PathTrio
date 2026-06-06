import CoreLocation
import Foundation

struct WorkoutExportBuilder {
    func csv(for workouts: [WorkoutSessionModel]) -> String {
        let header = [
            "id",
            "type",
            "started_at",
            "ended_at",
            "duration_seconds",
            "distance_meters",
            "average_speed_mps",
            "estimated_calories",
            "recording_mode",
            "is_manual_entry",
            "route_points"
        ]

        let rows = workouts
            .sorted { $0.startedAt < $1.startedAt }
            .map { workout in
                [
                    workout.id.uuidString,
                    workout.type.rawValue,
                    isoDate(workout.startedAt),
                    isoDate(workout.endedAt),
                    String(format: "%.0f", workout.duration),
                    String(format: "%.2f", workout.distanceMeters),
                    String(format: "%.3f", workout.averageSpeedMetersPerSecond),
                    workout.effectiveEstimatedCalories.map { String(format: "%.1f", $0) } ?? "",
                    workout.recordingMode.rawValue,
                    workout.isManualEntry ? "true" : "false",
                    "\(workout.locations.count)"
                ].map(csvEscaped).joined(separator: ",")
            }

        return ([header.joined(separator: ",")] + rows).joined(separator: "\n")
    }

    func gpx(for workout: WorkoutSessionModel) -> String {
        let points = workout.locations.sorted { $0.timestamp < $1.timestamp }
        let trackPoints = points.map { point in
            """
            <trkpt lat="\(point.latitude)" lon="\(point.longitude)"><ele>\(point.altitude)</ele><time>\(isoDate(point.timestamp))</time></trkpt>
            """
        }
        .joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="PeachMove" xmlns="http://www.topografix.com/GPX/1/1">
        <metadata><time>\(isoDate(workout.startedAt))</time></metadata>
        <trk><name>\(xmlEscaped(workout.type.displayName)) \(isoDate(workout.startedAt))</name><trkseg>
        \(trackPoints)
        </trkseg></trk>
        </gpx>
        """
    }

    func writeTemporaryFile(contents: String, filename: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PeachMoveExports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(filename)
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private func isoDate(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private func xmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
