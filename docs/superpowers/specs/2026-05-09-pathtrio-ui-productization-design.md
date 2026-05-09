# PathTrio UI Productization Design

Date: 2026-05-09

## Goal

PathTrio currently works like a functional MVP, but the interface feels like a scaffold. This pass should make it feel like a real bilingual walking, running, and cycling tracker while preserving the product strategy already chosen: manual-first recording, optional Smart Assist, optional background GPS, and optional Apple Health sync.

The first version of this UI polish should focus on the main app surfaces, not on adding new features.

## Product Direction

The app should feel like a focused outdoor activity recorder: clear, energetic, trustworthy, and easy to operate one-handed. It should not feel like a generic settings demo or a template SwiftUI sample.

The visual language should use:
- Clean white or near-white surfaces for readability.
- Strong blue/teal action color for recording and GPS confidence.
- Warm accent color for running or active alerts.
- Compact cards with 8 px corner radii where cards are truly useful.
- Larger metric typography on the workout surfaces.
- Native SF Symbols for actions and workout modes.

Avoid decorative gradients, marketing hero sections, nested cards, and purely cosmetic illustration.

## Screens In Scope

### Home

The home screen becomes the app's main dashboard.

It should include:
- A compact brand header with `三动迹` / `PathTrio` and subtitle.
- A prominent today summary with distance and time.
- Three workout mode cards for walking, running, and cycling, each with an icon, label, and selected state.
- A large start control that feels like the primary action of the app.
- Small but polished history and settings actions.

The screen should remain usable even before the user has any workout history.

### Active Workout

The active workout screen should feel like a live recorder, not a map with controls attached.

It should include:
- A map region that remains visually dominant.
- A bottom recording panel with large time and distance values.
- Pace or speed presented as a secondary but readable metric.
- Clear pause/resume and end controls.
- Route recording warnings as compact status strips.

The existing recording behavior and data flow should remain unchanged.

### Settings

Settings should still be easy to scan, but it should stop looking like an untouched system template.

It should include:
- Custom grouped panels instead of a plain `Form` look.
- Clear setting rows with icons where useful.
- The existing confirmation dialogs for background recording and Apple Health sync.
- The planned Apple Health write list in a clean checklist style.
- The privacy explanation as a concise footer panel.

### History Empty State

The empty history screen should look intentional.

It should include:
- A stronger empty-state icon treatment.
- Clear title and description.
- No fake data.

## Out Of Scope

This pass will not add charts, training plans, social sharing, goals, badges, weather, achievements, or account features.

This pass will not change the workout model, GPS recording pipeline, Smart Assist logic, HealthKit sync logic, or persistence schema unless a small UI-only helper is needed.

## Localization

All visible user-facing text added during this pass must exist in both English and Simplified Chinese. Existing bilingual behavior must remain intact.

The layout must handle Chinese text without truncation on iPhone 16 Pro Max. If practical, it should also remain reasonable on smaller iPhones, but the requested simulator target for verification is iPhone 16 Pro Max.

## Implementation Shape

Prefer a small local design layer rather than scattering magic colors and styles through each view.

Likely additions:
- `PathTrioTheme` or a similarly small helper for colors, spacing, and repeated backgrounds.
- Reusable row/card subviews for dashboard metrics, setting rows, and mode cards.
- Focused refactors inside `HomeView`, `ActiveWorkoutView`, `SettingsView`, and `HistoryView`.

Existing service and persistence code should not be touched for visual polish.

## Verification

Required verification:
- `xcodegen generate` if project structure changes.
- `xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'`.
- `xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build`.
- Simulator screenshots for Home, Settings, background recording confirmation, Apple Health confirmation, and History empty state.

The final result should be judged visually, not just by tests passing.

## Self Review

This spec is intentionally scoped to productizing the existing app UI. It does not introduce new app behavior, does not contradict the existing manual-first PathTrio direction, and keeps HealthKit and background GPS as optional user-controlled settings.
