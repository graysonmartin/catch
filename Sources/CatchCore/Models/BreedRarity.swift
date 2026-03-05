import Foundation

/// Rarity tier for a cat breed in the breed log.
public enum BreedRarity: Int, CaseIterable, Comparable, Sendable, Equatable, Hashable {
    case common = 0
    case uncommon = 1
    case rare = 2
    case legendary = 3

    public static func < (lhs: BreedRarity, rhs: BreedRarity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
