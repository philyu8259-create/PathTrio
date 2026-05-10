import CoreLocation
import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSessionModel.startedAt, order: .reverse) private var workouts: [WorkoutSessionModel]
    @State private var showingActiveWorkout = false
    @State private var todayTotals = WorkoutTotals()
    let openHistory: () -> Void
    private let autoStartTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    private var recentWorkouts: [WorkoutSessionModel] {
        Array(workouts.prefix(2))
    }

    private var dashboardColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack {
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        statusStrip
                        routePreviewCard(for: appModel.selectedWorkoutType)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("home.mode.title")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(PathTrioTheme.muted)
                            WorkoutTypePicker(selection: $appModel.selectedWorkoutType)
                        }

                        if let reminder = appModel.autoStartReminder {
                            AutoStartReminderCard(reminder: reminder) {
                                appModel.selectedWorkoutType = reminder.workoutType
                                appModel.autoStartReminder = nil
                                startWorkout()
                            } dismiss: {
                                appModel.autoStartReminder = nil
                                appModel.autoStartReminderEngine.reset()
                            }
                        }

                        startButton
                        todayDashboard
                        recentSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 72)
                }
            }
            .navigationDestination(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView()
            }
            .task {
                loadSettings()
                updateAutoStartMonitoring()
                refreshTodayTotals()
            }
            .onChange(of: appModel.latestCompletedWorkoutID) { _, _ in
                refreshTodayTotals()
            }
            .onChange(of: appModel.settingsStore.autoStartRemindersEnabled) { _, _ in
                updateAutoStartMonitoring()
            }
            .onChange(of: appModel.motionService.detectedActivity) { _, _ in
                updateAutoStartReminder()
            }
            .onReceive(autoStartTimer) { date in
                updateAutoStartReminder(now: date)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                Text("app.name")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(PathTrioTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("app.subtitle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
            }

            Spacer()

            Image(systemName: "location.north.line.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(PathTrioTheme.actionGradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: PathTrioTheme.action.opacity(0.20), radius: 12, x: 0, y: 6)
                .accessibilityHidden(true)
        }
        .padding(.top, 8)
    }

    private var statusStrip: some View {
        HStack(spacing: 8) {
            HomeStatusPill(title: L10n.string("home.status.ready"), systemImage: "checkmark.circle.fill", tint: PathTrioTheme.teal)
            HomeStatusPill(title: L10n.string("home.status.gps"), systemImage: "location.fill", tint: PathTrioTheme.action)
            HomeStatusPill(
                title: L10n.string(appModel.settingsStore.isAnySmartAssistEnabled ? "home.status.smartAssistOn" : "home.status.smartAssistOff"),
                systemImage: "sparkle.magnifyingglass",
                tint: appModel.settingsStore.isAnySmartAssistEnabled ? PathTrioTheme.warm : PathTrioTheme.muted
            )
        }
    }

    private func routePreviewCard(for selectedType: WorkoutType) -> some View {
        ZStack(alignment: .bottomLeading) {
            RouteMapView(locations: routePreviewLocations(for: selectedType))
                .frame(height: 210)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("home.route.title", systemImage: "map.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PathTrioTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.regularMaterial, in: Capsule())

                    Spacer()

                    Image(systemName: selectedType.systemImage)
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(PathTrioTheme.tint(for: selectedType), in: Circle())
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("home.quickStart")
                        .font(.headline.weight(.black))
                        .foregroundStyle(PathTrioTheme.ink)
                    Text(L10n.string("home.route.subtitle", selectedType.displayName))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(PathTrioTheme.muted)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
                .blendMode(.overlay)
        }
        .shadow(color: .black.opacity(0.035), radius: 12, x: 0, y: 5)
    }

    private var startButton: some View {
        Button {
            startWorkout()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.headline.weight(.bold))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.22), in: Circle())

                Text("action.start")
                    .font(.title3.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(PathTrioTheme.actionGradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .shadow(color: PathTrioTheme.action.opacity(0.32), radius: 15, x: 0, y: 8)
    }

    private var todayDashboard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.today.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            LazyVGrid(columns: dashboardColumns, spacing: 10) {
                MetricTile(
                    title: L10n.string("metric.distance"),
                    value: WorkoutMetricsFormatter.distance(todayTotals.distanceMeters),
                    systemImage: "map",
                    tint: PathTrioTheme.teal
                )
                MetricTile(
                    title: L10n.string("metric.duration"),
                    value: WorkoutMetricsFormatter.duration(todayTotals.duration),
                    systemImage: "timer",
                    tint: PathTrioTheme.action
                )
                MetricTile(
                    title: L10n.string("home.today.sessions"),
                    value: "\(todayTotals.workoutCount)",
                    systemImage: "figure.mixed.cardio",
                    tint: PathTrioTheme.warm
                )
                MetricTile(
                    title: L10n.string("metric.calories"),
                    value: WorkoutMetricsFormatter.calories(todayTotals.estimatedCalories),
                    systemImage: "flame",
                    tint: .red
                )
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("home.recent.title")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.muted)
                Spacer()
                Button(action: openHistory) {
                    Label("history.title", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                }
                .font(.caption.weight(.bold))
                .buttonStyle(.plain)
                .foregroundStyle(PathTrioTheme.action)
            }

            if recentWorkouts.isEmpty {
                HomeEmptyRecentCard()
            } else {
                VStack(spacing: 8) {
                    ForEach(recentWorkouts) { workout in
                        Button(action: openHistory) {
                            HomeRecentWorkoutRow(workout: workout)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func routePreviewLocations(for type: WorkoutType) -> [CLLocation] {
        let base: [(Double, Double)] = [
            (37.3349, -122.0090),
            (37.3372, -122.0068),
            (37.3401, -122.0079),
            (37.3420, -122.0045),
            (37.3448, -122.0057)
        ]
        let run: [(Double, Double)] = [
            (37.3318, -122.0312),
            (37.3332, -122.0275),
            (37.3368, -122.0257),
            (37.3389, -122.0218),
            (37.3407, -122.0186)
        ]
        let ride: [(Double, Double)] = [
            (37.3228, -122.0325),
            (37.3284, -122.0260),
            (37.3350, -122.0198),
            (37.3423, -122.0125),
            (37.3495, -122.0060)
        ]
        let coordinates = switch type {
        case .walk: base
        case .run: run
        case .ride: ride
        }
        return coordinates.map { CLLocation(latitude: $0.0, longitude: $0.1) }
    }

    private func startWorkout() {
        if appModel.settingsStore.backgroundRecordingEnabled {
            appModel.locationService.requestAlwaysPermission()
        } else {
            appModel.locationService.requestWhenInUsePermission()
        }
        appModel.activeDraft = appModel.recorder.start(type: appModel.selectedWorkoutType)
        appModel.autoStartReminder = nil
        appModel.autoStartReminderEngine.reset()
        appModel.locationService.start(backgroundAllowed: appModel.settingsStore.backgroundRecordingEnabled)
        if appModel.settingsStore.isAnySmartAssistEnabled {
            appModel.motionService.start()
        } else {
            appModel.motionService.stop()
        }
        showingActiveWorkout = true
    }

    private func loadSettings() {
        do {
            try SettingsPersistenceStore(context: modelContext).load(into: appModel.settingsStore)
        } catch {
            // Keep in-memory defaults if settings cannot be loaded.
        }
    }

    private func updateAutoStartMonitoring() {
        if appModel.settingsStore.autoStartRemindersEnabled {
            appModel.motionService.start()
        } else if !appModel.settingsStore.isAnySmartAssistEnabled {
            appModel.motionService.stop()
            appModel.autoStartReminder = nil
            appModel.autoStartReminderEngine.reset()
        }
    }

    private func updateAutoStartReminder(now: Date = Date()) {
        guard appModel.settingsStore.autoStartRemindersEnabled else { return }
        guard appModel.recorder.draft == nil else {
            appModel.autoStartReminder = nil
            appModel.autoStartReminderEngine.reset()
            return
        }
        if appModel.autoStartReminder != nil {
            return
        }

        appModel.autoStartReminder = appModel.autoStartReminderEngine.evaluate(
            detectedActivity: appModel.motionService.detectedActivity,
            now: now,
            isWorkoutActive: false
        )
    }

    private func refreshTodayTotals() {
        do {
            todayTotals = try WorkoutStore(context: modelContext).totals(forDayContaining: Date())
        } catch {
            todayTotals = WorkoutTotals()
        }
    }
}

private struct HomeStatusPill: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 9)
            .background(tint.opacity(0.12), in: Capsule())
            .background(.ultraThickMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.24), lineWidth: 1)
            }
            .shadow(color: tint.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

private struct HomeRecentWorkoutRow: View {
    let workout: WorkoutSessionModel

    private var paceOrSpeed: String {
        if workout.type.emphasizesPace {
            let pace = workout.distanceMeters > 0 ? workout.duration / (workout.distanceMeters / 1_000) : nil
            return WorkoutMetricsFormatter.pace(pace)
        }
        return WorkoutMetricsFormatter.speed(workout.averageSpeedMetersPerSecond)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.type.systemImage)
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(PathTrioTheme.tint(for: workout.type), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.displayName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                Text(workout.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(PathTrioTheme.muted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(WorkoutMetricsFormatter.distance(workout.distanceMeters))
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(PathTrioTheme.ink)
                Text(paceOrSpeed)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
            }
        }
        .padding(14)
        .pathTrioCard()
    }
}

private struct HomeEmptyRecentCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.title3.weight(.bold))
                .foregroundStyle(PathTrioTheme.teal)
                .frame(width: 42, height: 42)
                .background(PathTrioTheme.teal.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("home.recent.empty.title")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                Text("home.recent.empty.message")
                    .font(.caption)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .pathTrioCard()
    }
}

private struct AutoStartReminderCard: View {
    let reminder: AutoStartReminder
    let start: () -> Void
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: reminder.workoutType.systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(PathTrioTheme.tint(for: reminder.workoutType), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string("autoStart.title", reminder.workoutType.displayName))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                Text("autoStart.message")
                    .font(.footnote)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .foregroundStyle(PathTrioTheme.muted)

            Button(action: start) {
                Image(systemName: "play.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(PathTrioTheme.action, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PathTrioTheme.action.opacity(0.2), lineWidth: 1)
        }
    }
}
