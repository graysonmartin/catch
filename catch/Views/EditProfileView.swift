import SwiftUI
import CatchCore

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProfileSyncService.self) private var profileSyncService
    @Bindable var profile: UserProfile

    var onSave: ((UserProfile) -> Void)?

    @State private var displayName: String
    @State private var bio: String
    @State private var username: String
    @State private var avatarData: Data?
    @State private var isPrivate: Bool
    @State private var visibilitySettings: VisibilitySettings
    @State private var usernameAvailability: UsernameAvailability = .idle

    init(profile: UserProfile, onSave: ((UserProfile) -> Void)? = nil) {
        self.profile = profile
        self.onSave = onSave
        _displayName = State(initialValue: profile.displayName)
        _bio = State(initialValue: profile.bio)
        _username = State(initialValue: profile.username ?? "")
        _avatarData = State(initialValue: profile.avatarData)
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
        } footer: {
            if !username.isEmpty {
                Text(CatchStrings.Profile.usernameFooter)
            }
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
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        profile.username = trimmedUsername.isEmpty ? nil : trimmedUsername
        profile.avatarData = avatarData
        profile.isPrivate = isPrivate
        profile.visibilitySettings = visibilitySettings
        onSave?(profile)
        dismiss()
    }
}
