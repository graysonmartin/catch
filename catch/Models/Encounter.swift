import Foundation
import SwiftData
import CatchCore

@Model
final class Encounter {
    var date: Date
    var location: Location
    var notes: String
    var cat: Cat?
    var cloudKitRecordName: String?

    @Attribute(.externalStorage)
    var photos: [Data]

    init(date: Date = Date(), location: Location = .empty, notes: String = "", cat: Cat? = nil, photos: [Data] = []) {
        self.date = date
        self.location = location
        self.notes = notes
        self.cat = cat
        self.photos = photos
    }
}
