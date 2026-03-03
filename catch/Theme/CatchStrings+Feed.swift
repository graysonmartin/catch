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
    }
}
