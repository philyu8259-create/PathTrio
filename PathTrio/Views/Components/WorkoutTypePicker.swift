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
                    .background(isSelected ? tint.opacity(0.10) : .white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSelected ? tint : PathTrioTheme.line, lineWidth: isSelected ? 2 : 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(type.displayName)
            }
        }
    }
}
