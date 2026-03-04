import Foundation
import CatchCore

extension CatchStrings {

    enum Settings {
        // Navigation
        static let title = String(localized: "settings")

        // Display name
        static let displayNameSection = String(localized: "display name")
        static let displayNamePlaceholder = String(localized: "what should we call you")
        static let displayNameFooter = String(localized: "this is what other catchers see. make it count or don't, we're not your mom.")

        // Notifications
        static let notificationsSection = String(localized: "notifications")
        static let notificationsToggle = String(localized: "push notifications")
        static let notificationsFooter = String(localized: "let us bother you when something happens. or don't. we'll survive.")

        // About
        static let aboutSection = String(localized: "about")
        static let version = String(localized: "version")
        static let build = String(localized: "build")
        static let madeWith = String(localized: "made with questionable judgment")

        // Danger zone
        static let dangerZoneSection = String(localized: "danger zone")
        static let deleteAccount = String(localized: "delete account")
        static let deleteAccountConfirmTitle = String(localized: "wait, for real?")
        static let deleteAccountConfirmMessage = String(localized: "this will nuke everything. all your cats, encounters, the whole thing. steven will remember, though.")
        static let deleteAccountConfirm = String(localized: "yeah, delete it all")
        static let signOut = String(localized: "sign out")
        static let signOutConfirmTitle = String(localized: "leaving already?")
        static let signOutConfirmMessage = String(localized: "you can always come back. the cats aren't going anywhere.")
        static let signOutConfirm = String(localized: "sign me out")

        static func versionDisplay(_ version: String, _ build: String) -> String {
            String(localized: "\(version) (\(build))")
        }
    }
}
