import AuthenticationServices
import Observation
import os
import CatchCore

/// Legacy Apple-only auth service. Retained for backward compatibility with tests.
/// New code should use `SupabaseAuthService` instead.
@Observable
@MainActor
final class AppleAuthService: AuthService {
    private(set) var authState: AuthState = .unknown

    private static let keychainKey = "catch.appleUser"
    private static let logger = Logger(subsystem: "com.graysonmartin.catch", category: "AppleAuthService")

    @ObservationIgnored
    private let keychain: any KeychainService

    @ObservationIgnored
    private nonisolated(unsafe) var revocationObserver: (any NSObjectProtocol)?

    init(keychain: any KeychainService = KeychainServiceImpl()) {
        self.keychain = keychain

        if let user = Self.loadPersistedUser(from: keychain) {
            authState = .signedIn(user)
        } else {
            authState = .signedOut
        }
        observeRevocation()
    }

    deinit {
        if let observer = revocationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - AuthService

    func processSignInResult(_ result: Result<ASAuthorization, any Error>) throws -> AuthUser {
        let authorization = try result.get()

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        let fullName: String? = {
            guard let components = credential.fullName else { return nil }
            let formatted = PersonNameComponentsFormatter.localizedString(
                from: components,
                style: .default
            )
            return formatted.isEmpty ? nil : formatted
        }()

        let user = AuthUser(
            id: credential.user,
            email: credential.email ?? authState.user?.email,
            fullName: fullName ?? authState.user?.fullName,
            provider: .apple
        )

        Self.persistUser(user, to: keychain)
        authState = .signedIn(user)
        return user
    }

    func signOut() async {
        Self.clearPersistedUser(from: keychain)
        authState = .signedOut
    }

    #if DEBUG
    func debugSignIn() {
        let user = AuthUser(
            id: "debug-user-\(UUID().uuidString.prefix(8))",
            email: "debug@catch.test",
            fullName: "Debug User",
            provider: .apple
        )
        Self.persistUser(user, to: keychain)
        authState = .signedIn(user)
    }
    #endif

    func checkCredentialState() async {
        guard let user = authState.user else {
            authState = .signedOut
            return
        }

        do {
            let state = try await ASAuthorizationAppleIDProvider()
                .credentialState(forUserID: user.id)
            switch state {
            case .authorized:
                break
            case .revoked, .notFound, .transferred:
                await signOut()
            @unknown default:
                break
            }
        } catch {
            // Network failure — keep current state, don't sign out
        }
    }

    // MARK: - Persistence

    private static func persistUser(_ user: AuthUser, to keychain: any KeychainService) {
        guard let data = try? JSONEncoder().encode(user) else {
            logger.error("Failed to encode user for keychain persistence")
            return
        }
        do {
            try keychain.save(data, forKey: keychainKey)
        } catch {
            logger.error("Keychain save failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func loadPersistedUser(from keychain: any KeychainService) -> AuthUser? {
        let data: Data
        do {
            guard let loaded = try keychain.load(forKey: keychainKey) else { return nil }
            data = loaded
        } catch {
            logger.info("No persisted user in keychain: \(error.localizedDescription, privacy: .public)")
            return nil
        }
        do {
            return try JSONDecoder().decode(AuthUser.self, from: data)
        } catch {
            logger.error("Failed to decode persisted user: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private static func clearPersistedUser(from keychain: any KeychainService) {
        do {
            try keychain.delete(forKey: keychainKey)
        } catch {
            logger.warning("Keychain delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Revocation

    private func observeRevocation() {
        revocationObserver = NotificationCenter.default.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.signOut()
            }
        }
    }
}

enum AuthError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple sign-in credential."
        }
    }
}
