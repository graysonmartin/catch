import Foundation

/// Authoritative catalog of all breeds with metadata.
/// This is the single source of truth for the breed log, breed picker, and classifier output.
public enum BreedCatalog {

    public static let allBreeds: [BreedCatalogEntry] = [
        BreedCatalogEntry(
            breed: .abyssinian,
            description: "ancient vibes, modern chaos. one of the oldest known breeds, looks like a tiny mountain lion.",
            funFact: "nicknamed the 'aby-grabbys' because they steal everything",
            rarity: .uncommon,
            icon: "hare"
        ),
        BreedCatalogEntry(
            breed: .bengal,
            description: "literally a tiny leopard that lives in your house. chaos incarnate.",
            funFact: "they love water. like, actually enjoy baths. broken cats.",
            rarity: .rare,
            icon: "bolt.fill"
        ),
        BreedCatalogEntry(
            breed: .bombay,
            description: "mini panther. all black everything. walks like they own the night.",
            funFact: "bred specifically to look like a panther. someone said 'what if house cat but spooky' and here we are",
            rarity: .rare,
            icon: "moon.fill"
        ),
        BreedCatalogEntry(
            breed: .britishShorthair,
            description: "round face, round eyes, round everything. built like a distinguished gentleman.",
            funFact: "the cheshire cat was based on this breed. the smile checks out",
            rarity: .uncommon,
            icon: "crown"
        ),
        BreedCatalogEntry(
            breed: .domesticShorthair,
            description: "the mutt of cats. no pedigree, all personality. literally every other cat you've ever met.",
            funFact: "make up about 95% of cats in the US. they're the main characters and they know it",
            rarity: .common,
            icon: "house.fill"
        ),
        BreedCatalogEntry(
            breed: .maineCoon,
            description: "absolute unit. the great dane of cats. somehow still thinks it's a kitten.",
            funFact: "can grow up to 40 inches long. that's not a cat, that's a roommate",
            rarity: .uncommon,
            icon: "mountain.2"
        ),
        BreedCatalogEntry(
            breed: .persian,
            description: "flat face, maximum floof. the influencer of the cat world. high maintenance and proud.",
            funFact: "most popular pedigree breed worldwide. basic but make it elegant",
            rarity: .uncommon,
            icon: "cloud"
        ),
        BreedCatalogEntry(
            breed: .ragdoll,
            description: "goes completely limp when picked up. zero survival instinct. maximum chill.",
            funFact: "named ragdoll because they literally flop like a stuffed animal. no thoughts head empty",
            rarity: .uncommon,
            icon: "sofa"
        ),
        BreedCatalogEntry(
            breed: .russianBlue,
            description: "silver-blue coat, green eyes, permanent resting cat face. elegant and unbothered.",
            funFact: "they're said to smile because of their slightly upturned mouth. it's sarcasm",
            rarity: .uncommon,
            icon: "diamond"
        ),
        BreedCatalogEntry(
            breed: .scottishFold,
            description: "folded ears, owl face. sits in weird positions on purpose. knows they're cute.",
            funFact: "all scottish folds descend from one barn cat named susie. nepotism",
            rarity: .rare,
            icon: "ear"
        ),
        BreedCatalogEntry(
            breed: .siamese,
            description: "talks more than your group chat. piercing blue eyes. drama incarnate.",
            funFact: "one of the most vocal breeds. they will tell you about their day whether you asked or not",
            rarity: .common,
            icon: "bubble.left"
        ),
        BreedCatalogEntry(
            breed: .sphynx,
            description: "hairless and proud. warm to the touch. looks like an alien, acts like a dog.",
            funFact: "they're not actually hypoallergenic. they just look like they should be",
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
