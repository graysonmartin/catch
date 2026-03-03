import Foundation
import CatchCore

extension CatchStrings {

    enum TextInput {
        static let limitReached = String(localized: "limit reached")

        static func charactersRemaining(_ count: Int) -> String {
            String(localized: "\(count) left")
        }
    }
}
