import Foundation

public enum BreedLabelMapper {

    private static let mapping: [String: String] = [
        "Egyptian_cat": "Egyptian Mau",
        "Persian_cat": "Persian",
        "Siamese_cat": "Siamese",
        "tabby": "Tabby",
        "tiger_cat": "Tiger Tabby",
        "Angora": "Angora",
        "Birman": "Birman",
        "Bombay": "Bombay",
        "Burmese_cat": "Burmese",
        "Havana_Brown": "Havana Brown",
        "Japanese_Bobtail": "Japanese Bobtail",
        "Korat": "Korat",
        "Maine_Coon": "Maine Coon",
        "Manx": "Manx",
        "Norwegian_Forest_Cat": "Norwegian Forest Cat",
        "Ocicat": "Ocicat",
        "Ragdoll": "Ragdoll",
        "Russian_Blue": "Russian Blue",
        "Singapura": "Singapura",
        "Snowshoe": "Snowshoe",
        "Somali": "Somali",
        "Turkish_Angora": "Turkish Angora",
        "Abyssinian": "Abyssinian",
        "Bengal": "Bengal",
        "British_Shorthair": "British Shorthair",
        "Scottish_Fold": "Scottish Fold",
        "Sphynx": "Sphynx",
    ]

    public static func displayName(for rawIdentifier: String) -> String? {
        mapping[rawIdentifier]
    }

    public static func isCatBreed(_ rawIdentifier: String) -> Bool {
        mapping[rawIdentifier] != nil
    }

    public static var allDisplayNames: [String] {
        mapping.values.sorted()
    }
}
