import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Binding var selectedPhotos: [Data]
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !selectedPhotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedPhotos.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                CatPhotoView(photoData: selectedPhotos[index], size: 100)
                                Button {
                                    selectedPhotos.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, .black.opacity(0.5))
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.primary)
            }
            .onChange(of: pickerItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data),
                           let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                            selectedPhotos.append(compressed)
                        }
                    }
                    pickerItems.removeAll()
                }
            }
        }
    }
}
