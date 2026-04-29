# PathTrio

PathTrio is an iOS workout tracker for walking, running, and cycling.

The first version keeps the primary flow deliberately simple: users choose a workout type, start recording, review live route and metrics, then save the completed session. Optional Smart Assist settings can use motion activity and speed checks to suggest pauses, activity-type changes, or unusual-speed warnings without taking control away from the user.

## App Names

- English name: PathTrio
- English subtitle: Walk Run Ride Tracker
- Chinese name: 三动迹
- Chinese subtitle: 走路跑步骑行记录

## MVP Scope

- Manual workout selection for walk, run, and ride
- GPS route, duration, distance, pace, speed, and calorie estimate
- Pause, resume, end, summary, history, and workout detail views
- SwiftData local persistence for completed workouts and route points
- Optional Smart Assist toggles for auto-pause prompts, motion-type change prompts, and speed anomaly prompts
- Location and motion usage descriptions ready for App Store review wording

## Requirements

- Xcode with iOS 17 SDK or newer
- XcodeGen installed and available in `PATH`

## Development

Generate the Xcode project:

```sh
xcodegen generate
```

Run the test suite:

```sh
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17'
```

Build the app:

```sh
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Notes

- Background location is declared so the app can continue recording during an active workout after the screen locks.
- The current UI starts with foreground workout tracking. A later release should add a user-facing background-recording switch before enabling always-on behavior in production.
- HealthKit sync is intentionally deferred until the core recording and history flow is stable.
