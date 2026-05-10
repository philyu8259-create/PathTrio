import SwiftUI

struct MetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = PathTrioTheme.action

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 24, height: 24)
                    .background(tint.opacity(0.12), in: Circle())

                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PathTrioTheme.muted)
                    .lineLimit(1)
            }

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [PathTrioTheme.ink, tint.opacity(0.92)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 86)
        .padding(16)
        .pathTrioCard()
    }
}
