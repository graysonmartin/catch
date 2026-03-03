import XCTest
@testable import CatchCore

final class EncounterDateValidatorTests: XCTestCase {

    // MARK: - Minimum date

    func test_minimumDate_isJanuary1_2020() {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: EncounterDateValidator.minimumDate)
        XCTAssertEqual(components.year, 2020)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 1)
    }

    // MARK: - Maximum date

    func test_maximumDate_isCloseToNow() {
        let now = Date()
        let maxDate = EncounterDateValidator.maximumDate
        let interval = abs(now.timeIntervalSince(maxDate))
        XCTAssertLessThan(interval, 1.0, "maximumDate should be within 1 second of now")
    }

    // MARK: - Allowed range

    func test_allowedRange_startsAtMinimumDate() {
        XCTAssertEqual(EncounterDateValidator.allowedRange.lowerBound, EncounterDateValidator.minimumDate)
    }

    func test_allowedRange_endsAtApproximatelyNow() {
        let now = Date()
        let upperBound = EncounterDateValidator.allowedRange.upperBound
        let interval = abs(now.timeIntervalSince(upperBound))
        XCTAssertLessThan(interval, 1.0)
    }

    // MARK: - Validation: valid dates

    func test_validate_today_returnsValid() {
        XCTAssertEqual(EncounterDateValidator.validate(Date()), .valid)
    }

    func test_validate_recentPastDate_returnsValid() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertEqual(EncounterDateValidator.validate(yesterday), .valid)
    }

    func test_validate_minimumDate_returnsValid() {
        XCTAssertEqual(EncounterDateValidator.validate(EncounterDateValidator.minimumDate), .valid)
    }

    func test_validate_dateIn2021_returnsValid() {
        let date = DateComponents(calendar: .current, year: 2021, month: 6, day: 15).date!
        XCTAssertEqual(EncounterDateValidator.validate(date), .valid)
    }

    // MARK: - Validation: too far in past

    func test_validate_before2020_returnsTooFarInPast() {
        let oldDate = DateComponents(calendar: .current, year: 2019, month: 12, day: 31).date!
        XCTAssertEqual(EncounterDateValidator.validate(oldDate), .tooFarInPast)
    }

    func test_validate_year1800_returnsTooFarInPast() {
        let ancientDate = DateComponents(calendar: .current, year: 1800, month: 1, day: 1).date!
        XCTAssertEqual(EncounterDateValidator.validate(ancientDate), .tooFarInPast)
    }

    func test_validate_year2000_returnsTooFarInPast() {
        let date = DateComponents(calendar: .current, year: 2000, month: 3, day: 15).date!
        XCTAssertEqual(EncounterDateValidator.validate(date), .tooFarInPast)
    }

    // MARK: - Validation: future dates

    func test_validate_tomorrow_returnsInFuture() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertEqual(EncounterDateValidator.validate(tomorrow), .inFuture)
    }

    func test_validate_year3000_returnsInFuture() {
        let farFuture = DateComponents(calendar: .current, year: 3000, month: 1, day: 1).date!
        XCTAssertEqual(EncounterDateValidator.validate(farFuture), .inFuture)
    }

    func test_validate_nextYear_returnsInFuture() {
        let nextYear = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        XCTAssertEqual(EncounterDateValidator.validate(nextYear), .inFuture)
    }
}
