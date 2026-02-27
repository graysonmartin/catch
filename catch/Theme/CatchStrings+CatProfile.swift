import Foundation
import CatchCore

extension CatchStrings {

    enum CatProfile {
        static let spotted = String(localized: "Spotted")
        static let noEncountersLogged = String(localized: "no encounters logged")
        static let logSighting = String(localized: "log a sighting")
        static let deleteThisCat = String(localized: "delete this cat")
        static let deleteEncounterTitle = String(localized: "delete encounter?")
        static let deleteEncounterMessage = String(localized: "gone forever. no take-backs.")
        static let deleteCatMessage = String(localized: "this deletes all their encounters too. absolutely no undo.")

        // Remote variant (lowercase)
        static let noEncountersLoggedRemote = String(localized: "no encounters logged")

        static func firstSeen(_ date: Date) -> String {
            let formatted = date.formatted(date: .abbreviated, time: .omitted)
            return String(localized: "First seen \(formatted)")
        }

        static func encountersHeader(_ count: Int) -> String {
            String(localized: "Encounters (\(count))")
        }

        static func deleteCatTitle(name: String) -> String {
            String(localized: "delete \(name)?")
        }
    }
}
