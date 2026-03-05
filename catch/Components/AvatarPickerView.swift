import SwiftUI
import PhotosUI
import CatchCore

struct AvatarPickerView: View {
    @Binding var avatarData: Data?
    var size: CGFloat = 100
    var showCameraBadge: Bool = true

    @State private var pickerItem: PhotosPickerItem?
    @State private var isShowingPhotoOptions = false

    var body: some View {
        avatarPreview
            .frame(maxWidth: .infinity)
            .contentShape(Circle())
            .onTapGesture { isShowingPhotoOptions = true }
            .confirmationDialog(CatchStrings.Profile.profilePhoto, isPresented: $isShowingPhotoOptions) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text(CatchStrings.Profile.choosePhoto)
                }
                if avatarData != nil {
                    Button(CatchStrings.Profile.removePhoto, role: .destructive) {
                        avatarData = nil
                        pickerItem = nil
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if showCameraBadge {
                    cameraBadge
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                loadPhoto(from: newItem)
            }
    }

    private var avatarPreview: some View {
        Group {
            if let data = avatarData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(CatchTheme.secondary)
            }
        }
    }

    private var cameraBadge: some View {
        Image(systemName: "camera.circle.fill")
            .font(.title3)
            .foregroundStyle(.white)
            .background(Circle().fill(CatchTheme.primary).frame(width: 28, height: 28))
            .offset(x: -size * 0.05, y: -size * 0.05)
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: CatchTheme.jpegCompressionQuality) else {
                return
            }
            avatarData = jpeg
        }
    }
}
