import Foundation
import CatchCore

extension CatchStrings {

    enum Report {
        static let reportPost = String(localized: "report post")
        static let sheetTitle = String(localized: "report this encounter")
        static let categoryPrompt = String(localized: "what's the issue?")
        static let reasonPlaceholder = String(localized: "anything else we should know? (optional)")
        static let submit = String(localized: "submit report")
        static let submitting = String(localized: "submitting...")

        static let categorySpam = String(localized: "spam")
        static let categoryInappropriate = String(localized: "inappropriate content")
        static let categoryHarassment = String(localized: "harassment")
        static let categoryOther = String(localized: "something else")

        static let successTitle = String(localized: "thanks for letting us know")
        static let successSubtitle = String(localized: "we'll take a look")
        static let alreadyReported = String(localized: "you already reported this one")
    }
}
