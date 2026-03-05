import XCTest
import SwiftData
import CatchCore

@MainActor
final class UserProfileTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainer.forTesting()
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    func test_defaultInitSetsEmptyValues() {
        let profile = UserProfile()
        XCTAssertEqual(profile.displayName, "")
        XCTAssertEqual(profile.bio, "")
        XCTAssertNil(profile.username)
        XCTAssertNil(profile.avatarData)
        XCTAssertNil(profile.appleUserID)
        XCTAssertNil(profile.cloudKitRecordName)
        XCTAssertFalse(profile.isPrivate)
        XCTAssertLessThanOrEqual(profile.createdAt, Date())
    }

    func test_customInitSetsProvidedValues() {
        let avatar = Data([0x01, 0x02, 0x03])
        let profile = UserProfile(
            displayName: "cat enthusiast",
            bio: "just vibing",
            avatarData: avatar
        )
        XCTAssertEqual(profile.displayName, "cat enthusiast")
        XCTAssertEqual(profile.bio, "just vibing")
        XCTAssertEqual(profile.avatarData, avatar)
    }

    func test_persistenceRoundtrip() throws {
        Fixtures.userProfile(in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.displayName, "test user")
    }

    func test_avatarDataPersists() throws {
        let avatar = Data(repeating: 0xFF, count: 64)
        Fixtures.userProfile(avatarData: avatar, in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.first?.avatarData, avatar)
    }

    func test_fieldUpdatesPersist() throws {
        let profile = Fixtures.userProfile(in: context)
        try context.save()

        profile.displayName = "updated name"
        profile.bio = "new bio"
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.first?.displayName, "updated name")
        XCTAssertEqual(fetched.first?.bio, "new bio")
    }

    // MARK: - Apple Auth Fields

    func test_appleUserID_persistsRoundTrip() throws {
        Fixtures.userProfile(appleUserID: "apple-123", in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.first?.appleUserID, "apple-123")
    }

    func test_cloudKitRecordName_persistsRoundTrip() throws {
        Fixtures.userProfile(cloudKitRecordName: "ck-record-456", in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.first?.cloudKitRecordName, "ck-record-456")
    }

    func test_bothAuthFields_persistTogether() throws {
        Fixtures.userProfile(
            appleUserID: "apple-789",
            cloudKitRecordName: "ck-789",
            in: context
        )
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.first?.appleUserID, "apple-789")
        XCTAssertEqual(fetched.first?.cloudKitRecordName, "ck-789")
    }

    // MARK: - Username

    func test_username_defaultsToNil() {
        let profile = UserProfile()
        XCTAssertNil(profile.username)
    }

    func test_username_canBeSetViaInit() {
        let profile = UserProfile(username: "cat_lover")
        XCTAssertEqual(profile.username, "cat_lover")
    }

    func test_username_persistsRoundTrip() throws {
        Fixtures.userProfile(username: "cool_cat_99", in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.first?.username, "cool_cat_99")
    }

    func test_username_canBeUpdated() throws {
        let profile = Fixtures.userProfile(username: "old_name", in: context)
        try context.save()

        profile.username = "new_name"
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.first?.username, "new_name")
    }

    func test_username_canBeCleared() throws {
        let profile = Fixtures.userProfile(username: "temp_name", in: context)
        try context.save()

        profile.username = nil
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertNil(fetched.first?.username)
    }

    // MARK: - Privacy

    func test_isPrivate_defaultsToFalse() {
        let profile = UserProfile()
        XCTAssertFalse(profile.isPrivate)
    }

    func test_isPrivate_persistsWhenTrue() throws {
        let profile = Fixtures.userProfile(in: context)
        profile.isPrivate = true
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertTrue(fetched.first?.isPrivate ?? false)
    }

    func test_isPrivate_canBeSetViaInit() {
        let profile = UserProfile(isPrivate: true)
        XCTAssertTrue(profile.isPrivate)
    }

    // MARK: - Visibility Settings

    func test_visibilitySettings_defaultsToAllTrue() {
        let profile = UserProfile()
        XCTAssertEqual(profile.visibilitySettings, .default)
        XCTAssertTrue(profile.visibilitySettings.showCats)
        XCTAssertTrue(profile.visibilitySettings.showEncounters)
    }

    func test_visibilitySettings_persistsRoundTrip() throws {
        let custom = VisibilitySettings(showCats: false, showEncounters: true)
        let profile = Fixtures.userProfile(visibilitySettings: custom, in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.first?.visibilitySettings, custom)
    }

    func test_visibilitySettings_canBeSetViaInit() {
        let custom = VisibilitySettings(showCats: false, showEncounters: false)
        let profile = UserProfile(visibilitySettings: custom)
        XCTAssertEqual(profile.visibilitySettings, custom)
    }

    // MARK: - Profile Completeness

    func test_isProfileComplete_falseByDefault() {
        let profile = UserProfile()
        XCTAssertFalse(profile.isProfileComplete)
    }

    func test_isProfileComplete_falseWithDisplayNameOnly() {
        let profile = UserProfile(displayName: "cat fan")
        XCTAssertFalse(profile.isProfileComplete)
    }

    func test_isProfileComplete_falseWithUsernameOnly() {
        let profile = UserProfile(username: "cat_fan")
        XCTAssertFalse(profile.isProfileComplete)
    }

    func test_isProfileComplete_falseWithEmptyDisplayName() {
        let profile = UserProfile(displayName: "", username: "cat_fan")
        XCTAssertFalse(profile.isProfileComplete)
    }

    func test_isProfileComplete_falseWithWhitespaceDisplayName() {
        let profile = UserProfile(displayName: "   ", username: "cat_fan")
        XCTAssertFalse(profile.isProfileComplete)
    }

    func test_isProfileComplete_falseWithEmptyUsername() {
        let profile = UserProfile(displayName: "cat fan", username: "")
        XCTAssertFalse(profile.isProfileComplete)
    }

    func test_isProfileComplete_falseWithInvalidUsername() {
        let profile = UserProfile(displayName: "cat fan", username: "ab")
        XCTAssertFalse(profile.isProfileComplete)
    }

    func test_isProfileComplete_falseWithInvalidUsernameChars() {
        let profile = UserProfile(displayName: "cat fan", username: "cat fan!")
        XCTAssertFalse(profile.isProfileComplete)
    }

    func test_isProfileComplete_trueWithValidFields() {
        let profile = UserProfile(displayName: "cat fan", username: "cat_fan")
        XCTAssertTrue(profile.isProfileComplete)
    }

    func test_isProfileComplete_trueWithMinimalValidUsername() {
        let profile = UserProfile(displayName: "a", username: "abc")
        XCTAssertTrue(profile.isProfileComplete)
    }

    func test_isProfileComplete_unaffectedByOptionalFields() {
        let profile = UserProfile(
            displayName: "cat fan",
            bio: "",
            username: "cat_fan",
            avatarData: nil
        )
        XCTAssertTrue(profile.isProfileComplete)
    }
}
