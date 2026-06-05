import SwiftUI

struct WorkoutTypePicker: View {
    @Binding var selection: WorkoutType
    @Binding var favoriteTypes: Set<WorkoutType>
    let showsSearchField: Bool
    let showsCategoryChips: Bool
    let maxColumns: Int
    let maxVisibleTypes: Int?

    @State private var searchText = ""
    @State private var selectedCategory: WorkoutTypeCategory = .all

    init(
        selection: Binding<WorkoutType>,
        favoriteTypes: Binding<Set<WorkoutType>>,
        showsSearchField: Bool = true,
        showsCategoryChips: Bool = true,
        maxColumns: Int = 3,
        maxVisibleTypes: Int? = nil
    ) {
        self._selection = selection
        self._favoriteTypes = favoriteTypes
        self.showsSearchField = showsSearchField
        self.showsCategoryChips = showsCategoryChips
        self.maxColumns = maxColumns
        self.maxVisibleTypes = maxVisibleTypes
    }

    private var categories: [WorkoutTypeCategory] {
        showsCategoryChips ? WorkoutTypeCategory.allCases : [.all]
    }

    private var visibleTypes: [WorkoutType] {
        let filtered = WorkoutType.allCases.filter { type in
            if selectedCategory == .favorites && !favoriteTypes.contains(type) {
                return false
            }
            if selectedCategory == .cardio && !type.isCardio {
                return false
            }
            if selectedCategory == .endurance && !type.isEndurance {
                return false
            }
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
            let term = searchText.lowercased()
            return type.displayName.lowercased().contains(term) || type.rawValue.contains(term)
        }

        guard let maxVisibleTypes else { return filtered }
        return Array(filtered.prefix(maxVisibleTypes))
    }

    private var gridColumns: [GridItem] {
        let columns = max(2, maxColumns)
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: min(columns, 3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsCategoryChips {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category.titleKey)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(selectedCategory == category ? .white : PathTrioTheme.ink)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedCategory == category ? PathTrioTheme.action : .white,
                                        in: Capsule()
                                    )
                                    .overlay {
                                        Capsule()
                                            .stroke(selectedCategory == category ? PathTrioTheme.action : PathTrioTheme.line, lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if showsSearchField {
                TextField("workout.search.placeholder", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white.opacity(0.84))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(PathTrioTheme.action.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(alignment: .trailing) {
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(PathTrioTheme.muted)
                                    .padding(.trailing, 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
            }

            if visibleTypes.isEmpty {
                Text("workout.search.empty")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(visibleTypes) { type in
                        Button {
                            selection = type
                        } label: {
                            workoutTypeCard(type)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func workoutTypeCard(_ type: WorkoutType) -> some View {
        let tint = PathTrioTheme.tint(for: type)
        let isSelected = selection == type

        return ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Image(systemName: type.systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(isSelected ? .white : tint)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? tint : tint.opacity(0.12), in: Circle())

                Text(type.displayName)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(PathTrioTheme.ink)
                    .lineLimit(1)
            }
            .padding(.vertical, 14)
            .frame(height: 122)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.15) : .white.opacity(0.78))
            }
            .overlay {
                RoundedRectangle(cornerRadius: PathTrioTheme.cardCornerRadius, style: .continuous)
                    .stroke(isSelected ? tint : .white.opacity(0.82), lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: .black.opacity(isSelected ? 0.045 : 0.025), radius: 9, x: 0, y: 4)

            Button {
                if favoriteTypes.contains(type) {
                    favoriteTypes.remove(type)
                } else {
                    favoriteTypes.insert(type)
                }
            } label: {
                Image(systemName: favoriteTypes.contains(type) ? "star.fill" : "star")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(
                        favoriteTypes.contains(type)
                        ? PathTrioTheme.warm
                        : PathTrioTheme.muted
                    )
                    .frame(width: 24, height: 24)
                    .background(.white.opacity(0.8), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(6)
            .disabled(favoriteTypes.count >= 3 && !favoriteTypes.contains(type) && selectedCategory == .favorites)
        }
    }
}

private enum WorkoutTypeCategory: String, CaseIterable, Identifiable {
    case all
    case favorites
    case cardio
    case endurance

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all:
            "workout.category.all"
        case .favorites:
            "workout.category.favorites"
        case .cardio:
            "workout.category.cardio"
        case .endurance:
            "workout.category.endurance"
        }
    }
}

private extension WorkoutType {
    var isCardio: Bool {
        switch category {
        case .walking, .running, .cycling, .swimming, .studio:
            true
        case .water, .outdoorAdventure:
            false
        }
    }

    var isEndurance: Bool {
        switch category {
        case .walking, .running, .cycling, .swimming, .water, .outdoorAdventure:
            true
        case .studio:
            false
        }
    }
}
