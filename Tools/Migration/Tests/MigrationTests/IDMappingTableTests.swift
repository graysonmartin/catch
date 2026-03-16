import XCTest
@testable import MigrationLib

final class IDMappingTableTests: XCTestCase {

    // MARK: - Empty Table

    func testEmptyTableThrowsOnLookup() {
        let table = IDMappingTable()

        XCTAssertThrowsError(try table.supabaseCatID(for: "ck_cat_1")) { error in
            guard let migrationError = error as? MigrationError else {
                XCTFail("Expected MigrationError")
                return
            }
            XCTAssertEqual(migrationError, .missingCatMapping(cloudKitRecordName: "ck_cat_1"))
        }

        XCTAssertThrowsError(try table.supabaseEncounterID(for: "ck_enc_1")) { error in
            guard let migrationError = error as? MigrationError else {
                XCTFail("Expected MigrationError")
                return
            }
            XCTAssertEqual(migrationError, .missingEncounterMapping(cloudKitRecordName: "ck_enc_1"))
        }
    }

    func testEmptyTableCounts() {
        let table = IDMappingTable()
        XCTAssertEqual(table.catCount, 0)
        XCTAssertEqual(table.encounterCount, 0)
    }

    // MARK: - Populated Table

    func testCatMappingLookup() throws {
        let table = IDMappingTable(
            catMappings: ["ck_cat_1": "supa_cat_1", "ck_cat_2": "supa_cat_2"]
        )

        XCTAssertEqual(try table.supabaseCatID(for: "ck_cat_1"), "supa_cat_1")
        XCTAssertEqual(try table.supabaseCatID(for: "ck_cat_2"), "supa_cat_2")
        XCTAssertEqual(table.catCount, 2)
    }

    func testEncounterMappingLookup() throws {
        let table = IDMappingTable(
            encounterMappings: ["ck_enc_1": "supa_enc_1"]
        )

        XCTAssertEqual(try table.supabaseEncounterID(for: "ck_enc_1"), "supa_enc_1")
        XCTAssertEqual(table.encounterCount, 1)
    }

    // MARK: - Builder

    func testBuilderAddsCatMappings() throws {
        let builder = IDMappingTableBuilder()
        builder.addCatMapping(cloudKitRecordName: "ck_1", supabaseID: "supa_1")
        builder.addCatMapping(cloudKitRecordName: "ck_2", supabaseID: "supa_2")

        let table = builder.build()
        XCTAssertEqual(table.catCount, 2)
        XCTAssertEqual(try table.supabaseCatID(for: "ck_1"), "supa_1")
        XCTAssertEqual(try table.supabaseCatID(for: "ck_2"), "supa_2")
    }

    func testBuilderAddsEncounterMappings() throws {
        let builder = IDMappingTableBuilder()
        builder.addEncounterMapping(cloudKitRecordName: "ck_e1", supabaseID: "supa_e1")

        let table = builder.build()
        XCTAssertEqual(table.encounterCount, 1)
        XCTAssertEqual(try table.supabaseEncounterID(for: "ck_e1"), "supa_e1")
    }

    func testBuilderOverwritesDuplicates() throws {
        let builder = IDMappingTableBuilder()
        builder.addCatMapping(cloudKitRecordName: "ck_1", supabaseID: "old_id")
        builder.addCatMapping(cloudKitRecordName: "ck_1", supabaseID: "new_id")

        let table = builder.build()
        XCTAssertEqual(table.catCount, 1)
        XCTAssertEqual(try table.supabaseCatID(for: "ck_1"), "new_id")
    }

    func testBuilderBuildMultipleTimes() throws {
        let builder = IDMappingTableBuilder()
        builder.addCatMapping(cloudKitRecordName: "ck_1", supabaseID: "supa_1")
        let table1 = builder.build()

        builder.addCatMapping(cloudKitRecordName: "ck_2", supabaseID: "supa_2")
        let table2 = builder.build()

        // First table should still work
        XCTAssertEqual(table1.catCount, 1)
        // Second table has both
        XCTAssertEqual(table2.catCount, 2)
    }
}
