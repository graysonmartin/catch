import Foundation

extension CatchStrings {

    enum Feed {
        static let searchEmptyTitle = String(localized: "nothing here")
        static let searchPrompt = String(localized: "search encounters")
        static let unknownCat = String(localized: "Unknown Cat")
        static let pillNew = String(localized: "NEW")
        static let pillRepeat = String(localized: "REPEAT")
        static let pillStray = String(localized: "STRAY")
        static let newestFirst = String(localized: "newest first")
        static let oldestFirst = String(localized: "oldest first")

        static func searchEmptySubtitle(_ query: String) -> String {
            String(localized: "no encounters matching \"\(query)\"")
        }

        // Social feed
        static let socialEmptyTitle = String(localized: "ghost town")
        static let socialEmptySubtitle = String(localized: "follow some people and their cat encounters will show up here")

        static func spottedBy(_ name: String) -> String {
            String(localized: "spotted by \(name)")
        }
    }
}
