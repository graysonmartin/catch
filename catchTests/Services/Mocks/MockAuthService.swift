import Observation
import CatchCore

@Observable
@MainActor
final class MockAuthService: AuthService {
    private(set) var authState: AuthState = .signedOut

    var signOutCalled = false

    func signOut() async {
        signOutCalled = true
        authState = .signedOut
    }

    func simulateSignIn(user: AuthUser = AuthUser(id: "mock", email: nil, fullName: nil, provider: .apple)) {
        authState = .signedIn(user)
    }
}
