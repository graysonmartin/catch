import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import CatchCore

struct PhotoPickerView: View {
    @Binding var selectedPhotos: [Data]
    @Environment(VisionCatPhotoValidationService.self) private var validationService: VisionCatPhotoValidationService?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var draggingIndex: Int?
    @State private var validationResults: [Int: CatPhotoValidationResult] = [:]
    @State private var isValidating = false
    @State private var hasOverriddenWarning = false

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            if !selectedPhotos.isEmpty {
                photoStrip
                reorderHint
            }

            validationBanner

            photoPicker
        }
        .onChange(of: selectedPhotos) {
            runValidation()
        }
    }

    // MARK: - Photo Strip

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CatchSpacing.space8) {
                ForEach(selectedPhotos.indices, id: \.self) { index in
                    photoThumbnail(at: index)
                        .onDrag {
                            draggingIndex = index
                            return NSItemProvider(object: "\(index)" as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: PhotoDropDelegate(
                                currentIndex: index,
                                draggingIndex: $draggingIndex,
                                photos: $selectedPhotos
                            )
                        )
                }
            }
            .padding(.horizontal)
        }
    }

    private var reorderHint: some View {
        Text(CatchStrings.Components.dragToReorder)
            .font(.caption2)
            .foregroundStyle(CatchTheme.textSecondary)
            .padding(.horizontal)
    }

    // MARK: - Validation Banner

    @ViewBuilder
    private var validationBanner: some View {
        if isValidating {
            HStack(spacing: CatchSpacing.space8) {
                ProgressView()
                    .controlSize(.small)
                Text(CatchStrings.PhotoValidation.scanning)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
            .padding(.horizontal)
        } else if !hasOverriddenWarning, failedPhotoCount > 0 {
            HStack(spacing: CatchSpacing.space8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                    Text(CatchStrings.PhotoValidation.photosWithoutCats(failedPhotoCount))
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textPrimary)
                }

                Spacer()

                Button {
                    withAnimation { hasOverriddenWarning = true }
                } label: {
                    Text(CatchStrings.PhotoValidation.noCatOverride)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(CatchTheme.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Photo Picker

    private var photoPicker: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: CatchTheme.maxPhotoSelection,
            matching: .images
        ) {
            Label(CatchStrings.Components.addPhotos, systemImage: "photo.on.rectangle.angled")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CatchTheme.primary)
        }
        .onChange(of: pickerItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data),
                       let compressed = uiImage.jpegData(compressionQuality: CatchTheme.jpegCompressionQuality) {
                        selectedPhotos.append(compressed)
                    }
                }
                pickerItems.removeAll()
            }
        }
    }

    // MARK: - Thumbnails

    @ViewBuilder
    private func photoThumbnail(at index: Int) -> some View {
        let isPrimary = index == 0
        let hasFailed = validationResults[index]?.isCatDetected == false

        ZStack(alignment: .topTrailing) {
            CatPhotoView(photoData: selectedPhotos[index], size: 100)
                .overlay(alignment: .bottomLeading) {
                    if isPrimary {
                        primaryBadge
                    } else {
                        setAsPrimaryButton(index: index)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if hasFailed && !hasOverriddenWarning {
                        noCatBadge
                    }
                }
                .opacity(draggingIndex == index ? 0.5 : 1.0)

            deleteButton(index: index)
        }
    }

    private var primaryBadge: some View {
        Text(CatchStrings.Components.profilePic)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, CatchSpacing.space5)
            .padding(.vertical, CatchSpacing.space2)
            .background(CatchTheme.primary, in: Capsule())
            .padding(CatchSpacing.space4)
    }

    private var noCatBadge: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 14))
            .foregroundStyle(.orange)
            .padding(CatchSpacing.space4)
    }

    private func setAsPrimaryButton(index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                let photo = selectedPhotos.remove(at: index)
                selectedPhotos.insert(photo, at: 0)
            }
        } label: {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white, .black.opacity(0.4))
                .shadow(radius: 1)
        }
        .padding(CatchSpacing.space4)
    }

    private func deleteButton(index: Int) -> some View {
        Button {
            withAnimation {
                _ = selectedPhotos.remove(at: index)
                validationResults.removeValue(forKey: index)
                hasOverriddenWarning = false
                reindexResults()
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.white, .black.opacity(0.5))
        }
        .offset(x: CatchSpacing.space4, y: -CatchSpacing.space4)
    }

    // MARK: - Validation Logic

    private var failedPhotoCount: Int {
        validationResults.values.filter { !$0.isCatDetected }.count
    }

    private func runValidation() {
        guard let service = validationService, !selectedPhotos.isEmpty else {
            validationResults = [:]
            return
        }

        hasOverriddenWarning = false
        isValidating = true

        Task {
            let results = await service.validatePhotos(imageDataArray: selectedPhotos)
            var mapped: [Int: CatPhotoValidationResult] = [:]
            for result in results {
                mapped[result.photoIndex] = result
            }
            validationResults = mapped
            isValidating = false
        }
    }

    /// Re-keys results after a photo is deleted so indices stay in sync.
    private func reindexResults() {
        var reindexed: [Int: CatPhotoValidationResult] = [:]
        let sorted = validationResults.sorted { $0.key < $1.key }
        var newIndex = 0
        for (oldIndex, result) in sorted {
            guard oldIndex < selectedPhotos.count + 1 else { continue }
            if oldIndex != newIndex {
                reindexed[newIndex] = CatPhotoValidationResult(
                    isCatDetected: result.isCatDetected,
                    confidence: result.confidence,
                    photoIndex: newIndex
                )
            } else {
                reindexed[newIndex] = result
            }
            newIndex += 1
        }
        validationResults = reindexed
    }
}

// MARK: - Drop Delegate

private struct PhotoDropDelegate: DropDelegate {
    let currentIndex: Int
    @Binding var draggingIndex: Int?
    @Binding var photos: [Data]

    func performDrop(info: DropInfo) -> Bool {
        draggingIndex = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingIndex, dragging != currentIndex else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            photos.move(
                fromOffsets: IndexSet(integer: dragging),
                toOffset: currentIndex > dragging ? currentIndex + 1 : currentIndex
            )
            draggingIndex = currentIndex
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
