import Foundation
import CatchCore

enum CollectionSortOption: String, CaseIterable, Identifiable {
    case mostRecent = "most recent"
    case mostEncounters = "most encounters"
    case oldestFirst = "oldest first"
    case alphabetical = "a-z"
    case newestAddition = "newest addition"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mostRecent: CatchStrings.Collection.sortMostRecent
        case .mostEncounters: CatchStrings.Collection.sortMostEncounters
        case .oldestFirst: CatchStrings.Collection.sortOldestFirst
        case .alphabetical: CatchStrings.Collection.sortAlphabetical
        case .newestAddition: CatchStrings.Collection.sortNewestAddition
        }
    }
}
