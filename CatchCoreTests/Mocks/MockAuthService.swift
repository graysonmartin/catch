import AuthenticationServices
import Observation
@testable import CatchCore

@Observable
@MainActor
final class MockAuthService: AuthService {
    private(set) var authState: AuthState = .signedOut

    var processSignInResultStub: Result<AppleUser, any Error> = .success(
        AppleUser(userIdentifier: "mock-user", fullName: "Mock User", email: "mock@catch.app")
    )
    var checkCredentialStateCalled = false
    var signOutCalled = false

    func processSignInResult(_ result: Result<ASAuthorization, any Error>) throws -> AppleUser {
        let user = try processSignInResultStub.get()
        authState = .signedIn(user)
        return user
    }

    func signOut() {
        signOutCalled = true
        authState = .signedOut
    }

    func checkCredentialState() async {
        checkCredentialStateCalled = true
    }

    func simulateSignIn(user: AppleUser = AppleUser(userIdentifier: "mock", fullName: nil, email: nil)) {
        authState = .signedIn(user)
    }
}
