import Foundation
import CatchCore

extension CatchStrings {

    enum Log {
        // AddEncounterView
        static let logCatEncounter = String(localized: "Log a Cat Encounter")
        static let newCat = String(localized: "New Cat")
        static let seenAgain = String(localized: "Seen Again")

        // AddCatView
        static let photoRequired = String(localized: "at least 1 photo required -- no pics no proof")
        static let firstEncounter = String(localized: "First Encounter")
        static let firstEncounterHint = String(localized: "A first encounter will be logged automatically with today's date and the location above.")

        // LogEncounterView
        static let loggingFor = String(localized: "logging for")
        static let whichCat = String(localized: "which cat?")
        static let noCatsRegistered = String(localized: "no cats registered yet")
        static let registerOneNow = String(localized: "register one now")
        static let pickACat = String(localized: "pick a cat")
        static let encounterDetails = String(localized: "Encounter Details")
        static let logEncounterTitle = String(localized: "Log Encounter")
        static let whatHappened = String(localized: "What happened?")

        // EditCatView
        static let editCatTitle = String(localized: "Edit Cat")

        // EditEncounterView
        static let editEncounterTitle = String(localized: "Edit Encounter")
        static let catSection = String(localized: "cat")
        static let detailsSection = String(localized: "details")
        static let photosSection = String(localized: "photos")
        static let notesSection = String(localized: "notes")
        static let whatHappenedLower = String(localized: "what happened?")
    }
}
