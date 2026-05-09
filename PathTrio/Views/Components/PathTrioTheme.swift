import SwiftUI

enum PathTrioTheme {
    static let pageBackground = Color(red: 0.965, green: 0.976, blue: 0.980)
    static let ink = Color(red: 0.055, green: 0.071, blue: 0.090)
    static let muted = Color(red: 0.420, green: 0.463, blue: 0.510)
    static let action = Color(red: 0.000, green: 0.478, blue: 0.933)
    static let teal = Color(red: 0.000, green: 0.620, blue: 0.560)
    static let warm = Color(red: 0.940, green: 0.470, blue: 0.150)
    static let line = Color.black.opacity(0.08)

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
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PathTrioTheme.line, lineWidth: 1)
            }
    }
}

extension View {
    func pathTrioCard() -> some View {
        modifier(PathTrioCardBackground())
    }
}
