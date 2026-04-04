import XCTest
@testable import CatchCore

final class DateFormattingTests: XCTestCase {

    // MARK: - encounterDate

    func testEncounterDateTodayReturnsToday() {
        let now = Date()
        let twoHoursAgo = now.addingTimeInterval(-2 * 3600)

        let result = DateFormatting.encounterDate(twoHoursAgo, relativeTo: now)

        XCTAssertEqual(result, CatchStrings.Common.today,
                       "Expected 'today' for same-day encounter, got: \(result)")
    }

    func testEncounterDateYesterdayReturnsMonthDay() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -2, to: now)!

        let result = DateFormatting.encounterDate(yesterday, relativeTo: now)

        // Should NOT contain "today" — should be formatted as "Month Day"
        XCTAssertNotEqual(result, CatchStrings.Common.today,
                          "Expected month/day format for older date, got: \(result)")
    }

    // MARK: - encounterDateTime

    func testEncounterDateTimeTodayReturnsToday() {
        let now = Date()
        let thirtyMinutesAgo = now.addingTimeInterval(-30 * 60)

        let result = DateFormatting.encounterDateTime(thirtyMinutesAgo, relativeTo: now)

        XCTAssertEqual(result, CatchStrings.Common.today,
                       "Expected 'today' for same-day encounter, got: \(result)")
    }

    func testEncounterDateTimeOlderReturnsFullDateTime() {
        let now = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!

        let result = DateFormatting.encounterDateTime(threeDaysAgo, relativeTo: now)

        XCTAssertNotEqual(result, CatchStrings.Common.today,
                          "Expected date+time format for older date, got: \(result)")
    }

    func testEncounterDateJustNowReturnsToday() {
        let now = Date()

        let result = DateFormatting.encounterDate(now, relativeTo: now)

        XCTAssertEqual(result, CatchStrings.Common.today,
                       "Expected 'today' for current moment, got: \(result)")
    }
}
