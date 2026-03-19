import SwiftUI
import AuthenticationServices
import CatchCore

struct ProfileSetupView: View {
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(ProfileSyncService.self) private var profileSyncService
    @Environment(ToastManager.self) private var toastManager

    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var avatarData: Data?
    @State private var usernameAvailability: UsernameAvailability = .idle
    @State private var isRestoringProfile = true

    var onComplete: (_ isNewUser: Bool) -> Void

    init(onComplete: @escaping (_ isNewUser: Bool) -> Void) {
        self.onComplete = onComplete
    }

    private var isSignedIn: Bool { authService.authState.isSignedIn }

    private var canSubmit: Bool {
        guard isSignedIn else { return false }
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return false }
        guard UsernameValidator.validate(username) == .valid else { return false }
        guard usernameAvailability == .available else { return false }
        return true
    }

    var body: some View {
        if isSignedIn {
            profileSetupContent
        } else {
            SignInView { _ in
                Task {
                    isRestoringProfile = true
                    await restoreExistingProfile()
                }
            }
            .environment(authService)
        }
    }

    // MARK: - Profile Setup Content

    private var profileSetupContent: some View {
        ZStack {
            CatchTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: CatchSpacing.space32) {
                    headerSection
                    if isRestoringProfile {
                        PawLoadingView(label: CatchStrings.ProfileSetup.restoringProfile)
                    } else {
                        signedInBadge
                        AvatarPickerView(avatarData: $avatarData)
                        fieldsSection
                        submitButton
                    }
                }
                .padding(.horizontal, CatchSpacing.space32)
                .padding(.vertical, CatchSpacing.space48)
            }
        }
        .task {
            if isSignedIn {
                isRestoringProfile = true
                await restoreExistingProfile()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: CatchSpacing.space12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(CatchTheme.primary)
            Text(CatchStrings.ProfileSetup.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)
            Text(CatchStrings.ProfileSetup.subtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
        }
    }

    private var signedInBadge: some View {
        HStack(spacing: CatchSpacing.space8) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(CatchTheme.primary)
            Text(CatchStrings.ProfileSetup.accountConnected)
                .font(.subheadline).foregroundStyle(CatchTheme.textSecondary)
        }
        .padding(.vertical, CatchSpacing.space10)
        .padding(.horizontal, CatchSpacing.space16)
        .background(CatchTheme.cardBackground).clipShape(Capsule())
    }
}

// MARK: - Fields

extension ProfileSetupView {

    private var fieldsSection: some View {
        VStack(spacing: CatchSpacing.space20) {
            fieldRow(label: CatchStrings.ProfileSetup.displayNameLabel) {
                LimitedSingleLineFieldView(
                    CatchStrings.ProfileSetup.displayNamePlaceholder,
                    text: $displayName,
                    limit: TextInputLimits.displayName
                )
                .textContentType(.name)
            }
            VStack(alignment: .leading, spacing: CatchSpacing.space6) {
                Text(CatchStrings.ProfileSetup.usernameLabel)
                    .font(.caption.weight(.semibold)).foregroundStyle(CatchTheme.textSecondary)
                UsernameFieldView(
                    username: $username,
                    availability: $usernameAvailability,
                    checkAvailability: { username in
                        try await profileSyncService.checkUsernameAvailability(username)
                    }
                )
                .padding(CatchSpacing.space12)
                .background(CatchTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
                .overlay(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight)
                    .stroke(CatchTheme.secondary.opacity(0.3), lineWidth: 1))
            }
            fieldRow(label: CatchStrings.ProfileSetup.bioLabel) {
                LimitedTextFieldView(
                    CatchStrings.ProfileSetup.bioPlaceholder,
                    text: $bio,
                    limit: TextInputLimits.bio
                )
            }
        }
    }

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space6) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(CatchTheme.textSecondary)
            content()
                .padding(CatchSpacing.space12)
                .background(CatchTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
                .overlay(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight)
                    .stroke(CatchTheme.secondary.opacity(0.3), lineWidth: 1))
        }
    }

    private var submitButton: some View {
        Button { saveProfile() } label: {
            Text(CatchStrings.ProfileSetup.done)
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(canSubmit ? CatchTheme.primary : CatchTheme.primary.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSubmit)
    }
}

// MARK: - Actions

extension ProfileSetupView {

    private func restoreExistingProfile() async {
        guard let userID = authService.authState.user?.id else {
            isRestoringProfile = false
            return
        }

        do {
            let cloudProfile = try await profileSyncService.fetchProfile(userID: userID)
            guard let cloudProfile else {
                isRestoringProfile = false
                return
            }

            displayName = cloudProfile.displayName
            bio = cloudProfile.bio
            username = cloudProfile.username ?? ""

            isRestoringProfile = false
            onComplete(false)
        } catch where error.isCancellation {
            isRestoringProfile = false
        } catch {
            isRestoringProfile = false
            toastManager.showError(CatchStrings.ProfileSetup.signInFailed)
        }
    }

    private func saveProfile() {
        let profile = UserProfile(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            bio: bio.trimmingCharacters(in: .whitespaces),
            username: username.trimmingCharacters(in: .whitespaces),
            supabaseUserID: authService.authState.user?.id
        )
        Task {
            do {
                let avatarChange: AvatarChange = avatarData.map { .updated($0) } ?? .noChange
                try await profileSyncService.syncProfile(profile, avatarChange: avatarChange)
                onComplete(true)
            } catch {
                toastManager.showError(CatchStrings.Toast.profileSaveFailed)
            }
        }
    }
}
