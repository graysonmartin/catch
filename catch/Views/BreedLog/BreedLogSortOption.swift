import Foundation
import CatchCore

enum BreedLogSortOption: String, CaseIterable, Identifiable {
    case rarity = "rarity"
    case alphabetical = "a-z"
    case discoveredFirst = "discovered first"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rarity: CatchStrings.BreedLog.sortRarity
        case .alphabetical: CatchStrings.BreedLog.sortAlphabetical
        case .discoveredFirst: CatchStrings.BreedLog.sortDiscoveredFirst
        }
    }
}
