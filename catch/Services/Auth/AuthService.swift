import AuthenticationServices
import CatchCore

@MainActor
protocol AuthService: Observable {
    var authState: AuthState { get }
    func processSignInResult(_ result: Result<ASAuthorization, any Error>) throws -> AppleUser
    func signOut()
    func checkCredentialState() async
}
