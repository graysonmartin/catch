import Foundation
import CatchCore

// MARK: - Sort Direction

enum BreedLogSortDirection: Equatable {
    case ascending
    case descending

    var toggled: BreedLogSortDirection {
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

enum BreedLogSortOption: String, CaseIterable, Identifiable {
    case rarity = "rarity"
    case discoveredFirst = "discovery date"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rarity: CatchStrings.BreedLog.sortRarity
        case .discoveredFirst: CatchStrings.BreedLog.sortDiscoveredFirst
        }
    }

    var defaultDirection: BreedLogSortDirection {
        switch self {
        case .rarity: .ascending
        case .discoveredFirst: .descending
        }
    }

    // MARK: - Sorting

    func sorted(_ log: [BreedLogEntry], direction: BreedLogSortDirection) -> [BreedLogEntry] {
        let isAscending = direction == .ascending

        switch self {
        case .rarity:
            return log.sorted {
                isAscending
                    ? $0.catalogEntry.rarity < $1.catalogEntry.rarity
                    : $0.catalogEntry.rarity > $1.catalogEntry.rarity
            }
        case .discoveredFirst:
            return log.sorted { lhs, rhs in
                let lhsFirst = isAscending ? !lhs.isDiscovered : lhs.isDiscovered
                let rhsFirst = isAscending ? !rhs.isDiscovered : rhs.isDiscovered

                if lhsFirst != rhsFirst {
                    return lhsFirst
                }
                return lhs.catalogEntry.displayName
                    .localizedCaseInsensitiveCompare(rhs.catalogEntry.displayName) == .orderedAscending
            }
        }
    }
}
