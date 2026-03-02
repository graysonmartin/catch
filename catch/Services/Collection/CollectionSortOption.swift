import Foundation
import CatchCore

// MARK: - Sort Direction

enum CollectionSortDirection: Equatable {
    case ascending
    case descending

    var toggled: CollectionSortDirection {
        switch self {
        case .ascending: .descending
        case .descending: .ascending
        }
    }

    var chevronSymbol: String {
        switch self {
        case .ascending: "chevron.up"
        case .descending: "chevron.down"
        }
    }
}

// MARK: - Sort Option

enum CollectionSortOption: String, CaseIterable, Identifiable {
    case lastSeen = "last seen"
    case encounters = "encounter count"
    case alphabetical = "alphabetical"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lastSeen: CatchStrings.Collection.sortLastSeen
        case .encounters: CatchStrings.Collection.sortEncounters
        case .alphabetical: CatchStrings.Collection.sortAlphabetical
        }
    }

    var defaultDirection: CollectionSortDirection {
        switch self {
        case .lastSeen: .descending
        case .encounters: .descending
        case .alphabetical: .ascending
        }
    }
}
