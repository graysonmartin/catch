import SwiftUI
import PhotosUI
import CatchCore

struct PhotoPickerView: View {
    @Binding var selectedPhotos: [PhotoItem]
    private let minimumPhotos: Int
    private let thumbnailSize: CGFloat
    private let showsProfilePicBadge: Bool
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isShowingCamera = false
    @State private var isShowingPhotoSourceSheet = false
    @State private var isShowingLibraryPicker = false

    init(
        selectedPhotos: Binding<[PhotoItem]>,
        minimumPhotos: Int = 0,
        thumbnailSize: CGFloat = 100,
        showsProfilePicBadge: Bool = false
    ) {
        _selectedPhotos = selectedPhotos
        self.minimumPhotos = minimumPhotos
        self.thumbnailSize = thumbnailSize
        self.showsProfilePicBadge = showsProfilePicBadge
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            if !selectedPhotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CatchSpacing.space8) {
                        ForEach(Array(selectedPhotos.enumerated()), id: \.element.id) { index, _ in
                            photoThumbnail(at: index)
                        }
                    }
                    .padding(.horizontal)
                }
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
                    Button {
                        isShowingCamera = true
                    } label: {
                        Label(CatchStrings.Components.takePhoto, systemImage: "camera")
                    }
                }
                Button {
                    isShowingLibraryPicker = true
                } label: {
                    Label(CatchStrings.Components.chooseFromLibrary, systemImage: "photo.on.rectangle")
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
                           let uiImage = UIImage(data: data) {
                            let resized = ImageResizer.resize(uiImage, maxDimension: ImageResizer.photoMaxDimension)
                            if let compressed = resized.jpegData(compressionQuality: CatchTheme.jpegCompressionQuality) {
                                selectedPhotos.append(.local(compressed))
                            }
                        }
                    }
                    pickerItems.removeAll()
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraCaptureView(
                    onCapture: { data in
                        selectedPhotos.append(.local(data))
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
        let item = selectedPhotos[index]

        ZStack(alignment: .topTrailing) {
            thumbnailImage(for: item)
                .overlay(alignment: .bottomLeading) {
                    if showsProfilePicBadge {
                        if isPrimary {
                            primaryBadge
                        } else {
                            setAsPrimaryButton(index: index)
                        }
                    }
                }

            deleteButton(index: index)
        }
    }

    @ViewBuilder
    private func thumbnailImage(for item: PhotoItem) -> some View {
        switch item.content {
        case .local(let data):
            CatPhotoView(photoData: data, size: thumbnailSize)
        case .remote(let url):
            CatPhotoView(photoData: nil, photoUrl: url, size: thumbnailSize)
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
