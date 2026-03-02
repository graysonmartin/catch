import Foundation
import SwiftData
import CatchCore

@MainActor
final class SwiftDataExportService: DataExportService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    nonisolated func exportData() async throws -> ExportData {
        let cats = await fetchCats()
        guard !cats.isEmpty else {
            throw DataExportError.noDataToExport
        }
        return ExportData(cats: cats)
    }

    nonisolated func encodeToJSON(_ data: ExportData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            return try encoder.encode(data)
        } catch {
            throw DataExportError.encodingFailed
        }
    }

    // MARK: - Private

    @MainActor
    private func fetchCats() -> [ExportCat] {
        let descriptor = FetchDescriptor<Cat>(sortBy: [SortDescriptor(\.createdAt)])
        guard let cats = try? modelContext.fetch(descriptor) else { return [] }
        return cats.map { cat in
            ExportCat(
                name: cat.name,
                breed: cat.breed,
                estimatedAge: cat.estimatedAge,
                location: cat.location,
                notes: cat.notes,
                isOwned: cat.isOwned,
                createdAt: cat.createdAt,
                encounters: cat.encounters
                    .sorted { $0.date < $1.date }
                    .map { encounter in
                        ExportEncounter(
                            date: encounter.date,
                            location: encounter.location,
                            notes: encounter.notes
                        )
                    }
            )
        }
    }
}
