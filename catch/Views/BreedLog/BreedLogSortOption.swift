import Foundation

enum BreedLogSortOption: String, CaseIterable, Identifiable {
    case rarity = "rarity"
    case alphabetical = "a-z"
    case discoveredFirst = "discovered first"

    var id: String { rawValue }
}
