import Foundation

struct BreedCatalogEntry: Identifiable, Equatable {
    let id: String
    let displayName: String
    let description: String
    let funFact: String
    let rarity: BreedRarity
    let icon: String
}
