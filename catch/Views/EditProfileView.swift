import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    var onSave: ((UserProfile) -> Void)?

    @State private var displayName: String
    @State private var bio: String
    @State private var avatarData: Data?
    @State private var isPrivate: Bool
    @State private var visibilitySettings: VisibilitySettings
    @State private var pickerItem: PhotosPickerItem?
    @State private var isShowingPhotoOptions = false

    init(profile: UserProfile, onSave: ((UserProfile) -> Void)? = nil) {
        self.profile = profile
        self.onSave = onSave
        _displayName = State(initialValue: profile.displayName)
        _bio = State(initialValue: profile.bio)
        _avatarData = State(initialValue: profile.avatarData)
        _isPrivate = State(initialValue: profile.isPrivate)
        _visibilitySettings = State(initialValue: profile.visibilitySettings)
    }

    var body: some View {
        NavigationStack {
            Form {
                avatarSection
                infoSection
                privacySection
                if !isPrivate {
                    visibilitySection
                }
            }
            .navigationTitle(CatchStrings.Profile.editProfileTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CatchStrings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CatchStrings.Common.save) { save() }
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
        Section(CatchStrings.Profile.info) {
            TextField(CatchStrings.Profile.displayName, text: $displayName)
            TextField(CatchStrings.Profile.bio, text: $bio, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var privacySection: some View {
        Section {
            Toggle(CatchStrings.Profile.privateProfile, isOn: $isPrivate)
        } footer: {
            Text(CatchStrings.Profile.privateFooter)
        }
    }

    private var visibilitySection: some View {
        Section {
            Toggle(CatchStrings.Profile.showCats, isOn: $visibilitySettings.showCats)
            Toggle(CatchStrings.Profile.showEncounters, isOn: $visibilitySettings.showEncounters)
        } header: {
            Text(CatchStrings.Profile.visibility)
        } footer: {
            Text(CatchStrings.Profile.visibilityFooter)
        }
    }

    // MARK: - Actions

    private func save() {
        profile.displayName = displayName.trimmingCharacters(in: .whitespaces)
        profile.bio = bio.trimmingCharacters(in: .whitespaces)
        profile.avatarData = avatarData
        profile.isPrivate = isPrivate
        profile.visibilitySettings = visibilitySettings
        onSave?(profile)
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
