import SwiftUI
import SwiftData
import AuthenticationServices
import CatchCore

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppleAuthService.self) private var authService
    @Environment(ProfileSyncService.self) private var profileSyncService
    @Environment(ToastManager.self) private var toastManager

    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var avatarData: Data?
    @State private var usernameAvailability: UsernameAvailability = .idle
    @State private var signInError: String?
    @State private var isRestoringProfile = false

    var onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
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
        ZStack {
            CatchTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: CatchSpacing.space32) {
                    headerSection
                    if isRestoringProfile {
                        PawLoadingView(label: CatchStrings.ProfileSetup.restoringProfile)
                    } else if isSignedIn {
                        signedInBadge
                        AvatarPickerView(avatarData: $avatarData)
                        fieldsSection
                        submitButton
                    } else {
                        signInSection
                    }
                }
                .padding(.horizontal, CatchSpacing.space32)
                .padding(.vertical, CatchSpacing.space48)
            }
        }
        .task {
            prefillFromAppleUser()
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
            Text(isSignedIn ? CatchStrings.ProfileSetup.subtitle : CatchStrings.ProfileSetup.signInPrompt)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
        }
    }

    // MARK: - Sign In

    private var signInSection: some View {
        VStack(spacing: CatchSpacing.space16) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)

            if let signInError {
                Text(signInError)
                    .font(.caption).foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            #if DEBUG
            Button {
                authService.debugSignIn()
                prefillFromAppleUser()
                isRestoringProfile = true
                Task { await restoreExistingProfile() }
            } label: {
                Text(CatchStrings.Profile.fakeSignIn)
                    .font(.caption.weight(.semibold)).foregroundStyle(.white)
                    .padding(.horizontal, CatchSpacing.space16)
                    .padding(.vertical, CatchSpacing.space8)
                    .background(.red.opacity(0.8)).clipShape(Capsule())
            }
            #endif
        }
    }

    private var signedInBadge: some View {
        HStack(spacing: CatchSpacing.space8) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(CatchTheme.primary)
            Text(CatchStrings.ProfileSetup.appleAccountConnected)
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

    private func handleSignIn(_ result: Result<ASAuthorization, any Error>) {
        do {
            _ = try authService.processSignInResult(result)
            signInError = nil
            prefillFromAppleUser()
            isRestoringProfile = true
            Task { await restoreExistingProfile() }
        } catch {
            signInError = CatchStrings.ProfileSetup.signInFailed
        }
    }

    private func restoreExistingProfile() async {
        guard let appleUserID = authService.authState.user?.userIdentifier else {
            isRestoringProfile = false
            return
        }

        let cloudProfile: CloudUserProfile?
        do {
            cloudProfile = try await profileSyncService.fetchProfile(appleUserID: appleUserID)
        } catch {
            isRestoringProfile = false
            toastManager.showError(CatchStrings.ProfileSetup.signInFailed)
            return
        }

        guard let cloudProfile else {
            isRestoringProfile = false
            return
        }

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.appleUserID == appleUserID }
        )
        let existingProfile = try? modelContext.fetch(descriptor).first

        if let existingProfile {
            existingProfile.displayName = cloudProfile.displayName
            existingProfile.bio = cloudProfile.bio
            existingProfile.username = cloudProfile.username
            existingProfile.cloudKitRecordName = cloudProfile.recordName
            existingProfile.isPrivate = cloudProfile.isPrivate
            existingProfile.avatarData = cloudProfile.avatarData
        } else {
            let profile = UserProfile(
                displayName: cloudProfile.displayName,
                bio: cloudProfile.bio,
                username: cloudProfile.username,
                avatarData: cloudProfile.avatarData,
                appleUserID: cloudProfile.appleUserID,
                cloudKitRecordName: cloudProfile.recordName,
                isPrivate: cloudProfile.isPrivate
            )
            modelContext.insert(profile)
        }

        try? modelContext.save()
        onComplete()
    }

    private func prefillFromAppleUser() {
        guard let user = authService.authState.user else { return }
        if displayName.isEmpty, let fullName = user.fullName { displayName = fullName }
    }

    private func saveProfile() {
        let profile = UserProfile(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            bio: bio.trimmingCharacters(in: .whitespaces),
            username: username.trimmingCharacters(in: .whitespaces),
            avatarData: avatarData,
            appleUserID: authService.authState.user?.userIdentifier
        )
        modelContext.insert(profile)
        Task {
            do {
                try await profileSyncService.syncProfile(profile)
            } catch {
                toastManager.showError(CatchStrings.Toast.profileSaveFailed)
            }
        }
        onComplete()
    }
}
