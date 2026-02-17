import Foundation
import SwiftData

@Model
final class CareEntry {
    var startDate: Date
    var endDate: Date
    var notes: String
    var cat: Cat?

    var durationDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    init(startDate: Date = Date(), endDate: Date = Date(), notes: String = "", cat: Cat? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.cat = cat
    }
}
