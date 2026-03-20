import Foundation
import CatchCore

extension CatchStrings {

    enum Onboarding {
        static let letsGo = String(localized: "ok let's go")
        static let next = String(localized: "next")
        static let skip = String(localized: "skip")

        // Welcome page
        static let appName = String(localized: "catch")
        static let subtitle = String(localized: "track every cat you meet.")
        static let detail = String(localized: "log sightings. remember names.\nbecome the neighborhood cat census.")

        // Location page
        static let locationTitle = String(localized: "one more thing")
        static let locationDescription = String(localized: "catch uses your location to pin\nwhere you spot cats on the map.")
        static let locationReassurance = String(localized: "you can always skip this per-encounter.")
        static let enableLocation = String(localized: "enable location")
        static let locationEnabled = String(localized: "location enabled")
        static let locationDenied = String(localized: "no worries, you can change this in settings")
    }
}
