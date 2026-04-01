import Foundation
import CatchCore

extension CatchStrings {

    enum Notifications {
        // Navigation
        static let title = String(localized: "notifications")

        // Action descriptions
        static let likedYourEncounter = String(localized: "liked your encounter")
        static let commentedOnYourEncounter = String(localized: "commented on your encounter")
        static let startedFollowingYou = String(localized: "started following you")

        // Empty state
        static let emptyTitle = String(localized: "nothing here")
        static let emptySubtitle = String(localized: "you're not that popular yet. go log some cats and maybe someone will notice")

        // Encounter deep link
        static let encounterLoadFailed = String(localized: "encounter not found")
        static let encounterLoadFailedSubtitle = String(localized: "it might have been deleted, or something went wrong")

        // Fallbacks
        static let unknownUser = String(localized: "someone")

        // Toast
        static let loadFailed = String(localized: "couldn't load notifications. pull to refresh?")
    }
}
