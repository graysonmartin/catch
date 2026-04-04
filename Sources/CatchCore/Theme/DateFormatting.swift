import Foundation

public enum DateFormatting {

    /// Formats an encounter date: "today" for same-day encounters, "Month Day" for older dates.
    public static func encounterDate(_ date: Date, relativeTo now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) {
            return CatchStrings.Common.today
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    /// Formats an encounter date with time: "today" for same-day, "Month Day, Time" for older dates.
    public static func encounterDateTime(_ date: Date, relativeTo now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) {
            return CatchStrings.Common.today
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
}
