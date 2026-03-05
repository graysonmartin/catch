import Foundation

/// Canonical breed list — the single source of truth for breed identifiers
/// across the ML classifier, UI pickers, and breed log.
///
/// To add a new breed, add a case here. The `displayName` provides the
/// user-facing label, and `mlLabels` maps any raw CoreML identifiers
/// that should resolve to this breed.
public enum CatBreed: String, CaseIterable, Sendable, Equatable, Hashable {
    case abyssinian
    case angora
    case bengal
    case birman
    case bombay
    case britishShorthair
    case burmese
    case domesticShorthair
    case egyptianMau
    case havanaBrown
    case japaneseBobtail
    case korat
    case maineCoon
    case manx
    case norwegianForestCat
    case ocicat
    case persian
    case ragdoll
    case russianBlue
    case scottishFold
    case siamese
    case singapura
    case snowshoe
    case somali
    case sphynx
    case tabby
    case tigerTabby
    case turkishAngora

    /// User-facing display name for this breed.
    public var displayName: String {
        switch self {
        case .abyssinian: "Abyssinian"
        case .angora: "Angora"
        case .bengal: "Bengal"
        case .birman: "Birman"
        case .bombay: "Bombay"
        case .britishShorthair: "British Shorthair"
        case .burmese: "Burmese"
        case .domesticShorthair: "Domestic Shorthair"
        case .egyptianMau: "Egyptian Mau"
        case .havanaBrown: "Havana Brown"
        case .japaneseBobtail: "Japanese Bobtail"
        case .korat: "Korat"
        case .maineCoon: "Maine Coon"
        case .manx: "Manx"
        case .norwegianForestCat: "Norwegian Forest Cat"
        case .ocicat: "Ocicat"
        case .persian: "Persian"
        case .ragdoll: "Ragdoll"
        case .russianBlue: "Russian Blue"
        case .scottishFold: "Scottish Fold"
        case .siamese: "Siamese"
        case .singapura: "Singapura"
        case .snowshoe: "Snowshoe"
        case .somali: "Somali"
        case .sphynx: "Sphynx"
        case .tabby: "Tabby"
        case .tigerTabby: "Tiger Tabby"
        case .turkishAngora: "Turkish Angora"
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

    /// CoreML model labels that map to this breed.
    /// Breeds not predicted by the model return an empty array.
    private var mlLabels: [String] {
        switch self {
        case .abyssinian: ["Abyssinian"]
        case .bengal: ["Bengal"]
        case .bombay: ["Bombay"]
        case .britishShorthair: ["British_Shorthair"]
        case .domesticShorthair: ["Domestic_Shorthair"]
        case .maineCoon: ["Maine_Coon"]
        case .persian: ["Persian"]
        case .ragdoll: ["Ragdoll"]
        case .russianBlue: ["Russian_Blue"]
        case .scottishFold: ["Scottish_Fold"]
        case .siamese: ["Siamese"]
        case .sphynx: ["Sphynx"]
        default: []
        }
    }

    private static let mlLabelLookup: [String: CatBreed] = {
        var lookup: [String: CatBreed] = [:]
        for breed in CatBreed.allCases {
            for label in breed.mlLabels {
                lookup[label] = breed
            }
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
