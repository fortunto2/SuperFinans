//
//  Date+Extensions.swift
//  SuperFinans
//
//  Date helper extensions.
//

import Foundation

extension Date {
    /// Start of the current month
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    /// End of the current month
    var endOfMonth: Date {
        guard let interval = Calendar.current.dateInterval(of: .month, for: self) else { return self }
        return interval.end.addingTimeInterval(-1)
    }

    /// Start of the current day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Months from now
    func monthsFromNow() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: Date(), to: self)
        return max(components.month ?? 0, 0)
    }

    /// Add months
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Format as "Jan 2025"
    var monthYearFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: self)
    }

    /// Format as "Jan 15, 2025"
    var mediumFormatted: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    /// Format as relative date ("Today", "Yesterday", "Jan 15")
    var relativeFormatted: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            return mediumFormatted
        }
    }

    /// Group key for transactions list (e.g., "2025-01-15")
    var dateGroupKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    /// Whether this date is in the current month
    var isCurrentMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
}
