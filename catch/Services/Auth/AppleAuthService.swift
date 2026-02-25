import AuthenticationServices
import Observation

@Observable
@MainActor
final class AppleAuthService: AuthService {
    private(set) var authState: AuthState = .unknown

    private static let userDefaultsKey = "catch.appleUser"

    @ObservationIgnored
    private nonisolated(unsafe) var revocationObserver: (any NSObjectProtocol)?

    init() {
        if let user = Self.loadPersistedUser() {
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

    func processSignInResult(_ result: Result<ASAuthorization, any Error>) throws -> AppleUser {
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

        let user = AppleUser(
            userIdentifier: credential.user,
            fullName: fullName ?? authState.user?.fullName,
            email: credential.email ?? authState.user?.email
        )

        Self.persistUser(user)
        authState = .signedIn(user)
        return user
    }

    func signOut() {
        Self.clearPersistedUser()
        authState = .signedOut
    }

    #if DEBUG
    func debugSignIn() {
        let user = AppleUser(
            userIdentifier: "debug-user-\(UUID().uuidString.prefix(8))",
            fullName: "Debug User",
            email: "debug@catch.test"
        )
        Self.persistUser(user)
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
                .credentialState(forUserID: user.userIdentifier)
            switch state {
            case .authorized:
                break
            case .revoked, .notFound, .transferred:
                signOut()
            @unknown default:
                break
            }
        } catch {
            // Network failure — keep current state, don't sign out
        }
    }

    // MARK: - Persistence

    private static func persistUser(_ user: AppleUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    private static func loadPersistedUser() -> AppleUser? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(AppleUser.self, from: data)
    }

    private static func clearPersistedUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Revocation

    private func observeRevocation() {
        revocationObserver = NotificationCenter.default.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.signOut()
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
