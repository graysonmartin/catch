import SwiftUI

enum BreedRarity: Int, CaseIterable, Comparable {
    case common = 0
    case uncommon = 1
    case rare = 2
    case legendary = 3

    var label: String {
        switch self {
        case .common: "common"
        case .uncommon: "uncommon"
        case .rare: "rare"
        case .legendary: "legendary"
        }
    }

    var color: Color {
        switch self {
        case .common: Color(red: 0.5, green: 0.4, blue: 0.35)
        case .uncommon: Color(red: 0.3, green: 0.7, blue: 0.4)
        case .rare: Color(red: 0.3, green: 0.5, blue: 0.9)
        case .legendary: Color(red: 1.0, green: 0.6, blue: 0.2)
        }
    }

    static func < (lhs: BreedRarity, rhs: BreedRarity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
