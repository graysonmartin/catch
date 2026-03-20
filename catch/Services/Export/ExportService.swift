import Foundation
import CatchCore

/// Builds an `ExportPayload` from the user's loaded cats and encounters.
/// Lives in the app target because it depends on the app-level `Cat` / `Encounter` models.
enum ExportService {

    /// Maps the user's cats (with nested encounters) into a serializable payload.
    static func buildPayload(from cats: [Cat]) -> ExportPayload {
        let exportCats = cats.map { cat in
            ExportCat(
                id: cat.id.uuidString,
                name: cat.name,
                breed: cat.breed,
                estimatedAge: cat.estimatedAge.isEmpty ? nil : cat.estimatedAge,
                locationName: cat.location.name.isEmpty ? nil : cat.location.name,
                locationLat: cat.location.latitude,
                locationLng: cat.location.longitude,
                notes: cat.notes.isEmpty ? nil : cat.notes,
                isOwned: cat.isOwned,
                photoUrls: cat.photoUrls,
                createdAt: cat.createdAt,
                encounters: cat.encounters.map { encounter in
                    ExportEncounter(
                        id: encounter.id.uuidString,
                        date: encounter.date,
                        locationName: encounter.location.name.isEmpty ? nil : encounter.location.name,
                        locationLat: encounter.location.latitude,
                        locationLng: encounter.location.longitude,
                        notes: encounter.notes.isEmpty ? nil : encounter.notes,
                        photoUrls: encounter.photoUrls,
                        createdAt: encounter.createdAt
                    )
                }
            )
        }

        return ExportPayload(cats: exportCats)
    }

    /// Serializes the user's data to JSON `Data`.
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
}
