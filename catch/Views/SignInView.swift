import SwiftUI
import AuthenticationServices
import CatchCore

struct SignInView: View {
    @Environment(SupabaseAuthService.self) private var authService

    @State private var currentNonce: String?
    @State private var signInError: String?
    @State private var demoTapCount = 0
    @State private var demoTapResetTask: Task<Void, Never>?
    @State private var isDemoLoading = false

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
            .allowsHitTesting(!isDemoLoading)
            .overlay {
                if isDemoLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    PawLoadingView()
                }
            }
            .onDisappear { demoTapResetTask?.cancel() }
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        VStack(spacing: CatchSpacing.space16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 64))
                .foregroundStyle(CatchTheme.primary)
                .shadow(color: CatchTheme.primary.opacity(0.3), radius: 12, y: 4)
                .accessibilityHidden(true)
                .onTapGesture { handleDemoTap() }

            VStack(spacing: CatchSpacing.space8) {
                Text(CatchStrings.Onboarding.appName)
                    .font(.largeTitle.weight(.bold))
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
            googleSignInButton

            if let signInError {
                errorBanner(signInError)
            }
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

    // MARK: - Google

    private var googleSignInButton: some View {
        Button {
            Task { await handleGoogleSignIn() }
        } label: {
            HStack(spacing: CatchSpacing.space10) {
                Image("GoogleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(CatchStrings.ProfileSetup.signInWithGoogle)
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
            .shadow(
                color: .black.opacity(0.08),
                radius: 4,
                y: 2
            )
        }
    }

    // MARK: - Error Banner

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
}

// MARK: - Demo Login

extension SignInView {

    private func handleDemoTap() {
        demoTapCount += 1
        demoTapResetTask?.cancel()
        demoTapResetTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            demoTapCount = 0
        }
        if demoTapCount >= 5 {
            demoTapCount = 0
            demoTapResetTask?.cancel()
            Task { await handleDemoSignIn() }
        }
    }

    private func handleDemoSignIn() async {
        isDemoLoading = true
        defer { isDemoLoading = false }

        do {
            let user = try await authService.signInWithDemo()
            signInError = nil
            onSignedIn(user)
        } catch {
            signInError = CatchStrings.SignIn.demoSignInFailed
        }
    }
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
            guard let redirectURL = URL(string: "catch://auth-callback") else { return }
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
