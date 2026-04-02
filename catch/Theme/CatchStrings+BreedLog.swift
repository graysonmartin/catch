import Foundation
import CatchCore

extension CatchStrings {

    enum BreedLog {
        static let title = String(localized: "breed log")
        static let breedsDiscovered = String(localized: "breeds discovered")
        static let undiscoveredPlaceholder = String(localized: "???")

        // Sort options
        static let sortRarity = String(localized: "rarity")
        static let sortDiscoveredFirst = String(localized: "discovery date")

        // BreedDetailView
        static let catsFound = String(localized: "cats found")
        static let firstSeen = String(localized: "first seen")
        static let funFact = String(localized: "fun fact")

        static func yourBreedCats(_ breedName: String) -> String {
            String(localized: "your \(breedName) cats")
        }

        // BreedRarity
        static let rarityCommon = String(localized: "common")
        static let rarityUncommon = String(localized: "uncommon")
        static let rarityRare = String(localized: "rare")
        static let rarityLegendary = String(localized: "legendary")

        // Progress flavor text
        static let flavorZero = String(localized: "go find some fellas")
        static let flavorLow = String(localized: "barely scratching the surface")
        static let flavorMedLow = String(localized: "nice work, soldier")
        static let flavorMedium = String(localized: "halfway there. not too shabby")
        static let flavorMedHigh = String(localized: "holy crap u are doing well")
        static let flavorHigh = String(localized: "so close. so freaking close.")
        static let flavorMax = String(localized: "legendary")
        static let flavorDefault = String(localized: "how did you even get here")
    }
}
