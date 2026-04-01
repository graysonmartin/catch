import Foundation
import CatchCore

extension CatchStrings {

    enum Toast {
        // Actions
        static let retry = String(localized: "retry")

        // Follow
        static let followFailed = String(localized: "couldn't follow them. try again?")
        static let unfollowFailed = String(localized: "unfollow didn't work. try again?")

        // Like
        static let likeFailed = String(localized: "like didn't go through. try again?")

        // Comment
        static let commentFailed = String(localized: "comment failed to post. give it another shot?")
        static let commentDeleteFailed = String(localized: "couldn't delete that comment. try again?")

        // Sync
        static let syncFailed = String(localized: "sync failed. we'll try again soon")
        static let feedLoadFailed = String(localized: "couldn't load the feed. pull to refresh?")

        // Profile
        static let profileSaveFailed = String(localized: "profile save didn't stick. try again?")

        // Search
        static let searchFailed = String(localized: "search failed. try again?")

        // Follow requests
        static let approveFailed = String(localized: "couldn't approve that request. try again?")
        static let declineFailed = String(localized: "couldn't decline that request. try again?")

        // Social actions
        static let removeFollowerFailed = String(localized: "couldn't remove them. try again?")

        // Report
        static let reportFailed = String(localized: "report didn't go through. try again?")
        static let reportSuccess = String(localized: "thanks for letting us know")

        // Block
        static let blockFailed = String(localized: "couldn't block them. try again?")
        static let blockSuccess = String(localized: "blocked. they're gone")
        static let unblockFailed = String(localized: "couldn't unblock them. try again?")
        static let unblockSuccess = String(localized: "unblocked")
        static let rateLimitedBlock = String(localized: "too many blocks. slow down")

        // Rate limiting
        static let rateLimitedGeneric = String(localized: "slow down there")
        static let rateLimitedComment = String(localized: "too many comments. slow down")
        static let rateLimitedFollow = String(localized: "too many follows. slow down")
        static let rateLimitedLike = String(localized: "too many likes. slow down")
        static let rateLimitedReport = String(localized: "too many reports. slow down")
        static let rateLimitedDeleteComment = String(localized: "too many deletes. slow down")

        // CloudKit save/update/delete
        static let catSyncFailed = String(localized: "couldn't save to the cloud. check your connection?")
        static let encounterSyncFailed = String(localized: "encounter didn't sync. give it another shot?")
        static let catUpdateFailed = String(localized: "update didn't stick in the cloud. try again?")
        static let encounterUpdateFailed = String(localized: "encounter update failed to sync. try again?")
        static let deleteSyncFailed = String(localized: "couldn't delete from the cloud. try again?")
    }
}
