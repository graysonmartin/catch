import Foundation
import CatchCore

extension CatchStrings {

    enum Settings {
        // Navigation
        static let title = String(localized: "settings")

        // Legal
        static let legalSection = String(localized: "legal")
        static let privacyPolicy = String(localized: "privacy policy")
        static let termsOfService = String(localized: "terms of service")

        // About
        static let aboutSection = String(localized: "about")
        static let version = String(localized: "version")
        static let build = String(localized: "build")
        static let madeWith = String(localized: "made with love")

        // Danger zone
        static let dangerZoneSection = String(localized: "danger zone")
        static let deleteAccount = String(localized: "delete account")
        static let deleteAccountConfirmTitle = String(localized: "you sure?")
        static let deleteAccountConfirmMessage = String(localized: "this deletes all your cats, encounters, everything. can't undo this.")
        static let deleteAccountConfirm = String(localized: "delete it all")
        static let signOut = String(localized: "sign out")
        static let signOutConfirmTitle = String(localized: "sign out?")
        static let signOutConfirmMessage = String(localized: "your cats will be here when you get back")
        static let signOutConfirm = String(localized: "sign out")

        static func versionDisplay(_ version: String, _ build: String) -> String {
            String(localized: "\(version) (\(build))")
        }

        // Debug
        static let debugSection = String(localized: "admin (debug only)")
        static let debugFooter = String(localized: "this section only shows in debug builds. go wild.")
        static let debugResetWalkthrough = String(localized: "reset walkthrough")
    }
}
