import SwiftUI
import AuthenticationServices
import CatchCore

struct SignInView: View {
    @Environment(SupabaseAuthService.self) private var authService

    @State private var currentNonce: String?
    @State private var signInError: String?
    @State private var showEmailSignIn = false
    @State private var emailAddress = ""
    @State private var emailPassword = ""
    @State private var isEmailSignUp = false
    @State private var isEmailLoading = false

    var onSignedIn: (AuthUser) -> Void

    var body: some View {
        ZStack {
            CatchTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: CatchSpacing.space40) {
                    Spacer(minLength: CatchSpacing.space48)
                    brandHeader
                    signInButtons
                    Spacer(minLength: CatchSpacing.space32)
                }
                .padding(.horizontal, CatchSpacing.space32)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        VStack(spacing: CatchSpacing.space16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 64))
                .foregroundStyle(CatchTheme.primary)
                .shadow(color: CatchTheme.primary.opacity(0.3), radius: 12, y: 4)

            VStack(spacing: CatchSpacing.space8) {
                Text(CatchStrings.Onboarding.appName)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(CatchTheme.textPrimary)

                Text(CatchStrings.SignIn.tagline)
                    .font(.title3)
                    .foregroundStyle(CatchTheme.textSecondary)

                Text(CatchStrings.SignIn.prompt)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary.opacity(0.7))
                    .padding(.top, CatchSpacing.space4)
            }
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Sign In Buttons

    private var signInButtons: some View {
        VStack(spacing: CatchSpacing.space12) {
            appleSignInButton

            dividerRow

            googleSignInButton
            emailSignInButton

            if showEmailSignIn {
                emailSignInFields
            }

            if let signInError {
                errorBanner(signInError)
            }

            #if DEBUG
            debugButton
            #endif
        }
    }

    // MARK: - Apple

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
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
    }

    // MARK: - Divider

    private var dividerRow: some View {
        HStack(spacing: CatchSpacing.space12) {
            Rectangle()
                .fill(CatchTheme.textSecondary.opacity(0.15))
                .frame(height: 1)
            Text(CatchStrings.SignIn.orDivider)
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary.opacity(0.5))
            Rectangle()
                .fill(CatchTheme.textSecondary.opacity(0.15))
                .frame(height: 1)
        }
        .padding(.vertical, CatchSpacing.space4)
    }

    // MARK: - Google

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
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
            .shadow(
                color: Color(red: 0.26, green: 0.52, blue: 0.96).opacity(0.25),
                radius: 6,
                y: 3
            )
        }
    }

    // MARK: - Email

    private var emailSignInButton: some View {
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
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall)
                    .stroke(CatchTheme.textSecondary.opacity(0.15), lineWidth: 1)
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
                .padding(CatchSpacing.space14)
                .background(CatchTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
                .overlay(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight)
                    .stroke(CatchTheme.textSecondary.opacity(0.15), lineWidth: 1))

            SecureField(CatchStrings.ProfileSetup.passwordPlaceholder, text: $emailPassword)
                .textContentType(isEmailSignUp ? .newPassword : .password)
                .padding(CatchSpacing.space14)
                .background(CatchTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
                .overlay(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight)
                    .stroke(CatchTheme.textSecondary.opacity(0.15), lineWidth: 1))

            HStack {
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
                            .tint(.white)
                            .frame(width: 88, height: 40)
                    } else {
                        Text(isEmailSignUp
                             ? CatchStrings.ProfileSetup.signUp
                             : CatchStrings.ProfileSetup.signIn)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 88, height: 40)
                    }
                }
                .background(canSubmitEmail ? CatchTheme.primary : CatchTheme.primary.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
                .disabled(!canSubmitEmail || isEmailLoading)
            }
        }
        .padding(CatchSpacing.space16)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: CatchSpacing.space8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            Text(message)
                .font(.caption)
        }
        .foregroundStyle(.red)
        .multilineTextAlignment(.center)
        .padding(.vertical, CatchSpacing.space10)
        .padding(.horizontal, CatchSpacing.space16)
        .frame(maxWidth: .infinity)
        .background(.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
    }

    private var canSubmitEmail: Bool {
        !emailAddress.trimmingCharacters(in: .whitespaces).isEmpty &&
        emailPassword.count >= 6
    }

    #if DEBUG
    private var debugButton: some View {
        Button {
            debugSignIn()
        } label: {
            Text(CatchStrings.Profile.fakeSignIn)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, CatchSpacing.space16)
                .padding(.vertical, CatchSpacing.space8)
                .background(.red.opacity(0.8))
                .clipShape(Capsule())
        }
        .padding(.top, CatchSpacing.space8)
    }
    #endif
}

// MARK: - Auth Handlers

extension SignInView {

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

            signInError = nil

            Task {
                do {
                    let user = try await authService.signInWithApple(
                        idToken: identityToken,
                        nonce: nonce
                    )
                    onSignedIn(user)
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
                            continuation.resume(
                                throwing: SupabaseAuthError.providerError("No callback received.")
                            )
                        }
                    }
                    session.prefersEphemeralWebBrowserSession = false
                    session.presentationContextProvider = GoogleAuthPresentationContext.shared
                    session.start()
                }
            }

            let user = try await authService.handleOAuthCallback(callbackURL)
            signInError = nil
            onSignedIn(user)
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
            let user: AuthUser
            if isEmailSignUp {
                user = try await authService.signUpWithEmail(trimmedEmail, password: emailPassword)
            } else {
                user = try await authService.signInWithEmail(trimmedEmail, password: emailPassword)
            }
            signInError = nil
            onSignedIn(user)
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
                let user = try await authService.signInWithEmail(
                    "debug@catch.test",
                    password: "debug123456"
                )
                onSignedIn(user)
            } catch {
                signInError = "debug sign-in failed: \(error.localizedDescription)"
            }
        }
    }
    #endif
}

// MARK: - Google Auth Presentation Context

private final class GoogleAuthPresentationContext: NSObject,
    ASWebAuthenticationPresentationContextProviding {
    static let shared = GoogleAuthPresentationContext()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
