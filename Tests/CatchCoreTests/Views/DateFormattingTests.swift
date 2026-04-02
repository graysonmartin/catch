import XCTest
@testable import CatchCore

final class DateFormattingTests: XCTestCase {

    // MARK: - encounterDate

    func testEncounterDateTodayReturnsRelativeTime() {
        let now = Date()
        let twoHoursAgo = now.addingTimeInterval(-2 * 3600)

        let result = DateFormatting.encounterDate(twoHoursAgo, relativeTo: now)

        // Relative format produces strings like "2 hours ago"
        XCTAssertTrue(result.contains("ago") || result.contains("now"),
                      "Expected relative time for today, got: \(result)")
    }

    func testEncounterDateYesterdayReturnsMonthDay() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -2, to: now)!

        let result = DateFormatting.encounterDate(yesterday, relativeTo: now)

        // Should NOT contain "ago" — should be formatted as "Month Day"
        XCTAssertFalse(result.contains("ago"),
                       "Expected month/day format for older date, got: \(result)")
    }

    // MARK: - encounterDateTime

    func testEncounterDateTimeTodayReturnsRelativeTime() {
        let now = Date()
        let thirtyMinutesAgo = now.addingTimeInterval(-30 * 60)

        let result = DateFormatting.encounterDateTime(thirtyMinutesAgo, relativeTo: now)

        XCTAssertTrue(result.contains("ago") || result.contains("now"),
                      "Expected relative time for today, got: \(result)")
    }

    func testEncounterDateTimeOlderReturnsFullDateTime() {
        let now = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!

        let result = DateFormatting.encounterDateTime(threeDaysAgo, relativeTo: now)

        // Should not contain "ago" — should be a full date/time string
        XCTAssertFalse(result.contains("ago"),
                       "Expected date+time format for older date, got: \(result)")
    }

    func testEncounterDateJustNowReturnsRelative() {
        let now = Date()

        let result = DateFormatting.encounterDate(now, relativeTo: now)

        // "now" should produce relative time
        XCTAssertTrue(result.contains("now") || result.contains("second") || result.contains("ago"),
                      "Expected relative time for current moment, got: \(result)")
    }
}
