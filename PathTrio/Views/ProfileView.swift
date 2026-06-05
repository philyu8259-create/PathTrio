import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

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
                }
            }
            .task {
                await appModel.entitlementStore.refreshPurchasedEntitlements()
            }
            .onDisappear {
                appModel.saveSettings(to: modelContext)
            }
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

                Text(title)
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
