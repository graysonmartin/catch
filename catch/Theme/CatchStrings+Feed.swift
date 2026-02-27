import Foundation

extension CatchStrings {

    enum Feed {
        static let unknownCat = String(localized: "Unknown Cat")
        static let pillNew = String(localized: "NEW")
        static let pillRepeat = String(localized: "REPEAT")
        static let pillStray = String(localized: "STRAY")

        // Social feed
        static let socialEmptyTitle = String(localized: "ghost town")
        static let socialEmptySubtitle = String(localized: "follow some people and their cat encounters will show up here")

        static func spottedBy(_ name: String) -> String {
            String(localized: "spotted by \(name)")
        }
    }
}
