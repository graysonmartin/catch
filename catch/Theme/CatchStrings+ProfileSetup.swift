import Foundation
import CatchCore

extension CatchStrings {

    enum ProfileSetup {
        static let title = String(localized: "who are you")
        static let subtitle = String(localized: "pick a name and a handle.")
        static let signInPrompt = String(localized: "sign in first to get started.")
        static let signInFailed = String(localized: "sign in didn't work. give it another shot.")
        static let displayNameLabel = String(localized: "display name")
        static let displayNamePlaceholder = String(localized: "what should cats call you")
        static let usernameLabel = String(localized: "username")
        static let bioLabel = String(localized: "bio (optional)")
        static let bioPlaceholder = String(localized: "cat person, obviously")
        static let done = String(localized: "let me in")
        static let restoringProfile = String(localized: "welcome back, checking your profile...")
        static let accountConnected = String(localized: "account connected")
        static let signInWithApple = String(localized: "Sign in with Apple")
        static let signInWithGoogle = String(localized: "Sign in with Google")
        static let signInWithEmail = String(localized: "Sign in with Email")
        static let emailPlaceholder = String(localized: "your email")
        static let passwordPlaceholder = String(localized: "password (6+ characters)")
        static let signIn = String(localized: "sign in")
        static let signUp = String(localized: "sign up")
        static let switchToSignIn = String(localized: "already have an account?")
        static let switchToSignUp = String(localized: "need an account?")
        static let checkEmailForVerification = String(localized: "check your email to verify your account.")

        // Legacy — kept for backward compatibility
        static let appleAccountConnected = String(localized: "apple account connected")
    }
}
