import Foundation

extension CatchStrings {

    enum Collection {
        static let emptyTitle = String(localized: "no cats yet")
        static let emptySubtitle = String(localized: "your collection is tragically empty.")
        static let emptyAction = String(localized: "log a cat")
        static let searchEmptyTitle = String(localized: "no matches")
        static let searchPrompt = String(localized: "find a cat")
        static let sortName = String(localized: "name")
        static let sortMostSeen = String(localized: "most seen")
        static let sortRecentlySeen = String(localized: "recently seen")

        static func searchEmptySubtitle(_ query: String) -> String {
            String(localized: "nothing matching \"\(query)\" in your collection")
        }
    }
}
