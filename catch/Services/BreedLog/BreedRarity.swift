import SwiftUI
import CatchCore

extension BreedRarity {

    var label: String {
        switch self {
        case .common: CatchStrings.BreedLog.rarityCommon
        case .uncommon: CatchStrings.BreedLog.rarityUncommon
        case .rare: CatchStrings.BreedLog.rarityRare
        case .legendary: CatchStrings.BreedLog.rarityLegendary
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
}
