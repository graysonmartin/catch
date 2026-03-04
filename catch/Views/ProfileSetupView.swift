import SwiftUI
import SwiftData
import PhotosUI
import AuthenticationServices
import CatchCore

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppleAuthService.self) private var authService

    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var avatarData: Data?
    @State private var pickerItem: PhotosPickerItem?
    @State private var isShowingPhotoOptions = false
    @State private var usernameAvailability: UsernameAvailability = .idle
    @State private var usernameCheckTask: Task<Void, Never>?
    @State private var signInError: String?

    private var cloudKitService: CloudKitService = CKCloudKitService()
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
                    if isSignedIn {
                        signedInBadge
                        avatarSection
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
        .onAppear { prefillFromAppleUser() }
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
            Text(CatchStrings.Profile.signedInWithApple)
                .font(.subheadline).foregroundStyle(CatchTheme.textSecondary)
        }
        .padding(.vertical, CatchSpacing.space10)
        .padding(.horizontal, CatchSpacing.space16)
        .background(CatchTheme.cardBackground).clipShape(Capsule())
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        avatarPreview
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
            .onChange(of: pickerItem) { _, newItem in loadPhoto(from: newItem) }
    }

    private var avatarPreview: some View {
        ZStack(alignment: .bottomTrailing) {
            if let data = avatarData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
                    .frame(width: 100, height: 100).clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill").resizable().scaledToFit()
                    .frame(width: 100, height: 100).foregroundStyle(CatchTheme.secondary)
            }
            Image(systemName: "camera.circle.fill")
                .font(.title3).foregroundStyle(.white)
                .background(Circle().fill(CatchTheme.primary).frame(width: 28, height: 28))
        }
    }
}

// MARK: - Fields & Username Status

extension ProfileSetupView {

    private var fieldsSection: some View {
        VStack(spacing: CatchSpacing.space20) {
            fieldRow(label: CatchStrings.ProfileSetup.displayNameLabel) {
                TextField(CatchStrings.ProfileSetup.displayNamePlaceholder, text: $displayName)
                    .textContentType(.name)
            }
            VStack(alignment: .leading, spacing: CatchSpacing.space6) {
                Text(CatchStrings.ProfileSetup.usernameLabel)
                    .font(.caption.weight(.semibold)).foregroundStyle(CatchTheme.textSecondary)
                HStack {
                    Text("@").foregroundStyle(CatchTheme.textSecondary)
                    TextField(CatchStrings.Profile.usernamePlaceholder, text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: username) { _, newValue in
                            username = newValue.lowercased()
                            checkUsernameAvailability()
                        }
                }
                .padding(CatchSpacing.space12)
                .background(CatchTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
                .overlay(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight)
                    .stroke(CatchTheme.secondary.opacity(0.3), lineWidth: 1))
                usernameStatusView
            }
            fieldRow(label: CatchStrings.ProfileSetup.bioLabel) {
                TextField(CatchStrings.ProfileSetup.bioPlaceholder, text: $bio, axis: .vertical)
                    .lineLimit(3...5)
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

    @ViewBuilder
    private var usernameStatusView: some View {
        let validation = UsernameValidator.validate(username)
        if username.isEmpty {
            Text(CatchStrings.Profile.usernameFooter)
                .font(.caption).foregroundStyle(CatchTheme.textSecondary)
        } else if validation != .valid {
            Text(validationMessage(for: validation))
                .font(.caption).foregroundStyle(.red)
        } else {
            switch usernameAvailability {
            case .idle: EmptyView()
            case .checking:
                Text(CatchStrings.Profile.usernameChecking).font(.caption).foregroundStyle(CatchTheme.textSecondary)
            case .available:
                Text(CatchStrings.Profile.usernameAvailable).font(.caption).foregroundStyle(.green)
            case .taken:
                Text(CatchStrings.Profile.usernameTaken).font(.caption).foregroundStyle(.red)
            case .error:
                Text(CatchStrings.Profile.usernameCheckFailed).font(.caption).foregroundStyle(.orange)
            }
        }
    }

    private func validationMessage(for result: UsernameValidationResult) -> String {
        switch result {
        case .tooShort: CatchStrings.Profile.usernameTooShort
        case .tooLong: CatchStrings.Profile.usernameTooLong
        case .invalidCharacters: CatchStrings.Profile.usernameInvalidChars
        case .empty, .valid: ""
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
        } catch {
            signInError = CatchStrings.ProfileSetup.signInFailed
        }
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
        syncToCloudKit(profile)
        onComplete()
    }

    private func syncToCloudKit(_ profile: UserProfile) {
        guard let appleUserID = profile.appleUserID else { return }
        Task {
            do {
                let recordName = try await cloudKitService.saveUserProfile(
                    appleUserID: appleUserID, displayName: profile.displayName,
                    bio: profile.bio, username: profile.username, isPrivate: profile.isPrivate
                )
                profile.cloudKitRecordName = recordName
            } catch {
                // Non-blocking — profile saved locally, cloud sync retries later
            }
        }
    }

    private func checkUsernameAvailability() {
        usernameCheckTask?.cancel()
        let current = username
        guard UsernameValidator.validate(current) == .valid else {
            usernameAvailability = .idle
            return
        }
        usernameAvailability = .checking
        usernameCheckTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            do {
                let isAvailable = try await cloudKitService.checkUsernameAvailability(current)
                guard !Task.isCancelled else { return }
                usernameAvailability = isAvailable ? .available : .taken
            } catch {
                guard !Task.isCancelled else { return }
                usernameAvailability = .error
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: CatchTheme.jpegCompressionQuality) else { return }
            avatarData = jpeg
        }
    }
}
