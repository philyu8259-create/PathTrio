import SwiftUI

struct WatchHomeView: View {
    @ObservedObject var model: WatchConnectivityModel

    var body: some View {
        NavigationStack {
            Group {
                if model.envelope.isProUnlocked {
                    if let activeWorkout = model.envelope.activeWorkout {
                        LatestWorkoutView(
                            titleKey: "watch.active.title",
                            workout: activeWorkout,
                            updatedAt: Date(timeIntervalSince1970: model.envelope.updatedAt),
                            refresh: model.requestSnapshot
                        )
                    } else if let latestWorkout = model.envelope.latestWorkout {
                        LatestWorkoutView(
                            titleKey: "watch.latest.title",
                            workout: latestWorkout,
                            updatedAt: Date(timeIntervalSince1970: model.envelope.updatedAt),
                            refresh: model.requestSnapshot
                        )
                    } else {
                        WatchEmptyView(connectionState: model.connectionState, refresh: model.requestSnapshot)
                    }
                } else {
                    WatchLockedView(connectionState: model.connectionState, refresh: model.requestSnapshot)
                }
            }
            .navigationTitle(Text("watch.app.title"))
        }
    }
}

private struct LatestWorkoutView: View {
    let titleKey: LocalizedStringKey
    let workout: AppleWatchWorkoutSnapshot
    let updatedAt: Date
    let refresh: () -> Void

    private var typeColor: Color {
        switch workout.typeRawValue {
        case "run": .orange
        case "ride": .blue
        default: .teal
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: WatchWorkoutFormatters.systemImage(for: workout.typeRawValue))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(typeColor, in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(titleKey)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(typeColor)
                        Text(WatchWorkoutFormatters.displayName(for: workout.typeRawValue))
                            .font(.headline.weight(.bold))
                        HStack(spacing: 4) {
                            if workout.isActive, let stateRawValue = workout.stateRawValue {
                                Text(WatchWorkoutFormatters.stateName(for: stateRawValue))
                            } else {
                                Text(Date(timeIntervalSince1970: workout.startedAt), style: .date)
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }

                WatchMetricGrid(workout: workout, tint: typeColor)

                HStack {
                    Text("watch.latest.updated")
                    Text(updatedAt, style: .time)
                    Spacer()
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Text("watch.action.refresh"))
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct WatchMetricGrid: View {
    let workout: AppleWatchWorkoutSnapshot
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            WatchMetricRow(
                titleKey: "watch.metric.distance",
                value: WatchWorkoutFormatters.distance(workout.distanceMeters),
                systemImage: "map",
                tint: tint
            )
            WatchMetricRow(
                titleKey: "watch.metric.duration",
                value: WatchWorkoutFormatters.duration(workout.duration),
                systemImage: "timer",
                tint: .blue
            )
            WatchMetricRow(
                titleKey: workout.typeRawValue == "ride" ? "watch.metric.speed" : "watch.metric.pace",
                value: workout.typeRawValue == "ride"
                    ? WatchWorkoutFormatters.speed(workout.averageSpeedMetersPerSecond)
                    : WatchWorkoutFormatters.pace(duration: workout.duration, distanceMeters: workout.distanceMeters),
                systemImage: "speedometer",
                tint: .purple
            )
            WatchMetricRow(
                titleKey: "watch.metric.calories",
                value: WatchWorkoutFormatters.calories(workout.estimatedCalories),
                systemImage: "flame",
                tint: .red
            )
        }
    }
}

private struct WatchMetricRow: View {
    let titleKey: LocalizedStringKey
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(titleKey)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct WatchEmptyView: View {
    let connectionState: WatchConnectionState
    let refresh: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.teal)
            Text("watch.empty.title")
                .font(.headline.weight(.bold))
            Text(connectionState.messageKey)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("watch.action.refresh", action: refresh)
                .font(.caption.weight(.bold))
        }
        .padding(.horizontal, 8)
    }
}

private struct WatchLockedView: View {
    let connectionState: WatchConnectionState
    let refresh: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.yellow)
            Text("watch.locked.title")
                .font(.headline.weight(.bold))
            Text("watch.locked.message")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(connectionState.messageKey)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("watch.action.refresh", action: refresh)
                .font(.caption.weight(.bold))
        }
        .padding(.horizontal, 8)
    }
}

private extension WatchConnectionState {
    var messageKey: LocalizedStringKey {
        switch self {
        case .unsupported: "watch.connection.unsupported"
        case .waitingForPhone: "watch.connection.waiting"
        case .synced: "watch.connection.synced"
        }
    }
}

#Preview {
    let model = WatchConnectivityModel()
    model.envelope = AppleWatchSyncEnvelope(
        isProUnlocked: true,
        latestWorkout: AppleWatchWorkoutSnapshot(
            id: UUID().uuidString,
            typeRawValue: "run",
            startedAt: Date().addingTimeInterval(-3_600).timeIntervalSince1970,
            duration: 1_580,
            distanceMeters: 5_210,
            averageSpeedMetersPerSecond: 3.29,
            estimatedCalories: 340
        )
    )
    return WatchHomeView(model: model)
}
