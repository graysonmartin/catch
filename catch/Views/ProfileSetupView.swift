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
    @State private var signInError: String?
    @State private var isRestoringProfile = false
    @State private var currentNonce: String?
    @State private var showEmailSignIn = false
    @State private var emailAddress = ""
    @State private var emailPassword = ""
    @State private var isEmailSignUp = false
    @State private var isEmailLoading = false

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
            prefillFromUser()
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
            appleSignInButton
            googleSignInButton
            emailSignInToggle

            if showEmailSignIn {
                emailSignInFields
            }

            if let signInError {
                Text(signInError)
                    .font(.caption).foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            #if DEBUG
            Button {
                debugSignIn()
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

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            let nonce = NonceGenerator.randomNonce()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = NonceGenerator.sha256(nonce)
        } onCompletion: { result in
            handleAppleSignIn(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
    }

    private var googleSignInButton: some View {
        Button {
            Task { await handleGoogleSignIn() }
        } label: {
            HStack(spacing: CatchSpacing.space10) {
                Image(systemName: "globe")
                    .font(.body.weight(.medium))
                Text(CatchStrings.ProfileSetup.signInWithGoogle)
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(red: 0.26, green: 0.52, blue: 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var emailSignInToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showEmailSignIn.toggle()
            }
        } label: {
            HStack(spacing: CatchSpacing.space10) {
                Image(systemName: "envelope.fill")
                    .font(.body.weight(.medium))
                Text(CatchStrings.ProfileSetup.signInWithEmail)
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(CatchTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(CatchTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(CatchTheme.secondary.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var emailSignInFields: some View {
        VStack(spacing: CatchSpacing.space12) {
            TextField(CatchStrings.ProfileSetup.emailPlaceholder, text: $emailAddress)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(CatchSpacing.space12)
                .background(CatchTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
                .overlay(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight)
                    .stroke(CatchTheme.secondary.opacity(0.3), lineWidth: 1))

            SecureField(CatchStrings.ProfileSetup.passwordPlaceholder, text: $emailPassword)
                .textContentType(isEmailSignUp ? .newPassword : .password)
                .padding(CatchSpacing.space12)
                .background(CatchTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
                .overlay(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight)
                    .stroke(CatchTheme.secondary.opacity(0.3), lineWidth: 1))

            HStack(spacing: CatchSpacing.space16) {
                Button {
                    isEmailSignUp.toggle()
                } label: {
                    Text(isEmailSignUp
                         ? CatchStrings.ProfileSetup.switchToSignIn
                         : CatchStrings.ProfileSetup.switchToSignUp)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.primary)
                }

                Spacer()

                Button {
                    Task { await handleEmailSignIn() }
                } label: {
                    if isEmailLoading {
                        ProgressView()
                            .frame(width: 80, height: 40)
                    } else {
                        Text(isEmailSignUp
                             ? CatchStrings.ProfileSetup.signUp
                             : CatchStrings.ProfileSetup.signIn)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 40)
                            .background(canSubmitEmail ? CatchTheme.primary : CatchTheme.primary.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .disabled(!canSubmitEmail || isEmailLoading)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var canSubmitEmail: Bool {
        !emailAddress.trimmingCharacters(in: .whitespaces).isEmpty &&
        emailPassword.count >= 6
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

    private func handleAppleSignIn(_ result: Result<ASAuthorization, any Error>) {
        guard let nonce = currentNonce else {
            signInError = CatchStrings.ProfileSetup.signInFailed
            return
        }

        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken else {
                throw SupabaseAuthError.missingIdentityToken
            }

            let fullName: String? = {
                guard let components = credential.fullName else { return nil }
                let formatted = PersonNameComponentsFormatter.localizedString(
                    from: components, style: .default
                )
                return formatted.isEmpty ? nil : formatted
            }()

            signInError = nil

            Task {
                do {
                    let user = try await authService.signInWithApple(idToken: identityToken, nonce: nonce)
                    if let fullName, displayName.isEmpty {
                        displayName = fullName
                    }
                    if let email = user.email, displayName.isEmpty {
                        displayName = email.components(separatedBy: "@").first ?? ""
                    }
                    isRestoringProfile = true
                    await restoreExistingProfile()
                } catch {
                    signInError = CatchStrings.ProfileSetup.signInFailed
                }
            }
        } catch {
            signInError = CatchStrings.ProfileSetup.signInFailed
        }
    }

    private func handleGoogleSignIn() async {
        do {
            let redirectURL = URL(string: "catch://auth-callback")!
            let oauthURL = try await authService.googleOAuthURL(redirectTo: redirectURL)

            let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    let session = ASWebAuthenticationSession(
                        url: oauthURL,
                        callbackURLScheme: "catch"
                    ) { callbackURL, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if let callbackURL {
                            continuation.resume(returning: callbackURL)
                        } else {
                            continuation.resume(throwing: SupabaseAuthError.providerError("No callback received."))
                        }
                    }
                    session.prefersEphemeralWebBrowserSession = false
                    session.presentationContextProvider = GoogleAuthPresentationContext.shared
                    session.start()
                }
            }

            let user = try await authService.handleOAuthCallback(callbackURL)
            if let name = user.fullName, displayName.isEmpty {
                displayName = name
            }
            signInError = nil
            isRestoringProfile = true
            await restoreExistingProfile()
        } catch is CancellationError {
            // User cancelled
        } catch {
            signInError = CatchStrings.ProfileSetup.signInFailed
        }
    }

    private func handleEmailSignIn() async {
        isEmailLoading = true
        defer { isEmailLoading = false }

        let trimmedEmail = emailAddress.trimmingCharacters(in: .whitespaces)

        do {
            if isEmailSignUp {
                _ = try await authService.signUpWithEmail(trimmedEmail, password: emailPassword)
            } else {
                _ = try await authService.signInWithEmail(trimmedEmail, password: emailPassword)
            }
            signInError = nil
            prefillFromUser()
            isRestoringProfile = true
            await restoreExistingProfile()
        } catch SupabaseAuthError.signUpRequiresVerification {
            signInError = CatchStrings.ProfileSetup.checkEmailForVerification
        } catch {
            signInError = CatchStrings.ProfileSetup.signInFailed
        }
    }

    #if DEBUG
    private func debugSignIn() {
        Task {
            do {
                _ = try await authService.signInWithEmail("debug@catch.test", password: "debug123456")
                prefillFromUser()
                isRestoringProfile = true
                await restoreExistingProfile()
            } catch {
                signInError = "debug sign-in failed: \(error.localizedDescription)"
            }
        }
    }
    #endif

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

            // Pre-fill fields from existing profile
            displayName = cloudProfile.displayName
            bio = cloudProfile.bio
            username = cloudProfile.username ?? ""

            isRestoringProfile = false
            onComplete()
        } catch {
            isRestoringProfile = false
            toastManager.showError(CatchStrings.ProfileSetup.signInFailed)
        }
    }

    private func prefillFromUser() {
        guard let user = authService.authState.user else { return }
        if displayName.isEmpty, let fullName = user.fullName { displayName = fullName }
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
                try await profileSyncService.syncProfile(profile)
            } catch {
                toastManager.showError(CatchStrings.Toast.profileSaveFailed)
            }
        }
        onComplete()
    }
}

// MARK: - Google Auth Presentation Context

private final class GoogleAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = GoogleAuthPresentationContext()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
