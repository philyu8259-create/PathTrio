# PathTrio MVP Design

Date: 2026-04-29

## Product Positioning

PathTrio is a focused iOS tracker for three outdoor movement types: walking, running, and cycling. The core promise is reliable manual workout recording with clear GPS routes, simple stats, and optional smart assistance that helps users avoid missed pauses, activity changes, and speed anomalies.

The app should not present itself as a fully automatic always-on tracker in the first release. The first release is user-initiated, privacy-conscious, and predictable.

English app metadata:

- App Name: PathTrio
- Subtitle: Walk, Run & Ride Tracker

Chinese app metadata:

- App Name: 三动迹
- Subtitle: 步行跑步骑行记录

Suggested positioning copy:

- English: Track walks, runs, and rides with reliable GPS routes, plus optional smart motion assistance.
- Chinese: 稳定记录步行、跑步、骑行路线，也可开启智能运动辅助。

## MVP Goals

The MVP should make one complete workout flow feel dependable:

1. User opens the app.
2. User chooses Walk, Run, or Ride.
3. User starts recording.
4. App records route, time, distance, and pace or speed.
5. User can pause, resume, and end the workout.
6. App saves the workout locally.
7. User can review the workout in history with its map route and summary stats.

The primary mode is manual and stable. Smart Assist is optional and user-controlled.

## Non-Goals For Version 1

Version 1 should not include:

- Apple Watch support.
- Social feed or friend system.
- Training plans or coaching.
- AI coach features.
- Fully automatic all-day workout detection.
- Cloud sync or account system.
- Subscription paywall.
- Complex route replay animation.
- GPX export.
- Live Activity or Dynamic Island.

These can be considered after the basic workout-recording loop is reliable.

## Core User Flows

### First Launch

The app introduces its purpose briefly and requests permissions only when needed. It should explain that location is used to record workout routes, distance, and speed. Background location should be requested only when the user starts a workout or enables the feature after seeing a clear explanation.

### Start Workout

Home shows three movement choices:

- Walk
- Run
- Ride

The user selects one type and taps Start. Manual selection is the authoritative workout type for the saved record unless the user explicitly changes it.

### Active Workout

The active workout screen shows:

- Live map route.
- Elapsed time.
- Distance.
- Current speed or current pace.
- Average speed or average pace.
- Pause or Resume.
- End.

For Walk and Run, pace should be emphasized. For Ride, speed should be emphasized.

### End Workout

When the user taps End, the app asks for confirmation to avoid accidental loss. After confirmation, it saves the workout and opens a summary screen.

### Review Workout

The summary and detail screens show:

- Workout type.
- Date and time.
- Duration.
- Distance.
- Average pace or speed.
- Estimated calories, if enough profile data exists.
- Route map.

Estimated calories should be labeled as estimated. In Version 1, calories should stay hidden until the user enters body weight or grants a future HealthKit profile integration. The app should not show a calorie number based only on distance and workout type.

## Smart Assist

Smart Assist is optional and off by default in Version 1. It should help users notice likely issues after they enable it, not silently overwrite their workout.

Settings should include three independent switches:

1. Smart Activity Alerts, default off
   - Uses CoreMotion activity signals to detect likely movement-type changes.
   - Example: User selected Run, but sustained activity looks like cycling.
   - Behavior: show a prompt asking whether to switch type.
   - It does not change the workout type without user confirmation.

2. Auto Pause, default off
   - Detects sustained stillness or very low movement.
   - Behavior: pauses after a conservative threshold, then resumes when movement returns.
   - The active workout screen should make auto-paused state obvious.

3. Speed Anomaly Alerts, default off
   - Detects speeds that are implausible for the selected workout type.
   - Example: a Walk workout suddenly moves at car speed.
   - Behavior: prompt the user to pause, continue, or switch type if appropriate.

Smart Assist should not save motor-vehicle travel as a workout automatically. If the app detects likely automotive movement during a workout, it should warn the user rather than making irreversible changes.

## Screens

### Home

Home is the main action screen, not a complex dashboard. It should include:

- Today summary: distance and time.
- Three movement type controls.
- Large Start action.
- Small entries for History and Settings.

### Active Workout

The active workout screen should be optimized for glancing during movement:

- Map takes most of the screen.
- Key stats are large and readable.
- Controls are easy to tap.
- End action is protected by confirmation.

### Workout Summary

The summary appears immediately after ending a workout. It confirms that the workout was saved and shows the route and core stats.

### History

History lists saved workouts in reverse chronological order. Each item shows type, date, distance, duration, and pace or speed.

### Workout Detail

Detail shows the full route and stats for one saved workout.

### Settings

Settings includes:

- Units: metric first, with future support for imperial.
- Smart Assist switches.
- Location permission status and explanation.
- HealthKit connection, if implemented in a later version.
- Privacy statement.

## Data Model

### WorkoutSession

Fields:

- id
- type: walk, run, ride
- startedAt
- endedAt
- duration
- distanceMeters
- averageSpeedMetersPerSecond
- averagePaceSecondsPerKilometer, for walk and run
- estimatedCalories
- source: manual
- smartAssistEnabledAtStart
- createdAt
- updatedAt

### LocationPoint

Fields:

- id
- workoutSessionId
- timestamp
- latitude
- longitude
- horizontalAccuracy
- altitude
- speedMetersPerSecond
- course

The app should store enough route detail to render the workout map later, but it should filter obviously poor GPS points when calculating distance.

### UserSettings

Fields:

- preferredUnits
- smartActivityAlertsEnabled
- autoPauseEnabled
- speedAnomalyAlertsEnabled
- bodyWeightKilograms, optional
- healthKitSyncEnabled, future

## Technical Architecture

Recommended stack:

- SwiftUI for UI.
- CoreLocation for GPS route tracking.
- MapKit for maps and route display.
- CoreMotion and CMMotionActivityManager for Smart Assist.
- SwiftData for local persistence if the minimum iOS version allows it; otherwise Core Data.
- HealthKit as a later optional integration.

Core modules:

- LocationTrackingService: owns CLLocationManager, permissions, location updates, and background tracking.
- WorkoutRecorder: owns workout state, distance calculation, pause and resume, and route point filtering.
- MotionActivityService: wraps CoreMotion activity updates and exposes simplified activity signals.
- SmartAssistEngine: combines motion, speed, and workout state to produce user-facing prompts.
- WorkoutStore: persists sessions and points.
- SettingsStore: persists user preferences.

The SmartAssistEngine should produce suggestions or alerts, not mutate workout data directly. WorkoutRecorder remains the source of truth for the active session.

## Location And Background Policy

The app should request location permission in context:

- While-in-use location permission is needed for foreground workout recording.
- Always location permission is needed only if background workout recording is enabled.
- Background location should only be active during an active workout.
- Location updates must stop immediately when the workout ends.

The app should include clear permission copy explaining:

- Location records workout route, distance, and speed.
- Background location keeps recording when the screen is locked during an active workout.
- Route data is stored locally by default.

This approach reduces App Store review risk and matches user expectations.

## Battery Strategy

Version 1 should use a balanced default:

- Active movement: high enough GPS accuracy for route tracking.
- Auto-paused or sustained stillness: reduce update intensity where possible.
- Manual pause: avoid unnecessary route point accumulation.
- Workout ended: stop location updates immediately.

Future settings may expose Accuracy, Balanced, and Battery Saver modes, but the MVP should ship with one conservative balanced behavior.

## Privacy Strategy

PathTrio should be private by default:

- No account required.
- Workouts saved locally by default.
- No route upload in Version 1.
- HealthKit sync is optional when added.
- Permission explanations are visible in Settings.

Future sharing features should support hiding start and end points before export or image sharing.

## Error Handling

The app should handle:

- Location permission denied: show an explanation and link to Settings.
- Poor GPS accuracy: show a subtle warning and avoid overcounting bad points.
- Background permission missing: allow foreground tracking and explain the limitation.
- Motion access unavailable: keep manual workout recording working; Smart Assist becomes unavailable.
- App termination during active workout: preserve enough state to recover or mark the workout as interrupted.

Manual recording must remain usable even when Smart Assist is unavailable.

## Testing And Verification

MVP verification should cover:

- Start, pause, resume, and end for Walk, Run, and Ride.
- Route point persistence and map rendering.
- Distance calculation with filtered GPS points.
- Permission-denied states.
- Background recording behavior.
- Auto Pause thresholds.
- Smart Activity Alerts do not change type without user confirmation.
- Speed Anomaly Alerts appear for implausible speeds.
- Workout history survives app relaunch.

Simulator tests can verify UI and persistence, but real-device testing is required for GPS, background location, CoreMotion, and battery behavior.

## Recommended Build Order

1. Create native iOS project shell.
2. Build local persistence models.
3. Build Home, Active Workout, Summary, History, Detail, and Settings screens with mock data.
4. Implement foreground CoreLocation workout recording.
5. Add distance calculation and GPS point filtering.
6. Add background location mode and permission flow.
7. Add CoreMotion Smart Assist signals.
8. Add Smart Assist settings and prompts.
9. Run real-device validation for location, background behavior, and Smart Assist.

## Open Product Decisions

The following decisions can be made during implementation without changing the MVP shape:

- Minimum iOS version.
- SwiftData versus Core Data, based on minimum iOS version.
- Exact Auto Pause thresholds.
- Exact speed anomaly thresholds for Walk, Run, and Ride.
- Whether to add HealthKit profile reading before showing estimated calories.

The recommended defaults are: iOS 17 or later if SwiftData is preferred, conservative Auto Pause thresholds, Smart Assist switches off by default, and calories hidden until profile data exists.
