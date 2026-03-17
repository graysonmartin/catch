import Foundation
import Observation
import os
import CatchCore

/// Service layer for paginated local feed loading.
/// Fetches encounters with joined cat data using cursor-based pagination.
@Observable
@MainActor
final class FeedDataService {
    private(set) var encounters: [Encounter] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMorePages = false

    private let encounterRepository: any SupabaseEncounterRepository
    private let getUserID: @Sendable () -> String?
    private let pageSize: Int
    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "FeedDataService")

    /// ISO 8601 date string of the oldest item in the current feed, used as cursor.
    private var nextCursor: String?

    init(
        encounterRepository: any SupabaseEncounterRepository,
        getUserID: @escaping @Sendable () -> String?,
        pageSize: Int = PaginationConstants.defaultPageSize
    ) {
        self.encounterRepository = encounterRepository
        self.getUserID = getUserID
        self.pageSize = pageSize
    }

    // MARK: - Refresh

    /// Resets the cursor and fetches the first page of encounters.
    func refresh() async {
        guard let userID = getUserID() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let rows = try await encounterRepository.fetchEncounterFeed(
                ownerID: userID,
                limit: pageSize,
                cursor: nil
            )

            encounters = mapRows(rows)
            nextCursor = cursorFromRows(rows)
            hasMorePages = rows.count >= pageSize
        } catch {
            logger.error("Failed to refresh feed: \(error.localizedDescription)")
            encounters = []
            nextCursor = nil
            hasMorePages = false
        }
    }

    // MARK: - Load More

    /// Fetches the next page of encounters using the current cursor.
    func loadMore() async {
        guard hasMorePages, !isLoadingMore else { return }
        guard let userID = getUserID() else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let rows = try await encounterRepository.fetchEncounterFeed(
                ownerID: userID,
                limit: pageSize,
                cursor: nextCursor
            )

            let newEncounters = mapRows(rows)
            encounters.append(contentsOf: newEncounters)
            nextCursor = cursorFromRows(rows)
            hasMorePages = rows.count >= pageSize
        } catch {
            logger.error("Failed to load more feed: \(error.localizedDescription)")
            hasMorePages = false
        }
    }

    // MARK: - Mutation Support

    /// Prepends a newly created encounter to the top of the feed.
    func prependEncounter(_ encounter: Encounter) {
        encounters.insert(encounter, at: 0)
    }

    /// Removes an encounter from the feed (e.g. after deletion).
    func removeEncounter(id: UUID) {
        encounters.removeAll { $0.id == id }
    }

    /// Replaces an existing encounter in the feed (e.g. after editing).
    func replaceEncounter(_ encounter: Encounter) {
        guard let idx = encounters.firstIndex(where: { $0.id == encounter.id }) else { return }
        encounters[idx] = encounter
    }

    // MARK: - Private

    private func mapRows(_ rows: [SupabaseEncounterFeedRow]) -> [Encounter] {
        rows.map { row in
            let cat = Cat(
                id: row.cat.id,
                name: row.cat.name.isEmpty ? nil : row.cat.name,
                breed: row.cat.breed,
                estimatedAge: row.cat.estimatedAge ?? "",
                location: Location(
                    name: row.cat.locationName ?? "",
                    latitude: row.cat.locationLat,
                    longitude: row.cat.locationLng
                ),
                notes: row.cat.notes ?? "",
                isOwned: row.cat.isOwned,
                photoUrls: row.cat.photoUrls,
                createdAt: row.cat.createdAt
            )

            return Encounter(
                id: row.id,
                date: row.date,
                location: Location(
                    name: row.locationName ?? "",
                    latitude: row.locationLat,
                    longitude: row.locationLng
                ),
                notes: row.notes ?? "",
                catID: row.catID,
                ownerID: row.ownerID,
                photoUrls: row.photoUrls,
                likeCount: row.likeCount,
                commentCount: row.commentCount,
                createdAt: row.createdAt,
                cat: cat
            )
        }
    }

    private static let iso8601Formatter = ISO8601DateFormatter()

    private func cursorFromRows(_ rows: [SupabaseEncounterFeedRow]) -> String? {
        guard let last = rows.last else { return nil }
        return Self.iso8601Formatter.string(from: last.date)
    }
}
