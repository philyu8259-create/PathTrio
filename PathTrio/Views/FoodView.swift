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

                        usageCard
                        entryControls
                        if let image = displayedImageData.map({ data in Image(uiImage: UIImage(data: data) ?? UIImage()) }) {
                            imageSection(image)
                        }

                        if !editingFoodName.isEmpty || !editingCalories.isEmpty {
                            editableEntryCard
                        }

                        if !foodLogs.isEmpty {
                            historySection
                        } else {
                            Text("food.logs.empty")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(PathTrioTheme.muted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                    }
                    .padding(16)
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
                    editingFoodName = ""
                    editingCalories = ""
                    Task { await analyzeImageData(displayedImageData ?? Data(), mimeType: "image/jpeg") }
                }
            }
        }
    }

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("food.recognitionUsage")
                .font(.subheadline.weight(.bold))
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
        .background(PathTrioTheme.glassFill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
    }

    private var entryControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                PhotosPicker(
                    selection: $selectedLibraryItem,
                    matching: .images
                ) {
                    Label("food.action.pickPhoto", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(PathTrioTheme.actionGradient)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(!usage.canUseForRecognition)

                Button {
                    showingCameraPicker = true
                } label: {
                    Label("food.action.camera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(PathTrioTheme.actionGradient)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(!usage.canUseForRecognition)
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
            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, minHeight: 180)
                .frame(height: 200)
                .background(.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(PathTrioTheme.line, lineWidth: 1)
                }
        }
        .padding(12)
        .background(PathTrioTheme.glassFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
    }

    private var editableEntryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("food.recognitionResult")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PathTrioTheme.muted)

            VStack(spacing: 10) {
                TextField("food.input.foodName", text: $editingFoodName)
                    .textFieldStyle(.roundedBorder)

                TextField("food.input.calories", text: $editingCalories)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 10) {
                Button("food.action.save") {
                    saveEntry()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(PathTrioTheme.hawk.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(editingFoodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("action.cancel") {
                    clearDraft()
                }
                .buttonStyle(.plain)
                .foregroundStyle(PathTrioTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .background(PathTrioTheme.glassFill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
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
                    }
                    .padding(12)
                    .background(PathTrioTheme.glassFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(PathTrioTheme.line, lineWidth: 1)
                    }
                }
            }
        }
    }

    private func handleLibrarySelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard usage.canUseForRecognition else { return }
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

    private func saveEntry() {
        let trimmedName = editingFoodName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedCalories = Int(editingCalories.trimmingCharacters(in: .whitespacesAndNewlines))
        let calories = max(0, parsedCalories ?? 0)

        guard !trimmedName.isEmpty else {
            errorMessage = L10n.string("food.error.emptyName")
            return
        }

        do {
            modelContext.insert(FoodLogModel(foodName: trimmedName, estimatedCalories: calories))
            try modelContext.save()
            clearDraft()
        } catch {
            errorMessage = error.localizedDescription
        }
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
