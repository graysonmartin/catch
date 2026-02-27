import Foundation
import CatchCore

extension CatchStrings {

    enum Collection {
        // MARK: - Empty States

        static let emptyTitle = String(localized: "no cats yet")
        static let emptySubtitle = String(localized: "your collection is tragically empty.")
        static let emptyAction = String(localized: "log a cat")
        static let searchEmptyTitle = String(localized: "no matches")
        static let searchPrompt = String(localized: "find a cat")
        static let filterEmptyTitle = String(localized: "nothing here")
        static let filterEmptySubtitle = String(localized: "no cats match your vibe check. try loosening up the filters.")

        static func searchEmptySubtitle(_ query: String) -> String {
            String(localized: "nothing matching \"\(query)\" in your collection")
        }

        // MARK: - Sort Options

        static let sortMostRecent = String(localized: "newest")
        static let sortOldestFirst = String(localized: "oldest")
        static let sortMostEncounters = String(localized: "most encounters")
        static let sortAlphabetical = String(localized: "a-z")

        // MARK: - Filter Options

        static let filterOwned = String(localized: "mine")
        static let filterRepeats = String(localized: "repeats")
        static let filterLast7Days = String(localized: "last 7 days")
        static let filterLast30Days = String(localized: "last 30 days")
        static let filters = String(localized: "filters")
    }
}
