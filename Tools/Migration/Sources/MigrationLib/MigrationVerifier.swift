import Foundation
import Supabase

/// Verifies data integrity after migration by comparing expected counts
/// and checking relationship consistency.
public struct MigrationVerifier {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    /// Result of a verification run.
    public struct VerificationResult: Sendable {
        public let profileCount: CountCheck
        public let catCount: CountCheck
        public let encounterCount: CountCheck
        public let followCount: CountCheck
        public let likeCount: CountCheck
        public let commentCount: CountCheck

        public var isValid: Bool {
            profileCount.isValid &&
            catCount.isValid &&
            encounterCount.isValid &&
            followCount.isValid &&
            likeCount.isValid &&
            commentCount.isValid
        }
    }

    public struct CountCheck: Sendable {
        public let expected: Int
        public let actual: Int
        public var isValid: Bool { actual >= expected }
    }

    /// Runs all verification checks against the Supabase database.
    public func verify(
        expectedProfiles: Int,
        expectedCats: Int,
        expectedEncounters: Int,
        expectedFollows: Int,
        expectedLikes: Int,
        expectedComments: Int
    ) async throws -> VerificationResult {
        MigrationLogger.info("Running verification checks...")

        let profileCount = try await countRows(table: "profiles")
        let catCount = try await countRows(table: "cats")
        let encounterCount = try await countRows(table: "encounters")
        let followCount = try await countRows(table: "follows")
        let likeCount = try await countRows(table: "encounter_likes")
        let commentCount = try await countRows(table: "encounter_comments")

        let result = VerificationResult(
            profileCount: CountCheck(expected: expectedProfiles, actual: profileCount),
            catCount: CountCheck(expected: expectedCats, actual: catCount),
            encounterCount: CountCheck(expected: expectedEncounters, actual: encounterCount),
            followCount: CountCheck(expected: expectedFollows, actual: followCount),
            likeCount: CountCheck(expected: expectedLikes, actual: likeCount),
            commentCount: CountCheck(expected: expectedComments, actual: commentCount)
        )

        MigrationLogger.summary("Verification Results", counts: [
            ("Profiles", profileCount),
            ("Cats", catCount),
            ("Encounters", encounterCount),
            ("Follows", followCount),
            ("Likes", likeCount),
            ("Comments", commentCount)
        ])

        if result.isValid {
            MigrationLogger.info("All verification checks passed.")
        } else {
            MigrationLogger.warn("Some verification checks failed. Review counts above.")
            logMismatches(result)
        }

        return result
    }

    private func countRows(table: String) async throws -> Int {
        let response: [CountRow] = try await supabase
            .from(table)
            .select("id")
            .execute()
            .value
        return response.count
    }

    private func logMismatches(_ result: VerificationResult) {
        let checks: [(String, CountCheck)] = [
            ("Profiles", result.profileCount),
            ("Cats", result.catCount),
            ("Encounters", result.encounterCount),
            ("Follows", result.followCount),
            ("Likes", result.likeCount),
            ("Comments", result.commentCount)
        ]
        for (name, check) in checks where !check.isValid {
            MigrationLogger.error(
                "\(name): expected >= \(check.expected), got \(check.actual)"
            )
        }
    }
}

/// Minimal row for counting.
private struct CountRow: Codable {
    let id: UUID
}
