import XCTest

final class SupabaseSchemaTests: XCTestCase {

    // MARK: - Migration file paths (relative to repo root)

    private static let migrationFiles = [
        "supabase/migrations/001_initial_schema.sql",
        "supabase/migrations/002_rls_policies.sql",
        "supabase/migrations/003_feed_function.sql"
    ]

    private func repoRoot() throws -> URL {
        // Tests run from the package directory; walk up to find supabase/
        var dir = URL(fileURLWithPath: #file)
        for _ in 0..<10 {
            dir = dir.deletingLastPathComponent()
            let candidate = dir.appendingPathComponent("supabase/migrations")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return dir
            }
        }
        throw XCTSkip("Could not locate repo root from test file path")
    }

    // MARK: - Tests

    func testMigrationFilesExist() throws {
        let root = try repoRoot()
        for file in Self.migrationFiles {
            let path = root.appendingPathComponent(file).path
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: path),
                "Migration file missing: \(file)"
            )
        }
    }

    func testMigrationFilesAreNonEmpty() throws {
        let root = try repoRoot()
        for file in Self.migrationFiles {
            let url = root.appendingPathComponent(file)
            let contents = try String(contentsOf: url, encoding: .utf8)
            XCTAssertFalse(contents.isEmpty, "Migration file is empty: \(file)")
        }
    }

    func testSchemaContainsExpectedTables() throws {
        let root = try repoRoot()
        let url = root.appendingPathComponent("supabase/migrations/001_initial_schema.sql")
        let sql = try String(contentsOf: url, encoding: .utf8)

        let expectedTables = [
            "profiles", "cats", "encounters",
            "follows", "encounter_likes", "encounter_comments"
        ]
        for table in expectedTables {
            XCTAssertTrue(
                sql.contains("CREATE TABLE \(table)"),
                "Schema missing CREATE TABLE \(table)"
            )
        }
    }

    func testSchemaContainsExpectedIndexes() throws {
        let root = try repoRoot()
        let url = root.appendingPathComponent("supabase/migrations/001_initial_schema.sql")
        let sql = try String(contentsOf: url, encoding: .utf8)

        let expectedIndexes = [
            "idx_encounters_owner_date",
            "idx_encounters_cat_id",
            "idx_cats_owner_id",
            "idx_follows_follower_status",
            "idx_follows_followee_status",
            "idx_encounter_likes_encounter",
            "idx_encounter_comments_encounter_date"
        ]
        for index in expectedIndexes {
            XCTAssertTrue(
                sql.contains(index),
                "Schema missing index: \(index)"
            )
        }
    }

    func testSchemaContainsDenormalizedCountTriggers() throws {
        let root = try repoRoot()
        let url = root.appendingPathComponent("supabase/migrations/001_initial_schema.sql")
        let sql = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(sql.contains("adjust_like_count"), "Missing like count trigger function")
        XCTAssertTrue(sql.contains("adjust_comment_count"), "Missing comment count trigger function")
        XCTAssertTrue(sql.contains("adjust_follow_counts"), "Missing follow counts trigger function")
        XCTAssertTrue(sql.contains("set_updated_at"), "Missing updated_at trigger function")
    }

    func testRLSPoliciesContainCanViewUser() throws {
        let root = try repoRoot()
        let url = root.appendingPathComponent("supabase/migrations/002_rls_policies.sql")
        let sql = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(sql.contains("can_view_user"), "Missing can_view_user helper function")
        XCTAssertTrue(sql.contains("SECURITY DEFINER"), "can_view_user should be SECURITY DEFINER")
        XCTAssertTrue(sql.contains("SET search_path = public"), "Missing search_path pinning on SECURITY DEFINER function")
    }

    func testRLSPoliciesEnableRLSOnAllTables() throws {
        let root = try repoRoot()
        let url = root.appendingPathComponent("supabase/migrations/002_rls_policies.sql")
        let sql = try String(contentsOf: url, encoding: .utf8)

        let tables = [
            "profiles", "cats", "encounters",
            "follows", "encounter_likes", "encounter_comments"
        ]
        for table in tables {
            XCTAssertTrue(
                sql.contains("ALTER TABLE \(table) ENABLE ROW LEVEL SECURITY"),
                "RLS not enabled on \(table)"
            )
        }
    }

    func testFeedFunctionExists() throws {
        let root = try repoRoot()
        let url = root.appendingPathComponent("supabase/migrations/003_feed_function.sql")
        let sql = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(sql.contains("get_feed"), "Missing get_feed function")
        XCTAssertTrue(sql.contains("p_cursor"), "Missing cursor parameter")
        XCTAssertTrue(sql.contains("p_cursor_id"), "Missing cursor_id tiebreaker parameter")
        XCTAssertTrue(sql.contains("p_limit"), "Missing limit parameter")
        XCTAssertTrue(sql.contains("is_first_encounter"), "Missing is_first_encounter field")
        XCTAssertTrue(sql.contains("is_liked"), "Missing is_liked field")
        XCTAssertTrue(sql.contains("SET search_path = public"), "Missing search_path pinning on SECURITY DEFINER function")
    }
}
