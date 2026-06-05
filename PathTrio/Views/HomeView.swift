import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSessionModel.startedAt, order: .reverse) private var workouts: [WorkoutSessionModel]
    @State private var todayTotals = WorkoutTotals()
    @State private var showingActiveWorkout = false
    @State private var selectedType: WorkoutType = .walk
    @State private var favorites: Set<WorkoutType> = [.run]

    private let autoStartTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    let openWorkouts: () -> Void
    let openProfile: () -> Void

    private var streakDays: Int {
        let calendar = Calendar.current
        let activeDays = Set(workouts.map { calendar.startOfDay(for: $0.startedAt) })

        guard !activeDays.isEmpty else {
            return 0
        }

        let start = calendar.startOfDay(for: Date())
        var current = activeDays.contains(start) ? start : calendar.date(byAdding: .day, value: -1, to: start) ?? start
        var streak = 0
        while activeDays.contains(current) {
            streak += 1
            current = calendar.date(byAdding: .day, value: -1, to: current) ?? current
        }

        return streak
    }

    private var dailyTasks: [TodayTask] {
        [
            TodayTask(
                icon: "figure.walk",
                titleKey: "today.task.session.title",
                progressKey: "today.task.session.progress",
                currentText: "\(todayTotals.workoutCount)",
                targetText: "1",
                progressValue: min(1, Double(todayTotals.workoutCount)),
                isCompleted: todayTotals.workoutCount >= 1
            ),
            TodayTask(
                icon: "timer",
                titleKey: "today.task.minutes.title",
                progressKey: "today.task.minutes.progress",
                currentText: "\(Int(todayTotals.duration / 60))",
                targetText: "20",
                progressValue: min(1, todayTotals.duration / 1_200),
                isCompleted: todayTotals.duration >= 1_200
            ),
            TodayTask(
                icon: "map.fill",
                titleKey: "today.task.distance.title",
                progressKey: "today.task.distance.progress",
                currentText: WorkoutMetricsFormatter.distance(min(todayTotals.distanceMeters, 2_000)),
                targetText: WorkoutMetricsFormatter.distance(2_000),
                progressValue: min(1, todayTotals.distanceMeters / 2_000),
                isCompleted: todayTotals.distanceMeters >= 2_000
            )
        ]
    }

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack {
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        PathTrioPageHeader(
                            titleKey: "today.title",
                            subtitleKey: "today.subtitle",
                            systemImage: "sparkles",
                            tint: PathTrioTheme.action
                        )
                        trioPalCard
                        todayStats
                        quickStartSection
                        streakSection
                        dailyTasksSection
                        quickActionsSection

                        if let reminder = appModel.autoStartReminder {
                            AutoStartReminderCard(
                                reminder: reminder,
                                start: {
                                    selectedType = reminder.workoutType
                                    appModel.selectedWorkoutType = reminder.workoutType
                                    startWorkout()
                                }, dismiss: {
                                    appModel.autoStartReminder = nil
                                    appModel.autoStartReminderEngine.reset()
                                }
                            )
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 96)
                }
            }
            .navigationDestination(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView()
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                appModel.loadSettings(from: modelContext)
                appModel.reconcileLockedProSettings(in: modelContext)
                selectedType = appModel.selectedWorkoutType
                refreshTodayTotals()
                updateAutoStartMonitoring()
                #if DEBUG
                if ScreenshotDemoData.shouldOpenActiveWorkout {
                    selectedType = .run
                    appModel.selectedWorkoutType = .run
                    let draft = ScreenshotDemoData.activeWorkoutDraft()
                    appModel.activeDraft = appModel.recorder.start(type: draft.type, at: draft.startedAt)
                    appModel.activeDraft = appModel.recorder.addLocations(draft.locations, now: Date()) ?? draft
                    showingActiveWorkout = true
                }
                #endif
            }
            .onAppear {
                selectedType = appModel.selectedWorkoutType
            }
            .onChange(of: appModel.latestCompletedWorkoutID) { _, _ in
                refreshTodayTotals()
            }
            .onChange(of: selectedType) { _, selected in
                appModel.selectedWorkoutType = selected
            }
            .onReceive(autoStartTimer) { date in
                updateAutoStartReminder(now: date)
            }
            .onChange(of: appModel.motionService.detectedActivity) { _, _ in
                updateAutoStartReminder()
            }
            .onChange(of: appModel.settingsStore.autoStartRemindersEnabled) { _, _ in
                updateAutoStartMonitoring()
            }
        }
    }

    private var trioPalCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(PathTrioTheme.sunsetGradient)
                    .frame(width: 84, height: 84)
                    .overlay {
                        Image(PathTrioAssets.Image.peachBuddyMascot)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 62, height: 62)
                            .clipShape(Circle())
                    }

                Circle()
                    .stroke(.white.opacity(0.82), lineWidth: 1)
                    .frame(width: 84, height: 84)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("home.peachBuddy.title")
                    .font(.title3.weight(.black))
                    .foregroundStyle(PathTrioTheme.ink)
                Text("home.peachBuddy.subtitle")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .pathTrioCard()
    }

    private var todayStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("today.metrics.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                    systemImage: "flame.fill",
                    tint: PathTrioTheme.hawk
                )
            }
        }
    }

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("today.quickStart")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            WorkoutTypePicker(
                selection: $selectedType,
                favoriteTypes: $favorites,
                showsSearchField: false,
                showsCategoryChips: false,
                maxColumns: 3,
                maxVisibleTypes: 3
            )

            Button {
                startWorkout()
            } label: {
                Label("today.quickStart.button", systemImage: "play.fill")
                    .font(.headline.weight(.black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [PathTrioTheme.hawk, PathTrioTheme.action],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .shadow(color: PathTrioTheme.hawk.opacity(0.35), radius: 12, x: 0, y: 8)
        }
        .padding(14)
        .pathTrioCard()
    }

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("today.streak.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(PathTrioTheme.sunsetGradient)
                        .frame(width: 56, height: 56)

                    Image(systemName: "flame.fill")
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string("today.streak.value", "\(streakDays)"))
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(PathTrioTheme.ink)
                    Text(
                        streakDays > 0
                            ? L10n.string("today.streak.active", "\(streakDays)")
                            : L10n.string("today.streak.inactive")
                    )
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(PathTrioTheme.glassFill)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(PathTrioTheme.hawk.opacity(0.18), lineWidth: 1)
            }
        }
    }

    private var dailyTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("today.tasks.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            VStack(spacing: 10) {
                ForEach(dailyTasks) { task in
                    TodayTaskRow(task: task)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("today.quickActions.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            HStack(spacing: 10) {
                quickActionTile(
                    title: L10n.string("today.quickActions.workouts"),
                    icon: "figure.run",
                    tint: PathTrioTheme.action
                )
                .onTapGesture {
                    openWorkouts()
                }

                quickActionTile(
                    title: L10n.string("today.quickActions.profile"),
                    icon: "person.crop.circle",
                    tint: PathTrioTheme.teal
                )
                .onTapGesture {
                    openProfile()
                }
            }
        }
    }

    private func quickActionTile(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(tint, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(PathTrioTheme.glassFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        }
    }

    private func startWorkout() {
        if appModel.settingsStore.backgroundRecordingEnabled {
            appModel.locationService.requestAlwaysPermission()
        } else {
            appModel.locationService.requestWhenInUsePermission()
        }

        appModel.activeDraft = appModel.recorder.start(type: selectedType)
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

    private func refreshTodayTotals() {
        do {
            todayTotals = try WorkoutStore(context: modelContext).totals(forDayContaining: Date())
        } catch {
            todayTotals = .init()
        }
    }

    private func updateAutoStartReminder(now: Date = Date()) {
        guard appModel.settingsStore.autoStartRemindersEnabled else { return }
        guard appModel.recorder.draft == nil else {
            appModel.autoStartReminder = nil
            appModel.autoStartReminderEngine.reset()
            return
        }
        guard appModel.autoStartReminder == nil else { return }

        appModel.autoStartReminder = appModel.autoStartReminderEngine.evaluate(
            detectedActivity: appModel.motionService.detectedActivity,
            now: now,
            isWorkoutActive: false
        )
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
}

private struct TodayTask: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: String
    let progressKey: String
    let currentText: String
    let targetText: String
    let progressValue: Double
    let isCompleted: Bool
}

private struct TodayTaskRow: View {
    let task: TodayTask

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(task.isCompleted ? PathTrioTheme.warm : PathTrioTheme.action, in: Circle())
                .overlay {
                    Circle().stroke(.white.opacity(0.7), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.string(task.titleKey))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)

                Text(L10n.string(task.progressKey, task.currentText, task.targetText))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)

                ProgressView(value: task.progressValue)
                    .tint(task.isCompleted ? PathTrioTheme.hawk : PathTrioTheme.action)
            }

            Spacer(minLength: 0)

            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(task.isCompleted ? PathTrioTheme.warm : PathTrioTheme.line)
        }
        .padding(12)
        .background(.white.opacity(0.58))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(task.isCompleted ? PathTrioTheme.warm.opacity(0.35) : PathTrioTheme.action.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct AutoStartReminderCard: View {
    let reminder: AutoStartReminder
    let start: () -> Void
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.workoutType.systemImage)
                .font(.title3.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(PathTrioTheme.tint(for: reminder.workoutType), in: Circle())
                .overlay {
                    Circle().stroke(.white.opacity(0.78), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string("autoStart.title", reminder.workoutType.displayName))
                    .font(.headline.weight(.black))
                    .foregroundStyle(PathTrioTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("autoStart.message")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.black))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .foregroundStyle(PathTrioTheme.muted)
                .background(.white.opacity(0.65), in: Circle())
                .accessibilityLabel(Text("action.cancel"))

                Button(action: start) {
                    Image(systemName: "play.fill")
                        .font(.caption.weight(.black))
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(PathTrioTheme.action, in: Circle())
                .accessibilityLabel(Text("action.start"))
            }
        }
        .padding(14)
        .pathTrioCard()
    }
}
