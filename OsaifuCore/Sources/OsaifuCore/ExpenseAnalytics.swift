import Foundation

/// A category's summed amount; one data point in a breakdown or chart.
public struct CategoryTotal: Identifiable, Sendable {
    public let category: ExpenseCategory
    public let total: Double
    public var id: ExpenseCategory { category }
}

/// All spending within a single calendar month, broken down by category.
public struct MonthlySummary: Identifiable, Sendable {
    public let monthStart: Date
    public let categoryTotals: [CategoryTotal]
    public var id: Date { monthStart }
    public var total: Double { categoryTotals.reduce(0) { $0 + $1.total } }
}

/// A single (month, category) data point used by the stacked history chart.
public struct MonthlyCategoryTotal: Identifiable, Sendable {
    public let monthStart: Date
    public let category: ExpenseCategory
    public let total: Double
    public var id: String { "\(monthStart.timeIntervalSinceReferenceDate)-\(category.rawValue)" }
}

/// Pure functions that turn raw `Expense` records into chart-ready aggregates.
public enum ExpenseAnalytics {
    /// Totals per category, sorted from highest to lowest spending.
    public static func categoryTotals(for expenses: [Expense]) -> [CategoryTotal] {
        Dictionary(grouping: expenses, by: \.category)
            .map { CategoryTotal(category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    /// The subset of `expenses` falling in the same calendar month as `date`.
    public static func expenses(_ expenses: [Expense], inMonthOf date: Date, calendar: Calendar = .current) -> [Expense] {
        expenses.filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
    }

    /// One summary per month that has spending, sorted oldest to newest.
    public static func monthlySummaries(for expenses: [Expense], calendar: Calendar = .current) -> [MonthlySummary] {
        Dictionary(grouping: expenses) { startOfMonth($0.date, calendar: calendar) }
            .map { MonthlySummary(monthStart: $0.key, categoryTotals: categoryTotals(for: $0.value)) }
            .sorted { $0.monthStart < $1.monthStart }
    }

    /// Flattened (month, category) data points for a stacked bar chart.
    public static func monthlyCategoryTotals(for expenses: [Expense], calendar: Calendar = .current) -> [MonthlyCategoryTotal] {
        monthlySummaries(for: expenses, calendar: calendar).flatMap { summary in
            summary.categoryTotals.map {
                MonthlyCategoryTotal(monthStart: summary.monthStart, category: $0.category, total: $0.total)
            }
        }
    }

    /// The first instant of the calendar month containing `date`.
    public static func startOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}

extension Double {
    /// Formats the value as currency using the given ISO 4217 currency code.
    public func currencyFormatted(code: String) -> String {
        formatted(.currency(code: code))
    }
}
