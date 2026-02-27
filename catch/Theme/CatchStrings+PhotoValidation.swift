import Foundation
import CatchCore

extension CatchStrings {

    enum PhotoValidation {
        static let scanning = String(localized: "scanning for cats...")
        static let noCatWarning = String(localized: "hmm we don't see a cat in here")
        static let noCatOverride = String(localized: "trust me it's a cat")
        static let warningDismissed = String(localized: "ok we believe you (barely)")

        static func photosWithoutCats(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 photo might not have a cat in it")
            }
            return String(localized: "\(count) photos might not have cats in them")
        }
    }
}
