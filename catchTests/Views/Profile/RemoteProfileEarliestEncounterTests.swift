import XCTest

@MainActor
final class RemoteProfileEarliestEncounterTests: XCTestCase {

    // MARK: - earliestEncounterIDs logic (mirrors RemoteProfileContent)

    func testSingleEncounterPerCatMarkedAsFirst() {
        let encounters = [
            makeEncounter(recordName: "enc-1", catRecordName: "cat-a", daysAgo: 10),
            makeEncounter(recordName: "enc-2", catRecordName: "cat-b", daysAgo: 5)
        ]

        let ids = computeEarliestEncounterIDs(encounters)

        XCTAssertEqual(ids, Set(["enc-1", "enc-2"]))
    }

    func testMultipleEncountersSameCatOnlyEarliestMarked() {
        let encounters = [
            makeEncounter(recordName: "enc-1", catRecordName: "cat-a", daysAgo: 30),
            makeEncounter(recordName: "enc-2", catRecordName: "cat-a", daysAgo: 10),
            makeEncounter(recordName: "enc-3", catRecordName: "cat-a", daysAgo: 1)
        ]

        let ids = computeEarliestEncounterIDs(encounters)

        XCTAssertEqual(ids, Set(["enc-1"]))
    }

    func testMixedCatsOnlyEarliestPerCatMarked() {
        let encounters = [
            makeEncounter(recordName: "enc-a1", catRecordName: "cat-a", daysAgo: 20),
            makeEncounter(recordName: "enc-b1", catRecordName: "cat-b", daysAgo: 15),
            makeEncounter(recordName: "enc-a2", catRecordName: "cat-a", daysAgo: 5),
            makeEncounter(recordName: "enc-b2", catRecordName: "cat-b", daysAgo: 2)
        ]

        let ids = computeEarliestEncounterIDs(encounters)

        XCTAssertEqual(ids, Set(["enc-a1", "enc-b1"]))
    }

    func testEmptyEncountersReturnsEmptySet() {
        let ids = computeEarliestEncounterIDs([])

        XCTAssertTrue(ids.isEmpty)
    }

    func testEncountersWithSameDateHandled() {
        let now = Date()
        let encounters = [
            CloudEncounter(
                recordName: "enc-1", ownerID: "user", catRecordName: "cat-a",
                date: now, locationName: "", locationLatitude: nil,
                locationLongitude: nil, notes: "", photos: []
            ),
            CloudEncounter(
                recordName: "enc-2", ownerID: "user", catRecordName: "cat-a",
                date: now, locationName: "", locationLatitude: nil,
                locationLongitude: nil, notes: "", photos: []
            )
        ]

        let ids = computeEarliestEncounterIDs(encounters)

        // One of them should be marked as first — stable sort picks first by array order
        XCTAssertEqual(ids.count, 1)
    }

    // MARK: - Helpers

    /// Mirrors the logic in RemoteProfileContent.earliestEncounterIDs
    private func computeEarliestEncounterIDs(_ encounters: [CloudEncounter]) -> Set<String> {
        var ids = Set<String>()
        var seenCats = Set<String>()
        let allSorted = encounters.sorted { $0.date < $1.date }
        for encounter in allSorted {
            if !seenCats.contains(encounter.catRecordName) {
                seenCats.insert(encounter.catRecordName)
                ids.insert(encounter.recordName)
            }
        }
        return ids
    }

    private func makeEncounter(
        recordName: String,
        catRecordName: String,
        daysAgo: Int
    ) -> CloudEncounter {
        CloudEncounter(
            recordName: recordName,
            ownerID: "test-user",
            catRecordName: catRecordName,
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            photos: []
        )
    }
}
