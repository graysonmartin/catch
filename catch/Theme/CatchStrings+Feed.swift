import Foundation
import CatchCore

extension CatchStrings {

    enum Feed {
        static let unknownCat = String(localized: "Unknown Cat")
        static let pillNew = String(localized: "NEW")
        static let pillRepeat = String(localized: "REPEAT")
        static let pillStray = String(localized: "STRAY")
        static let pillYou = String(localized: "YOU")

        // Empty states
        static let emptyTitle = String(localized: "no sightings yet")
        static let emptySubtitle = String(localized: "log a cat encounter or follow some people to fill this up")

        // Legacy social empty (kept for reference)
        static let socialEmptyTitle = String(localized: "ghost town")
        static let socialEmptySubtitle = String(localized: "follow some people and their cat encounters will show up here")

        static let spottedByPrefix = String(localized: "spotted by ")

        static func spottedBy(_ name: String) -> String {
            String(localized: "spotted by \(name)")
        }

        static func spottedOnByPrefix(_ date: String) -> String {
            String(localized: "spotted \(date) by ")
        }

        static func spottedOn(_ date: String) -> String {
            String(localized: "spotted \(date)")
        }

        // Detail labels
        static let breedLabel = String(localized: "breed")
        static let tapForDetails = String(localized: "tap for details")

        // Overflow menu
        static let editEncounter = String(localized: "edit encounter")
        static let deleteEncounter = String(localized: "delete encounter")
        static let deleteEncounterTitle = String(localized: "delete this encounter?")
        static let deleteEncounterMessage = String(localized: "gone forever. no undo.")

        // Suggested people
        static let suggestedHeader = String(localized: "here's who's been spotting cats")

        static func catCount(_ count: Int) -> String {
            count == 1
                ? String(localized: "1 cat logged")
                : String(localized: "\(count) cats logged")
        }
    }
}
