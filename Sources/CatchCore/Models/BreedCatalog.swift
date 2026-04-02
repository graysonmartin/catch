import Foundation

/// Authoritative catalog of all breeds with metadata.
/// This is the single source of truth for the breed log, breed picker, and classifier output.
public enum BreedCatalog {

    public static let allBreeds: [BreedCatalogEntry] = [
        BreedCatalogEntry(
            breed: .abyssinian,
            description: "one of the oldest known breeds. looks like a small mountain lion.",
            funFact: "extremely curious and known for getting into places they shouldn't be",
            rarity: .uncommon,
            icon: "hare"
        ),
        BreedCatalogEntry(
            breed: .bengal,
            description: "wild-looking coat pattern. descended from asian leopard cats.",
            funFact: "one of the few breeds that actually enjoys water",
            rarity: .rare,
            icon: "bolt.fill"
        ),
        BreedCatalogEntry(
            breed: .bombay,
            description: "solid black coat, copper eyes. sometimes called a pocket panther.",
            funFact: "bred in the 1950s to resemble a miniature black panther",
            rarity: .rare,
            icon: "moon.fill"
        ),
        BreedCatalogEntry(
            breed: .britishShorthair,
            description: "round face, dense coat, stocky build. very calm temperament.",
            funFact: "the cheshire cat was based on this breed",
            rarity: .uncommon,
            icon: "crown"
        ),
        BreedCatalogEntry(
            breed: .domesticShorthair,
            description: "no specific pedigree. the most common cat you'll find. #basic",
            funFact: "make up about 95% of cats in the US",
            rarity: .common,
            icon: "house.fill"
        ),
        BreedCatalogEntry(
            breed: .maineCoon,
            description: "the largest domesticated cat breed. long fur, tufted ears.",
            funFact: "can grow up to 40 inches long and weigh over 25 pounds.",
            rarity: .uncommon,
            icon: "mountain.2"
        ),
        BreedCatalogEntry(
            breed: .persian,
            description: "flat face, long fur, quiet demeanor. needs regular grooming.",
            funFact: "the most popular pedigree breed worldwide",
            rarity: .uncommon,
            icon: "cloud"
        ),
        BreedCatalogEntry(
            breed: .ragdoll,
            description: "large, blue-eyed, semi-longhair. goes limp when picked up.",
            funFact: "named for their tendency to go completely relaxed when held",
            rarity: .uncommon,
            icon: "sofa"
        ),
        BreedCatalogEntry(
            breed: .russianBlue,
            description: "silver-blue coat, bright green eyes. quiet and reserved.",
            funFact: "their slightly upturned mouth gives them a subtle permanent smile",
            rarity: .uncommon,
            icon: "diamond"
        ),
        BreedCatalogEntry(
            breed: .scottishFold,
            description: "folded ears, round face. known for sitting in odd positions.",
            funFact: "every scottish fold descends from a single barn cat named susie",
            rarity: .rare,
            icon: "ear"
        ),
        BreedCatalogEntry(
            breed: .siamese,
            description: "blue eyes, color-point coat. extremely vocal.",
            funFact: "one of the most talkative breeds #meowmeow",
            rarity: .common,
            icon: "bubble.left"
        ),
        BreedCatalogEntry(
            breed: .sphynx,
            description: "hairless, warm to the touch. very social and affectionate.",
            funFact: "not actually hypoallergenic. the allergen is in their skin, not fur",
            rarity: .legendary,
            icon: "globe.americas"
        ),
    ]

    public static let count = allBreeds.count

    public static func entry(for breedName: String) -> BreedCatalogEntry? {
        allBreeds.first { $0.id == breedName }
    }

    public static func entry(for breed: CatBreed) -> BreedCatalogEntry? {
        allBreeds.first { $0.breed == breed }
    }

    public static func contains(_ breedName: String) -> Bool {
        CatBreed.fromDisplayName(breedName) != nil
    }
}
