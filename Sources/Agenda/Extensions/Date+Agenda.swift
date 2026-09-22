import Foundation
import CoreGraphics

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }

    /// Minutes elapsed since midnight of the same day — used to place
    /// an activity block at the right vertical offset in the timeline.
    var minutesSinceMidnight: CGFloat {
        let components = Calendar.current.dateComponents([.hour, .minute], from: self)
        return CGFloat((components.hour ?? 0) * 60 + (components.minute ?? 0))
    }

    func roundedToNearest(minutes: Int) -> Date {
        let interval = TimeInterval(minutes * 60)
        let rounded = (timeIntervalSinceReferenceDate / interval).rounded() * interval
        return Date(timeIntervalSinceReferenceDate: rounded)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func formatted(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }
}
