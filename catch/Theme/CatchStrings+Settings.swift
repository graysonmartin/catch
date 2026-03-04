import Foundation
import CatchCore

extension CatchStrings {

    enum Settings {
        // Navigation
        static let title = String(localized: "settings")

        // Display name
        static let displayNameSection = String(localized: "display name")
        static let displayNamePlaceholder = String(localized: "what should we call you")
        static let displayNameFooter = String(localized: "this is what other catchers see")

        // Notifications
        static let notificationsSection = String(localized: "notifications")
        static let notificationsToggle = String(localized: "push notifications")
        static let notificationsFooter = String(localized: "we'll ping you when stuff happens")

        // About
        static let aboutSection = String(localized: "about")
        static let version = String(localized: "version")
        static let build = String(localized: "build")
        static let madeWith = String(localized: "made with love")

        // Danger zone
        static let dangerZoneSection = String(localized: "danger zone")
        static let deleteAccount = String(localized: "delete account")
        static let deleteAccountConfirmTitle = String(localized: "you sure?")
        static let deleteAccountConfirmMessage = String(localized: "this deletes all your cats, encounters, everything. no take-backs.")
        static let deleteAccountConfirm = String(localized: "delete it all")
        static let signOut = String(localized: "sign out")
        static let signOutConfirmTitle = String(localized: "sign out?")
        static let signOutConfirmMessage = String(localized: "your cats will be here when you get back")
        static let signOutConfirm = String(localized: "sign out")

        static func versionDisplay(_ version: String, _ build: String) -> String {
            String(localized: "\(version) (\(build))")
        }
    }
}
