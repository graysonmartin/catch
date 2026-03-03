import XCTest
@testable import CatchCore

final class TextInputLimitsTests: XCTestCase {

    // MARK: - Constants

    func testCatNameLimitIs50() {
        XCTAssertEqual(TextInputLimits.catName, 50)
    }

    func testCatNotesLimitIs500() {
        XCTAssertEqual(TextInputLimits.catNotes, 500)
    }

    func testEncounterNotesLimitIs500() {
        XCTAssertEqual(TextInputLimits.encounterNotes, 500)
    }

    func testBioLimitIs300() {
        XCTAssertEqual(TextInputLimits.bio, 300)
    }

    func testCommentLimitIs500() {
        XCTAssertEqual(TextInputLimits.comment, 500)
    }

    // MARK: - remaining(text:limit:)

    func testRemainingWithEmptyText() {
        XCTAssertEqual(TextInputLimits.remaining(text: "", limit: 50), 50)
    }

    func testRemainingWithPartialText() {
        XCTAssertEqual(TextInputLimits.remaining(text: "hello", limit: 50), 45)
    }

    func testRemainingAtExactLimit() {
        let text = String(repeating: "a", count: 50)
        XCTAssertEqual(TextInputLimits.remaining(text: text, limit: 50), 0)
    }

    func testRemainingBeyondLimitClampsToZero() {
        let text = String(repeating: "a", count: 60)
        XCTAssertEqual(TextInputLimits.remaining(text: text, limit: 50), 0)
    }

    // MARK: - isAtLimit(text:limit:)

    func testIsAtLimitReturnsFalseWhenUnder() {
        XCTAssertFalse(TextInputLimits.isAtLimit(text: "hi", limit: 50))
    }

    func testIsAtLimitReturnsTrueAtExactLimit() {
        let text = String(repeating: "x", count: 50)
        XCTAssertTrue(TextInputLimits.isAtLimit(text: text, limit: 50))
    }

    func testIsAtLimitReturnsTrueWhenOver() {
        let text = String(repeating: "x", count: 55)
        XCTAssertTrue(TextInputLimits.isAtLimit(text: text, limit: 50))
    }

    // MARK: - shouldShowCount(text:limit:)

    func testShouldShowCountReturnsFalseWhenWellBelow() {
        let text = String(repeating: "a", count: 10)
        XCTAssertFalse(TextInputLimits.shouldShowCount(text: text, limit: 500))
    }

    func testShouldShowCountReturnsFalseJustBelowThreshold() {
        // 90% of 500 = 450 characters. 449 should be below threshold.
        let text = String(repeating: "a", count: 449)
        XCTAssertFalse(TextInputLimits.shouldShowCount(text: text, limit: 500))
    }

    func testShouldShowCountReturnsTrueAtThreshold() {
        // 90% of 500 = 450 characters
        let text = String(repeating: "a", count: 450)
        XCTAssertTrue(TextInputLimits.shouldShowCount(text: text, limit: 500))
    }

    func testShouldShowCountReturnsTrueAboveThreshold() {
        let text = String(repeating: "a", count: 480)
        XCTAssertTrue(TextInputLimits.shouldShowCount(text: text, limit: 500))
    }

    func testShouldShowCountReturnsTrueAtLimit() {
        let text = String(repeating: "a", count: 500)
        XCTAssertTrue(TextInputLimits.shouldShowCount(text: text, limit: 500))
    }

    func testShouldShowCountReturnsFalseForZeroLimit() {
        XCTAssertFalse(TextInputLimits.shouldShowCount(text: "hello", limit: 0))
    }

    func testShouldShowCountWithSmallLimit() {
        // 90% of 50 = 45
        let text = String(repeating: "a", count: 45)
        XCTAssertTrue(TextInputLimits.shouldShowCount(text: text, limit: 50))
    }

    func testShouldShowCountWithSmallLimitBelowThreshold() {
        let text = String(repeating: "a", count: 44)
        XCTAssertFalse(TextInputLimits.shouldShowCount(text: text, limit: 50))
    }

    // MARK: - enforceLimit(text:limit:)

    func testEnforceLimitReturnsTextWhenUnder() {
        let text = "hello"
        XCTAssertEqual(TextInputLimits.enforceLimit(text: text, limit: 50), "hello")
    }

    func testEnforceLimitReturnsTextAtExactLimit() {
        let text = String(repeating: "a", count: 50)
        XCTAssertEqual(TextInputLimits.enforceLimit(text: text, limit: 50), text)
    }

    func testEnforceLimitTruncatesWhenOver() {
        let text = String(repeating: "a", count: 55)
        let result = TextInputLimits.enforceLimit(text: text, limit: 50)
        XCTAssertEqual(result.count, 50)
        XCTAssertEqual(result, String(repeating: "a", count: 50))
    }

    func testEnforceLimitPreservesContentUpToLimit() {
        let text = "abcdefghij" // 10 chars
        let result = TextInputLimits.enforceLimit(text: text, limit: 5)
        XCTAssertEqual(result, "abcde")
    }

    func testEnforceLimitWithEmptyText() {
        XCTAssertEqual(TextInputLimits.enforceLimit(text: "", limit: 50), "")
    }
}
