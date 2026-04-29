import SwiftUI

struct WorkoutTypePicker: View {
    @Binding var selection: WorkoutType

    var body: some View {
        HStack(spacing: 10) {
            ForEach(WorkoutType.allCases) { type in
                Button {
                    selection = type
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: type.systemImage)
                            .font(.title2)
                        Text(type.displayName)
                            .font(.callout.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selection == type ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selection == type ? Color.accentColor : Color.clear, lineWidth: 2)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(type.displayName)
            }
        }
    }
}
