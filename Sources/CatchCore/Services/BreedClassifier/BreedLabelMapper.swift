import Foundation

public enum BreedLabelMapper {

    /// Labels the Create ML model can predict → display names.
    private static let modelMapping: [String: String] = [
        "Abyssinian": "Abyssinian",
        "Bengal": "Bengal",
        "Bombay": "Bombay",
        "British_Shorthair": "British Shorthair",
        "Domestic_Shorthair": "Domestic Shorthair",
        "Maine_Coon": "Maine Coon",
        "Persian": "Persian",
        "Ragdoll": "Ragdoll",
        "Russian_Blue": "Russian Blue",
        "Scottish_Fold": "Scottish Fold",
        "Siamese": "Siamese",
        "Sphynx": "Sphynx",
    ]

    /// Broader curated breed list for the manual picker (superset of model labels).
    private static let curatedBreeds: [String] = [
        "Abyssinian",
        "Angora",
        "Bengal",
        "Birman",
        "Bombay",
        "British Shorthair",
        "Burmese",
        "Domestic Shorthair",
        "Egyptian Mau",
        "Havana Brown",
        "Japanese Bobtail",
        "Korat",
        "Maine Coon",
        "Manx",
        "Norwegian Forest Cat",
        "Ocicat",
        "Persian",
        "Ragdoll",
        "Russian Blue",
        "Scottish Fold",
        "Siamese",
        "Singapura",
        "Snowshoe",
        "Somali",
        "Sphynx",
        "Tabby",
        "Tiger Tabby",
        "Turkish Angora",
    ]

    public static func displayName(for rawIdentifier: String) -> String? {
        modelMapping[rawIdentifier]
    }

    public static func isCatBreed(_ rawIdentifier: String) -> Bool {
        modelMapping[rawIdentifier] != nil
    }

    public static var allDisplayNames: [String] {
        curatedBreeds
    }
}
