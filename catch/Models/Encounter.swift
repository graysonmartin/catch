import Foundation
import SwiftData

@Model
final class Encounter {
    var date: Date
    var location: Location
    var notes: String
    var cat: Cat?

    init(date: Date = Date(), location: Location = .empty, notes: String = "", cat: Cat? = nil) {
        self.date = date
        self.location = location
        self.notes = notes
        self.cat = cat
    }
}
