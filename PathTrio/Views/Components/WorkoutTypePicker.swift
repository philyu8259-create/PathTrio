import SwiftUI

struct WorkoutTypePicker: View {
    @Binding var selection: WorkoutType

    var body: some View {
        HStack(spacing: 10) {
            ForEach(WorkoutType.allCases) { type in
                let tint = PathTrioTheme.tint(for: type)
                let isSelected = selection == type

                Button {
                    selection = type
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: type.systemImage)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(isSelected ? .white : tint)
                            .frame(width: 40, height: 40)
                            .background(isSelected ? tint : tint.opacity(0.12), in: Circle())

                        Text(type.displayName)
                            .font(.callout.weight(.bold))
                            .foregroundStyle(PathTrioTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 112)
                    .background {
                        RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                            .fill(.ultraThickMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                                    .fill(isSelected ? tint.opacity(0.16) : .white.opacity(0.56))
                            }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                            .stroke(isSelected ? tint : .white.opacity(0.82), lineWidth: isSelected ? 2 : 1)
                    }
                    .shadow(color: .black.opacity(isSelected ? 0.045 : 0.025), radius: 9, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(type.displayName)
            }
        }
    }
}
