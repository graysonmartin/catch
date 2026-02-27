import Foundation
import CatchCore

enum CollectionSortOption: String, CaseIterable, Identifiable {
    case mostRecent = "newest"
    case oldestFirst = "oldest"
    case mostEncounters = "most encounters"
    case alphabetical = "a-z"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mostRecent: CatchStrings.Collection.sortMostRecent
        case .oldestFirst: CatchStrings.Collection.sortOldestFirst
        case .mostEncounters: CatchStrings.Collection.sortMostEncounters
        case .alphabetical: CatchStrings.Collection.sortAlphabetical
        }
    }
}
