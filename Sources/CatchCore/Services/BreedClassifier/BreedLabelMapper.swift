import Foundation

/// Maps raw ML model identifiers to display names using `CatBreed`
/// as the single source of truth.
public enum BreedLabelMapper {

    /// Returns the display name for a raw CoreML model identifier,
    /// or `nil` if the identifier is not recognized.
    public static func displayName(for rawIdentifier: String) -> String? {
        CatBreed.fromMLLabel(rawIdentifier)?.displayName
    }

    /// Whether the raw identifier maps to a known cat breed in the model.
    public static func isCatBreed(_ rawIdentifier: String) -> Bool {
        CatBreed.isRecognizedMLLabel(rawIdentifier)
    }

    /// All breed display names from the canonical list, sorted alphabetically.
    public static var allDisplayNames: [String] {
        CatBreed.allDisplayNames
    }
}
