import Foundation
import CatchCore

extension CatchStrings {

    enum Walkthrough {
        // Navigation
        static let skip = String(localized: "skip all this")
        static let next = String(localized: "next")
        static let done = String(localized: "okay let's go")

        // Location step
        static let locationTitle = String(localized: "where are the cats")
        static let locationSubtitle = String(localized: "we use your location to pin\nwhere you spot cats on the map.")
        static let locationReassurance = String(localized: "you can skip this\nand add locations manually later.")
        static let enableLocation = String(localized: "enable location")
        static let locationEnabled = String(localized: "nice, you're on the grid")
        static let locationSkipped = String(localized: "no worries, you can turn this on later")

        // Notification step
        static let notificationTitle = String(localized: "stay in the loop")
        static let notificationSubtitle = String(localized: "get pinged when someone likes your\nspotting, drops a comment, or follows you.")
        static let enableNotifications = String(localized: "enable notifications")
        static let notificationEnabled = String(localized: "notifications enabled")
        static let notificationSkipped = String(localized: "no worries, you can turn these on later")

        // Suggested people step
        static let peopleTitle = String(localized: "find your people")
        static let peopleSubtitle = String(localized: "follow some cat spotters to see\ntheir encounters in your feed.")
        static let noPeopleYet = String(localized: "no one here yet. you're early.")
        static let loadingPeople = String(localized: "sniffing around...")

    }
}
