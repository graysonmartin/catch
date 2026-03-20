import Foundation
import CatchCore

extension CatchStrings {

    enum OnboardingTour {
        // MARK: - Breed Prediction

        static let breedTitle = String(localized: "auto breed detection")
        static let breedSubtitle = String(localized: "snap a photo and we'll tell you what kind of cat it is. it's basically magic.")
        static let breedMockName = String(localized: "steven")
        static let breedMockResult = String(localized: "domestic shorthair")
        static let breedMockConfidence = String(localized: "96% match")
        static let breedMockPill = String(localized: "NEW")

        // MARK: - Map

        static let mapTitle = String(localized: "your cat map")
        static let mapSubtitle = String(localized: "every cat you log gets pinned to the map. see where the little guys hang out.")
        static let mapMockLocationA = String(localized: "maple st")
        static let mapMockLocationB = String(localized: "elm park")
        static let mapMockLocationC = String(localized: "the alley")
        static let mapMockCatA = String(localized: "steven")
        static let mapMockCatB = String(localized: "business cat")
        static let mapMockCatC = String(localized: "void")

        // MARK: - Diary

        static let diaryTitle = String(localized: "your encounter diary")
        static let diarySubtitle = String(localized: "every sighting is logged to your profile. a chronological record of your cat encounters. very official.")
        static let diaryMockNote = String(localized: "just sitting there. judging me.")
        static let diaryMockDate = String(localized: "today")
        static let diaryMockLocation = String(localized: "the usual spot")

        // MARK: - Breed Collection

        static let collectionTitle = String(localized: "breed collection")
        static let collectionSubtitle = String(localized: "gotta catch 'em all. log different breeds to fill out your collection and flex on your friends.")
        static let collectionMockDiscovered = String(localized: "3 / 70+ breeds")
        static let collectionMockBreedA = String(localized: "tabby")
        static let collectionMockBreedB = String(localized: "siamese")
        static let collectionMockBreedC = String(localized: "maine coon")
    }
}
