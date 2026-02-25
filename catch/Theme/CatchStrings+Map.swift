import Foundation

extension CatchStrings {

    enum Map {
        static let emptyTitle = String(localized: "no locations yet")
        static let emptySubtitle = String(localized: "cats with GPS coordinates will appear here. use the location button when logging encounters.")

        static func catsHere(_ count: Int) -> String {
            String(localized: "\(count) Cats Here")
        }
    }
}
