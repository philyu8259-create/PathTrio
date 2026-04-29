# PathTrio iOS MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native SwiftUI iOS MVP for PathTrio that supports manual Walk, Run, and Ride workout recording, local history, route display, permission-aware location tracking, and optional Smart Assist switches.

**Architecture:** Use a small XcodeGen-managed SwiftUI app with focused domain, service, persistence, and view-model files. The app state flows through `AppModel`, while `WorkoutRecorder` owns active workout state, `LocationTrackingService` wraps CoreLocation, `SmartAssistEngine` produces suggestions without mutating data, and `WorkoutStore` persists completed sessions in SwiftData.

**Tech Stack:** SwiftUI, SwiftData, CoreLocation, MapKit, CoreMotion, XCTest, XcodeGen, iOS 17+.

---

## Scope Notes

This plan implements the Version 1 MVP described in `docs/superpowers/specs/2026-04-29-pathtrio-mvp-design.md`.

Version 1 uses iOS 17+ so the app can use SwiftData cleanly. Smart Assist is included as optional settings and deterministic engine logic, with CoreMotion wired behind a service wrapper. Real-device verification is required before App Store submission because simulator location and motion behavior are incomplete.

## File Structure

Create this structure:

```text
project.yml
PathTrio/
  App/
    PathTrioApp.swift
    AppModel.swift
  Domain/
    WorkoutType.swift
    WorkoutState.swift
    WorkoutMetrics.swift
    WorkoutSessionDraft.swift
    SmartAssistSuggestion.swift
  Persistence/
    WorkoutSessionModel.swift
    LocationPointModel.swift
    UserSettingsModel.swift
    WorkoutStore.swift
    SettingsStore.swift
  Services/
    DistanceCalculator.swift
    LocationTrackingService.swift
    MotionActivityService.swift
    SmartAssistEngine.swift
  Views/
    HomeView.swift
    ActiveWorkoutView.swift
    WorkoutSummaryView.swift
    HistoryView.swift
    WorkoutDetailView.swift
    SettingsView.swift
    Components/
      MetricTile.swift
      WorkoutTypePicker.swift
      RouteMapView.swift
  Resources/
    Assets.xcassets/
      AccentColor.colorset/Contents.json
      AppIcon.appiconset/Contents.json
    InfoPlist.strings
PathTrioTests/
  DistanceCalculatorTests.swift
  SmartAssistEngineTests.swift
  WorkoutRecorderTests.swift
```

Responsibilities:

- `project.yml`: XcodeGen project definition, iOS deployment target, background location mode, permissions, test target.
- `PathTrio/App`: app entry point and top-level dependency container.
- `PathTrio/Domain`: pure Swift types with no framework side effects.
- `PathTrio/Persistence`: SwiftData models and stores.
- `PathTrio/Services`: CoreLocation/CoreMotion wrappers and testable business logic.
- `PathTrio/Views`: SwiftUI screens and reusable UI pieces.
- `PathTrioTests`: unit tests for route distance, recorder state, and Smart Assist decisions.

---

### Task 1: Project Shell

**Files:**
- Create: `project.yml`
- Create: `PathTrio/App/PathTrioApp.swift`
- Create: `PathTrio/App/AppModel.swift`
- Create: `PathTrio/Views/HomeView.swift`
- Create: `PathTrio/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `PathTrio/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `PathTrio/Resources/InfoPlist.strings`

- [ ] **Step 1: Add the XcodeGen project file**

Create `project.yml`:

```yaml
name: PathTrio
options:
  bundleIdPrefix: com.phil
  deploymentTarget:
    iOS: "17.0"
settings:
  base:
    SWIFT_VERSION: 5.9
    MARKETING_VERSION: 1.0
    CURRENT_PROJECT_VERSION: 1
targets:
  PathTrio:
    type: application
    platform: iOS
    sources:
      - PathTrio
    resources:
      - PathTrio/Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.phil.PathTrio
        INFOPLIST_KEY_CFBundleDisplayName: PathTrio
        INFOPLIST_KEY_NSHumanReadableCopyright: ""
        INFOPLIST_KEY_NSLocationWhenInUseUsageDescription: PathTrio uses location to record your workout route, distance, and speed while you are tracking a walk, run, or ride.
        INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription: PathTrio uses background location only during an active workout so it can keep recording when your screen is locked.
        INFOPLIST_KEY_NSMotionUsageDescription: PathTrio uses motion activity to provide optional Smart Assist alerts for pauses, activity changes, and unusual speeds.
        INFOPLIST_KEY_UIBackgroundModes:
          - location
    info:
      path: PathTrio/Info.plist
      properties:
        UILaunchScreen: {}
  PathTrioTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - PathTrioTests
    dependencies:
      - target: PathTrio
```

- [ ] **Step 2: Add the app entry point**

Create `PathTrio/App/PathTrioApp.swift`:

```swift
import SwiftUI

@main
struct PathTrioApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appModel)
        }
    }
}
```

- [ ] **Step 3: Add the top-level app model**

Create `PathTrio/App/AppModel.swift`:

```swift
import Foundation
import Observation

@Observable
final class AppModel {
}
```

- [ ] **Step 4: Add a placeholder Home view**

Create `PathTrio/Views/HomeView.swift`:

```swift
import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("PathTrio")
                .font(.largeTitle.bold())
            Text("Walk, Run & Ride Tracker")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

- [ ] **Step 5: Add placeholder assets**

Create `PathTrio/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`:

```json
{
  "colors": [
    {
      "idiom": "universal",
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "0.078",
          "green": "0.518",
          "blue": "0.486",
          "alpha": "1.000"
        }
      }
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

Create `PathTrio/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images": [
    {
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

Create `PathTrio/Resources/InfoPlist.strings`:

```text
"CFBundleDisplayName" = "PathTrio";
```

- [ ] **Step 6: Generate and build**

Run:

```bash
xcodegen generate
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: XcodeGen creates `PathTrio.xcodeproj`; build succeeds and shows the placeholder Home view.

- [ ] **Step 7: Commit**

```bash
git add project.yml PathTrio
git commit -m "feat: scaffold PathTrio iOS project"
```

---

### Task 2: Domain Models And Formatting

**Files:**
- Create: `PathTrio/Domain/WorkoutType.swift`
- Create: `PathTrio/Domain/WorkoutState.swift`
- Create: `PathTrio/Domain/WorkoutMetrics.swift`
- Create: `PathTrio/Domain/WorkoutSessionDraft.swift`
- Create: `PathTrio/Domain/SmartAssistSuggestion.swift`

- [ ] **Step 1: Add workout type**

Create `PathTrio/Domain/WorkoutType.swift`:

```swift
import Foundation

enum WorkoutType: String, CaseIterable, Codable, Identifiable {
    case walk
    case run
    case ride

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .walk: "Walk"
        case .run: "Run"
        case .ride: "Ride"
        }
    }

    var systemImage: String {
        switch self {
        case .walk: "figure.walk"
        case .run: "figure.run"
        case .ride: "bicycle"
        }
    }

    var emphasizesPace: Bool {
        self == .walk || self == .run
    }
}
```

- [ ] **Step 2: Add workout state**

Create `PathTrio/Domain/WorkoutState.swift`:

```swift
import Foundation

enum WorkoutState: Equatable {
    case idle
    case recording
    case paused
    case autoPaused
    case ended
}
```

- [ ] **Step 3: Add metric formatting**

Create `PathTrio/Domain/WorkoutMetrics.swift`:

```swift
import Foundation

struct WorkoutMetrics: Equatable {
    var duration: TimeInterval
    var distanceMeters: Double
    var averageSpeedMetersPerSecond: Double

    var paceSecondsPerKilometer: Double? {
        guard distanceMeters > 0 else { return nil }
        return duration / (distanceMeters / 1_000)
    }
}

enum WorkoutMetricsFormatter {
    static func distance(_ meters: Double) -> String {
        if meters < 1_000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.2f km", meters / 1_000)
    }

    static func duration(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded()))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func speed(_ metersPerSecond: Double) -> String {
        String(format: "%.1f km/h", metersPerSecond * 3.6)
    }

    static func pace(_ secondsPerKilometer: Double?) -> String {
        guard let secondsPerKilometer, secondsPerKilometer.isFinite else {
            return "-- /km"
        }
        let minutes = Int(secondsPerKilometer) / 60
        let seconds = Int(secondsPerKilometer) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}
```

- [ ] **Step 4: Add active workout draft**

Create `PathTrio/Domain/WorkoutSessionDraft.swift`:

```swift
import CoreLocation
import Foundation

struct WorkoutSessionDraft: Identifiable {
    let id: UUID
    let type: WorkoutType
    let startedAt: Date
    var endedAt: Date?
    var state: WorkoutState
    var locations: [CLLocation]
    var metrics: WorkoutMetrics

    init(
        id: UUID = UUID(),
        type: WorkoutType,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        state: WorkoutState = .recording,
        locations: [CLLocation] = [],
        metrics: WorkoutMetrics = WorkoutMetrics(duration: 0, distanceMeters: 0, averageSpeedMetersPerSecond: 0)
    ) {
        self.id = id
        self.type = type
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.state = state
        self.locations = locations
        self.metrics = metrics
    }
}
```

- [ ] **Step 5: Add Smart Assist suggestion model**

Create `PathTrio/Domain/SmartAssistSuggestion.swift`:

```swift
import Foundation

enum SmartAssistSuggestion: Equatable, Identifiable {
    case activityChange(from: WorkoutType, to: WorkoutType)
    case autoPause
    case speedAnomaly(currentSpeedMetersPerSecond: Double, workoutType: WorkoutType)

    var id: String {
        switch self {
        case .activityChange(let from, let to):
            return "activity-\(from.rawValue)-\(to.rawValue)"
        case .autoPause:
            return "auto-pause"
        case .speedAnomaly(_, let workoutType):
            return "speed-anomaly-\(workoutType.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .activityChange(_, let to):
            return "Switch to \(to.displayName)?"
        case .autoPause:
            return "Pause workout?"
        case .speedAnomaly:
            return "Unusual speed detected"
        }
    }

    var message: String {
        switch self {
        case .activityChange(let from, let to):
            return "PathTrio detected movement that looks more like \(to.displayName.lowercased()) than \(from.displayName.lowercased())."
        case .autoPause:
            return "You appear to be still. PathTrio can pause this workout until movement resumes."
        case .speedAnomaly:
            return "Your speed is unusually high for this workout type. You may want to pause recording."
        }
    }
}
```

- [ ] **Step 6: Build**

Run:

```bash
xcodegen generate
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: PASS. The app still shows the placeholder Home view.

- [ ] **Step 7: Commit**

```bash
git add PathTrio/Domain
git commit -m "feat: add workout domain models"
```

---

### Task 3: Distance Calculation And Recorder Core

**Files:**
- Create: `PathTrio/Services/DistanceCalculator.swift`
- Create: `PathTrio/Services/WorkoutRecorder.swift`
- Create: `PathTrioTests/DistanceCalculatorTests.swift`
- Create: `PathTrioTests/WorkoutRecorderTests.swift`

- [ ] **Step 1: Add failing distance tests**

Create `PathTrioTests/DistanceCalculatorTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
xcodegen generate
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PathTrioTests/DistanceCalculatorTests
```

Expected: FAIL because `DistanceCalculator` does not exist.

- [ ] **Step 3: Implement distance calculator**

Create `PathTrio/Services/DistanceCalculator.swift`:

```swift
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
```

- [ ] **Step 4: Add recorder tests**

Create `PathTrioTests/WorkoutRecorderTests.swift`:

```swift
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
```

- [ ] **Step 5: Run recorder tests to verify failure**

Run:

```bash
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PathTrioTests/WorkoutRecorderTests
```

Expected: FAIL because `WorkoutRecorder` does not exist.

- [ ] **Step 6: Implement recorder**

Create `PathTrio/Services/WorkoutRecorder.swift`:

```swift
import CoreLocation
import Foundation
import Observation

@Observable
final class WorkoutRecorder {
    private let distanceCalculator: DistanceCalculator
    private(set) var draft: WorkoutSessionDraft?

    init(distanceCalculator: DistanceCalculator) {
        self.distanceCalculator = distanceCalculator
    }

    @discardableResult
    func start(type: WorkoutType, at date: Date = Date()) -> WorkoutSessionDraft {
        let next = WorkoutSessionDraft(type: type, startedAt: date, state: .recording)
        draft = next
        return next
    }

    @discardableResult
    func pause() -> WorkoutState {
        guard var current = draft else { return .idle }
        current.state = .paused
        draft = current
        return current.state
    }

    @discardableResult
    func autoPause() -> WorkoutState {
        guard var current = draft else { return .idle }
        current.state = .autoPaused
        draft = current
        return current.state
    }

    @discardableResult
    func resume() -> WorkoutState {
        guard var current = draft else { return .idle }
        current.state = .recording
        draft = current
        return current.state
    }

    @discardableResult
    func addLocations(_ locations: [CLLocation], now: Date = Date()) -> WorkoutSessionDraft? {
        guard var current = draft, current.state == .recording else { return draft }
        current.locations.append(contentsOf: locations)
        current.metrics = metrics(for: current, now: now)
        draft = current
        return current
    }

    @discardableResult
    func end(at date: Date = Date()) -> WorkoutSessionDraft? {
        guard var current = draft else { return nil }
        current.endedAt = date
        current.state = .ended
        current.metrics = metrics(for: current, now: date)
        draft = nil
        return current
    }

    private func metrics(for draft: WorkoutSessionDraft, now: Date) -> WorkoutMetrics {
        let duration = max(0, now.timeIntervalSince(draft.startedAt))
        let distance = distanceCalculator.totalDistanceMeters(for: draft.locations)
        let speed = duration > 0 ? distance / duration : 0
        return WorkoutMetrics(duration: duration, distanceMeters: distance, averageSpeedMetersPerSecond: speed)
    }
}
```

- [ ] **Step 7: Run tests to verify pass**

Run:

```bash
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PathTrioTests/DistanceCalculatorTests -only-testing:PathTrioTests/WorkoutRecorderTests
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add PathTrio/Services/DistanceCalculator.swift PathTrio/Services/WorkoutRecorder.swift PathTrioTests
git commit -m "feat: add workout recorder core"
```

---

### Task 4: SwiftData Persistence

**Files:**
- Modify: `PathTrio/App/PathTrioApp.swift`
- Create: `PathTrio/Persistence/WorkoutSessionModel.swift`
- Create: `PathTrio/Persistence/LocationPointModel.swift`
- Create: `PathTrio/Persistence/UserSettingsModel.swift`
- Create: `PathTrio/Persistence/WorkoutStore.swift`
- Create: `PathTrio/Persistence/SettingsStore.swift`

- [ ] **Step 1: Add SwiftData to the app entry point**

Modify `PathTrio/App/PathTrioApp.swift`:

```swift
import SwiftData
import SwiftUI

@main
struct PathTrioApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appModel)
        }
        .modelContainer(for: [
            WorkoutSessionModel.self,
            LocationPointModel.self,
            UserSettingsModel.self
        ])
    }
}
```

- [ ] **Step 2: Add SwiftData models**

Create `PathTrio/Persistence/WorkoutSessionModel.swift`:

```swift
import Foundation
import SwiftData

@Model
final class WorkoutSessionModel {
    @Attribute(.unique) var id: UUID
    var typeRawValue: String
    var startedAt: Date
    var endedAt: Date
    var duration: TimeInterval
    var distanceMeters: Double
    var averageSpeedMetersPerSecond: Double
    var estimatedCalories: Double?
    var smartAssistEnabledAtStart: Bool
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \LocationPointModel.workout) var locations: [LocationPointModel]

    init(
        id: UUID = UUID(),
        type: WorkoutType,
        startedAt: Date,
        endedAt: Date,
        duration: TimeInterval,
        distanceMeters: Double,
        averageSpeedMetersPerSecond: Double,
        estimatedCalories: Double? = nil,
        smartAssistEnabledAtStart: Bool,
        locations: [LocationPointModel] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.distanceMeters = distanceMeters
        self.averageSpeedMetersPerSecond = averageSpeedMetersPerSecond
        self.estimatedCalories = estimatedCalories
        self.smartAssistEnabledAtStart = smartAssistEnabledAtStart
        self.locations = locations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var type: WorkoutType {
        WorkoutType(rawValue: typeRawValue) ?? .walk
    }
}
```

Create `PathTrio/Persistence/LocationPointModel.swift`:

```swift
import Foundation
import SwiftData

@Model
final class LocationPointModel {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var horizontalAccuracy: Double
    var altitude: Double
    var speedMetersPerSecond: Double
    var course: Double
    var workout: WorkoutSessionModel?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double,
        altitude: Double,
        speedMetersPerSecond: Double,
        course: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.altitude = altitude
        self.speedMetersPerSecond = speedMetersPerSecond
        self.course = course
    }
}
```

Create `PathTrio/Persistence/UserSettingsModel.swift`:

```swift
import Foundation
import SwiftData

@Model
final class UserSettingsModel {
    @Attribute(.unique) var id: UUID
    var preferredUnits: String
    var smartActivityAlertsEnabled: Bool
    var autoPauseEnabled: Bool
    var speedAnomalyAlertsEnabled: Bool
    var bodyWeightKilograms: Double?
    var healthKitSyncEnabled: Bool

    init(
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        preferredUnits: String = "metric",
        smartActivityAlertsEnabled: Bool = false,
        autoPauseEnabled: Bool = false,
        speedAnomalyAlertsEnabled: Bool = false,
        bodyWeightKilograms: Double? = nil,
        healthKitSyncEnabled: Bool = false
    ) {
        self.id = id
        self.preferredUnits = preferredUnits
        self.smartActivityAlertsEnabled = smartActivityAlertsEnabled
        self.autoPauseEnabled = autoPauseEnabled
        self.speedAnomalyAlertsEnabled = speedAnomalyAlertsEnabled
        self.bodyWeightKilograms = bodyWeightKilograms
        self.healthKitSyncEnabled = healthKitSyncEnabled
    }
}
```

- [ ] **Step 3: Add workout store**

Create `PathTrio/Persistence/WorkoutStore.swift`:

```swift
import CoreLocation
import Foundation
import SwiftData

@MainActor
struct WorkoutStore {
    let context: ModelContext

    func saveCompletedWorkout(_ draft: WorkoutSessionDraft, smartAssistEnabledAtStart: Bool) throws -> WorkoutSessionModel {
        guard let endedAt = draft.endedAt else {
            throw WorkoutStoreError.missingEndDate
        }

        let points = draft.locations.map {
            LocationPointModel(
                timestamp: $0.timestamp,
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                horizontalAccuracy: $0.horizontalAccuracy,
                altitude: $0.altitude,
                speedMetersPerSecond: max(0, $0.speed),
                course: $0.course
            )
        }

        let session = WorkoutSessionModel(
            id: draft.id,
            type: draft.type,
            startedAt: draft.startedAt,
            endedAt: endedAt,
            duration: draft.metrics.duration,
            distanceMeters: draft.metrics.distanceMeters,
            averageSpeedMetersPerSecond: draft.metrics.averageSpeedMetersPerSecond,
            estimatedCalories: nil,
            smartAssistEnabledAtStart: smartAssistEnabledAtStart,
            locations: points
        )

        context.insert(session)
        try context.save()
        return session
    }
}

enum WorkoutStoreError: Error {
    case missingEndDate
}
```

- [ ] **Step 4: Add settings store**

Create `PathTrio/Persistence/SettingsStore.swift`:

```swift
import Foundation
import Observation

@Observable
final class SettingsStore {
    var preferredUnits: String = "metric"
    var smartActivityAlertsEnabled: Bool = false
    var autoPauseEnabled: Bool = false
    var speedAnomalyAlertsEnabled: Bool = false
    var bodyWeightKilograms: Double?
    var healthKitSyncEnabled: Bool = false

    var isAnySmartAssistEnabled: Bool {
        smartActivityAlertsEnabled || autoPauseEnabled || speedAnomalyAlertsEnabled
    }
}
```

- [ ] **Step 5: Build**

Run:

```bash
xcodegen generate
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: build succeeds with the placeholder Home view and SwiftData model container.

- [ ] **Step 6: Commit**

```bash
git add PathTrio/App/PathTrioApp.swift PathTrio/Persistence
git commit -m "feat: add local workout persistence"
```

---

### Task 5: Location, Motion, And Smart Assist Services

**Files:**
- Create: `PathTrio/Services/LocationTrackingService.swift`
- Create: `PathTrio/Services/MotionActivityService.swift`
- Create: `PathTrio/Services/SmartAssistEngine.swift`
- Create: `PathTrioTests/SmartAssistEngineTests.swift`

- [ ] **Step 1: Add Smart Assist tests**

Create `PathTrioTests/SmartAssistEngineTests.swift`:

```swift
import XCTest
@testable import PathTrio

final class SmartAssistEngineTests: XCTestCase {
    func testDoesNotSuggestWhenSettingsAreOff() {
        let engine = SmartAssistEngine()

        let suggestion = engine.evaluate(
            workoutType: .walk,
            currentSpeedMetersPerSecond: 12,
            detectedActivity: .cycling,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: false,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: false
            )
        )

        XCTAssertNil(suggestion)
    }

    func testSuggestsActivityChangeWhenEnabled() {
        let engine = SmartAssistEngine()

        let suggestion = engine.evaluate(
            workoutType: .run,
            currentSpeedMetersPerSecond: 5,
            detectedActivity: .cycling,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: true,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: false
            )
        )

        XCTAssertEqual(suggestion, .activityChange(from: .run, to: .ride))
    }

    func testSuggestsSpeedAnomalyForWalkAtCarSpeed() {
        let engine = SmartAssistEngine()

        let suggestion = engine.evaluate(
            workoutType: .walk,
            currentSpeedMetersPerSecond: 14,
            detectedActivity: .unknown,
            settings: SmartAssistSettings(
                smartActivityAlertsEnabled: false,
                autoPauseEnabled: false,
                speedAnomalyAlertsEnabled: true
            )
        )

        XCTAssertEqual(suggestion, .speedAnomaly(currentSpeedMetersPerSecond: 14, workoutType: .walk))
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PathTrioTests/SmartAssistEngineTests
```

Expected: FAIL because `SmartAssistEngine`, `SmartAssistSettings`, and `DetectedMotionActivity` do not exist.

- [ ] **Step 3: Implement Smart Assist engine**

Create `PathTrio/Services/SmartAssistEngine.swift`:

```swift
import Foundation

struct SmartAssistSettings {
    var smartActivityAlertsEnabled: Bool
    var autoPauseEnabled: Bool
    var speedAnomalyAlertsEnabled: Bool
}

enum DetectedMotionActivity: Equatable {
    case stationary
    case walking
    case running
    case cycling
    case automotive
    case unknown

    var workoutType: WorkoutType? {
        switch self {
        case .walking: .walk
        case .running: .run
        case .cycling: .ride
        case .stationary, .automotive, .unknown: nil
        }
    }
}

struct SmartAssistEngine {
    func evaluate(
        workoutType: WorkoutType,
        currentSpeedMetersPerSecond: Double,
        detectedActivity: DetectedMotionActivity,
        settings: SmartAssistSettings
    ) -> SmartAssistSuggestion? {
        if settings.speedAnomalyAlertsEnabled, isSpeedAnomalous(currentSpeedMetersPerSecond, for: workoutType) {
            return .speedAnomaly(currentSpeedMetersPerSecond: currentSpeedMetersPerSecond, workoutType: workoutType)
        }

        if settings.autoPauseEnabled, detectedActivity == .stationary, currentSpeedMetersPerSecond < 0.4 {
            return .autoPause
        }

        if settings.smartActivityAlertsEnabled,
           let detectedType = detectedActivity.workoutType,
           detectedType != workoutType {
            return .activityChange(from: workoutType, to: detectedType)
        }

        return nil
    }

    private func isSpeedAnomalous(_ speed: Double, for type: WorkoutType) -> Bool {
        switch type {
        case .walk:
            speed > 4.5
        case .run:
            speed > 8.5
        case .ride:
            speed > 22
        }
    }
}
```

- [ ] **Step 4: Implement location tracking service**

Create `PathTrio/Services/LocationTrackingService.swift`:

```swift
import CoreLocation
import Foundation
import Observation

@Observable
final class LocationTrackingService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var latestLocations: [CLLocation] = []
    private(set) var latestErrorMessage: String?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = true
        manager.allowsBackgroundLocationUpdates = false
        manager.showsBackgroundLocationIndicator = true
    }

    func requestWhenInUsePermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermission() {
        manager.requestAlwaysAuthorization()
    }

    func start(backgroundAllowed: Bool) {
        manager.allowsBackgroundLocationUpdates = backgroundAllowed
        latestLocations.removeAll()
        latestErrorMessage = nil
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        latestLocations.append(contentsOf: locations)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        latestErrorMessage = error.localizedDescription
    }
}
```

- [ ] **Step 5: Implement motion activity service**

Create `PathTrio/Services/MotionActivityService.swift`:

```swift
import CoreMotion
import Foundation
import Observation

@Observable
final class MotionActivityService {
    private let manager = CMMotionActivityManager()
    private let queue = OperationQueue()
    private(set) var detectedActivity: DetectedMotionActivity = .unknown

    var isAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    func start() {
        guard isAvailable else {
            detectedActivity = .unknown
            return
        }

        manager.startActivityUpdates(to: queue) { [weak self] activity in
            guard let activity else { return }
            Task { @MainActor in
                self?.detectedActivity = Self.map(activity)
            }
        }
    }

    func stop() {
        manager.stopActivityUpdates()
    }

    private static func map(_ activity: CMMotionActivity) -> DetectedMotionActivity {
        if activity.automotive { return .automotive }
        if activity.cycling { return .cycling }
        if activity.running { return .running }
        if activity.walking { return .walking }
        if activity.stationary { return .stationary }
        return .unknown
    }
}
```

- [ ] **Step 6: Run service tests**

Run:

```bash
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PathTrioTests/SmartAssistEngineTests
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add PathTrio/Services PathTrioTests/SmartAssistEngineTests.swift
git commit -m "feat: add smart assist services"
```

---

### Task 6: Shared UI Components

**Files:**
- Create: `PathTrio/Views/Components/MetricTile.swift`
- Create: `PathTrio/Views/Components/WorkoutTypePicker.swift`
- Create: `PathTrio/Views/Components/RouteMapView.swift`

- [ ] **Step 1: Add metric tile**

Create `PathTrio/Views/Components/MetricTile.swift`:

```swift
import SwiftUI

struct MetricTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
```

- [ ] **Step 2: Add workout type picker**

Create `PathTrio/Views/Components/WorkoutTypePicker.swift`:

```swift
import SwiftUI

struct WorkoutTypePicker: View {
    @Binding var selection: WorkoutType

    var body: some View {
        HStack(spacing: 10) {
            ForEach(WorkoutType.allCases) { type in
                Button {
                    selection = type
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: type.systemImage)
                            .font(.title2)
                        Text(type.displayName)
                            .font(.callout.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selection == type ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selection == type ? Color.accentColor : Color.clear, lineWidth: 2)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(type.displayName)
            }
        }
    }
}
```

- [ ] **Step 3: Add route map view**

Create `PathTrio/Views/Components/RouteMapView.swift`:

```swift
import CoreLocation
import MapKit
import SwiftUI

struct RouteMapView: View {
    let locations: [CLLocation]

    private var cameraPosition: MapCameraPosition {
        guard let last = locations.last else {
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
        return .region(MKCoordinateRegion(
            center: last.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        Map(initialPosition: cameraPosition) {
            if locations.count > 1 {
                MapPolyline(coordinates: locations.map(\.coordinate))
                    .stroke(Color.accentColor, lineWidth: 5)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}
```

- [ ] **Step 4: Build**

Run:

```bash
xcodegen generate
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: PASS. The app still shows the placeholder Home view, and the reusable components compile.

- [ ] **Step 5: Commit**

```bash
git add PathTrio/Views/Components
git commit -m "feat: add shared workout UI components"
```

---

### Task 7: Main Screens

**Files:**
- Modify: `PathTrio/App/AppModel.swift`
- Modify: `PathTrio/Views/HomeView.swift`
- Create: `PathTrio/Views/ActiveWorkoutView.swift`
- Create: `PathTrio/Views/WorkoutSummaryView.swift`
- Create: `PathTrio/Views/HistoryView.swift`
- Create: `PathTrio/Views/WorkoutDetailView.swift`
- Create: `PathTrio/Views/SettingsView.swift`

- [ ] **Step 1: Replace AppModel with the MVP app state**

Modify `PathTrio/App/AppModel.swift`:

```swift
import Foundation
import Observation

@Observable
final class AppModel {
    var selectedWorkoutType: WorkoutType = .walk
    var activeDraft: WorkoutSessionDraft?
    var latestCompletedWorkoutID: UUID?
    var activeSuggestion: SmartAssistSuggestion?

    let recorder: WorkoutRecorder
    let settingsStore: SettingsStore
    let smartAssistEngine: SmartAssistEngine
    let locationService: LocationTrackingService
    let motionService: MotionActivityService

    init(
        recorder: WorkoutRecorder = WorkoutRecorder(distanceCalculator: DistanceCalculator()),
        settingsStore: SettingsStore = SettingsStore(),
        smartAssistEngine: SmartAssistEngine = SmartAssistEngine(),
        locationService: LocationTrackingService = LocationTrackingService(),
        motionService: MotionActivityService = MotionActivityService()
    ) {
        self.recorder = recorder
        self.settingsStore = settingsStore
        self.smartAssistEngine = smartAssistEngine
        self.locationService = locationService
        self.motionService = motionService
    }

    var smartAssistSettings: SmartAssistSettings {
        SmartAssistSettings(
            smartActivityAlertsEnabled: settingsStore.smartActivityAlertsEnabled,
            autoPauseEnabled: settingsStore.autoPauseEnabled,
            speedAnomalyAlertsEnabled: settingsStore.speedAnomalyAlertsEnabled
        )
    }
}
```

- [ ] **Step 2: Add Home screen**

Modify `PathTrio/Views/HomeView.swift`:

```swift
import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showingActiveWorkout = false
    @State private var showingHistory = false
    @State private var showingSettings = false

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PathTrio")
                        .font(.largeTitle.bold())
                    Text("Walk, Run & Ride Tracker")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    MetricTile(title: "Today", value: "0.00 km", systemImage: "map")
                    MetricTile(title: "Time", value: "00:00", systemImage: "timer")
                }

                WorkoutTypePicker(selection: $appModel.selectedWorkoutType)

                Button {
                    appModel.activeDraft = appModel.recorder.start(type: appModel.selectedWorkoutType)
                    showingActiveWorkout = true
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()

                HStack {
                    Button {
                        showingHistory = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }

                    Spacer()

                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationDestination(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView()
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}
```

- [ ] **Step 3: Add Active Workout screen**

Create `PathTrio/Views/ActiveWorkoutView.swift`:

```swift
import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndConfirmation = false
    @State private var completedDraft: WorkoutSessionDraft?

    var body: some View {
        VStack(spacing: 0) {
            RouteMapView(locations: appModel.recorder.draft?.locations ?? [])
                .frame(maxHeight: .infinity)

            VStack(spacing: 14) {
                let draft = appModel.recorder.draft ?? appModel.activeDraft
                let metrics = draft?.metrics ?? WorkoutMetrics(duration: 0, distanceMeters: 0, averageSpeedMetersPerSecond: 0)
                let type = draft?.type ?? appModel.selectedWorkoutType

                HStack(spacing: 12) {
                    MetricTile(title: "Time", value: WorkoutMetricsFormatter.duration(metrics.duration), systemImage: "timer")
                    MetricTile(title: "Distance", value: WorkoutMetricsFormatter.distance(metrics.distanceMeters), systemImage: "map")
                }

                HStack(spacing: 12) {
                    MetricTile(
                        title: type.emphasizesPace ? "Pace" : "Speed",
                        value: type.emphasizesPace ? WorkoutMetricsFormatter.pace(metrics.paceSecondsPerKilometer) : WorkoutMetricsFormatter.speed(metrics.averageSpeedMetersPerSecond),
                        systemImage: type.emphasizesPace ? "speedometer" : "gauge.with.dots.needle.67percent"
                    )
                    MetricTile(title: "Status", value: statusText(draft?.state), systemImage: "waveform.path.ecg")
                }

                HStack(spacing: 12) {
                    Button {
                        if appModel.recorder.draft?.state == .recording {
                            _ = appModel.recorder.pause()
                        } else {
                            _ = appModel.recorder.resume()
                        }
                    } label: {
                        Label(appModel.recorder.draft?.state == .recording ? "Pause" : "Resume", systemImage: appModel.recorder.draft?.state == .recording ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        showingEndConfirmation = true
                    } label: {
                        Label("End", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(.regularMaterial)
        }
        .navigationBarBackButtonHidden()
        .confirmationDialog("End workout?", isPresented: $showingEndConfirmation, titleVisibility: .visible) {
            Button("End Workout", role: .destructive) {
                completedDraft = appModel.recorder.end()
                appModel.activeDraft = nil
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $completedDraft) { draft in
            WorkoutSummaryView(draft: draft) {
                dismiss()
            }
        }
    }

    private func statusText(_ state: WorkoutState?) -> String {
        switch state {
        case .recording: "Recording"
        case .paused: "Paused"
        case .autoPaused: "Auto Paused"
        case .ended: "Ended"
        case .idle, .none: "Ready"
        }
    }
}
```

- [ ] **Step 4: Add summary screen**

Create `PathTrio/Views/WorkoutSummaryView.swift`:

```swift
import SwiftUI

struct WorkoutSummaryView: View {
    let draft: WorkoutSessionDraft
    let done: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                RouteMapView(locations: draft.locations)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    MetricTile(title: "Distance", value: WorkoutMetricsFormatter.distance(draft.metrics.distanceMeters), systemImage: "map")
                    MetricTile(title: "Duration", value: WorkoutMetricsFormatter.duration(draft.metrics.duration), systemImage: "timer")
                }

                MetricTile(
                    title: draft.type.emphasizesPace ? "Average Pace" : "Average Speed",
                    value: draft.type.emphasizesPace ? WorkoutMetricsFormatter.pace(draft.metrics.paceSecondsPerKilometer) : WorkoutMetricsFormatter.speed(draft.metrics.averageSpeedMetersPerSecond),
                    systemImage: "speedometer"
                )

                Spacer()
            }
            .padding()
            .navigationTitle("Workout Saved")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: done)
                }
            }
        }
    }
}
```

- [ ] **Step 5: Add history and detail screens**

Create `PathTrio/Views/HistoryView.swift`:

```swift
import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSessionModel.startedAt, order: .reverse) private var workouts: [WorkoutSessionModel]

    var body: some View {
        NavigationStack {
            List(workouts) { workout in
                NavigationLink {
                    WorkoutDetailView(workout: workout)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.type.displayName)
                            .font(.headline)
                        Text("\(WorkoutMetricsFormatter.distance(workout.distanceMeters)) · \(WorkoutMetricsFormatter.duration(workout.duration))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if workouts.isEmpty {
                    ContentUnavailableView("No Workouts", systemImage: "figure.walk", description: Text("Your saved walks, runs, and rides will appear here."))
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

Create `PathTrio/Views/WorkoutDetailView.swift`:

```swift
import CoreLocation
import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutSessionModel

    private var locations: [CLLocation] {
        workout.locations
            .sorted { $0.timestamp < $1.timestamp }
            .map {
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude),
                    altitude: $0.altitude,
                    horizontalAccuracy: $0.horizontalAccuracy,
                    verticalAccuracy: -1,
                    course: $0.course,
                    speed: $0.speedMetersPerSecond,
                    timestamp: $0.timestamp
                )
            }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                RouteMapView(locations: locations)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    MetricTile(title: "Distance", value: WorkoutMetricsFormatter.distance(workout.distanceMeters), systemImage: "map")
                    MetricTile(title: "Duration", value: WorkoutMetricsFormatter.duration(workout.duration), systemImage: "timer")
                }

                MetricTile(
                    title: workout.type.emphasizesPace ? "Pace" : "Speed",
                    value: workout.type.emphasizesPace ? WorkoutMetricsFormatter.pace(workout.distanceMeters > 0 ? workout.duration / (workout.distanceMeters / 1_000) : nil) : WorkoutMetricsFormatter.speed(workout.averageSpeedMetersPerSecond),
                    systemImage: "speedometer"
                )
            }
            .padding()
        }
        .navigationTitle(workout.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

- [ ] **Step 6: Add settings screen**

Create `PathTrio/Views/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = appModel.settingsStore

        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Units", selection: $settings.preferredUnits) {
                        Text("Metric").tag("metric")
                    }
                }

                Section("Smart Assist") {
                    Toggle("Smart Activity Alerts", isOn: $settings.smartActivityAlertsEnabled)
                    Toggle("Auto Pause", isOn: $settings.autoPauseEnabled)
                    Toggle("Speed Anomaly Alerts", isOn: $settings.speedAnomalyAlertsEnabled)
                }

                Section("Privacy") {
                    Text("PathTrio stores workouts locally by default and uses location only to record active workout routes, distance, and speed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

- [ ] **Step 7: Build**

Run:

```bash
xcodegen generate
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: PASS. Active workouts can be started, paused, ended, and summarized with in-memory data; SwiftData saving is wired in Task 8.

- [ ] **Step 8: Commit**

```bash
git add PathTrio/App/AppModel.swift PathTrio/Views
git commit -m "feat: add PathTrio MVP screens"
```

---

### Task 8: Wire Saving, Location Updates, And Smart Assist Prompts

**Files:**
- Modify: `PathTrio/Views/HomeView.swift`
- Modify: `PathTrio/Views/ActiveWorkoutView.swift`
- Modify: `PathTrio/Views/WorkoutSummaryView.swift`

- [ ] **Step 1: Confirm AppModel exposes live services**

Run:

```bash
rg -n "locationService|motionService|smartAssistSettings" PathTrio/App/AppModel.swift
```

Expected: output contains all three names. If any are missing, re-apply Task 7 Step 1 before continuing.

- [ ] **Step 2: Start location and motion on workout start**

Modify the Start button action in `PathTrio/Views/HomeView.swift`:

```swift
Button {
    appModel.locationService.requestWhenInUsePermission()
    appModel.activeDraft = appModel.recorder.start(type: appModel.selectedWorkoutType)
    appModel.locationService.start(backgroundAllowed: false)
    if appModel.settingsStore.isAnySmartAssistEnabled {
        appModel.motionService.start()
    }
    showingActiveWorkout = true
} label: {
    Label("Start", systemImage: "play.fill")
        .font(.title3.weight(.semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
}
```

- [ ] **Step 3: Poll service updates in Active Workout**

Modify `PathTrio/Views/ActiveWorkoutView.swift` to add this modifier to the outer `VStack`:

```swift
.onChange(of: appModel.locationService.latestLocations.count) { _, _ in
    appModel.activeDraft = appModel.recorder.addLocations(appModel.locationService.latestLocations)
    if let draft = appModel.recorder.draft {
        appModel.activeSuggestion = appModel.smartAssistEngine.evaluate(
            workoutType: draft.type,
            currentSpeedMetersPerSecond: draft.metrics.averageSpeedMetersPerSecond,
            detectedActivity: appModel.motionService.detectedActivity,
            settings: appModel.smartAssistSettings
        )
    }
}
.alert(item: Binding(
    get: { appModel.activeSuggestion },
    set: { appModel.activeSuggestion = $0 }
)) { suggestion in
    Alert(
        title: Text(suggestion.title),
        message: Text(suggestion.message),
        dismissButton: .default(Text("OK"))
    )
}
```

- [ ] **Step 4: Stop services when ending**

Modify the `End Workout` action in `PathTrio/Views/ActiveWorkoutView.swift`:

```swift
Button("End Workout", role: .destructive) {
    appModel.locationService.stop()
    appModel.motionService.stop()
    completedDraft = appModel.recorder.end()
    appModel.activeDraft = nil
}
```

- [ ] **Step 5: Save completed workout from summary**

Modify `PathTrio/Views/WorkoutSummaryView.swift` to save with SwiftData:

```swift
import SwiftData
import SwiftUI

struct WorkoutSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppModel.self) private var appModel
    let draft: WorkoutSessionDraft
    let done: () -> Void
    @State private var saveErrorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                RouteMapView(locations: draft.locations)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    MetricTile(title: "Distance", value: WorkoutMetricsFormatter.distance(draft.metrics.distanceMeters), systemImage: "map")
                    MetricTile(title: "Duration", value: WorkoutMetricsFormatter.duration(draft.metrics.duration), systemImage: "timer")
                }

                MetricTile(
                    title: draft.type.emphasizesPace ? "Average Pace" : "Average Speed",
                    value: draft.type.emphasizesPace ? WorkoutMetricsFormatter.pace(draft.metrics.paceSecondsPerKilometer) : WorkoutMetricsFormatter.speed(draft.metrics.averageSpeedMetersPerSecond),
                    systemImage: "speedometer"
                )

                if let saveErrorMessage {
                    Text(saveErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Workout Saved")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: done)
                }
            }
            .task {
                do {
                    let store = WorkoutStore(context: modelContext)
                    _ = try store.saveCompletedWorkout(
                        draft,
                        smartAssistEnabledAtStart: appModel.settingsStore.isAnySmartAssistEnabled
                    )
                } catch {
                    saveErrorMessage = "This workout could not be saved. Please try again."
                }
            }
        }
    }
}
```

- [ ] **Step 6: Build and test**

Run:

```bash
xcodegen generate
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add PathTrio/Views/HomeView.swift PathTrio/Views/ActiveWorkoutView.swift PathTrio/Views/WorkoutSummaryView.swift
git commit -m "feat: wire workout recording flow"
```

---

### Task 9: Final Verification And Push

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add project README**

Create `README.md`:

````markdown
# PathTrio

PathTrio is an iOS app for tracking walks, runs, and rides with reliable GPS routes and optional Smart Assist.

## MVP

- Manual Walk, Run, and Ride recording
- Route map, duration, distance, pace, and speed
- Local workout history
- Optional Smart Activity Alerts, Auto Pause, and Speed Anomaly Alerts
- Private by default, no account required

## Development

Generate the Xcode project:

```bash
xcodegen generate
```

Build:

```bash
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Test:

```bash
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17'
```

Real-device testing is required for GPS, background location, CoreMotion, and battery behavior.
````

- [ ] **Step 2: Run clean generation**

Run:

```bash
rm -rf PathTrio.xcodeproj
xcodegen generate
```

Expected: `PathTrio.xcodeproj` is generated successfully.

- [ ] **Step 3: Run full test suite**

Run:

```bash
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: PASS.

- [ ] **Step 4: Run app build**

Run:

```bash
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: PASS.

- [ ] **Step 5: Inspect git diff**

Run:

```bash
git status --short
git diff --stat
```

Expected: only intentional project files are changed.

- [ ] **Step 6: Commit README and any final fixes**

```bash
git add README.md project.yml PathTrio PathTrioTests
git commit -m "docs: add PathTrio development instructions"
```

- [ ] **Step 7: Push**

```bash
git push origin main
```

Expected: GitHub repository `philyu8259-create/PathTrio` contains the generated MVP source and passing test suite.

---

## Self-Review

Spec coverage:

- Manual Walk, Run, and Ride selection: covered in Tasks 2, 6, and 7.
- Active workout route, time, distance, pace, and speed: covered in Tasks 3, 6, 7, and 8.
- Local history and workout detail: covered in Tasks 4 and 7.
- Smart Assist switches and non-mutating suggestions: covered in Tasks 5, 7, and 8.
- Permission-aware GPS and background location copy: covered in Tasks 1, 5, and 8.
- Privacy and no-account posture: covered in Tasks 7 and 9.
- Testing: covered in Tasks 3, 5, 8, and 9.

Known follow-up after this plan:

- Real-device validation for GPS, background location, CoreMotion, and battery behavior.
- Better visual design pass after the functional MVP is running.
- App icon and launch branding.
- HealthKit integration in a later version.
