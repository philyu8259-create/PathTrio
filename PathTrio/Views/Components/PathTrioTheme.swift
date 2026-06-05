import SwiftUI

enum PathTrioTheme {
    static let pageBackground = LinearGradient(
        colors: [
            Color(red: 0.971, green: 0.988, blue: 1.000),
            Color(red: 0.934, green: 0.972, blue: 0.992),
            Color(red: 0.957, green: 0.928, blue: 1.000)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ink = Color(red: 0.055, green: 0.071, blue: 0.090)
    static let muted = Color(red: 0.420, green: 0.463, blue: 0.510)
    static let action = Color(red: 0.000, green: 0.478, blue: 0.933)
    static let actionAlt = Color(red: 0.050, green: 0.760, blue: 0.990)
    static let teal = Color(red: 0.000, green: 0.620, blue: 0.560)
    static let warm = Color(red: 0.940, green: 0.470, blue: 0.150)
    static let hawk = Color(red: 0.968, green: 0.590, blue: 0.160)
    static let sunset = Color(red: 1.000, green: 0.390, blue: 0.450)
    static let tabBarFill = LinearGradient(
        colors: [
            Color(red: 0.992, green: 0.996, blue: 1.000).opacity(0.94),
            Color(red: 0.938, green: 0.976, blue: 0.990).opacity(0.94)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let sunsetGradient = LinearGradient(
        colors: [sunset, hawk],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let line = Color.black.opacity(0.08)
    static let cardCornerRadius: CGFloat = 8
    static let glassFill = LinearGradient(
        colors: [
            Color.white.opacity(0.82),
            Color(red: 0.930, green: 0.982, blue: 0.990).opacity(0.64),
            Color(red: 0.934, green: 0.956, blue: 1.000).opacity(0.58)
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
}

struct PathTrioCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                    .fill(PathTrioTheme.glassFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.92), lineWidth: 1)
                    .blendMode(.overlay)
            }
            .overlay {
                RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                    .stroke(PathTrioTheme.action.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: PathTrioTheme.action.opacity(0.10), radius: 14, x: 0, y: 7)
            .shadow(color: .black.opacity(0.035), radius: 5, x: 0, y: 2)
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
                .background(tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.78), lineWidth: 1)
                }
                .shadow(color: tint.opacity(0.18), radius: 12, x: 0, y: 6)
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
