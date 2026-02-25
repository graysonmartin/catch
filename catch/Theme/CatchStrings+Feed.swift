import Foundation

extension CatchStrings {

    enum Feed {
        static let emptyTitle = String(localized: "no encounters yet")
        static let emptySubtitle = String(localized: "go outside. find a cat. report back.")
        static let emptyAction = String(localized: "log your first cat")
        static let searchEmptyTitle = String(localized: "nothing here")
        static let searchPrompt = String(localized: "search encounters")
        static let unknownCat = String(localized: "Unknown Cat")
        static let pillNew = String(localized: "NEW")
        static let pillRepeat = String(localized: "REPEAT")
        static let newestFirst = String(localized: "newest first")
        static let oldestFirst = String(localized: "oldest first")

        static func searchEmptySubtitle(_ query: String) -> String {
            String(localized: "no encounters matching \"\(query)\"")
        }

        // Orphaned encounters
        static let orphanedAlertTitle = String(localized: "delete orphaned encounter?")
        static let orphanedAlertMessage = String(localized: "this encounter lost its cat. let it go.")
    }
}
