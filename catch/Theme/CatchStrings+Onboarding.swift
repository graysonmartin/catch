import Foundation
import CatchCore

extension CatchStrings {

    enum Onboarding {
        static let letsGo = String(localized: "let's go")
        static let next = String(localized: "next")
        static let skip = String(localized: "skip")

        // Welcome page
        static let appName = String(localized: "catch")
        static let subtitle = String(localized: "track every cat you meet.")
        static let detail = String(localized: "log sightings. remember names.\nbecome the neighborhood cat census.")

        // Tour page
        static let tourTitle = String(localized: "here's the rundown")
        static let tourFeed = String(localized: "feed")
        static let tourFeedDetail = String(localized: "your timeline of every cat encounter")
        static let tourLog = String(localized: "log")
        static let tourLogDetail = String(localized: "register new cats or log re-sightings")
        static let tourMap = String(localized: "map")
        static let tourMapDetail = String(localized: "see where all your cats hang out")
        static let tourProfile = String(localized: "profile")
        static let tourProfileDetail = String(localized: "your cats, your stats, your whole deal")

        // Location page
        static let locationTitle = String(localized: "one more thing")
        static let locationDescription = String(localized: "catch uses your location to pin\nwhere you spot cats on the map.")
        static let locationReassurance = String(localized: "you can always skip this per-encounter.\nwe're not tracking you, promise.")
        static let enableLocation = String(localized: "enable location")
        static let locationEnabled = String(localized: "location enabled")
        static let locationDenied = String(localized: "no worries, you can change this in settings")
    }
}
