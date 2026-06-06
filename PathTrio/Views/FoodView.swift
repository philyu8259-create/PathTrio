import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct FoodView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodLogModel.loggedAt, order: .reverse) private var foodLogs: [FoodLogModel]

    @State private var selectedLibraryItem: PhotosPickerItem?
    @State private var displayedImageData: Data?
    @State private var editingFoodName = ""
    @State private var editingCalories = ""
    @State private var isRecognizing = false
    @State private var usage = FoodAIUsage.zero
    @State private var errorMessage: String?
    @State private var showingCameraPicker = false
    @State private var isManualEntryMode = false
    @State private var editingFoodLog: FoodLogModel?
    @State private var pendingDeleteFoodLog: FoodLogModel?

    private let dailyCalorieGoal = 1800

    var body: some View {
        NavigationStack {
            ZStack {
                PathTrioTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        PathTrioPageHeader(
                            titleKey: "food.title",
                            subtitleKey: "food.subtitle",
                            systemImage: "fork.knife",
                            tint: PathTrioTheme.action
                        )

                        peachBuddyFoodCard
                        dailyProgressCard
                        usageCard
                        entryControls

                        if let image = displayedImageData.map({ data in Image(uiImage: UIImage(data: data) ?? UIImage()) }) {
                            imageSection(image)
                        }

                        if shouldShowEntryCard {
                            editableEntryCard
                        }

                        if !foodLogs.isEmpty {
                            mealSummaryCard
                            historySection
                        } else {
                            foodEmptyState
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 96)
                }
            }
            .navigationTitle(Text("food.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                refreshUsage()
            }
            .onChange(of: selectedLibraryItem) { _, newValue in
                Task { await handleLibrarySelection(newValue) }
            }
            .alert("food.recognitionError.title", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("action.done", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let message = errorMessage {
                    Text(message)
                }
            }
            .sheet(isPresented: $showingCameraPicker) {
                CameraPickerView { result in
                    showingCameraPicker = false

                    guard let result = result else {
                        return
                    }

                    displayedImageData = result.jpegData(compressionQuality: 0.86)
                    isManualEntryMode = false
                    editingFoodName = ""
                    editingCalories = ""
                    Task { await analyzeImageData(displayedImageData ?? Data(), mimeType: "image/jpeg") }
                }
            }
            .sheet(isPresented: Binding(
                get: { editingFoodLog != nil },
                set: { if !$0 { editingFoodLog = nil } }
            )) {
                if editingFoodLog != nil {
                    editFoodLogSheet
                }
            }
            .confirmationDialog(
                "food.delete.confirm.title",
                isPresented: Binding(
                    get: { pendingDeleteFoodLog != nil },
                    set: { if !$0 { pendingDeleteFoodLog = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("food.action.delete", role: .destructive) {
                    performDeleteFoodLog()
                }
                Button("action.cancel", role: .cancel) {
                    pendingDeleteFoodLog = nil
                }
            } message: {
                if let entry = pendingDeleteFoodLog {
                    Text(L10n.string("food.delete.confirm.message", entry.foodName))
                }
            }
        }
    }

    private var shouldShowEntryCard: Bool {
        editingFoodLog == nil && (isManualEntryMode || !editingFoodName.isEmpty || !editingCalories.isEmpty)
    }

    private var todayFoodLogs: [FoodLogModel] {
        foodLogs.filter { Calendar.current.isDateInToday($0.loggedAt) }
    }

    private var todayCalorieTotal: Int {
        todayFoodLogs.reduce(0) { $0 + $1.estimatedCalories }
    }

    private var todayMealCount: Int {
        todayFoodLogs.count
    }

    private var todayCaloriesAverage: Int {
        guard todayMealCount > 0 else { return 0 }
        return Int((Double(todayCalorieTotal) / Double(todayMealCount)).rounded())
    }

    private var caloriesGoalProgress: Double {
        min(1, Double(todayCalorieTotal) / Double(dailyCalorieGoal))
    }

    private var remainingCalorieGoal: Int {
        max(0, dailyCalorieGoal - todayCalorieTotal)
    }

    private var goalProgressColor: Color {
        if todayCalorieTotal == 0 {
            return PathTrioTheme.muted
        }
        if todayCalorieTotal >= dailyCalorieGoal {
            return PathTrioTheme.teal
        }
        return PathTrioTheme.hawk
    }

    private var goalProgressStatus: String {
        if todayCalorieTotal == 0 {
            return L10n.string("food.summary.status.empty")
        }
        if todayCalorieTotal >= dailyCalorieGoal {
            return L10n.string("food.summary.status.reached")
        }
        return L10n.string("food.summary.status.left", "\(remainingCalorieGoal)")
    }

    private var peachBuddyFoodCard: some View {
        HStack(spacing: 12) {
            Image(PathTrioAssets.Image.peachBuddyFoodLog)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .padding(10)
                .background(
                    Circle()
                        .fill(PathTrioTheme.sunsetGradient.opacity(0.22))
                )
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.9), lineWidth: 1.2)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text("food.peachBuddy.title")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(PathTrioTheme.ink)
                Text("food.peachBuddy.message")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(PathTrioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.000, green: 0.966, blue: 0.995),
                            Color.white.opacity(0.84),
                            Color(red: 0.980, green: 1.000, blue: 0.990)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PathTrioTheme.hawk.opacity(0.22), lineWidth: 1.2)
        }
    }

    private var dailyProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("food.dailyGoal.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [goalProgressColor.opacity(0.30), goalProgressColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(goalProgressColor)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string("food.dailyGoal.subtitle", "\(todayMealCount)"))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(PathTrioTheme.ink)
                        .lineLimit(1)
                    Text(L10n.string("food.dailyGoal.value", "\(todayCalorieTotal)", "\(dailyCalorieGoal)"))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(goalProgressColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text("food.dailyGoal.kcalBadge")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(goalProgressColor))
            }

            ProgressView(value: caloriesGoalProgress)
                .progressViewStyle(.linear)
                .tint(goalProgressColor)
                .padding(.trailing, 2)

            HStack(spacing: 10) {
                foodStatBadge(
                    title: "food.summary.meals",
                    icon: "fork.knife",
                    value: "\(todayMealCount)",
                    tint: PathTrioTheme.action
                )
                foodStatBadge(
                    title: "food.summary.avg",
                    icon: "chart.bar.xaxis",
                    value: "\(todayCaloriesAverage)",
                    tint: PathTrioTheme.warm
                )
                foodStatBadge(
                    title: "food.summary.latest",
                    icon: "clock.arrow.circlepath",
                    value: "\(todayFoodLogs.first?.estimatedCalories ?? 0)",
                    tint: PathTrioTheme.teal
                )
            }

            Text(goalProgressStatus)
                .font(.caption.weight(.semibold))
                .foregroundStyle(goalProgressColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(PathTrioTheme.glassFill)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.80), lineWidth: 1)
        }
    }

    private func foodStatBadge(title: String, icon: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 18, height: 18)
                    .background(tint.opacity(0.14), in: Circle())
                Text(L10n.string(title))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PathTrioTheme.muted)
                    .lineLimit(1)
            }

            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(PathTrioTheme.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PathTrioTheme.line, lineWidth: 1)
        }
    }

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("food.recognitionUsage")
                .font(.subheadline.weight(.black))
                .foregroundStyle(PathTrioTheme.muted)

            HStack {
                Text(L10n.string("food.recognitionUsage.value", "\(usage.usedCount)", "\(usage.dailyLimit)"))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.ink)

                Spacer(minLength: 0)

                ProgressView(value: Double(usage.usedCount), total: Double(max(usage.dailyLimit, 1)))
                    .progressViewStyle(.linear)
                    .tint(PathTrioTheme.hawk)
                    .frame(width: 140)
            }

            if usage.canUseForRecognition {
                Text(L10n.string("food.recognitionUsage.remaining", "\(usage.remainingCount)"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PathTrioTheme.teal)
            } else {
                Text("food.recognitionUsage.exhausted")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(PathTrioTheme.glassFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
    }

    private var entryControls: some View {
        VStack(spacing: 10) {
            Text("food.controls.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    PhotosPicker(
                        selection: $selectedLibraryItem,
                        matching: .images
                    ) {
                        FoodPanelButtonLabel(titleKey: "food.action.pickPhoto", systemImage: "photo.on.rectangle", isPrimary: true)
                    }
                    .buttonStyle(.plain)
                    .disabled(!usage.canUseForRecognition)

                    FoodPanelButton(
                        titleKey: "food.action.camera",
                        systemImage: "camera",
                        isPrimary: true,
                        isEnabled: usage.canUseForRecognition
                    ) {
                        showingCameraPicker = true
                    }
                }

                FoodPanelButton(
                    titleKey: "food.action.manual",
                    systemImage: "plus.circle",
                    isPrimary: false,
                    isEnabled: true
                ) {
                    activateManualEntry()
                }
            }

            if !usage.canUseForRecognition {
                Text("food.recognitionUsage.limitReached")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 4)
            } else if isRecognizing {
                ProgressView("food.recognizing")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PathTrioTheme.muted)
            }
        }
    }

    private func imageSection(_ image: Image) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("food.recognitionResult.image")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(PathTrioTheme.ink)
                Spacer(minLength: 0)
            }

            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, minHeight: 180)
                .frame(height: 200)
                .background(.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PathTrioTheme.line, lineWidth: 1)
                }
        }
        .padding(12)
        .background(PathTrioTheme.glassFill)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
    }

    private var editableEntryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isManualEntryMode ? "food.action.manual" : "food.recognitionResult")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            Text("food.entry.header")
                .font(.caption.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)

            VStack(spacing: 8) {
                TextField("food.input.foodName", text: $editingFoodName)
                    .textInputAutocapitalization(.sentences)
                    .padding(10)
                    .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.88), lineWidth: 1)
                    }

                TextField("food.input.calories", text: $editingCalories)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.88), lineWidth: 1)
                    }
            }

            HStack(spacing: 10) {
                FoodPanelButton(
                    titleKey: "food.action.save",
                    systemImage: "checkmark.circle",
                    isPrimary: true,
                    isEnabled: !editingFoodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    _ = saveEntry()
                }

                FoodPanelButton(
                    titleKey: "action.cancel",
                    systemImage: "xmark",
                    isPrimary: false,
                    isEnabled: true
                ) {
                    clearDraft()
                }
            }
        }
        .padding(14)
        .background(PathTrioTheme.glassFill)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
    }

    private var mealSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("food.summary.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            Text(L10n.string("food.summary.subtitle", "\(todayMealCount)", "\(todayCalorieTotal)"))
                .font(.headline.weight(.semibold))
                .foregroundStyle(PathTrioTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(PathTrioTheme.glassFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PathTrioTheme.line, lineWidth: 1)
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("food.logs.title")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            LazyVStack(spacing: 10) {
                ForEach(foodLogs) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.foodName)
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(PathTrioTheme.ink)
                                .lineLimit(1)

                            Text(entry.displayDate)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(PathTrioTheme.muted)
                        }

                        Spacer(minLength: 0)

                            Text(L10n.string("food.logs.calories", "\(entry.estimatedCalories)"))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(PathTrioTheme.action)

                            HStack(spacing: 4) {
                                Button {
                                    beginEditing(entry)
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.subheadline.weight(.bold))
                                        .frame(width: 28, height: 28)
                                        .background(PathTrioTheme.line.opacity(0.7), in: Circle())
                                        .foregroundStyle(PathTrioTheme.ink)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("food.action.edit")

                                Button {
                                    pendingDeleteFoodLog = entry
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.subheadline.weight(.bold))
                                        .frame(width: 28, height: 28)
                                        .background(.red.opacity(0.1), in: Circle())
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("food.action.delete")
                            }
                        }
                    .padding(12)
                    .background(PathTrioTheme.glassFill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(PathTrioTheme.line, lineWidth: 1)
                    }
                }
            }
        }
    }

    private var foodEmptyState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(PathTrioAssets.Image.peachBuddyRest)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .background(.white.opacity(0.74), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("food.logs.empty")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(PathTrioTheme.ink)
                    Text("food.logs.empty.message")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PathTrioTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            FoodPanelButton(
                titleKey: "food.action.manual",
                systemImage: "plus",
                isPrimary: false,
                isEnabled: true
            ) {
                activateManualEntry()
            }
        }
        .padding(14)
        .pathTrioCard()
    }

    private func handleLibrarySelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard usage.canUseForRecognition else { return }
        isManualEntryMode = false
        isRecognizing = true
        errorMessage = nil

        defer {
            isRecognizing = false
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw FoodRecognitionError.emptyImage
            }

            displayedImageData = data
            editingFoodName = ""
            editingCalories = ""
            await analyzeImageData(data, mimeType: "image/jpeg")
        } catch {
            errorMessage = (error as? FoodRecognitionError)?.localizedDescription ?? error.localizedDescription
            clearDraft()
        }
    }

    private func analyzeImageData(_ data: Data, mimeType: String) async {
        guard !data.isEmpty else { return }
        isRecognizing = true
        defer {
            isRecognizing = false
        }

        do {
            let result = try await appModel.foodRecognitionService.recognize(
                imageData: data,
                mimeType: mimeType,
                context: modelContext
            )
            editingFoodName = result.foodName
            editingCalories = "\(result.estimatedCalories)"
            refreshUsage()
        } catch {
            errorMessage = (error as? FoodRecognitionError)?.localizedDescription ?? error.localizedDescription
        }
    }

    private func saveEntry() -> Bool {
        let trimmedName = editingFoodName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedCalories = Int(editingCalories.trimmingCharacters(in: .whitespacesAndNewlines))
        let calories = max(0, parsedCalories ?? 0)

        guard !trimmedName.isEmpty else {
            errorMessage = L10n.string("food.error.emptyName")
            return false
        }

        do {
            if let foodToEdit = editingFoodLog {
                foodToEdit.foodName = trimmedName
                foodToEdit.estimatedCalories = calories
            } else {
                modelContext.insert(FoodLogModel(foodName: trimmedName, estimatedCalories: calories))
            }
            try modelContext.save()
            clearDraft()
        } catch {
            errorMessage = error.localizedDescription
            return false
        }

        return true
    }

    private func activateManualEntry() {
        clearDraft()
        isManualEntryMode = true
    }

    private func refreshUsage() {
        do {
            usage = try appModel.foodRecognitionService.loadUsage(from: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearDraft() {
        editingFoodName = ""
        editingCalories = ""
        displayedImageData = nil
        selectedLibraryItem = nil
        isManualEntryMode = false
        editingFoodLog = nil
    }

    private var editFoodLogSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("food.action.edit")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            Text("food.entry.header")
                .font(.caption.weight(.bold))
                .foregroundStyle(PathTrioTheme.ink)

            VStack(spacing: 8) {
                TextField("food.input.foodName", text: $editingFoodName)
                    .textInputAutocapitalization(.sentences)
                    .padding(10)
                    .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.88), lineWidth: 1)
                    }

                TextField("food.input.calories", text: $editingCalories)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.88), lineWidth: 1)
                    }
            }

            HStack(spacing: 10) {
                FoodPanelButton(
                    titleKey: "food.action.save",
                    systemImage: "checkmark.circle",
                    isPrimary: true,
                    isEnabled: !editingFoodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    if saveEntry() {
                        editingFoodLog = nil
                    }
                }

                FoodPanelButton(
                    titleKey: "action.cancel",
                    systemImage: "xmark",
                    isPrimary: false,
                    isEnabled: true
                ) {
                    clearDraft()
                }
            }
        }
        .padding(14)
        .background(PathTrioTheme.glassFill)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
        .padding(16)
    }

    private func beginEditing(_ entry: FoodLogModel) {
        editingFoodLog = entry
        editingFoodName = entry.foodName
        editingCalories = "\(entry.estimatedCalories)"
        isManualEntryMode = false
        displayedImageData = nil
        selectedLibraryItem = nil
    }

    private func performDeleteFoodLog() {
        guard let foodToDelete = pendingDeleteFoodLog else {
            return
        }

        if editingFoodLog === foodToDelete {
            clearDraft()
        }

        do {
            modelContext.delete(foodToDelete)
            try modelContext.save()
            pendingDeleteFoodLog = nil
        } catch {
            errorMessage = L10n.string("food.error.deleteFailed")
            pendingDeleteFoodLog = foodToDelete
        }
    }
}

private struct FoodPanelButtonLabel: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    let isPrimary: Bool

    var body: some View {
        Label(titleKey, systemImage: systemImage)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(isPrimary ? .white : PathTrioTheme.ink)
            .background(
                isPrimary ? AnyShapeStyle(PathTrioTheme.actionGradient) : AnyShapeStyle(Color.white.opacity(0.76))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.75), lineWidth: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PathTrioTheme.action.opacity(0.12), lineWidth: isPrimary ? 0 : 1)
            }
    }
}

private struct FoodPanelButton: View {
    let titleKey: String
    let systemImage: String
    let isPrimary: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            FoodPanelButtonLabel(titleKey: LocalizedStringKey(titleKey), systemImage: systemImage, isPrimary: isPrimary)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.52)
    }
}

private struct CameraPickerView: UIViewControllerRepresentable {
    let onComplete: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func dismantleUIViewController(_ uiViewController: UIImagePickerController, coordinator _: Coordinator) {
        uiViewController.dismiss(animated: true)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            parent.onComplete(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onComplete(nil)
        }
    }
}
