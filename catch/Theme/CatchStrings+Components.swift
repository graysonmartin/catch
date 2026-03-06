import Foundation
import CatchCore

extension CatchStrings {

    enum Components {
        // LocationPickerView
        static let gettingLocation = String(localized: "Getting Location...")
        static let useCurrentLocation = String(localized: "Use Current Location")
        static let coordinatesSaved = String(localized: "Coordinates saved")
        static let openSettings = String(localized: "Open Settings")
        static let typeLocationName = String(localized: "Search for a location...")
        static let locationDenied = String(localized: "Location access denied. Enable it in Settings.")
        static let locationTimeout = String(localized: "Location request timed out. Try again.")
        static let resolvingLocation = String(localized: "pinning location...")
        static let locationPinned = String(localized: "location pinned to map")
        static let dragToAdjust = String(localized: "move map to adjust")
        static let viewOnMap = String(localized: "view on map")
        static let changeLocation = String(localized: "change")
        static let tapToSetLocation = String(localized: "tap to set location")
        static let confirmLocation = String(localized: "Confirm")
        static let searchLocation = String(localized: "Search")
        static let currentLocation = String(localized: "Current Location")
        static let searchOrGPS = String(localized: "search or use current location")

        // PhotoPickerView / CameraCaptureView
        static let dragToReorder = String(localized: "drag to reorder (first photo is your profile pic)")
        static let addPhotos = String(localized: "Add Photos")
        static let takePhoto = String(localized: "Take Photo")
        static let chooseFromLibrary = String(localized: "Choose from Library")
        static let profilePic = String(localized: "profile pic")

        // BreedPickerView
        static let breedName = String(localized: "breed name")
        static let somethingElse = String(localized: "something else...")
        static let clear = String(localized: "clear")
        static let unknown = String(localized: "unknown")

        // BreedPredictionCard
        static let analyzingCreature = String(localized: "analyzing...")
        static let weThinkThisIs = String(localized: "we think this is...")
        static let noneOfThese = String(localized: "none of these, sorry")

        // CatPickerView
        static let nameOrLocation = String(localized: "name or location")
        static let pickACat = String(localized: "pick a cat")
        static let neverSeen = String(localized: "never seen")
        static let lastSeenPrefix = String(localized: "last seen ")

        // StevenEasterEggView
        static let youFoundHim = String(localized: "you found him.")

        // FullScreenPhotoViewer
        static let closePhotoViewer = String(localized: "close")

        static func photoPageIndicator(_ current: Int, _ total: Int) -> String {
            String(localized: "\(current) of \(total)")
        }
    }
}
