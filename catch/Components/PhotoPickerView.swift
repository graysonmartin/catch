import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import CatchCore

struct PhotoPickerView: View {
    @Binding var selectedPhotos: [Data]
    private let minimumPhotos: Int
    private let thumbnailSize: CGFloat
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var draggingIndex: Int?
    @State private var isShowingCamera = false
    @State private var isShowingPhotoSourceSheet = false
    @State private var isShowingLibraryPicker = false

    init(selectedPhotos: Binding<[Data]>, minimumPhotos: Int = 0, thumbnailSize: CGFloat = 100) {
        _selectedPhotos = selectedPhotos
        self.minimumPhotos = minimumPhotos
        self.thumbnailSize = thumbnailSize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            if !selectedPhotos.isEmpty {
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

                Text(CatchStrings.Components.dragToReorder)
                    .font(.caption2)
                    .foregroundStyle(CatchTheme.textSecondary)
                    .padding(.horizontal)
            }

            Button {
                isShowingPhotoSourceSheet = true
            } label: {
                Label(CatchStrings.Components.addPhotos, systemImage: "photo.on.rectangle.angled")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.primary)
            }
            .confirmationDialog(
                CatchStrings.Components.addPhotos,
                isPresented: $isShowingPhotoSourceSheet,
                titleVisibility: .hidden
            ) {
                if CameraCaptureView.isCameraAvailable {
                    Button(CatchStrings.Components.takePhoto) {
                        isShowingCamera = true
                    }
                }
                Button(CatchStrings.Components.chooseFromLibrary) {
                    isShowingLibraryPicker = true
                }
            }
            .photosPicker(
                isPresented: $isShowingLibraryPicker,
                selection: $pickerItems,
                maxSelectionCount: CatchTheme.maxPhotoSelection,
                matching: .images
            )
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
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraCaptureView(
                    onCapture: { data in
                        selectedPhotos.append(data)
                        isShowingCamera = false
                    },
                    onCancel: {
                        isShowingCamera = false
                    }
                )
                .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private func photoThumbnail(at index: Int) -> some View {
        let isPrimary = index == 0

        ZStack(alignment: .topTrailing) {
            CatPhotoView(photoData: selectedPhotos[index], size: thumbnailSize)
                .overlay(alignment: .bottomLeading) {
                    if isPrimary {
                        primaryBadge
                    } else {
                        setAsPrimaryButton(index: index)
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

    private var isAtMinimum: Bool {
        selectedPhotos.count <= minimumPhotos
    }

    private func deleteButton(index: Int) -> some View {
        Button {
            withAnimation {
                _ = selectedPhotos.remove(at: index)
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.white, .black.opacity(0.5))
        }
        .disabled(isAtMinimum)
        .opacity(isAtMinimum ? 0.3 : 1.0)
        .offset(x: CatchSpacing.space4, y: -CatchSpacing.space4)
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
