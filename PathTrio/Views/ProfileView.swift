import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @State private var gamificationSnapshot = GamificationSnapshot(
        totalWorkouts: 0,
        currentStreak: 0,
        longestStreak: 0,
        availableShields: 0,
        wasProtectedToday: false,
        trioPalState: .resting
    )
    @State private var achievementCards: [AchievementCardModel] = []

    var body: some View {
        NavigationStack {
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        PathTrioPageHeader(
                            titleKey: "profile.title",
                            subtitleKey: "profile.subtitle",
                            systemImage: "person.crop.circle",
                            tint: PathTrioTheme.teal
                        )

                        peachBuddyStatusCard
                        achievementsPreview

                        VStack(spacing: 12) {
                            Text("profile.pro.title")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(PathTrioTheme.muted)

                            HStack(spacing: 12) {
                                Image(systemName: appModel.entitlementStore.isProUnlocked ? "crown.fill" : "lock.circle")
                                    .font(.title2.weight(.black))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                appModel.entitlementStore.isProUnlocked ? PathTrioTheme.warm : PathTrioTheme.teal,
                                                appModel.entitlementStore.isProUnlocked ? PathTrioTheme.sunset : PathTrioTheme.teal
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        in: Circle()
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(
                                        appModel.entitlementStore.isProUnlocked
                                            ? L10n.string("profile.pro.active")
                                            : L10n.string("profile.pro.free")
                                    )
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(PathTrioTheme.ink)

                                    Text(
                                        appModel.entitlementStore.isProUnlocked
                                            ? L10n.string("profile.pro.unlockMessage")
                                            : L10n.string("profile.pro.lockedMessage")
                                    )
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PathTrioTheme.muted)
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(PathTrioTheme.glassFill)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.white.opacity(0.7), lineWidth: 1)
                            }
                        }

                        VStack(spacing: 8) {
                            ProfileQuickLink(title: "profile.history", systemImage: "clock.arrow.circlepath") {
                                HistoryView(showsDoneButton: false)
                            }
                            ProfileQuickLink(title: "profile.settings", systemImage: "gearshape") {
                                SettingsView(showsDoneButton: false)
                            }

                            ProfileQuickLink(title: "profile.achievements", systemImage: "rosette") {
                                Text("profile.achievements.placeholder")
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 96)
                }
            }
            .task {
                await appModel.entitlementStore.refreshPurchasedEntitlements()
                loadGamification()
            }
            .onDisappear {
                appModel.saveSettings(to: modelContext)
            }
        }
    }

    private var peachBuddyStatusCard: some View {
        HStack(spacing: 12) {
            Image(peachBuddyImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .background(.white.opacity(0.78), in: Circle())
                .overlay {
                    Circle().stroke(.white.opacity(0.86), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text("profile.peachBuddy.title")
                    .font(.headline.weight(.black))
                    .foregroundStyle(PathTrioTheme.ink)

                Text(L10n.string(gamificationSnapshot.trioPalState.labelKey))
                    .font(.footnote.weight(.black))
                    .foregroundStyle(PathTrioTheme.hawk)

                Text(L10n.string("profile.peachBuddy.stats", "\(gamificationSnapshot.currentStreak)", "\(gamificationSnapshot.totalWorkouts)"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .pathTrioCard()
    }

    private var achievementsPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("profile.achievements")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.muted)

                Spacer(minLength: 0)

                Text(L10n.string("profile.achievements.unlocked", "\(achievementCards.filter(\.isUnlocked).count)", "\(max(achievementCards.count, 1))"))
                    .font(.caption.weight(.black))
                    .foregroundStyle(PathTrioTheme.hawk)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(achievementCards.prefix(4))) { card in
                    AchievementPreviewCard(card: card)
                }
            }
        }
        .padding(14)
        .pathTrioCard()
    }

    private var peachBuddyImageName: String {
        switch gamificationSnapshot.trioPalState {
        case .resting:
            PathTrioAssets.Image.peachBuddyRest
        case .warmUp, .steady:
            PathTrioAssets.Image.peachBuddyMascot
        case .blazing, .protected:
            PathTrioAssets.Image.peachBuddyStreak
        }
    }

    private func loadGamification() {
        do {
            let store = GamificationStore(context: modelContext)
            gamificationSnapshot = try store.loadSnapshot()
            achievementCards = try store.loadAchievementCards()
        } catch {
            gamificationSnapshot = GamificationSnapshot(
                totalWorkouts: 0,
                currentStreak: 0,
                longestStreak: 0,
                availableShields: 0,
                wasProtectedToday: false,
                trioPalState: .resting
            )
            achievementCards = []
        }
    }
}

private struct AchievementPreviewCard: View {
    let card: AchievementCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: card.systemImage)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(card.isUnlocked ? .white : PathTrioTheme.muted)
                    .frame(width: 32, height: 32)
                    .background(card.isUnlocked ? PathTrioTheme.hawk : .white.opacity(0.78), in: Circle())

                Spacer(minLength: 0)

                Image(systemName: card.isUnlocked ? "checkmark.seal.fill" : "lock")
                    .font(.caption.weight(.black))
                    .foregroundStyle(card.isUnlocked ? PathTrioTheme.hawk : PathTrioTheme.muted)
            }

            Text(L10n.string(card.titleKey))
                .font(.caption.weight(.black))
                .foregroundStyle(PathTrioTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            ProgressView(value: card.progress)
                .tint(card.isUnlocked ? PathTrioTheme.hawk : PathTrioTheme.action)
        }
        .padding(10)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(card.isUnlocked ? PathTrioTheme.hawk.opacity(0.28) : PathTrioTheme.line, lineWidth: 1)
        }
    }
}

private struct ProfileQuickLink<Destination: View>: View {
    let title: String
    let systemImage: String
    let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PathTrioTheme.action)
                    .frame(width: 34, height: 34)
                    .background(PathTrioTheme.action.opacity(0.12), in: Circle())
                    .overlay(Circle().stroke(PathTrioTheme.action.opacity(0.28), lineWidth: 1))

                Text(L10n.string(title))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PathTrioTheme.muted)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(PathTrioTheme.glassFill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(PathTrioTheme.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
