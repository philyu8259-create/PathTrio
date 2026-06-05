import SwiftData
import SwiftUI

struct WorkoutsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSessionModel.startedAt, order: .reverse) private var workouts: [WorkoutSessionModel]
    @State private var selectedType: WorkoutType = .walk
    @State private var showingActiveWorkout = false
    @State private var favorites: Set<WorkoutType> = [.walk, .run]

    private var countsByType: [WorkoutType: Int] {
        var counts: [WorkoutType: Int] = [:]
        workouts.forEach { counts[$0.type, default: 0] += 1 }
        return counts
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
                            titleKey: "workouts.title",
                            subtitleKey: "workouts.subtitle",
                            systemImage: "figure.run",
                            tint: PathTrioTheme.action
                        )

                        WorkoutTypePicker(
                            selection: $selectedType,
                            favoriteTypes: $favorites,
                            showsSearchField: true,
                            showsCategoryChips: true,
                            maxColumns: 3
                        )

                        Text("workouts.quickStart")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PathTrioTheme.muted)
                        Button {
                            startWorkout()
                        } label: {
                            Label("workouts.start", systemImage: "play.fill")
                                .font(.headline.weight(.black))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: [PathTrioTheme.action, PathTrioTheme.hawk],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .shadow(color: PathTrioTheme.action.opacity(0.28), radius: 12, x: 0, y: 8)

                        Text("workouts.history.summary")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PathTrioTheme.muted)

                        HStack(spacing: 10) {
                            WorkoutTypeSummaryCard(
                                type: .walk,
                                count: countsByType[.walk, default: 0],
                                tint: PathTrioTheme.teal
                            )
                            WorkoutTypeSummaryCard(
                                type: .run,
                                count: countsByType[.run, default: 0],
                                tint: PathTrioTheme.warm
                            )
                            WorkoutTypeSummaryCard(
                                type: .ride,
                                count: countsByType[.ride, default: 0],
                                tint: PathTrioTheme.action
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .navigationDestination(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView()
            }
            .task {
                appModel.loadSettings(from: modelContext)
                selectedType = appModel.selectedWorkoutType
            }
            .onAppear {
                selectedType = appModel.selectedWorkoutType
            }
            .onChange(of: selectedType) { _, type in
                appModel.selectedWorkoutType = type
            }
            .toolbar(.hidden, for: .navigationBar)
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
}

private struct WorkoutTypeSummaryCard: View {
    let type: WorkoutType
    let count: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: type.systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(tint, in: Circle())
            Text(type.displayName)
                .font(.caption.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)
            Text(L10n.string("workouts.summary.count", "\(count)"))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(PathTrioTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(PathTrioTheme.glassFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
    }
}
