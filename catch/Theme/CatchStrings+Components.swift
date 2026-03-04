import Foundation
import CatchCore

extension CatchStrings {

    enum Components {
        // LocationPickerView
        static let gettingLocation = String(localized: "Getting Location...")
        static let useCurrentLocation = String(localized: "Use Current Location")
        static let coordinatesSaved = String(localized: "Coordinates saved")
        static let openSettings = String(localized: "Open Settings")
        static let typeLocationName = String(localized: "Or type location name")
        static let locationDenied = String(localized: "Location access denied. Enable it in Settings.")
        static let locationTimeout = String(localized: "Location request timed out. Try again.")

        // PhotoPickerView
        static let dragToReorder = String(localized: "drag to reorder -- first photo is your profile pic")
        static let addPhotos = String(localized: "Add Photos")
        static let profilePic = String(localized: "profile pic")

        // BreedPickerView
        static let breedName = String(localized: "breed name")
        static let somethingElse = String(localized: "something else...")
        static let clear = String(localized: "clear")
        static let unknown = String(localized: "unknown")

        // BreedPredictionCard
        static let analyzingCreature = String(localized: "analyzing this creature...")
        static let weThinkThisIs = String(localized: "we think this is...")
        static let noneOfThese = String(localized: "none of these, sorry")

        // CatPickerView
        static let nameOrLocation = String(localized: "name or location")
        static let pickACat = String(localized: "pick a cat")
        static let neverSeen = String(localized: "never seen")
        static let lastSeenPrefix = String(localized: "last seen ")

        // StevenEasterEggView
        static let youFoundHim = String(localized: "you found him.")
    }
}
