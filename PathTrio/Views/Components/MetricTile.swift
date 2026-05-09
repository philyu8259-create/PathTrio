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
                    .frame(width: 18, height: 18)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
                    .lineLimit(1)
            }

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(PathTrioTheme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 78)
        .padding(14)
        .pathTrioCard()
    }
}
