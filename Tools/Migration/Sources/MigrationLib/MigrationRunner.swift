import Foundation
import Supabase

/// Orchestrates the full CloudKit to Supabase migration.
///
/// Migration steps (run in dependency order):
/// 1. Load user mapping file (Apple ID to Supabase UUID)
/// 2. Load CloudKit export data
/// 3. Migrate profiles
/// 4. Migrate cats (with photos)
/// 5. Migrate encounters (with photos)
/// 6. Migrate follow relationships
/// 7. Migrate likes
/// 8. Migrate comments
/// 9. Verify data integrity
public final class MigrationRunner {
    private let supabase: SupabaseClient
    private let photoMigrator: PhotoMigrator
    private let isDryRun: Bool
    private let idBuilder = IDMappingTableBuilder()

    public init(supabaseURL: URL, supabaseServiceKey: String, isDryRun: Bool) {
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseServiceKey
        )
        self.photoMigrator = PhotoMigrator(supabase: supabase, isDryRun: isDryRun)
        self.isDryRun = isDryRun
    }

    /// Runs the full migration pipeline.
    public func run(
        mappingFilePath: String,
        exportFilePath: String
    ) async throws {
        let totalSteps = 9

        // Step 1: Load user mapping
        MigrationLogger.step(1, of: totalSteps, "Loading user mapping file...")
        let userMapping = try UserMapping.load(from: mappingFilePath)
        MigrationLogger.info("Loaded \(userMapping.entries.count) user mapping(s)")

        // Step 2: Load CloudKit export
        MigrationLogger.step(2, of: totalSteps, "Loading CloudKit export data...")
        let export = try loadExport(from: exportFilePath)
        MigrationLogger.summary("CloudKit Export Counts", counts: [
            ("Profiles", export.profiles.count),
            ("Cats", export.cats.count),
            ("Encounters", export.encounters.count),
            ("Follows", export.follows.count),
            ("Likes", export.likes.count),
            ("Comments", export.comments.count)
        ])

        // Step 3: Migrate profiles
        MigrationLogger.step(3, of: totalSteps, "Migrating profiles...")
        let profileCount = try await migrateProfiles(export.profiles, userMapping: userMapping)
        MigrationLogger.info("Migrated \(profileCount) profile(s)")

        // Step 4: Migrate cats
        MigrationLogger.step(4, of: totalSteps, "Migrating cats...")
        let catCount = try await migrateCats(export.cats, userMapping: userMapping)
        MigrationLogger.info("Migrated \(catCount) cat(s)")

        // Step 5: Migrate encounters
        MigrationLogger.step(5, of: totalSteps, "Migrating encounters...")
        let idMappings = idBuilder.build()
        let encounterCount = try await migrateEncounters(
            export.encounters,
            userMapping: userMapping,
            idMappings: idMappings
        )
        MigrationLogger.info("Migrated \(encounterCount) encounter(s)")

        // Rebuild after encounters are added
        let finalMappings = idBuilder.build()

        // Step 6: Migrate follows
        MigrationLogger.step(6, of: totalSteps, "Migrating follow relationships...")
        let followCount = try await migrateFollows(export.follows, userMapping: userMapping)
        MigrationLogger.info("Migrated \(followCount) follow(s)")

        // Step 7: Migrate likes
        MigrationLogger.step(7, of: totalSteps, "Migrating likes...")
        let likeCount = try await migrateLikes(
            export.likes,
            userMapping: userMapping,
            idMappings: finalMappings
        )
        MigrationLogger.info("Migrated \(likeCount) like(s)")

        // Step 8: Migrate comments
        MigrationLogger.step(8, of: totalSteps, "Migrating comments...")
        let commentCount = try await migrateComments(
            export.comments,
            userMapping: userMapping,
            idMappings: finalMappings
        )
        MigrationLogger.info("Migrated \(commentCount) comment(s)")

        // Step 9: Verify
        MigrationLogger.step(9, of: totalSteps, "Verifying data integrity...")
        if !isDryRun {
            let verifier = MigrationVerifier(supabase: supabase)
            let result = try await verifier.verify(
                expectedProfiles: profileCount,
                expectedCats: catCount,
                expectedEncounters: encounterCount,
                expectedFollows: followCount,
                expectedLikes: likeCount,
                expectedComments: commentCount
            )
            if result.isValid {
                MigrationLogger.info("Migration completed successfully.")
            } else {
                MigrationLogger.warn("Migration completed with verification warnings.")
            }
        } else {
            MigrationLogger.info("[dry-run] Skipping verification.")
            MigrationLogger.info("[dry-run] Migration dry run completed.")
        }
    }

    // MARK: - Private

    private func loadExport(from path: String) throws -> CloudKitExport {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CloudKitExport.self, from: data)
    }

    private func migrateProfiles(
        _ profiles: [CKExportProfile],
        userMapping: UserMapping
    ) async throws -> Int {
        var count = 0
        for profile in profiles {
            guard let supabaseID = userMapping.supabaseUserIDOrNil(for: profile.appleUserID) else {
                MigrationLogger.warn("Skipping profile for unmapped user: \(profile.appleUserID)")
                continue
            }

            let payload = MigrationMapper.mapProfile(profile, supabaseUserID: supabaseID)

            if isDryRun {
                MigrationLogger.info("  [dry-run] Would upsert profile: \(payload.displayName)")
            } else {
                try await supabase
                    .from("profiles")
                    .upsert(payload, onConflict: "id")
                    .execute()
            }
            count += 1
        }
        return count
    }

    private func migrateCats(
        _ cats: [CKExportCat],
        userMapping: UserMapping
    ) async throws -> Int {
        var count = 0
        for cat in cats {
            guard let supabaseOwnerID = userMapping.supabaseUserIDOrNil(for: cat.ownerID) else {
                MigrationLogger.warn("Skipping cat '\(cat.name ?? "unnamed")' for unmapped owner: \(cat.ownerID)")
                continue
            }

            let supabaseCatID = UUID().uuidString
            idBuilder.addCatMapping(cloudKitRecordName: cat.recordName, supabaseID: supabaseCatID)

            let photoUrls = try await photoMigrator.migratePhotos(
                urls: cat.photoURLs,
                bucket: "cat-photos",
                ownerID: supabaseOwnerID,
                entityID: supabaseCatID
            )

            let payload = MigrationMapper.mapCat(
                cat,
                supabaseOwnerID: supabaseOwnerID,
                supabaseCatID: supabaseCatID,
                photoUrls: photoUrls
            )

            if isDryRun {
                MigrationLogger.info("  [dry-run] Would upsert cat: \(payload.name) (id: \(supabaseCatID))")
            } else {
                try await supabase
                    .from("cats")
                    .upsert(payload, onConflict: "id")
                    .execute()
            }
            count += 1
        }
        return count
    }

    private func migrateEncounters(
        _ encounters: [CKExportEncounter],
        userMapping: UserMapping,
        idMappings: IDMappingTable
    ) async throws -> Int {
        var count = 0
        for encounter in encounters {
            guard let supabaseOwnerID = userMapping.supabaseUserIDOrNil(for: encounter.ownerID) else {
                MigrationLogger.warn("Skipping encounter for unmapped owner: \(encounter.ownerID)")
                continue
            }

            guard let supabaseCatID = try? idMappings.supabaseCatID(for: encounter.catRecordName) else {
                MigrationLogger.warn("Skipping encounter for unmapped cat: \(encounter.catRecordName)")
                continue
            }

            let supabaseEncounterID = UUID().uuidString
            idBuilder.addEncounterMapping(
                cloudKitRecordName: encounter.recordName,
                supabaseID: supabaseEncounterID
            )

            let photoUrls = try await photoMigrator.migratePhotos(
                urls: encounter.photoURLs,
                bucket: "encounter-photos",
                ownerID: supabaseOwnerID,
                entityID: supabaseEncounterID
            )

            let payload = MigrationMapper.mapEncounter(
                encounter,
                supabaseOwnerID: supabaseOwnerID,
                supabaseEncounterID: supabaseEncounterID,
                supabaseCatID: supabaseCatID,
                photoUrls: photoUrls
            )

            if isDryRun {
                MigrationLogger.info("  [dry-run] Would upsert encounter: \(supabaseEncounterID)")
            } else {
                try await supabase
                    .from("encounters")
                    .upsert(payload, onConflict: "id")
                    .execute()
            }
            count += 1
        }
        return count
    }

    private func migrateFollows(
        _ follows: [CKExportFollow],
        userMapping: UserMapping
    ) async throws -> Int {
        var count = 0
        for follow in follows {
            guard let supabaseFollowerID = userMapping.supabaseUserIDOrNil(for: follow.followerID) else {
                MigrationLogger.warn("Skipping follow for unmapped follower: \(follow.followerID)")
                continue
            }
            guard let supabaseFolloweeID = userMapping.supabaseUserIDOrNil(for: follow.followeeID) else {
                MigrationLogger.warn("Skipping follow for unmapped followee: \(follow.followeeID)")
                continue
            }

            let payload = MigrationMapper.mapFollow(
                follow,
                supabaseFollowerID: supabaseFollowerID,
                supabaseFolloweeID: supabaseFolloweeID
            )

            if isDryRun {
                MigrationLogger.info("  [dry-run] Would upsert follow: \(supabaseFollowerID) -> \(supabaseFolloweeID)")
            } else {
                try await supabase
                    .from("follows")
                    .upsert(payload, onConflict: "follower_id,followee_id")
                    .execute()
            }
            count += 1
        }
        return count
    }

    private func migrateLikes(
        _ likes: [CKExportLike],
        userMapping: UserMapping,
        idMappings: IDMappingTable
    ) async throws -> Int {
        var count = 0
        for like in likes {
            guard let supabaseUserID = userMapping.supabaseUserIDOrNil(for: like.userID) else {
                MigrationLogger.warn("Skipping like for unmapped user: \(like.userID)")
                continue
            }
            guard let supabaseEncounterID = try? idMappings.supabaseEncounterID(for: like.encounterRecordName) else {
                MigrationLogger.warn("Skipping like for unmapped encounter: \(like.encounterRecordName)")
                continue
            }

            let payload = MigrationMapper.mapLike(
                like,
                supabaseUserID: supabaseUserID,
                supabaseEncounterID: supabaseEncounterID
            )

            if isDryRun {
                MigrationLogger.info("  [dry-run] Would upsert like: user \(supabaseUserID) on \(supabaseEncounterID)")
            } else {
                try await supabase
                    .from("encounter_likes")
                    .upsert(payload, onConflict: "encounter_id,user_id")
                    .execute()
            }
            count += 1
        }
        return count
    }

    private func migrateComments(
        _ comments: [CKExportComment],
        userMapping: UserMapping,
        idMappings: IDMappingTable
    ) async throws -> Int {
        var count = 0
        for comment in comments {
            guard let supabaseUserID = userMapping.supabaseUserIDOrNil(for: comment.userID) else {
                MigrationLogger.warn("Skipping comment for unmapped user: \(comment.userID)")
                continue
            }
            guard let supabaseEncounterID = try? idMappings.supabaseEncounterID(for: comment.encounterRecordName) else {
                MigrationLogger.warn("Skipping comment for unmapped encounter: \(comment.encounterRecordName)")
                continue
            }

            let payload = MigrationMapper.mapComment(
                comment,
                supabaseUserID: supabaseUserID,
                supabaseEncounterID: supabaseEncounterID
            )

            if isDryRun {
                MigrationLogger.info("  [dry-run] Would insert comment by \(supabaseUserID)")
            } else {
                // Comments use insert (not upsert) since there's no unique constraint
                // on (encounter_id, user_id, text). A user can comment multiple times.
                // Idempotency note: re-running may create duplicate comments. For a one-time
                // beta migration this is acceptable; clean up duplicates manually if needed.
                try await supabase
                    .from("encounter_comments")
                    .insert(payload)
                    .execute()
            }
            count += 1
        }
        return count
    }
}
