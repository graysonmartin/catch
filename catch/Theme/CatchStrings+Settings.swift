import Foundation
import CatchCore

extension CatchStrings {

    enum Settings {
        // Navigation
        static let title = String(localized: "settings")

        // Display name
        static let displayNameSection = String(localized: "identity")
        static let displayNameLabel = String(localized: "display name")
        static let displayNamePlaceholder = String(localized: "what do the cats call you")

        // Notifications
        static let notificationsSection = String(localized: "notifications")
        static let notificationsToggle = String(localized: "push notifications")
        static let notificationsFooter = String(localized: "get notified when the cats are doing something. or don't. they don't care either way.")

        // Appearance
        static let appearanceSection = String(localized: "vibes")
        static let appearanceLabel = String(localized: "appearance")
        static let appearanceSystem = String(localized: "system")
        static let appearanceLight = String(localized: "light")
        static let appearanceDark = String(localized: "dark")

        // About
        static let aboutSection = String(localized: "about")
        static let version = String(localized: "version")
        static let madeWithAttitude = String(localized: "made with attitude by someone who should be touching grass")

        // Sign out
        static let signOut = String(localized: "sign out")
        static let signOutConfirmTitle = String(localized: "for real?")
        static let signOutConfirmMessage = String(localized: "you're about to sign out. the cats will forget you existed. (not really but still)")
        static let signOutConfirm = String(localized: "yeah, peace out")
    }
}
