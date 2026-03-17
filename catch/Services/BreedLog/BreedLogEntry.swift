import Foundation
import CatchCore

struct BreedLogEntry: Identifiable {
    let catalogEntry: BreedCatalogEntry
    let isDiscovered: Bool
    let catCount: Int
    let firstDiscoveredDate: Date?
    let previewPhotoUrl: String?

    var id: String { catalogEntry.id }
}
