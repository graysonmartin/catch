import Foundation
import CatchCore

/// Result of parsing an import file — used for confirmation before committing.
struct ImportPreview: Sendable {
    let catCount: Int
    let encounterCount: Int
    let payload: ExportPayload
}

/// Errors specific to the import flow.
enum ImportError: Error, LocalizedError {
    case invalidFile
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "The file doesn't look like a valid Catch backup."
        case .unsupportedVersion(let v):
            return "Unsupported backup version (\(v)). Update the app and try again."
        }
    }
}

/// Parses an export file and converts DTOs back into domain models for insertion.
enum ImportService {

    private static let supportedVersions: ClosedRange<Int> = 1...1

    /// Reads a file URL and returns a preview of what would be imported.
    static func preview(from url: URL) throws -> ImportPreview {
        let data: Data
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            data = try Data(contentsOf: url)
        } else {
            data = try Data(contentsOf: url)
        }

        let payload: ExportPayload
        do {
            payload = try ExportSerializer.decode(data)
        } catch {
            throw ImportError.invalidFile
        }

        guard supportedVersions.contains(payload.version) else {
            throw ImportError.unsupportedVersion(payload.version)
        }

        let encounterCount = payload.cats.reduce(0) { $0 + $1.encounters.count }
        return ImportPreview(
            catCount: payload.cats.count,
            encounterCount: encounterCount,
            payload: payload
        )
    }

    /// Converts export DTOs into app-level domain models.
    /// Callers use these models to insert via `CatDataService` / Supabase.
    static func convertToCats(from payload: ExportPayload) -> [Cat] {
        payload.cats.map { exportCat in
            let encounters = exportCat.encounters.map { exportEnc in
                Encounter(
                    id: UUID(uuidString: exportEnc.id) ?? UUID(),
                    date: exportEnc.date,
                    location: Location(
                        name: exportEnc.locationName ?? "",
                        latitude: exportEnc.locationLat,
                        longitude: exportEnc.locationLng
                    ),
                    notes: exportEnc.notes ?? "",
                    catID: UUID(uuidString: exportCat.id),
                    ownerID: UUID(),
                    photoUrls: exportEnc.photoUrls,
                    createdAt: exportEnc.createdAt
                )
            }

            return Cat(
                id: UUID(uuidString: exportCat.id) ?? UUID(),
                name: exportCat.name,
                breed: exportCat.breed,
                estimatedAge: exportCat.estimatedAge ?? "",
                location: Location(
                    name: exportCat.locationName ?? "",
                    latitude: exportCat.locationLat,
                    longitude: exportCat.locationLng
                ),
                notes: exportCat.notes ?? "",
                isOwned: exportCat.isOwned,
                photoUrls: exportCat.photoUrls,
                encounters: encounters,
                createdAt: exportCat.createdAt
            )
        }
    }
}
