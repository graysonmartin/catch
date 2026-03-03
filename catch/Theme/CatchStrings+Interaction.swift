import Foundation
import CatchCore

extension CatchStrings {

    enum Interaction {
        static let comments = String(localized: "comments")
        static let noCommentsTitle = String(localized: "no comments yet")
        static let noCommentsSubtitle = String(localized: "be the first to say something")
        static let addComment = String(localized: "add a comment...")
        static let send = String(localized: "send")
        static let deleteComment = String(localized: "delete comment")
        static let deleteCommentConfirm = String(localized: "this can't be undone")

        // Liked-by list
        static let likedBy = String(localized: "liked by")
        static let noLikesTitle = String(localized: "no likes yet")
        static let noLikesSubtitle = String(localized: "first one to tap that heart wins bragging rights")

        static func likeCount(_ count: Int) -> String {
            count == 1 ? String(localized: "1 like") : String(localized: "\(count) likes")
        }

        static func commentCount(_ count: Int) -> String {
            count == 1 ? String(localized: "1 comment") : String(localized: "\(count) comments")
        }
    }
}
