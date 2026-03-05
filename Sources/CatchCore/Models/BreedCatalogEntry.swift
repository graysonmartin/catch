import Foundation

/// Metadata for a single breed in the breed catalog.
public struct BreedCatalogEntry: Identifiable, Equatable, Sendable {
    public let breed: CatBreed
    public let description: String
    public let funFact: String
    public let rarity: BreedRarity
    public let icon: String

    public var id: String { breed.displayName }
    public var displayName: String { breed.displayName }

    public init(
        breed: CatBreed,
        description: String,
        funFact: String,
        rarity: BreedRarity,
        icon: String
    ) {
        self.breed = breed
        self.description = description
        self.funFact = funFact
        self.rarity = rarity
        self.icon = icon
    }
}
