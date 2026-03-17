import XCTest
import CatchCore

@MainActor
final class UserProfileTests: XCTestCase {

    func test_defaultInitSetsEmptyValues() {
        let profile = UserProfile()
        XCTAssertEqual(profile.displayName, "")
        XCTAssertEqual(profile.bio, "")
        XCTAssertNil(profile.username)
        XCTAssertNil(profile.supabaseUserID)
        XCTAssertFalse(profile.isPrivate)
        XCTAssertLessThanOrEqual(profile.createdAt, Date())
    }

    func test_customInitSetsProvidedValues() {
        let profile = UserProfile(
            displayName: "cat enthusiast",
            bio: "just vibing"
        )
        XCTAssertEqual(profile.displayName, "cat enthusiast")
        XCTAssertEqual(profile.bio, "just vibing")
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

    func test_username_canBeUpdated() {
        var profile = UserProfile(username: "old_name")
        profile.username = "new_name"
        XCTAssertEqual(profile.username, "new_name")
    }

    func test_username_canBeCleared() {
        var profile = UserProfile(username: "temp_name")
        profile.username = nil
        XCTAssertNil(profile.username)
    }

    // MARK: - Privacy

    func test_isPrivate_defaultsToFalse() {
        let profile = UserProfile()
        XCTAssertFalse(profile.isPrivate)
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
            username: "cat_fan"
        )
        XCTAssertTrue(profile.isProfileComplete)
    }
}
