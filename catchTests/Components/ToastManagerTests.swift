import XCTest

@MainActor
final class ToastManagerTests: XCTestCase {

    private var sut: ToastManager!

    override func setUp() {
        super.setUp()
        sut = ToastManager(autoDismissDelay: .milliseconds(100))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateHasNoToast() {
        XCTAssertNil(sut.currentToast)
    }

    // MARK: - Show Error

    func testShowErrorSetsCurrentToast() {
        sut.showError("something broke")

        XCTAssertNotNil(sut.currentToast)
        XCTAssertEqual(sut.currentToast?.message, "something broke")
        XCTAssertEqual(sut.currentToast?.style, .error)
    }

    func testShowErrorWithRetryActionSetsRetryAction() {
        var retryCalled = false
        sut.showError("retry me") {
            retryCalled = true
        }

        XCTAssertNotNil(sut.currentToast?.retryAction)
        sut.currentToast?.retryAction?()
        XCTAssertTrue(retryCalled)
    }

    func testShowErrorWithoutRetryActionHasNilRetry() {
        sut.showError("no retry")

        XCTAssertNil(sut.currentToast?.retryAction)
    }

    // MARK: - Show Success

    func testShowSuccessSetsCurrentToast() {
        sut.showSuccess("nice one")

        XCTAssertNotNil(sut.currentToast)
        XCTAssertEqual(sut.currentToast?.message, "nice one")
        XCTAssertEqual(sut.currentToast?.style, .success)
    }

    // MARK: - Show Warning

    func testShowWarningSetsCurrentToast() {
        sut.showWarning("heads up")

        XCTAssertNotNil(sut.currentToast)
        XCTAssertEqual(sut.currentToast?.message, "heads up")
        XCTAssertEqual(sut.currentToast?.style, .warning)
    }

    // MARK: - Dismiss

    func testDismissClearsCurrentToast() {
        sut.showError("error")
        XCTAssertNotNil(sut.currentToast)

        sut.dismiss()
        XCTAssertNil(sut.currentToast)
    }

    // MARK: - Replacement

    func testShowingNewToastReplacesExisting() {
        sut.showError("first")
        let firstID = sut.currentToast?.id

        sut.showError("second")
        let secondID = sut.currentToast?.id

        XCTAssertNotEqual(firstID, secondID)
        XCTAssertEqual(sut.currentToast?.message, "second")
    }

    func testShowingDifferentStyleReplacesExisting() {
        sut.showError("error")
        XCTAssertEqual(sut.currentToast?.style, .error)

        sut.showSuccess("success")
        XCTAssertEqual(sut.currentToast?.style, .success)
        XCTAssertEqual(sut.currentToast?.message, "success")
    }

    // MARK: - Auto-Dismiss

    func testToastAutoDismissesAfterDelay() async {
        sut.showError("temporary")
        XCTAssertNotNil(sut.currentToast)

        // Wait longer than the auto-dismiss delay (100ms in tests)
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertNil(sut.currentToast)
    }

    func testNewToastCancelsPreviousAutoDismissTimer() async {
        sut.showError("first")
        let firstID = sut.currentToast?.id

        // Show second toast before first auto-dismisses
        try? await Task.sleep(for: .milliseconds(50))
        sut.showSuccess("second")
        let secondID = sut.currentToast?.id
        XCTAssertNotEqual(firstID, secondID)

        // Wait past when first timer would have fired, but before second expires
        try? await Task.sleep(for: .milliseconds(80))
        XCTAssertNotNil(sut.currentToast, "Second toast should still be visible — first timer must not dismiss it")
        XCTAssertEqual(sut.currentToast?.id, secondID)

        // Wait for second timer to expire
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertNil(sut.currentToast)
    }

    func testDismissBeforeAutoDismissDoesNotCrash() {
        sut.showError("dismiss early")
        sut.dismiss()
        XCTAssertNil(sut.currentToast)
    }

    // MARK: - Toast Equality

    func testToastEqualityBasedOnID() {
        sut.showError("a")
        let toastA = sut.currentToast

        sut.showError("b")
        let toastB = sut.currentToast

        XCTAssertNotEqual(toastA, toastB)
    }

    func testSameToastIsEqual() {
        sut.showError("same")
        let toast = sut.currentToast

        XCTAssertEqual(toast, toast)
    }
}
