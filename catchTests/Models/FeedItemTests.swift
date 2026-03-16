import XCTest
import CatchCore

@MainActor
final class FeedItemTests: XCTestCase {

    // MARK: - Identifiers

    func testLocalItemIDPrefixedWithLocal() {
        let cat = Fixtures.cat(name: "Noodle")
        let encounter = Fixtures.encounter(for: cat)
        let item = FeedItem.local(encounter)

        XCTAssertTrue(item.id.hasPrefix("local-"))
    }

    func testRemoteItemIDPrefixedWithRemote() {
        let item = makeRemoteItem(recordName: "enc-42")

        XCTAssertEqual(item.id, "remote-enc-42")
    }

    // MARK: - Date

    func testLocalItemDateMatchesEncounterDate() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let cat = Fixtures.cat(name: "Mochi")
        let encounter = Fixtures.encounter(for: cat, date: date)
        let item = FeedItem.local(encounter)

        XCTAssertEqual(item.date, date)
    }

    func testRemoteItemDateMatchesEncounterDate() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let item = makeRemoteItem(recordName: "enc-r1", date: date)

        XCTAssertEqual(item.date, date)
    }

    // MARK: - isLocal

    func testLocalItemIsLocalReturnsTrue() {
        let cat = Fixtures.cat(name: "Bean")
        let encounter = Fixtures.encounter(for: cat)
        let item = FeedItem.local(encounter)

        XCTAssertTrue(item.isLocal)
    }

    func testRemoteItemIsLocalReturnsFalse() {
        let item = makeRemoteItem(recordName: "enc-remote")

        XCTAssertFalse(item.isLocal)
    }

    // MARK: - Encounter Record Name

    func testLocalItemEncounterRecordNameReturnsUUID() {
        let cat = Fixtures.cat(name: "Pixel")
        let encounter = Fixtures.encounter(for: cat)
        let item = FeedItem.local(encounter)

        XCTAssertEqual(item.encounterRecordName, encounter.id.uuidString)
    }

    func testRemoteItemEncounterRecordNameMatchesRecordName() {
        let item = makeRemoteItem(recordName: "enc-r99")

        XCTAssertEqual(item.encounterRecordName, "enc-r99")
    }

    // MARK: - Chronological Sorting

    func testMixedItemsSortChronologically() {
        let oldDate = Date(timeIntervalSince1970: 1_600_000_000)
        let midDate = Date(timeIntervalSince1970: 1_650_000_000)
        let newDate = Date(timeIntervalSince1970: 1_700_000_000)

        let cat = Fixtures.cat(name: "Sorter")
        let localOld = FeedItem.local(Fixtures.encounter(for: cat, date: oldDate))
        let localNew = FeedItem.local(Fixtures.encounter(for: cat, date: newDate))
        let remoteMid = makeRemoteItem(recordName: "enc-mid", date: midDate)

        let sorted = [localOld, remoteMid, localNew].sorted { $0.date > $1.date }

        XCTAssertEqual(sorted[0].date, newDate)
        XCTAssertEqual(sorted[1].date, midDate)
        XCTAssertEqual(sorted[2].date, oldDate)
        XCTAssertTrue(sorted[0].isLocal)
        XCTAssertFalse(sorted[1].isLocal)
        XCTAssertTrue(sorted[2].isLocal)
    }

    // MARK: - Helpers

    private func makeRemoteItem(
        recordName: String,
        date: Date = Date()
    ) -> FeedItem {
        let encounter = CloudEncounter(
            recordName: recordName,
            ownerID: "owner-1",
            catRecordName: "cat-1",
            date: date,
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            photos: []
        )
        let owner = CloudUserProfile(
            recordName: "profile-1",
            appleUserID: "owner-1",
            displayName: "friend",
            bio: "",
            username: "friend",
            isPrivate: false
        )
        return .remote(encounter, cat: nil, owner: owner, isFirstEncounter: false)
    }
}
