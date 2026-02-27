import XCTest
import SwiftData

@MainActor
final class ProfileDisplayDataTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try ModelContainer.forTesting()
        context = container.mainContext
    }

    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Local init

    func testLocalInitMapsBasicFields() {
        let profile = Fixtures.userProfile(
            displayName: "grayson",
            bio: "cat obsessed",
            username: "grayson_m",
            in: context
        )

        let data = ProfileDisplayData(local: profile, catCount: 5, encounterCount: 12)

        XCTAssertEqual(data.displayName, "grayson")
        XCTAssertEqual(data.bio, "cat obsessed")
        XCTAssertEqual(data.username, "grayson_m")
        XCTAssertEqual(data.catCount, 5)
        XCTAssertEqual(data.encounterCount, 12)
        XCTAssertFalse(data.isPrivate)
    }

    func testLocalInitMapsAvatarData() {
        let avatar = Data([0x89, 0x50, 0x4E, 0x47])
        let profile = Fixtures.userProfile(avatarData: avatar, in: context)

        let data = ProfileDisplayData(local: profile, catCount: 0, encounterCount: 0)

        XCTAssertEqual(data.avatarData, avatar)
    }

    func testLocalInitMapsNilAvatar() {
        let profile = Fixtures.userProfile(in: context)

        let data = ProfileDisplayData(local: profile, catCount: 0, encounterCount: 0)

        XCTAssertNil(data.avatarData)
    }

    func testLocalInitMapsPrivateFlag() {
        let profile = Fixtures.userProfile(isPrivate: true, in: context)

        let data = ProfileDisplayData(local: profile, catCount: 0, encounterCount: 0)

        XCTAssertTrue(data.isPrivate)
    }

    func testLocalInitMapsCreatedAt() {
        let profile = Fixtures.userProfile(in: context)

        let data = ProfileDisplayData(local: profile, catCount: 0, encounterCount: 0)

        XCTAssertEqual(
            data.createdAt.timeIntervalSince1970,
            profile.createdAt.timeIntervalSince1970,
            accuracy: 1
        )
    }

    func testLocalInitNilUsername() {
        let profile = Fixtures.userProfile(username: nil, in: context)

        let data = ProfileDisplayData(local: profile, catCount: 0, encounterCount: 0)

        XCTAssertNil(data.username)
    }

    // MARK: - Remote init

    func testRemoteInitMapsBasicFields() {
        let browseData = makeUserBrowseData(
            displayName: "tuong",
            bio: "i see cats",
            username: "tuong_cats",
            catCount: 3,
            encounterCount: 4
        )

        let data = ProfileDisplayData(remote: browseData)

        XCTAssertEqual(data.displayName, "tuong")
        XCTAssertEqual(data.bio, "i see cats")
        XCTAssertEqual(data.username, "tuong_cats")
        XCTAssertEqual(data.catCount, 3)
        XCTAssertEqual(data.encounterCount, 4)
    }

    func testRemoteInitAvatarIsNil() {
        let browseData = makeUserBrowseData()

        let data = ProfileDisplayData(remote: browseData)

        XCTAssertNil(data.avatarData)
    }

    func testRemoteInitMapsPrivateFlag() {
        let browseData = makeUserBrowseData(isPrivate: true)

        let data = ProfileDisplayData(remote: browseData)

        XCTAssertTrue(data.isPrivate)
    }

    func testRemoteInitCountsFromArrays() {
        let browseData = makeUserBrowseData(catCount: 2, encounterCount: 5)

        let data = ProfileDisplayData(remote: browseData)

        XCTAssertEqual(data.catCount, 2)
        XCTAssertEqual(data.encounterCount, 5)
    }

    // MARK: - Helpers

    private func makeUserBrowseData(
        displayName: String = "test",
        bio: String = "",
        username: String? = nil,
        isPrivate: Bool = false,
        catCount: Int = 0,
        encounterCount: Int = 0
    ) -> UserBrowseData {
        let profile = CloudUserProfile(
            recordName: "profile-test",
            appleUserID: "fake-test",
            displayName: displayName,
            bio: bio,
            username: username,
            isPrivate: isPrivate
        )

        let cats = (0..<catCount).map { i in
            CloudCat(
                recordName: "cat-\(i)",
                ownerID: "fake-test",
                name: "Cat \(i)",
                breed: "",
                estimatedAge: "1",
                locationName: "Here",
                locationLatitude: nil,
                locationLongitude: nil,
                notes: "",
                isOwned: false,
                createdAt: Date(),
                photos: []
            )
        }

        let encounters = (0..<encounterCount).map { i in
            CloudEncounter(
                recordName: "enc-\(i)",
                ownerID: "fake-test",
                catRecordName: cats.isEmpty ? "cat-0" : cats[i % cats.count].recordName,
                date: Date(),
                locationName: "Here",
                locationLatitude: nil,
                locationLongitude: nil,
                notes: "",
                photos: []
            )
        }

        return UserBrowseData(
            profile: profile,
            cats: cats,
            encounters: encounters,
            followerCount: 0,
            followingCount: 0,
            fetchedAt: Date()
        )
    }
}
