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
        static let appleAccountConnected = String(localized: "apple account connected")
    }
}
