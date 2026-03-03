import Foundation

public enum EncounterDateValidationResult: Equatable {
    case valid
    case tooFarInPast
    case inFuture
}

public enum EncounterDateValidator {

    /// Earliest allowed encounter date: January 1, 2020.
    public static let minimumDate: Date = {
        guard let date = DateComponents(calendar: .current, year: 2020, month: 1, day: 1).date else {
            return Date.distantPast
        }
        return date
    }()

    /// Latest allowed encounter date: the current moment.
    public static var maximumDate: Date { Date() }

    /// The allowed date range for encounter date pickers.
    public static var allowedRange: ClosedRange<Date> {
        minimumDate...maximumDate
    }

    /// Validates whether the given date falls within the allowed encounter range.
    public static func validate(_ date: Date) -> EncounterDateValidationResult {
        if date < minimumDate {
            return .tooFarInPast
        }
        if date > Date() {
            return .inFuture
        }
        return .valid
    }
}
