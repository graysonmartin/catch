import Foundation
import CatchCore

extension CatchStrings {

    enum BreedLog {
        static let title = String(localized: "breed log")
        static let breedsDiscovered = String(localized: "breeds discovered")
        static let undiscoveredPlaceholder = String(localized: "???")

        // Sort options
        static let sortRarity = String(localized: "rarity")
        static let sortAlphabetical = String(localized: "a-z")
        static let sortDiscoveredFirst = String(localized: "discovered first")

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
        static let flavorZero = String(localized: "steven is judging you")
        static let flavorLow = String(localized: "barely scratching the surface")
        static let flavorMedLow = String(localized: "you're getting out more. proud of you")
        static let flavorMedium = String(localized: "okay cat whisperer, we see you")
        static let flavorMedHigh = String(localized: "this is becoming a whole thing huh")
        static let flavorHigh = String(localized: "so close. don't sleep now")
        static let flavorMax = String(localized: "touch grass maybe?")
        static let flavorDefault = String(localized: "how did you even get here")
    }
}
