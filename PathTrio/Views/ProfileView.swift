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

                        profileHeroCard
                        achievementsBoard
                        proStatusCard
                        clubhouseLinks
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

    private var unlockedAchievementCount: Int {
        achievementCards.filter(\.isUnlocked).count
    }

    private var profileHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(PathTrioTheme.candyGradient([PathTrioTheme.mint, PathTrioTheme.banana]))
                        .frame(width: 104, height: 104)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(color: PathTrioTheme.mint.opacity(0.28), radius: 0, x: 0, y: 6)

                    Image(peachBuddyImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 82, height: 82)
                        .clipShape(Circle())

                    Image(systemName: gamificationSnapshot.currentStreak > 0 ? "flame.fill" : "moon.zzz.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(PathTrioTheme.sunset, in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("profile.hero.title")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(PathTrioTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text("profile.hero.subtitle")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(PathTrioTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(L10n.string(gamificationSnapshot.trioPalState.labelKey))
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(PathTrioTheme.action, in: Capsule())
                }
            }

            HStack(spacing: 8) {
                ProfileStatPill(
                    title: L10n.string("profile.peachBuddy.stats", "\(gamificationSnapshot.currentStreak)", "\(gamificationSnapshot.totalWorkouts)"),
                    systemImage: "flame.fill",
                    tint: PathTrioTheme.sunset
                )
                ProfileStatPill(
                    title: L10n.string("profile.hero.longest", "\(gamificationSnapshot.longestStreak)"),
                    systemImage: "trophy.fill",
                    tint: PathTrioTheme.hawk
                )
            }

            ProfileStatPill(
                title: L10n.string("profile.hero.shields", "\(gamificationSnapshot.availableShields)"),
                systemImage: "shield.fill",
                tint: PathTrioTheme.teal
            )
        }
        .padding(16)
        .background(
            PathTrioTheme.candyGradient([
                Color.white.opacity(0.98),
                Color(red: 0.916, green: 0.992, blue: 0.960),
                Color(red: 1.000, green: 0.944, blue: 0.862)
            ]),
            in: RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                .stroke(.white, lineWidth: 2)
        }
    }

    private var achievementsBoard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("profile.achievements")
                        .font(.headline.weight(.black))
                        .foregroundStyle(PathTrioTheme.ink)

                    Text("profile.achievements.subtitle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PathTrioTheme.muted)
                }

                Spacer(minLength: 0)

                Text(L10n.string("profile.achievements.unlocked", "\(unlockedAchievementCount)", "\(max(achievementCards.count, 1))"))
                    .font(.caption.weight(.black))
                    .foregroundStyle(PathTrioTheme.hawk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(achievementCards.prefix(4))) { card in
                    AchievementPreviewCard(card: card)
                }
            }

            NavigationLink {
                AchievementGalleryView(cards: achievementCards)
            } label: {
                Label("profile.achievements.viewAll", systemImage: "rosette")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(PathTrioTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(PathTrioTheme.hawk.opacity(0.24), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .pathTrioCard()
    }

    private var proStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("profile.pro.title")
                .font(.headline.weight(.black))
                .foregroundStyle(PathTrioTheme.muted)

            HStack(spacing: 12) {
                Image(systemName: appModel.entitlementStore.isProUnlocked ? "crown.fill" : "lock.circle")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        PathTrioTheme.candyGradient([
                            appModel.entitlementStore.isProUnlocked ? PathTrioTheme.banana : PathTrioTheme.teal,
                            appModel.entitlementStore.isProUnlocked ? PathTrioTheme.sunset : PathTrioTheme.action
                        ]),
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
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.88), lineWidth: 1)
            }
        }
        .padding(14)
        .pathTrioCard()
    }

    private var clubhouseLinks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("profile.links.title")
                .font(.headline.weight(.black))
                .foregroundStyle(PathTrioTheme.muted)

            VStack(spacing: 8) {
                ProfileQuickLink(title: "profile.history", systemImage: "clock.arrow.circlepath", tint: PathTrioTheme.action) {
                    HistoryView(showsDoneButton: false)
                }
                ProfileQuickLink(title: "profile.settings", systemImage: "gearshape", tint: PathTrioTheme.teal) {
                    SettingsView(showsDoneButton: false)
                }
                ProfileQuickLink(title: "profile.achievements", systemImage: "rosette", tint: PathTrioTheme.hawk) {
                    AchievementGalleryView(cards: achievementCards)
                }
            }
        }
    }

    private var peachBuddyImageName: String {
        switch gamificationSnapshot.trioPalState {
        case .resting:
            PathTrioAssets.Image.peachBuddyRest
        case .warmUp, .steady:
            PathTrioAssets.Image.peachMoveIconJog
        case .blazing, .protected:
            PathTrioAssets.Image.peachMoveIconStreak
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
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(card.isUnlocked ? PathTrioTheme.hawk.opacity(0.28) : PathTrioTheme.line, lineWidth: 1)
        }
    }
}

private struct ProfileStatPill: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.black))
            .foregroundStyle(PathTrioTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(0.28), lineWidth: 1)
            }
    }
}

private struct AchievementGalleryView: View {
    let cards: [AchievementCardModel]

    var body: some View {
        ZStack {
            PathTrioTheme.pageBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    PathTrioPageHeader(
                        titleKey: "profile.achievements",
                        subtitleKey: "profile.achievements.subtitle",
                        systemImage: "rosette",
                        tint: PathTrioTheme.hawk
                    )

                    LazyVStack(spacing: 10) {
                        ForEach(cards) { card in
                            AchievementDetailCard(card: card)
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(Text("profile.achievements"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AchievementDetailCard: View {
    let card: AchievementCardModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: card.systemImage)
                .font(.title3.weight(.black))
                .foregroundStyle(card.isUnlocked ? .white : PathTrioTheme.muted)
                .frame(width: 48, height: 48)
                .background(card.isUnlocked ? PathTrioTheme.hawk : .white.opacity(0.78), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.88), lineWidth: 1))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(L10n.string(card.titleKey))
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(PathTrioTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Spacer(minLength: 0)

                    Text(L10n.string("profile.achievements.detail.progress", "\(card.currentValue)", "\(card.threshold)"))
                        .font(.caption.weight(.black))
                        .foregroundStyle(card.isUnlocked ? PathTrioTheme.hawk : PathTrioTheme.muted)
                        .lineLimit(1)
                }

                Text(L10n.string(card.detailKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressView(value: card.progress)
                    .tint(card.isUnlocked ? PathTrioTheme.hawk : PathTrioTheme.action)
            }

            Image(systemName: card.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(card.isUnlocked ? PathTrioTheme.hawk : PathTrioTheme.muted)
        }
        .padding(12)
        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(card.isUnlocked ? PathTrioTheme.hawk.opacity(0.28) : PathTrioTheme.line, lineWidth: 1)
        }
    }
}

private struct ProfileQuickLink<Destination: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: Circle())
                    .overlay(Circle().stroke(tint.opacity(0.28), lineWidth: 1))

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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(PathTrioTheme.glassFill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PathTrioTheme.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
