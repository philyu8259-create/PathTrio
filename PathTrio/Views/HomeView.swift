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

    private var activeMapStyle: PathTrioMapStyle {
        appModel.entitlementStore.canUse(.mapStyles) ? appModel.settingsStore.preferredMapStyle : .standard
    }

    private var goalProgress: [WorkoutGoalProgress] {
        WorkoutGoalProgressCalculator().progress(
            for: workouts,
            weeklyDistanceGoalMeters: appModel.settingsStore.weeklyDistanceGoalMeters,
            monthlyWorkoutGoalCount: appModel.settingsStore.monthlyWorkoutGoalCount
        )
    }

    private var currentPreviewLocations: [CLLocation] {
        guard let latestLocation = appModel.locationService.latestLocations.last else { return [] }
        return [latestLocation]
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
                        goalsSection
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
            .toolbar(.hidden, for: .navigationBar)
            .task {
                appModel.loadSettings(from: modelContext)
                appModel.reconcileLockedProSettings(in: modelContext)
                appModel.locationService.preparePreviewLocation()
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
        HStack(alignment: .center, spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(.white.opacity(0.82), lineWidth: 1)
                }
                .shadow(color: PathTrioTheme.action.opacity(0.18), radius: 12, x: 0, y: 6)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("app.name")
                        .font(.system(size: 31, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    PathTrioTheme.ink.opacity(0.94),
                                    PathTrioTheme.action.opacity(0.86)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)

                    Text("PathTrio")
                        .font(.caption.weight(.black))
                        .foregroundStyle(PathTrioTheme.action)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(PathTrioTheme.action.opacity(0.10), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(PathTrioTheme.action.opacity(0.14), lineWidth: 1)
                        }
                        .lineLimit(1)
                }

                Text("app.subtitle")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Spacer()
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
            RouteMapView(locations: currentPreviewLocations, followsLatestLocation: true, style: activeMapStyle)
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

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("goals.title")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.muted)

                Spacer()

                Text("pro.badge")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(PathTrioTheme.warm)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(PathTrioTheme.warm.opacity(0.12), in: Capsule())
            }

            if appModel.entitlementStore.canUse(.goals) {
                VStack(spacing: 10) {
                    ForEach(goalProgress, id: \.titleKey) { progress in
                        GoalProgressRow(progress: progress)
                    }
                }
                .padding(14)
                .pathTrioCard()
            } else {
                ProLockedPreviewCard(feature: .goals)
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

    private func startWorkout() {
        if appModel.settingsStore.backgroundRecordingEnabled {
            appModel.locationService.requestAlwaysPermission()
        } else {
            appModel.locationService.requestWhenInUsePermission()
        }
        appModel.activeDraft = appModel.recorder.start(type: appModel.selectedWorkoutType)
        appModel.autoStartReminder = nil
        appModel.autoStartReminderEngine.reset()
        appModel.smartAssistEngine.reset()
        appModel.locationService.start(backgroundAllowed: appModel.settingsStore.backgroundRecordingEnabled)
        if appModel.settingsStore.isAnySmartAssistEnabled {
            appModel.motionService.start()
        } else {
            appModel.motionService.stop()
        }
        showingActiveWorkout = true
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

private struct GoalProgressRow: View {
    let progress: WorkoutGoalProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: progress.systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.action)
                    .frame(width: 28, height: 28)
                    .background(PathTrioTheme.action.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.string(progress.titleKey))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(PathTrioTheme.ink)
                    Text(L10n.string("goals.progress", progress.value, progress.target))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PathTrioTheme.muted)
                }

                Spacer(minLength: 0)

                Text("\(Int((progress.progress * 100).rounded()))%")
                    .font(.footnote.weight(.black))
                    .foregroundStyle(PathTrioTheme.action)
                    .monospacedDigit()
            }

            ProgressView(value: progress.progress)
                .tint(PathTrioTheme.action)
        }
    }
}

private struct ProLockedPreviewCard: View {
    let feature: ProFeature

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.warm)
                .frame(width: 30, height: 30)
                .background(PathTrioTheme.warm.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string(feature.titleKey))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                Text(L10n.string("pro.locked.preview", L10n.string(feature.messageKey)))
                    .font(.footnote)
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .pathTrioCard()
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
