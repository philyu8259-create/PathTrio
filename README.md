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
- Optional background recording toggle for active workouts
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
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'
```

Build the app:

```sh
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

## Notes

- Background location is declared so the app can continue recording during an active workout after the screen locks.
- Background location remains user-controlled and is only requested when the background recording setting is enabled.
- HealthKit sync is optional and controlled by the user's Pro/settings choices.

## Public Pages

- Support email: 67238615@qq.com
- Support: https://philyu8259-create.github.io/PathTrio/support-en.html
- Privacy Policy: https://philyu8259-create.github.io/PathTrio/privacy-policy-en.html
- Terms of Use: https://www.apple.com/legal/internet-services/itunes/appstore/dev/stdeula/
- 中文支持: https://philyu8259-create.github.io/PathTrio/support-zh-Hans.html
- 中文隐私政策: https://philyu8259-create.github.io/PathTrio/privacy-policy-zh-Hans.html
- 中文使用条款（Apple 标准 EULA）: https://www.apple.com/legal/internet-services/itunes/appstore/dev/stdeula/
