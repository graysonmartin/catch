import Observation
import CatchCore

@MainActor
protocol AuthService: Observable {
    var authState: AuthState { get }
    func signOut() async
}
