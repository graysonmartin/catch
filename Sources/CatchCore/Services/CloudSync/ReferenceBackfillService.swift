import CloudKit

/// One-time migration service that backfills CKReference fields on existing CloudKit records
/// that only have string FK fields. Safe to run multiple times — records that already have
/// references are skipped.
public enum ReferenceBackfillService {

    /// Result summary for a backfill run.
    public struct BackfillResult: Sendable, Equatable {
        public let encountersUpdated: Int
        public let commentsUpdated: Int
        public let likesUpdated: Int

        public var totalUpdated: Int {
            encountersUpdated + commentsUpdated + likesUpdated
        }

        public var isFullyBackfilled: Bool {
            totalUpdated == 0
        }

        public init(encountersUpdated: Int, commentsUpdated: Int, likesUpdated: Int) {
            self.encountersUpdated = encountersUpdated
            self.commentsUpdated = commentsUpdated
            self.likesUpdated = likesUpdated
        }
    }

    /// Backfills CKReference fields for all record types owned by the given user.
    ///
    /// - Parameters:
    ///   - ownerID: The owner's Apple user ID used to scope encounter queries.
    ///   - database: The CloudKit database to query and save against.
    /// - Returns: A summary of how many records were updated.
    public static func backfillAll(
        ownerID: String,
        database: CKDatabase
    ) async throws -> BackfillResult {
        async let encounterCount = backfillEncounters(ownerID: ownerID, database: database)
        async let commentCount = backfillComments(database: database)
        async let likeCount = backfillLikes(database: database)

        return try await BackfillResult(
            encountersUpdated: encounterCount,
            commentsUpdated: commentCount,
            likesUpdated: likeCount
        )
    }

    // MARK: - Private

    private static func backfillEncounters(
        ownerID: String,
        database: CKDatabase
    ) async throws -> Int {
        let predicate = NSPredicate(format: "ownerID == %@", ownerID)
        let records = try await fetchAllRecords(
            recordType: EncounterRecordMapper.recordType,
            predicate: predicate,
            database: database
        )

        let toUpdate = records.compactMap { EncounterRecordMapper.backfillReference(on: $0) }
        try await saveInBatches(toUpdate, database: database)
        return toUpdate.count
    }

    private static func backfillComments(database: CKDatabase) async throws -> Int {
        let predicate = NSPredicate(value: true)
        let records = try await fetchAllRecords(
            recordType: CommentRecordMapper.recordType,
            predicate: predicate,
            database: database
        )

        let toUpdate = records.compactMap { CommentRecordMapper.backfillReference(on: $0) }
        try await saveInBatches(toUpdate, database: database)
        return toUpdate.count
    }

    private static func backfillLikes(database: CKDatabase) async throws -> Int {
        let predicate = NSPredicate(value: true)
        let records = try await fetchAllRecords(
            recordType: LikeRecordMapper.recordType,
            predicate: predicate,
            database: database
        )

        let toUpdate = records.compactMap { LikeRecordMapper.backfillReference(on: $0) }
        try await saveInBatches(toUpdate, database: database)
        return toUpdate.count
    }

    private static func fetchAllRecords(
        recordType: String,
        predicate: NSPredicate,
        database: CKDatabase
    ) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        var allRecords: [CKRecord] = []

        let (firstResults, firstCursor) = try await database.records(matching: query, resultsLimit: 200)
        allRecords.append(contentsOf: extractRecords(from: firstResults))

        var cursor = firstCursor
        while let activeCursor = cursor {
            let (pageResults, nextCursor) = try await database.records(
                continuingMatchFrom: activeCursor,
                resultsLimit: 200
            )
            allRecords.append(contentsOf: extractRecords(from: pageResults))
            cursor = nextCursor
        }

        return allRecords
    }

    private static func extractRecords(
        from results: [(CKRecord.ID, Result<CKRecord, any Error>)]
    ) -> [CKRecord] {
        results.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return record
        }
    }

    private static func saveInBatches(_ records: [CKRecord], database: CKDatabase) async throws {
        let batchSize = 400
        for startIndex in stride(from: 0, to: records.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, records.count)
            let batch = Array(records[startIndex..<endIndex])

            let operation = CKModifyRecordsOperation(recordsToSave: batch)
            operation.savePolicy = .changedKeys
            operation.database = database

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                database.add(operation)
            }
        }
    }
}
