import Foundation
import CatchCore

extension CatchStrings {

    enum Map {
        static let emptyTitle = String(localized: "no locations yet")
        static let emptySubtitle = String(localized: "cats with GPS coordinates will appear here. use the location button when logging encounters.")
        static let emptyAction = String(localized: "log a cat")

        static func catsHere(_ count: Int) -> String {
            String(localized: "\(count) Cats Here")
        }

        // Missing location
        static let missingLocationsTitle = String(localized: "missing locations")
        static let noLocationSet = String(localized: "no location set")

        static func catsNotShown(_ count: Int) -> String {
            String(localized: "\(count) cat\(count == 1 ? "" : "s") not shown")
        }
    }
}
