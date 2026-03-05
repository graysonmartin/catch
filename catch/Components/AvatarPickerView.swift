import SwiftUI
import PhotosUI
import CatchCore

struct AvatarPickerView: View {
    @Binding var avatarData: Data?
    var size: CGFloat = 100
    var showCameraBadge: Bool = true

    @State private var pickerItem: PhotosPickerItem?
    @State private var isShowingPhotoOptions = false
    @State private var isShowingPhotoPicker = false

    var body: some View {
        avatarPreview
            .frame(maxWidth: .infinity)
            .contentShape(Circle())
            .onTapGesture { isShowingPhotoOptions = true }
            .confirmationDialog(CatchStrings.Profile.profilePhoto, isPresented: $isShowingPhotoOptions) {
                Button(CatchStrings.Profile.choosePhoto) {
                    isShowingPhotoPicker = true
                }
                if avatarData != nil {
                    Button(CatchStrings.Profile.removePhoto, role: .destructive) {
                        avatarData = nil
                        pickerItem = nil
                    }
                }
            }
            .photosPicker(isPresented: $isShowingPhotoPicker, selection: $pickerItem, matching: .images)
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
            .onTapGesture { isShowingPhotoOptions = true }
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
