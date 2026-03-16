import XCTest
@testable import MigrationLib

final class UserMappingTests: XCTestCase {

    // MARK: - Init

    func testInitWithEntries() {
        let entries = [
            UserMapping.Entry(appleUserID: "apple_1", supabaseUserID: "supa_1"),
            UserMapping.Entry(appleUserID: "apple_2", supabaseUserID: "supa_2")
        ]
        let mapping = UserMapping(entries: entries)

        XCTAssertEqual(mapping.entries.count, 2)
        XCTAssertEqual(mapping.appleUserIDs, Set(["apple_1", "apple_2"]))
    }

    func testDuplicateAppleIDKeepsLast() {
        let entries = [
            UserMapping.Entry(appleUserID: "apple_1", supabaseUserID: "supa_old"),
            UserMapping.Entry(appleUserID: "apple_1", supabaseUserID: "supa_new")
        ]
        let mapping = UserMapping(entries: entries)

        XCTAssertEqual(mapping.entries.count, 1)
        XCTAssertEqual(try mapping.supabaseUserID(for: "apple_1"), "supa_new")
    }

    // MARK: - Lookup

    func testSupabaseUserIDReturnsCorrectID() throws {
        let mapping = UserMapping(entries: [
            .init(appleUserID: "apple_1", supabaseUserID: "supa_1")
        ])

        XCTAssertEqual(try mapping.supabaseUserID(for: "apple_1"), "supa_1")
    }

    func testSupabaseUserIDThrowsForMissing() {
        let mapping = UserMapping(entries: [])

        XCTAssertThrowsError(try mapping.supabaseUserID(for: "unknown")) { error in
            guard let migrationError = error as? MigrationError else {
                XCTFail("Expected MigrationError")
                return
            }
            XCTAssertEqual(migrationError, .missingUserMapping(appleUserID: "unknown"))
        }
    }

    func testSupabaseUserIDOrNilReturnsNilForMissing() {
        let mapping = UserMapping(entries: [
            .init(appleUserID: "apple_1", supabaseUserID: "supa_1")
        ])

        XCTAssertNil(mapping.supabaseUserIDOrNil(for: "unknown"))
        XCTAssertEqual(mapping.supabaseUserIDOrNil(for: "apple_1"), "supa_1")
    }

    func testEntryLookup() {
        let mapping = UserMapping(entries: [
            .init(appleUserID: "apple_1", supabaseUserID: "supa_1", displayName: "Alice")
        ])

        let entry = mapping.entry(for: "apple_1")
        XCTAssertEqual(entry?.displayName, "Alice")
        XCTAssertNil(mapping.entry(for: "unknown"))
    }

    // MARK: - File Loading

    func testLoadFromMissingFileThrows() {
        XCTAssertThrowsError(try UserMapping.load(from: "/nonexistent/path.json")) { error in
            guard let migrationError = error as? MigrationError else {
                XCTFail("Expected MigrationError")
                return
            }
            XCTAssertEqual(migrationError, .mappingFileNotFound(path: "/nonexistent/path.json"))
        }
    }

    // MARK: - Codable

    func testEntryCodable() throws {
        let entry = UserMapping.Entry(
            appleUserID: "apple_abc",
            supabaseUserID: "supa_xyz",
            displayName: "TestUser"
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(UserMapping.Entry.self, from: data)
        XCTAssertEqual(entry, decoded)
    }

    func testEntryCodingKeysUseSnakeCase() throws {
        let json = """
        {"apple_user_id":"a1","supabase_user_id":"s1","display_name":"Bob"}
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(UserMapping.Entry.self, from: json)
        XCTAssertEqual(entry.appleUserID, "a1")
        XCTAssertEqual(entry.supabaseUserID, "s1")
        XCTAssertEqual(entry.displayName, "Bob")
    }
}
