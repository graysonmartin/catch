import Foundation
import CatchCore

extension CatchStrings {

    enum Walkthrough {
        // Navigation
        static let skip = String(localized: "skip all this")
        static let next = String(localized: "next")
        static let done = String(localized: "okay let's go")
        static let continueButton = String(localized: "next")

        // Welcome step
        static let welcomeTitle = String(localized: "you're in")
        static let welcomeSubtitle = String(localized: "welcome to the neighborhood cat census.")
        static let welcomeDetail = String(localized: "just a couple things before you start")

        // Location step
        static let locationTitle = String(localized: "where are the cats")
        static let locationSubtitle = String(localized: "we use your location to pin\nwhere you spot cats on the map.")
        static let locationReassurance = String(localized: "totally optional. you can skip this\nand add locations manually later.")
        static let enableLocation = String(localized: "enable location")
        static let locationEnabled = String(localized: "nice, you're on the grid")
        static let locationSkipped = String(localized: "no worries, you can turn this on later")

        // Suggested people step
        static let peopleTitle = String(localized: "find your people")
        static let peopleSubtitle = String(localized: "follow some cat spotters to see\ntheir encounters in your feed.")
        static let noPeopleYet = String(localized: "no one here yet. you're early.")
        static let loadingPeople = String(localized: "sniffing around...")

        // Step indicator
        static func stepOf(_ current: Int, _ total: Int) -> String {
            String(localized: "\(current) of \(total)")
        }
    }
}
