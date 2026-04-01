import Foundation
import Observation
import Supabase

public enum SupabaseAuthError: LocalizedError, Sendable {
    case missingIdentityToken
    case invalidIdentityToken
    case sessionExpired
    case providerError(String)
    case demoSignInFailed

    public var errorDescription: String? {
        switch self {
        case .missingIdentityToken:
            return "No identity token received from sign-in provider."
        case .invalidIdentityToken:
            return "The identity token could not be read."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .providerError(let message):
            return message
        case .demoSignInFailed:
            return "Demo sign-in failed."
        }
    }
}

@Observable
@MainActor
public final class SupabaseAuthService: @unchecked Sendable {
    public private(set) var authState: AuthState = .unknown

    @ObservationIgnored
    private let clientProvider: any SupabaseClientProviding

    @ObservationIgnored
    private var authListenerTask: Task<Void, Never>?

    private var client: SupabaseClient { clientProvider.client }

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
        restoreSession()
        startAuthListener()
    }

    deinit {
        authListenerTask?.cancel()
    }

    // MARK: - Apple Sign-In

    /// Signs in with an Apple identity token obtained from `ASAuthorizationAppleIDCredential`.
    /// - Parameters:
    ///   - idToken: The raw JWT identity token from Apple (`.identityToken`).
    ///   - nonce: The raw (unhashed) nonce used in the Apple Sign-In request.
    /// - Returns: The authenticated `AuthUser`.
    @discardableResult
    public func signInWithApple(idToken: Data, nonce: String) async throws -> AuthUser {
        guard let tokenString = String(data: idToken, encoding: .utf8) else {
            throw SupabaseAuthError.invalidIdentityToken
        }

        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: tokenString, nonce: nonce)
        )

        let user = mapSessionUser(session.user, provider: .apple)
        authState = .signedIn(user)
        return user
    }

    // MARK: - Google Sign-In (OAuth)

    /// Returns the OAuth URL for Google sign-in. The caller should open this in
    /// `ASWebAuthenticationSession` and pass the callback URL to `handleOAuthCallback(_:)`.
    public func googleOAuthURL(redirectTo: URL) async throws -> URL {
        try await client.auth.getOAuthSignInURL(provider: .google, redirectTo: redirectTo)
    }

    /// Completes the OAuth flow after the user is redirected back from the provider.
    @discardableResult
    public func handleOAuthCallback(_ url: URL) async throws -> AuthUser {
        let session = try await client.auth.session(from: url)
        let user = mapSessionUser(session.user, provider: .google)
        authState = .signedIn(user)
        return user
    }

    // MARK: - Demo Sign-In

    /// Signs in using the demo account edge function. Used for App Store review.
    /// The edge function generates a fresh session — no hardcoded tokens.
    public func signInWithDemo() async throws -> AuthUser {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let tokenResponse: DemoTokenResponse = try await client.functions
            .invoke("demo-session", options: .init(method: .post), decoder: decoder)

        let session = try await client.auth.setSession(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken
        )

        let user = mapSessionUser(session.user, provider: .email)
        authState = .signedIn(user)
        return user
    }

    // MARK: - Sign Out

    public func signOut() async {
        try? await client.auth.signOut()
        authState = .signedOut
    }

    // MARK: - Session

    /// The current Supabase user ID, or `nil` if not signed in.
    public var currentUserID: String? {
        authState.user?.id
    }

    public func refreshSessionIfNeeded() async {
        do {
            let session = try await client.auth.session
            let user = mapSessionUser(session.user, provider: providerFromSession(session))
            authState = .signedIn(user)
        } catch {
            authState = .signedOut
        }
    }

    // MARK: - Private

    private func restoreSession() {
        // Supabase SDK auto-persists sessions. Try to read the current one synchronously.
        // If it exists, set state immediately so the UI doesn't flash the sign-in screen.
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let session = try await self.client.auth.session
                let user = self.mapSessionUser(session.user, provider: self.providerFromSession(session))
                if self.authState == .unknown {
                    self.authState = .signedIn(user)
                }
            } catch {
                if self.authState == .unknown {
                    self.authState = .signedOut
                }
            }
        }
    }

    private func startAuthListener() {
        authListenerTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in await self.client.auth.authStateChanges {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    switch event {
                    case .signedIn, .tokenRefreshed:
                        if let session {
                            let user = self.mapSessionUser(
                                session.user,
                                provider: self.providerFromSession(session)
                            )
                            self.authState = .signedIn(user)
                        }
                    case .signedOut:
                        self.authState = .signedOut
                    default:
                        break
                    }
                }
            }
        }
    }

    private func mapSessionUser(_ supaUser: Supabase.User, provider: AuthProvider) -> AuthUser {
        AuthUser(
            id: supaUser.id.uuidString.lowercased(),
            email: supaUser.email,
            fullName: supaUser.userMetadata["full_name"]?.value as? String,
            provider: provider
        )
    }

    private func providerFromSession(_ session: Supabase.Session) -> AuthProvider {
        let providerString = session.user.appMetadata["provider"]?.value as? String
        switch providerString {
        case "apple": return .apple
        case "google": return .google
        default: return .apple
        }
    }
}

// MARK: - Demo Token Response

private struct DemoTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
