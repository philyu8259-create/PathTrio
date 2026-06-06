import SwiftData
import SwiftUI

struct WorkoutsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSessionModel.startedAt, order: .reverse) private var workouts: [WorkoutSessionModel]
    @State private var selectedType: WorkoutType = .walk
    @State private var showingActiveWorkout = false
    @State private var favorites: Set<WorkoutType> = [.walk, .run]

    private let topSummaryFallbackTypes: [WorkoutType] = [.walk, .run, .ride]

    private var countsByType: [WorkoutType: Int] {
        var counts: [WorkoutType: Int] = [:]
        workouts.forEach { counts[$0.type, default: 0] += 1 }
        return counts
    }

    private var topSummaryTypes: [WorkoutType] {
        var ranked = WorkoutType.allCases
            .filter { countsByType[$0, default: 0] > 0 }
            .sorted {
                let lhsCount = countsByType[$0, default: 0]
                let rhsCount = countsByType[$1, default: 0]
                if lhsCount == rhsCount {
                    return $0.rawValue < $1.rawValue
                }
                return lhsCount > rhsCount
            }

        if ranked.isEmpty {
            return topSummaryFallbackTypes
        }

        for fallback in topSummaryFallbackTypes where ranked.count < 3 {
            if !ranked.contains(fallback) {
                ranked.append(fallback)
            }
        }

        return Array(ranked.prefix(3))
    }

    private var activeModeHint: WorkoutModeHintKind {
        if selectedType.emphasizesPace {
            return .speed
        }
        if selectedType.supportsGPS {
            return .distance
        }
        return .focus
    }

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack {
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        workoutsHero
                        modeGuideSection

                        WorkoutTypePicker(
                            selection: $selectedType,
                            favoriteTypes: $favorites,
                            showsSearchField: true,
                            showsCategoryChips: true,
                            maxColumns: 3
                        )

                        quickStartPanel

                        recentSummaryPanel
                    }
                    .padding(16)
                    .padding(.bottom, 100)
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

    private var workoutsHero: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("workouts.hero.badge")
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(PathTrioTheme.hawk.opacity(0.18), in: Capsule())

                Text("workouts.hero.title")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(PathTrioTheme.ink.opacity(0.94))
                    .lineLimit(2)

                Text("workouts.hero.subtitle")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(PathTrioTheme.sunsetGradient)
                    .frame(width: 74, height: 74)
                Image(PathTrioAssets.Image.peachBuddyMascot)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                Circle()
                    .stroke(.white.opacity(0.9), lineWidth: 1)
                    .frame(width: 74, height: 74)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                .fill(.white.opacity(0.88))
        )
        .overlay {
            RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                .stroke(.white.opacity(0.8), lineWidth: 1)
        }
        .shadow(color: PathTrioTheme.hawk.opacity(0.16), radius: 16, x: 0, y: 8)
        .overlay(alignment: .topTrailing) {
            Text("workouts.title")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(PathTrioTheme.action.opacity(0.75), in: Capsule())
                .padding(8)
                .accessibilityHidden(true)
        }
    }

    private var modeGuideSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("workouts.modes.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            HStack(spacing: 10) {
                ForEach(modeHints, id: \.kind) { hint in
                    WorkoutModeHintChip(
                        icon: hint.icon,
                        titleKey: hint.titleKey,
                        subtitleKey: hint.subtitleKey,
                        tint: hint.tint,
                        isActive: hint.kind == activeModeHint
                    )
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    private var quickStartPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                .fill(PathTrioTheme.glassFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                .stroke(.white.opacity(0.9), lineWidth: 1)
        }
    }

    private var recentSummaryPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("workouts.history.summary")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            HStack(spacing: 10) {
                ForEach(Array(topSummaryTypes.enumerated()), id: \.offset) { index, type in
                    WorkoutTypeSummaryCard(
                        type: type,
                        count: countsByType[type, default: 0],
                        tint: PathTrioTheme.tint(for: type),
                        rank: index + 1
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var modeHints: [WorkoutModeHint] {
        [
            WorkoutModeHint(
                kind: .speed,
                icon: "bolt.fill",
                titleKey: "workouts.mode.speed.title",
                subtitleKey: "workouts.mode.speed.subtitle",
                tint: PathTrioTheme.warm
            ),
            WorkoutModeHint(
                kind: .distance,
                icon: "timer",
                titleKey: "workouts.mode.distance.title",
                subtitleKey: "workouts.mode.distance.subtitle",
                tint: PathTrioTheme.action
            ),
            WorkoutModeHint(
                kind: .focus,
                icon: "sparkles",
                titleKey: "workouts.mode.focus.title",
                subtitleKey: "workouts.mode.focus.subtitle",
                tint: PathTrioTheme.teal
            )
        ]
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

private enum WorkoutModeHintKind {
    case speed
    case distance
    case focus
}

private struct WorkoutModeHint {
    let kind: WorkoutModeHintKind
    let icon: String
    let titleKey: String
    let subtitleKey: String
    let tint: Color
}

private struct WorkoutModeHintChip: View {
    let icon: String
    let titleKey: String
    let subtitleKey: String
    let tint: Color
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.black))
                .foregroundStyle(isActive ? .white : tint)
                .frame(width: 38, height: 38)
                .background(isActive ? tint : tint.opacity(0.12), in: Circle())

            Text(L10n.string(titleKey))
                .font(.footnote.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)
                .lineLimit(1)

            Text(L10n.string(subtitleKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(PathTrioTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                .fill(isActive ? tint.opacity(0.2) : .white.opacity(0.78))
        )
        .overlay {
            RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                .stroke(isActive ? tint.opacity(0.75) : .white.opacity(0.82), lineWidth: isActive ? 2 : 1)
        }
    }
}

private struct WorkoutTypeSummaryCard: View {
    let type: WorkoutType
    let count: Int
    let tint: Color
    let rank: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("#\(rank)")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(PathTrioTheme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.9), in: Capsule())

                Spacer(minLength: 0)

                Image(systemName: "star.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(count > 0 ? PathTrioTheme.warm : PathTrioTheme.muted)
            }

            Image(systemName: type.systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(tint, in: Circle())

            Text(type.displayName)
                .font(.caption.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(L10n.string("workouts.summary.count", "\(count)"))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(PathTrioTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                .fill(.white.opacity(0.78))
        )
        .overlay {
            RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [tint.opacity(0.4), .white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 4)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(tint.opacity(0.16))
                .frame(width: 42, height: 42)
                .offset(x: 10, y: -8)
        }
    }
}
