import XCTest
@testable import CatchCore

final class PushNotificationErrorTests: XCTestCase {

    func testAuthorizationDeniedDescription() {
        let error = PushNotificationError.authorizationDenied
        XCTAssertEqual(
            error.errorDescription,
            "notification permissions denied — enable in settings"
        )
    }

    func testSubscriptionFailedDescription() {
        let error = PushNotificationError.subscriptionFailed
        XCTAssertEqual(
            error.errorDescription,
            "couldn't set up push notifications"
        )
    }

    func testNotSignedInDescription() {
        let error = PushNotificationError.notSignedIn
        XCTAssertEqual(
            error.errorDescription,
            "sign in to get notified about your cats"
        )
    }

    func testFetchSubscriptionsFailedDescription() {
        let error = PushNotificationError.fetchSubscriptionsFailed
        XCTAssertEqual(
            error.errorDescription,
            "couldn't check existing notification subscriptions"
        )
    }

    func testEquatable() {
        XCTAssertEqual(PushNotificationError.notSignedIn, PushNotificationError.notSignedIn)
        XCTAssertNotEqual(PushNotificationError.notSignedIn, PushNotificationError.subscriptionFailed)
    }
}
