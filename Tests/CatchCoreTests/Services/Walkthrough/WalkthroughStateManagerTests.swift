import XCTest
@testable import CatchCore

final class WalkthroughStateManagerTests: XCTestCase {

    private var sut: WalkthroughStateManager!

    override func setUp() {
        super.setUp()
        sut = WalkthroughStateManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - shouldShowWalkthrough

    func test_shouldShowWalkthrough_allConditionsMet_returnsTrue() {
        let result = sut.shouldShowWalkthrough(
            hasCompletedOnboarding: true,
            isSignedIn: true,
            hasCompletedProfileSetup: true,
            hasCompletedWalkthrough: false
        )
        XCTAssertTrue(result)
    }

    func test_shouldShowWalkthrough_walkthroughAlreadyCompleted_returnsFalse() {
        let result = sut.shouldShowWalkthrough(
            hasCompletedOnboarding: true,
            isSignedIn: true,
            hasCompletedProfileSetup: true,
            hasCompletedWalkthrough: true
        )
        XCTAssertFalse(result)
    }

    func test_shouldShowWalkthrough_onboardingNotCompleted_returnsFalse() {
        let result = sut.shouldShowWalkthrough(
            hasCompletedOnboarding: false,
            isSignedIn: true,
            hasCompletedProfileSetup: true,
            hasCompletedWalkthrough: false
        )
        XCTAssertFalse(result)
    }

    func test_shouldShowWalkthrough_notSignedIn_returnsFalse() {
        let result = sut.shouldShowWalkthrough(
            hasCompletedOnboarding: true,
            isSignedIn: false,
            hasCompletedProfileSetup: true,
            hasCompletedWalkthrough: false
        )
        XCTAssertFalse(result)
    }

    func test_shouldShowWalkthrough_profileSetupNotCompleted_returnsFalse() {
        let result = sut.shouldShowWalkthrough(
            hasCompletedOnboarding: true,
            isSignedIn: true,
            hasCompletedProfileSetup: false,
            hasCompletedWalkthrough: false
        )
        XCTAssertFalse(result)
    }

    // MARK: - shouldSkipWalkthroughForReturningUser

    func test_shouldSkipForReturningUser_profileExists_returnsTrue() {
        XCTAssertTrue(sut.shouldSkipWalkthroughForReturningUser(profileExists: true))
    }

    func test_shouldSkipForReturningUser_noProfile_returnsFalse() {
        XCTAssertFalse(sut.shouldSkipWalkthroughForReturningUser(profileExists: false))
    }

    // MARK: - walkthroughCompletionAfterProfileSetup

    func test_walkthroughCompletion_newUser_returnsFalse() {
        let result = sut.walkthroughCompletionAfterProfileSetup(isNewUser: true)
        XCTAssertFalse(result, "New users should not have walkthrough marked as completed")
    }

    func test_walkthroughCompletion_returningUser_returnsTrue() {
        let result = sut.walkthroughCompletionAfterProfileSetup(isNewUser: false)
        XCTAssertTrue(result, "Returning users should have walkthrough marked as completed")
    }
}
