import Foundation

extension CatchStrings {

    enum Collection {
        static let emptyTitle = String(localized: "No Cats Collected")
        static let emptySubtitle = String(localized: "Cats you encounter will appear here.")
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
