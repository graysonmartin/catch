import Foundation
import CatchCore

extension CatchStrings {

    enum Block {
        static let blockUser = String(localized: "block user")
        static let unblockUser = String(localized: "unblock user")
        static let blockConfirmTitle = String(localized: "block this user?")
        static let blockConfirmMessage = String(localized: "they won't be able to see your content, and you won't see theirs")
        static let blockedUsersTitle = String(localized: "blocked users")
        static let noBlockedUsers = String(localized: "no one's on your block list")
        static let noBlockedUsersSubtitle = String(localized: "if you block someone, they'll show up here")
        static let unblock = String(localized: "unblock")
        static let unblockConfirmTitle = String(localized: "unblock this user?")
        static let unblockConfirmMessage = String(localized: "they'll be able to see your content again")
    }
}
