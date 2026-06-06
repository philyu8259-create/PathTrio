import SwiftUI

enum PathTrioTheme {
    static let pageBackground = LinearGradient(
        colors: [
            Color(red: 1.000, green: 0.972, blue: 0.930),
            Color(red: 0.934, green: 0.990, blue: 0.966),
            Color(red: 0.936, green: 0.958, blue: 1.000)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ink = Color(red: 0.125, green: 0.104, blue: 0.153)
    static let muted = Color(red: 0.438, green: 0.446, blue: 0.520)
    static let action = Color(red: 0.185, green: 0.498, blue: 0.965)
    static let actionAlt = Color(red: 0.180, green: 0.780, blue: 0.980)
    static let teal = Color(red: 0.000, green: 0.690, blue: 0.600)
    static let warm = Color(red: 0.965, green: 0.430, blue: 0.180)
    static let hawk = Color(red: 1.000, green: 0.670, blue: 0.180)
    static let sunset = Color(red: 1.000, green: 0.380, blue: 0.420)
    static let peach = Color(red: 1.000, green: 0.565, blue: 0.390)
    static let mint = Color(red: 0.450, green: 0.900, blue: 0.760)
    static let banana = Color(red: 1.000, green: 0.840, blue: 0.280)
    static let candyPurple = Color(red: 0.555, green: 0.455, blue: 0.960)
    static let tabBarFill = LinearGradient(
        colors: [
            Color.white.opacity(0.96),
            Color(red: 1.000, green: 0.940, blue: 0.900).opacity(0.94)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let sunsetGradient = LinearGradient(
        colors: [sunset, hawk],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let line = Color(red: 0.165, green: 0.135, blue: 0.220).opacity(0.10)
    static let cardCornerRadius: CGFloat = 8
    static let glassFill = LinearGradient(
        colors: [
            Color.white.opacity(0.98),
            Color(red: 1.000, green: 0.968, blue: 0.925).opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let actionGradient = LinearGradient(
        colors: [
            actionAlt,
            action
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static func tint(for type: WorkoutType) -> Color {
        switch type.tintToken {
        case .teal:
            teal
        case .warm:
            warm
        case .action:
            action
        case .blue:
            .blue
        case .green:
            .green
        case .orange:
            .orange
        }
    }

    static func candyGradient(_ colors: [Color]) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct PathTrioCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                    .fill(PathTrioTheme.glassFill)
                    .shadow(color: PathTrioTheme.peach.opacity(0.18), radius: 0, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.055), radius: 10, x: 0, y: 5)
            }
            .overlay {
                RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.96), lineWidth: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                    .stroke(PathTrioTheme.ink.opacity(0.10), lineWidth: 1)
            }
    }
}

extension View {
    func pathTrioCard() -> some View {
        modifier(PathTrioCardBackground())
    }
}

struct PathTrioPageHeader: View {
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.78), lineWidth: 1)
                }
                .shadow(color: tint.opacity(0.24), radius: 0, x: 0, y: 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(titleKey)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(PathTrioTheme.ink.opacity(0.94))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(subtitleKey)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }
}
