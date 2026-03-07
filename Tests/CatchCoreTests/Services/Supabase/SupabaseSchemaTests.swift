import XCTest

/// Smoke tests verifying migration files contain expected SQL structures.
/// These are substring-presence checks, not structural SQL validation.
final class SupabaseSchemaTests: XCTestCase {

    // MARK: - Constants

    private static let migrationFiles = [
        "supabase/migrations/001_initial_schema.sql",
        "supabase/migrations/002_rls_policies.sql",
        "supabase/migrations/003_feed_function.sql"
    ]

    private static let allTables = [
        "profiles", "cats", "encounters",
        "follows", "encounter_likes", "encounter_comments"
    ]

    // MARK: - Helpers

    private lazy var root: URL = {
        var dir = URL(fileURLWithPath: #file)
        for _ in 0..<10 {
            dir = dir.deletingLastPathComponent()
            if FileManager.default.fileExists(atPath: dir.appendingPathComponent("supabase/migrations").path) {
                return dir
            }
        }
        return dir
    }()

    private func loadMigration(_ filename: String) throws -> String {
        let url = root.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("Could not locate \(filename) from test file path")
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Tests

    func testMigrationFilesExist() throws {
        for file in Self.migrationFiles {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: root.appendingPathComponent(file).path),
                "Migration file missing: \(file)"
            )
        }
    }

    func testMigrationFilesAreNonEmpty() throws {
        for file in Self.migrationFiles {
            let contents = try loadMigration(file)
            XCTAssertFalse(contents.isEmpty, "Migration file is empty: \(file)")
        }
    }

    func testSchemaContainsExpectedTables() throws {
        let sql = try loadMigration("supabase/migrations/001_initial_schema.sql")

        for table in Self.allTables {
            XCTAssertTrue(
                sql.contains("CREATE TABLE \(table)"),
                "Schema missing CREATE TABLE \(table)"
            )
        }
    }

    func testSchemaContainsExpectedIndexes() throws {
        let sql = try loadMigration("supabase/migrations/001_initial_schema.sql")

        let expectedIndexes = [
            "idx_encounters_owner_date",
            "idx_encounters_cat_id",
            "idx_cats_owner_id",
            "idx_follows_follower_status",
            "idx_follows_followee_status",
            "idx_encounter_likes_encounter",
            "idx_encounter_comments_encounter_date",
            "idx_encounters_date_id_desc",
            "idx_encounters_cat_date_asc"
        ]
        for index in expectedIndexes {
            XCTAssertTrue(
                sql.contains(index),
                "Schema missing index: \(index)"
            )
        }
    }

    func testSchemaContainsDenormalizedCountTriggers() throws {
        let sql = try loadMigration("supabase/migrations/001_initial_schema.sql")

        XCTAssertTrue(sql.contains("adjust_like_count"), "Missing like count trigger function")
        XCTAssertTrue(sql.contains("adjust_comment_count"), "Missing comment count trigger function")
        XCTAssertTrue(sql.contains("adjust_follow_counts"), "Missing follow counts trigger function")
        XCTAssertTrue(sql.contains("set_updated_at"), "Missing updated_at trigger function")
    }

    func testRLSPoliciesContainCanViewUser() throws {
        let sql = try loadMigration("supabase/migrations/002_rls_policies.sql")

        XCTAssertTrue(sql.contains("can_view_user"), "Missing can_view_user helper function")
        XCTAssertTrue(sql.contains("SECURITY DEFINER"), "can_view_user should be SECURITY DEFINER")
        XCTAssertTrue(sql.contains("SET search_path = public"), "Missing search_path pinning on SECURITY DEFINER function")
    }

    func testRLSPoliciesEnableRLSOnAllTables() throws {
        let sql = try loadMigration("supabase/migrations/002_rls_policies.sql")

        for table in Self.allTables {
            XCTAssertTrue(
                sql.contains("ALTER TABLE \(table) ENABLE ROW LEVEL SECURITY"),
                "RLS not enabled on \(table)"
            )
        }
    }

    func testFeedFunctionExists() throws {
        let sql = try loadMigration("supabase/migrations/003_feed_function.sql")

        XCTAssertTrue(sql.contains("get_feed"), "Missing get_feed function")
        XCTAssertTrue(sql.contains("p_cursor"), "Missing cursor parameter")
        XCTAssertTrue(sql.contains("p_cursor_id"), "Missing cursor_id tiebreaker parameter")
        XCTAssertTrue(sql.contains("p_limit"), "Missing limit parameter")
        XCTAssertTrue(sql.contains("is_first_encounter"), "Missing is_first_encounter field")
        XCTAssertTrue(sql.contains("is_liked"), "Missing is_liked field")
        XCTAssertTrue(sql.contains("SET search_path = public"), "Missing search_path pinning on SECURITY DEFINER function")
    }
}
