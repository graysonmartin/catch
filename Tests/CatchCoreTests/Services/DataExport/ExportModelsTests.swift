import XCTest
@testable import CatchCore

final class ExportModelsTests: XCTestCase {

    // MARK: - ExportEncounter

    func test_exportEncounter_codableRoundtrip() throws {
        let encounter = ExportEncounter(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            location: Location(name: "Rooftop", latitude: 37.334, longitude: -122.009),
            notes: "orange tabby vibes"
        )
        let data = try JSONEncoder().encode(encounter)
        let decoded = try JSONDecoder().decode(ExportEncounter.self, from: data)
        XCTAssertEqual(decoded, encounter)
    }

    func test_exportEncounter_codableRoundtrip_emptyFields() throws {
        let encounter = ExportEncounter(
            date: Date(timeIntervalSince1970: 0),
            location: .empty,
            notes: ""
        )
        let data = try JSONEncoder().encode(encounter)
        let decoded = try JSONDecoder().decode(ExportEncounter.self, from: data)
        XCTAssertEqual(decoded, encounter)
    }

    // MARK: - ExportCat

    func test_exportCat_codableRoundtrip() throws {
        let cat = ExportCat(
            name: "Steven",
            breed: "Tabby",
            estimatedAge: "3 years",
            location: Location(name: "The Alley", latitude: 37.0, longitude: -122.0),
            notes: "absolute legend",
            isOwned: true,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            encounters: [
                ExportEncounter(
                    date: Date(timeIntervalSince1970: 1_700_100_000),
                    location: Location(name: "Rooftop"),
                    notes: "spotted again"
                )
            ]
        )
        let data = try JSONEncoder().encode(cat)
        let decoded = try JSONDecoder().decode(ExportCat.self, from: data)
        XCTAssertEqual(decoded, cat)
    }

    func test_exportCat_codableRoundtrip_nilOptionals() throws {
        let cat = ExportCat(
            name: nil,
            breed: nil,
            estimatedAge: "",
            location: .empty,
            notes: "",
            isOwned: false,
            createdAt: Date(timeIntervalSince1970: 0),
            encounters: []
        )
        let data = try JSONEncoder().encode(cat)
        let decoded = try JSONDecoder().decode(ExportCat.self, from: data)
        XCTAssertEqual(decoded, cat)
    }

    func test_exportCat_codableRoundtrip_multipleEncounters() throws {
        let encounters = makeEncounters(count: 5)
        let cat = ExportCat(
            name: "Patches",
            breed: "Calico",
            estimatedAge: "1 year",
            location: Location(name: "Park"),
            notes: "",
            isOwned: false,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            encounters: encounters
        )
        let data = try JSONEncoder().encode(cat)
        let decoded = try JSONDecoder().decode(ExportCat.self, from: data)
        XCTAssertEqual(decoded, cat)
        XCTAssertEqual(decoded.encounters.count, 5)
    }

    // MARK: - ExportData

    func test_exportData_codableRoundtrip() throws {
        let exportData = ExportData(
            version: 1,
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            cats: [
                ExportCat(
                    name: "Steven",
                    breed: "Tabby",
                    estimatedAge: "3 years",
                    location: Location(name: "Home"),
                    notes: "king",
                    isOwned: true,
                    createdAt: Date(timeIntervalSince1970: 1_699_000_000),
                    encounters: []
                )
            ]
        )
        let data = try JSONEncoder().encode(exportData)
        let decoded = try JSONDecoder().decode(ExportData.self, from: data)
        XCTAssertEqual(decoded, exportData)
    }

    func test_exportData_defaultVersion() {
        let exportData = ExportData(cats: [])
        XCTAssertEqual(exportData.version, 1)
    }

    func test_exportData_emptyCats() throws {
        let exportData = ExportData(
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            cats: []
        )
        let data = try JSONEncoder().encode(exportData)
        let decoded = try JSONDecoder().decode(ExportData.self, from: data)
        XCTAssertEqual(decoded, exportData)
        XCTAssertTrue(decoded.cats.isEmpty)
    }

    func test_exportData_codableRoundtrip_multipleCats() throws {
        let cats: [ExportCat] = [
            makeExportCat(name: "Cat 0"),
            makeExportCat(name: "Cat 1"),
            makeExportCat(name: "Cat 2"),
        ]
        let exportData = ExportData(
            exportedAt: Date(timeIntervalSince1970: 1_700_200_000),
            cats: cats
        )
        let data = try JSONEncoder().encode(exportData)
        let decoded = try JSONDecoder().decode(ExportData.self, from: data)
        XCTAssertEqual(decoded, exportData)
        XCTAssertEqual(decoded.cats.count, 3)
    }

    // MARK: - ISO8601 Date Encoding

    func test_exportData_iso8601Encoding() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let exportData = ExportData(
            version: 1,
            exportedAt: fixedDate,
            cats: []
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("2023-11-14") ?? false)
    }

    // MARK: - Equatable

    func test_exportEncounter_equality() {
        let a = ExportEncounter(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            location: Location(name: "Park"),
            notes: "nice"
        )
        let b = ExportEncounter(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            location: Location(name: "Park"),
            notes: "nice"
        )
        XCTAssertEqual(a, b)
    }

    func test_exportEncounter_inequality_differentNotes() {
        let a = ExportEncounter(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            location: Location(name: "Park"),
            notes: "nice"
        )
        let b = ExportEncounter(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            location: Location(name: "Park"),
            notes: "mean"
        )
        XCTAssertNotEqual(a, b)
    }

    func test_exportCat_equality() {
        let cat1 = makeExportCat(name: "Steven")
        let cat2 = makeExportCat(name: "Steven")
        XCTAssertEqual(cat1, cat2)
    }

    func test_exportCat_inequality_differentName() {
        let cat1 = makeExportCat(name: "Steven")
        let cat2 = makeExportCat(name: "Patches")
        XCTAssertNotEqual(cat1, cat2)
    }

    // MARK: - Helpers

    private func makeExportCat(name: String) -> ExportCat {
        ExportCat(
            name: name,
            breed: "Tabby",
            estimatedAge: "3 years",
            location: Location(name: "Home"),
            notes: "",
            isOwned: true,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            encounters: []
        )
    }

    private func makeEncounters(count: Int) -> [ExportEncounter] {
        (0..<count).map { i in
            ExportEncounter(
                date: Date(timeIntervalSince1970: Double(1_700_000_000 + i * 86400)),
                location: Location(name: "Spot \(i)"),
                notes: "encounter \(i)"
            )
        }
    }
}
