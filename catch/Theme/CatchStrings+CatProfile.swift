import Foundation
import CatchCore

extension CatchStrings {

    enum CatProfile {
        static let spotted = String(localized: "Spotted")
        static let noEncountersLogged = String(localized: "no encounters logged")
        static let logSighting = String(localized: "log a sighting")
        static let deleteThisCat = String(localized: "delete this cat")
        static let deleteEncounterTitle = String(localized: "delete encounter?")
        static let deleteEncounterMessage = String(localized: "gone forever. can't undo this.")
        static let deleteLastEncounterTitle = String(localized: "delete this cat?")
        static let deleteLastEncounterMessage = String(localized: "this is the last encounter. deleting it removes the cat entirely.")
        static let deleteCatMessage = String(localized: "this deletes all their encounters too. can't undo.")
        static let aboutSection = String(localized: "about")
        static let encounterTimeline = String(localized: "timeline")
        static let noPhotos = String(localized: "no pics yet. kinda mysterious ngl")
        static let ownedBadge = String(localized: "yours")

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
