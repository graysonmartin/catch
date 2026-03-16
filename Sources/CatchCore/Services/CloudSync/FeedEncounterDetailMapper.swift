import Foundation

/// Maps `CloudEncounter` + `CloudCat` pairs into `FeedEncounterDetail` projections
/// for feed card display.
public enum FeedEncounterDetailMapper {

    /// Maps a single encounter and its associated cat into a feed detail.
    ///
    /// - Parameters:
    ///   - encounter: The cloud encounter to map.
    ///   - cat: The associated cat, if any.
    ///   - isFirstEncounter: Whether this is the first encounter for the cat.
    /// - Returns: A `FeedEncounterDetail` ready for display.
    public static func map(
        encounter: CloudEncounter,
        cat: CloudCat?,
        isFirstEncounter: Bool
    ) -> FeedEncounterDetail {
        FeedEncounterDetail(
            recordName: encounter.recordName,
            catName: cat?.displayName ?? CatchStrings.Common.unnamedCatFallback,
            breed: cat?.breed ?? "",
            isUnnamed: cat?.isUnnamed ?? true,
            isOwned: cat?.isOwned ?? false,
            date: encounter.date,
            locationName: encounter.locationName,
            notes: encounter.notes,
            encounterPhotos: encounter.photos,
            catPhotos: cat?.photos ?? [],
            encounterPhotoUrls: encounter.photoUrls,
            catPhotoUrls: cat?.photoUrls ?? [],
            isFirstEncounter: isFirstEncounter
        )
    }

    /// Maps a batch of encounters with their cats into feed details.
    ///
    /// - Parameters:
    ///   - encounters: The cloud encounters to map.
    ///   - cats: All available cats (matched by `catRecordName`).
    ///   - allEncounters: All encounters for this user, used to determine first-encounter status.
    /// - Returns: An array of `FeedEncounterDetail` sorted newest-first.
    public static func mapBatch(
        encounters: [CloudEncounter],
        cats: [CloudCat],
        allEncounters: [CloudEncounter]
    ) -> [FeedEncounterDetail] {
        let catsByRecord = Dictionary(
            cats.map { ($0.recordName, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let earliestByCat = Dictionary(
            grouping: allEncounters,
            by: \.catRecordName
        ).compactMapValues { group in
            group.min(by: { $0.date < $1.date })?.recordName
        }

        return encounters.map { encounter in
            let cat = catsByRecord[encounter.catRecordName]
            let isFirst = earliestByCat[encounter.catRecordName] == encounter.recordName
            return map(encounter: encounter, cat: cat, isFirstEncounter: isFirst)
        }
    }
}
