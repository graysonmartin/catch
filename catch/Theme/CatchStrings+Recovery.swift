import Foundation
import CatchCore

extension CatchStrings {

    enum Recovery {
        static let title = String(localized: "well this is awkward")
        static let subtitle = String(localized: "something went wrong loading your data. the app just needs a moment.")
        static let retryButton = String(localized: "try again")
        static let resetButton = String(localized: "start fresh")
        static let resetConfirmTitle = String(localized: "you sure about this?")
        static let resetConfirmMessage = String(localized: "this wipes all local data. your cats, encounters, everything on this device.")
        static let resetConfirmAction = String(localized: "wipe it")
        static let technicalDetails = String(localized: "tech details")
    }
}
