import Foundation
import CatchCore

extension CatchStrings {

    enum Profile {
        // Navigation titles
        static let collectionTab = String(localized: "collection")

        // Profile view
        static let profileTitle = String(localized: "profile")
        static let mysteriousStranger = String(localized: "mysterious stranger")
        static let tooCoolForBio = String(localized: "too cool for a bio")
        static let cats = String(localized: "cats")
        static let encounters = String(localized: "encounters")
        static let followers = String(localized: "followers")
        static let following = String(localized: "following")
        static let signedInWithApple = String(localized: "signed in with apple")
        static let signInPrompt = String(localized: "sign in to back up your profile")
        static let fakeSignIn = String(localized: "fake sign in (debug)")
        static let emptyTitle = String(localized: "who even are you")
        static let emptySubtitle = String(localized: "set up your profile so the cats know who they're dealing with")
        static let setUpProfile = String(localized: "set up profile")
        static let breedLog = String(localized: "breed log")

        static func lurkingSince(_ date: Date) -> String {
            let formatted = date.formatted(.dateTime.month(.wide).year())
            return String(localized: "lurking since \(formatted)")
        }

        // Edit profile
        static let editProfileTitle = String(localized: "edit profile")
        static let profilePhoto = String(localized: "profile photo")
        static let choosePhoto = String(localized: "choose photo")
        static let removePhoto = String(localized: "remove photo")
        static let info = String(localized: "info")
        static let displayName = String(localized: "display name")
        static let username = String(localized: "username")
        static let usernamePlaceholder = String(localized: "pick a username")
        static let usernameFooter = String(localized: "3-20 characters. lowercase letters, numbers, underscores only. this is how people find you.")
        static let usernameAvailable = String(localized: "you got it")
        static let usernameTaken = String(localized: "already taken")
        static let usernameTooShort = String(localized: "too short (3 min)")
        static let usernameTooLong = String(localized: "too long (20 max)")
        static let usernameInvalidChars = String(localized: "letters, numbers, underscores only")
        static let usernameChecking = String(localized: "checking...")
        static let usernameCheckFailed = String(localized: "couldn't check, try again")
        static let bio = String(localized: "bio")
        static let privateProfile = String(localized: "private profile")
        static let privateFooter = String(localized: "when private, people have to send a request before they can see your cats. you're basically famous.")
        static let showCats = String(localized: "show cats")
        static let showEncounters = String(localized: "show encounters")
        static let visibility = String(localized: "visibility")
        static let visibilityFooter = String(localized: "controls what people see on your public profile. private mode overrides everything.")

        static func validationMessage(for result: UsernameValidationResult) -> String {
            switch result {
            case .tooShort: usernameTooShort
            case .tooLong: usernameTooLong
            case .invalidCharacters: usernameInvalidChars
            case .empty, .valid: ""
            }
        }
    }
}
