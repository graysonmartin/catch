import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    @State private var displayName: String
    @State private var bio: String
    @State private var avatarData: Data?
    @State private var isPrivate: Bool
    @State private var pickerItem: PhotosPickerItem?
    @State private var isShowingPhotoOptions = false

    init(profile: UserProfile) {
        self.profile = profile
        _displayName = State(initialValue: profile.displayName)
        _bio = State(initialValue: profile.bio)
        _avatarData = State(initialValue: profile.avatarData)
        _isPrivate = State(initialValue: profile.isPrivate)
    }

    var body: some View {
        NavigationStack {
            Form {
                avatarSection
                infoSection
                privacySection
            }
            .navigationTitle("edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                loadPhoto(from: newItem)
            }
        }
    }

    // MARK: - Sections

    private var avatarSection: some View {
        Section {
            avatarPreview
                .frame(maxWidth: .infinity)
                .contentShape(Circle())
                .onTapGesture { isShowingPhotoOptions = true }
                .confirmationDialog("profile photo", isPresented: $isShowingPhotoOptions) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Text("choose photo")
                    }
                    if avatarData != nil {
                        Button("remove photo", role: .destructive) {
                            avatarData = nil
                            pickerItem = nil
                        }
                    }
                }
        }
    }

    private var avatarPreview: some View {
        Group {
            if let data = avatarData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(CatchTheme.secondary)
            }
        }
    }

    private var infoSection: some View {
        Section("info") {
            TextField("display name", text: $displayName)
            TextField("bio", text: $bio, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var privacySection: some View {
        Section {
            Toggle("private profile", isOn: $isPrivate)
        } footer: {
            Text("when private, people have to request to follow you. going private won't auto-approve existing requests.")
        }
    }

    // MARK: - Actions

    private func save() {
        profile.displayName = displayName.trimmingCharacters(in: .whitespaces)
        profile.bio = bio.trimmingCharacters(in: .whitespaces)
        profile.avatarData = avatarData
        profile.isPrivate = isPrivate
        dismiss()
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
