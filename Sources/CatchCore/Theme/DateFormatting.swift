import Foundation

public enum DateFormatting {

    /// Formats an encounter date: relative time for today ("2 hours ago"), "Month Day" for older dates.
    public static func encounterDate(_ date: Date, relativeTo now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(.relative(presentation: .named))
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    /// Formats an encounter date with time: relative for today, "Month Day, Time" for older dates.
    public static func encounterDateTime(_ date: Date, relativeTo now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(.relative(presentation: .named))
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
}
