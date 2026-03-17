import SwiftUI
import CatchCore

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProfileSyncService.self) private var profileSyncService
    @Environment(ToastManager.self) private var toastManager

    private let profile: UserProfile
    var onSave: ((UserProfile) -> Void)?

    @State private var displayName: String
    @State private var bio: String
    @State private var username: String
    @State private var avatarData: Data?
    @State private var isPrivate: Bool
    @State private var visibilitySettings: VisibilitySettings
    @State private var usernameAvailability: UsernameAvailability = .idle

    @State private var isLoadingAvatar = false
    @State private var didChangeAvatar = false

    init(profile: UserProfile, onSave: ((UserProfile) -> Void)? = nil) {
        self.profile = profile
        self.onSave = onSave
        _displayName = State(initialValue: profile.displayName)
        _bio = State(initialValue: profile.bio)
        _username = State(initialValue: profile.username ?? "")
        _avatarData = State(initialValue: nil)
        _isPrivate = State(initialValue: profile.isPrivate)
        _visibilitySettings = State(initialValue: profile.visibilitySettings)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AvatarPickerView(avatarData: $avatarData, showCameraBadge: false)
                }

                infoSection
                privacySection
                if !isPrivate {
                    visibilitySection
                }
            }
            .task { await loadExistingAvatar() }
            .onChange(of: avatarData) { _, _ in
                if !isLoadingAvatar { didChangeAvatar = true }
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
        }
    }

    // MARK: - Sections

    private var infoSection: some View {
        Section {
            TextField(CatchStrings.Profile.displayName, text: $displayName)
            UsernameFieldView(
                username: $username,
                availability: $usernameAvailability,
                currentUsername: profile.username,
                checkAvailability: { username in
                    try await profileSyncService.checkUsernameAvailability(username)
                }
            )
            LimitedTextFieldView(
                CatchStrings.Profile.bio,
                text: $bio,
                limit: TextInputLimits.bio
            )
        } header: {
            Text(CatchStrings.Profile.info)
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

    private func loadExistingAvatar() async {
        guard avatarData == nil,
              let urlString = profile.avatarUrl,
              let url = URL(string: urlString) else { return }
        isLoadingAvatar = true
        defer { isLoadingAvatar = false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: CatchTheme.jpegCompressionQuality) else { return }
            avatarData = jpeg
        } catch {
            // Avatar load failed — user can still pick a new photo
        }
    }

    private func save() {
        var updated = profile
        updated.displayName = displayName.trimmingCharacters(in: .whitespaces)
        updated.bio = bio.trimmingCharacters(in: .whitespaces)
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        updated.username = trimmedUsername.isEmpty ? nil : trimmedUsername
        updated.isPrivate = isPrivate
        updated.visibilitySettings = visibilitySettings

        Task {
            do {
                let avatarPayload = didChangeAvatar ? avatarData : nil
                let newAvatarUrl = try await profileSyncService.syncProfile(updated, avatarData: avatarPayload)
                if let newAvatarUrl {
                    updated.avatarUrl = newAvatarUrl
                }
                onSave?(updated)
                dismiss()
            } catch {
                toastManager.showError(CatchStrings.Toast.profileSaveFailed)
            }
        }
    }
}
