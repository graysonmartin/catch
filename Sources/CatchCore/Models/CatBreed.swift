import Foundation

/// Canonical breed list — the single source of truth for breed identifiers
/// across the ML classifier, UI pickers, and breed log.
///
/// Only breeds recognized by the CoreML classifier are included.
/// To add a new breed, add a case here and train the model to recognize it.
public enum CatBreed: String, CaseIterable, Sendable, Equatable, Hashable {
    case abyssinian
    case bengal
    case bombay
    case britishShorthair
    case domesticShorthair
    case maineCoon
    case persian
    case ragdoll
    case russianBlue
    case scottishFold
    case siamese
    case sphynx

    /// User-facing display name for this breed.
    public var displayName: String {
        switch self {
        case .abyssinian: "Abyssinian"
        case .bengal: "Bengal"
        case .bombay: "Bombay"
        case .britishShorthair: "British Shorthair"
        case .domesticShorthair: "Domestic Shorthair"
        case .maineCoon: "Maine Coon"
        case .persian: "Persian"
        case .ragdoll: "Ragdoll"
        case .russianBlue: "Russian Blue"
        case .scottishFold: "Scottish Fold"
        case .siamese: "Siamese"
        case .sphynx: "Sphynx"
        }
    }

    /// All display names sorted alphabetically.
    public static var allDisplayNames: [String] {
        allCases.map(\.displayName).sorted()
    }

    /// Look up a breed by its display name.
    public static func fromDisplayName(_ name: String) -> CatBreed? {
        displayNameLookup[name]
    }

    /// Look up a breed by a raw CoreML model identifier.
    public static func fromMLLabel(_ label: String) -> CatBreed? {
        mlLabelLookup[label]
    }

    /// Whether the given raw identifier is a recognized ML model label.
    public static func isRecognizedMLLabel(_ label: String) -> Bool {
        mlLabelLookup[label] != nil
    }

    // MARK: - Private

    /// CoreML model label that maps to this breed.
    private var mlLabel: String {
        switch self {
        case .abyssinian: "Abyssinian"
        case .bengal: "Bengal"
        case .bombay: "Bombay"
        case .britishShorthair: "British_Shorthair"
        case .domesticShorthair: "Domestic_Shorthair"
        case .maineCoon: "Maine_Coon"
        case .persian: "Persian"
        case .ragdoll: "Ragdoll"
        case .russianBlue: "Russian_Blue"
        case .scottishFold: "Scottish_Fold"
        case .siamese: "Siamese"
        case .sphynx: "Sphynx"
        }
    }

    private static let mlLabelLookup: [String: CatBreed] = {
        var lookup: [String: CatBreed] = [:]
        for breed in CatBreed.allCases {
            lookup[breed.mlLabel] = breed
        }
        return lookup
    }()

    private static let displayNameLookup: [String: CatBreed] = {
        var lookup: [String: CatBreed] = [:]
        for breed in CatBreed.allCases {
            lookup[breed.displayName] = breed
        }
        return lookup
    }()
}
