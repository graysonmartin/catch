import Foundation
import CatchCore

extension CatchStrings {

    enum Toast {
        // Actions
        static let retry = String(localized: "retry")

        // Follow
        static let followFailed = String(localized: "couldn't follow them. try again?")
        static let unfollowFailed = String(localized: "unfollow didn't work. awkward")

        // Like
        static let likeFailed = String(localized: "like didn't go through. weird")

        // Comment
        static let commentFailed = String(localized: "comment failed to post. give it another shot?")
        static let commentDeleteFailed = String(localized: "couldn't delete that comment. it lives on")

        // Sync
        static let syncFailed = String(localized: "sync hit a wall. we'll try again soon")
        static let feedLoadFailed = String(localized: "couldn't load the feed. pull to refresh?")

        // Profile
        static let profileSaveFailed = String(localized: "profile save didn't stick. try again?")

        // Search
        static let searchFailed = String(localized: "search came up empty-handed. not our best moment")

        // Follow requests
        static let approveFailed = String(localized: "couldn't approve that request. try again?")
        static let declineFailed = String(localized: "couldn't decline. they're persistent")

        // Social actions
        static let removeFollowerFailed = String(localized: "couldn't remove them. they're still lurking")
    }
}
