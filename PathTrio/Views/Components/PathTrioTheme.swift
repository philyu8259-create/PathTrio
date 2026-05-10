import SwiftUI

enum PathTrioTheme {
    static let pageBackground = LinearGradient(
        colors: [
            Color(red: 0.970, green: 0.992, blue: 1.000),
            Color(red: 0.930, green: 0.974, blue: 0.958),
            Color(red: 0.936, green: 0.948, blue: 0.992)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ink = Color(red: 0.055, green: 0.071, blue: 0.090)
    static let muted = Color(red: 0.420, green: 0.463, blue: 0.510)
    static let action = Color(red: 0.000, green: 0.478, blue: 0.933)
    static let teal = Color(red: 0.000, green: 0.620, blue: 0.560)
    static let warm = Color(red: 0.940, green: 0.470, blue: 0.150)
    static let line = Color.black.opacity(0.08)
    static let cardCornerRadius: CGFloat = 8
    static let glassFill = LinearGradient(
        colors: [
            Color.white.opacity(0.78),
            Color(red: 0.910, green: 0.978, blue: 0.980).opacity(0.58),
            Color(red: 0.925, green: 0.948, blue: 1.000).opacity(0.52)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let actionGradient = LinearGradient(
        colors: [
            Color(red: 0.150, green: 0.580, blue: 0.960),
            action
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static func tint(for type: WorkoutType) -> Color {
        switch type {
        case .walk: teal
        case .run: warm
        case .ride: action
        }
    }
}

struct PathTrioCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                    .fill(.ultraThickMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                            .fill(PathTrioTheme.glassFill)
                    }
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
