import Foundation
import CatchCore

extension CatchStrings {

    enum Notifications {
        static let encounterAlertTitle = String(localized: "someone spotted your cat")
        static let encounterAlertBody = String(localized: "a new encounter was logged for one of your cats")

        static let likeAlertTitle = String(localized: "someone liked your post")
        static let likeAlertBody = String(localized: "your encounter got some love")

        static let commentAlertTitle = String(localized: "new comment")
        static let commentAlertBody = String(localized: "someone commented on your encounter")
    }
}
