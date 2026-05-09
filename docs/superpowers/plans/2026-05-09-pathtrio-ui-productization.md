# PathTrio UI Productization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the existing functional PathTrio MVP surfaces into a more polished bilingual activity-tracker UI without changing workout, GPS, Smart Assist, HealthKit, or persistence behavior.

**Architecture:** Add a small local SwiftUI design layer for color, spacing, card backgrounds, and repeated setting/dashboard components. Refactor only the screen views in scope: `HomeView`, `ActiveWorkoutView`, `SettingsView`, `HistoryView`, plus existing small components where that keeps code focused.

**Tech Stack:** SwiftUI, SwiftData, XcodeGen, existing `@Environment(AppModel.self)` state, existing localization tables, iPhone 16 Pro Max simulator verification.

---

### Task 1: Add Local UI Theme And Reusable Polish Components

**Files:**
- Create: `PathTrio/Views/Components/PathTrioTheme.swift`
- Modify: `project.yml`

- [ ] **Step 1: Add the theme file**

Create `PathTrio/Views/Components/PathTrioTheme.swift` with:

```swift
import SwiftUI

enum PathTrioTheme {
    static let pageBackground = Color(red: 0.965, green: 0.976, blue: 0.980)
    static let ink = Color(red: 0.055, green: 0.071, blue: 0.090)
    static let muted = Color(red: 0.420, green: 0.463, blue: 0.510)
    static let action = Color(red: 0.000, green: 0.478, blue: 0.933)
    static let teal = Color(red: 0.000, green: 0.620, blue: 0.560)
    static let warm = Color(red: 0.940, green: 0.470, blue: 0.150)
    static let line = Color.black.opacity(0.08)

    static func tint(for type: WorkoutType) -> Color {
        switch type {
        case .walk: teal
        case .run: warm
        case .ride: action
        }
    }
}

struct PathTrioCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PathTrioTheme.line, lineWidth: 1)
            }
    }
}

extension View {
    func pathTrioCard() -> some View {
        modifier(PathTrioCardBackground())
    }
}
```

- [ ] **Step 2: Regenerate the project**

Run:

```bash
xcodegen generate
```

Expected: `Created project at .../PathTrio.xcodeproj`.

- [ ] **Step 3: Build to verify new file wiring**

Run:

```bash
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

Expected: `** BUILD SUCCEEDED **`.

### Task 2: Productize Home Dashboard

**Files:**
- Modify: `PathTrio/Views/HomeView.swift`
- Modify: `PathTrio/Views/Components/MetricTile.swift`
- Modify: `PathTrio/Views/Components/WorkoutTypePicker.swift`

- [ ] **Step 1: Refactor `MetricTile` into a stronger metric component**

Keep the same initializer and make the visual style use larger numeric type, white card background, stable height, and the local theme.

- [ ] **Step 2: Refactor `WorkoutTypePicker` into mode cards**

Keep the same binding API. Use `PathTrioTheme.tint(for:)`, icon badges, selected border, and fixed card height so the three modes read as app-specific controls.

- [ ] **Step 3: Refactor `HomeView` layout**

Use a `ZStack` page background, `ScrollView`, a compact brand header, a prominent today summary section, the improved mode picker, a large start button, and polished bottom actions for history/settings. Keep the existing start-workout behavior exactly as it is.

- [ ] **Step 4: Build**

Run:

```bash
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

Expected: `** BUILD SUCCEEDED **`.

### Task 3: Productize Settings And History Empty State

**Files:**
- Modify: `PathTrio/Views/SettingsView.swift`
- Modify: `PathTrio/Views/HistoryView.swift`

- [ ] **Step 1: Replace plain settings `Form` with custom grouped panels**

Keep all current bindings, confirmation dialogs, load/save behavior, and strings. Use `ScrollView` and custom rows so settings no longer look like a raw scaffold.

- [ ] **Step 2: Keep privacy-sensitive toggles behavior unchanged**

Verify that enabling background recording still shows `settings.recording.backgroundConfirm.*` and enabling Health sync still shows `settings.health.confirm.*`.

- [ ] **Step 3: Replace history empty overlay**

For empty history, use a centered custom empty state with a stronger icon treatment, title, and description. Keep real history list behavior unchanged when workouts exist.

- [ ] **Step 4: Build**

Run:

```bash
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

Expected: `** BUILD SUCCEEDED **`.

### Task 4: Productize Active Workout Recorder

**Files:**
- Modify: `PathTrio/Views/ActiveWorkoutView.swift`

- [ ] **Step 1: Rework the bottom recorder panel**

Keep the map dominant. Make the bottom panel feel like a live recorder with large time and distance values, secondary pace/speed and status, compact warning strips, and clear pause/end controls.

- [ ] **Step 2: Preserve recording behavior**

Keep the existing route status evaluation, location consumption, Smart Assist alert, end confirmation, and summary sheet logic intact.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

Expected: `** BUILD SUCCEEDED **`.

### Task 5: Full Verification And Screenshots

**Files:**
- No planned production edits.

- [ ] **Step 1: Run localized tests and full test suite**

Run:

```bash
xcodebuild test -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'
```

Expected: `** TEST SUCCEEDED **` with all tests passing.

- [ ] **Step 2: Run final build**

Run:

```bash
xcodebuild -scheme PathTrio -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Capture screenshots**

Run the app on iPhone 16 Pro Max and capture:
- Home.
- Settings.
- Background recording confirmation.
- Apple Health confirmation.
- History empty state.
- Active workout screen if simulator permissions allow launching the flow.

- [ ] **Step 4: Commit and push**

Run:

```bash
git add PathTrio PathTrioTests project.yml PathTrio.xcodeproj docs/superpowers/plans/2026-05-09-pathtrio-ui-productization.md
git commit -m "feat: productize core ui surfaces"
git push origin main
```

Expected: changes are pushed to `main`.

## Self Review

This plan covers every scoped screen from the UI productization spec: Home, Active Workout, Settings, and History empty state. It avoids new product features, preserves manual-first recording and optional Smart Assist/HealthKit/background GPS, and requires visual simulator screenshots in addition to tests and build verification.
