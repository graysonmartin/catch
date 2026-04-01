import Foundation
import CatchCore

/// Builds an `ExportPayload` from the user's loaded cats and encounters.
/// Lives in the app target because it depends on the app-level `Cat` / `Encounter` models.
enum ExportService {

    static func buildPayload(from cats: [Cat]) -> ExportPayload {
        let exportCats = cats.map { cat in
            let (locName, locLat, locLng) = exportLocation(cat.location)
            return ExportCat(
                name: cat.name,
                breed: cat.breed,
                estimatedAge: cat.estimatedAge.isEmpty ? nil : cat.estimatedAge,
                locationName: locName,
                locationLat: locLat,
                locationLng: locLng,
                notes: cat.notes.isEmpty ? nil : cat.notes,
                isOwned: cat.isOwned,
                createdAt: cat.createdAt,
                encounters: cat.encounters.map { encounter in
                    let (eName, eLat, eLng) = exportLocation(encounter.location)
                    return ExportEncounter(
                        date: encounter.date,
                        locationName: eName,
                        locationLat: eLat,
                        locationLng: eLng,
                        notes: encounter.notes.isEmpty ? nil : encounter.notes,
                        createdAt: encounter.createdAt
                    )
                }
            )
        }

        return ExportPayload(cats: exportCats)
    }

    static func exportJSON(from cats: [Cat]) throws -> Data {
        let payload = buildPayload(from: cats)
        return try ExportSerializer.encode(payload)
    }

    /// Writes an export file to a temporary URL suitable for sharing.
    static func writeTemporaryFile(from cats: [Cat]) throws -> URL {
        let data = try exportJSON(from: cats)
        let fileName = ExportSerializer.backupFileName()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL, options: .atomic)
        return tempURL
    }

    private static func exportLocation(_ location: Location) -> (String?, Double?, Double?) {
        (
            location.name.isEmpty ? nil : location.name,
            location.latitude,
            location.longitude
        )
    }
}
