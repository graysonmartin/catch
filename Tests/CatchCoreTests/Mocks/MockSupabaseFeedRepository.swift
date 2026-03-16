import Foundation
import Observation
@testable import CatchCore

@Observable
@MainActor
final class MockSupabaseFeedRepository: SupabaseFeedRepository {
    private(set) var fetchFeedCalls: [(followedUserIDs: [String], limit: Int, cursor: String?)] = []

    var fetchFeedResult: [SupabaseFeedRow] = []
    var errorToThrow: (any Error)?

    /// Optional per-cursor results for pagination testing.
    var fetchFeedResultsByCursor: [String?: [SupabaseFeedRow]] = [:]

    func fetchFeed(
        followedUserIDs: [String],
        limit: Int,
        cursor: String?
    ) async throws -> [SupabaseFeedRow] {
        fetchFeedCalls.append((followedUserIDs, limit, cursor))
        if let error = errorToThrow { throw error }

        if let cursorResult = fetchFeedResultsByCursor[cursor] {
            return cursorResult
        }
        return fetchFeedResult
    }

    func reset() {
        fetchFeedCalls = []
        fetchFeedResult = []
        fetchFeedResultsByCursor = [:]
        errorToThrow = nil
    }
}
