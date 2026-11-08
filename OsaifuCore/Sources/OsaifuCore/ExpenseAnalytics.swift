import Foundation

/// A category's summed amount; one data point in a breakdown or chart.
public struct CategoryTotal: Identifiable, Sendable {
    public let category: ExpenseCategory
    public let total: Money
    public var id: ExpenseCategory { category }
}

/// All spending within a single calendar month, broken down by category.
public struct MonthlySummary: Identifiable, Sendable {
    public let monthStart: Date
    public let categoryTotals: [CategoryTotal]
    public let currencyCode: String
    public var id: Date { monthStart }
    public var total: Money { Money.sum(categoryTotals.map(\.total), in: currencyCode) }
}

/// A single (month, category) data point used by the stacked history chart.
public struct MonthlyCategoryTotal: Identifiable, Sendable {
    public let monthStart: Date
    public let category: ExpenseCategory
    public let total: Money
    public var id: String { "\(monthStart.timeIntervalSinceReferenceDate)-\(category.rawValue)" }
}

/// Pure functions that turn raw `Expense` records into chart-ready aggregates.
///
/// Every function totals one currency and leaves each other currency out, so a
/// total is never the sum of two currencies. `inOtherCurrencies(_:than:)` names
/// what was left out.
public enum ExpenseAnalytics {
    /// Totals per category in one currency, sorted from highest to lowest.
    public static func categoryTotals(for expenses: [Expense], in currencyCode: String) -> [CategoryTotal] {
        Dictionary(grouping: expenses.filter { $0.currencyCode == currencyCode }, by: \.category)
            .map { CategoryTotal(category: $0.key, total: Money.sum($0.value.map(\.money), in: currencyCode)) }
            // The category breaks a tie, so two equal totals keep one order
            // from one redraw to the next.
            .sorted {
                $0.total.minorUnits == $1.total.minorUnits
                    ? $0.category.rawValue < $1.category.rawValue
                    : $0.total.minorUnits > $1.total.minorUnits
            }
    }

    /// The subset of `expenses` falling in the same calendar month as `date`.
    public static func expenses(_ expenses: [Expense], inMonthOf date: Date, calendar: Calendar = .current) -> [Expense] {
        expenses.filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
    }

    /// The expenses that another currency keeps out of the totals.
    public static func inOtherCurrencies(_ expenses: [Expense], than currencyCode: String) -> [Expense] {
        expenses.filter { $0.currencyCode != currencyCode }
    }

    /// One summary per month that has spending, sorted oldest to newest.
    public static func monthlySummaries(
        for expenses: [Expense],
        in currencyCode: String,
        calendar: Calendar = .current
    ) -> [MonthlySummary] {
        Dictionary(grouping: expenses.filter { $0.currencyCode == currencyCode }) {
            startOfMonth($0.date, calendar: calendar)
        }
        .map {
            MonthlySummary(
                monthStart: $0.key,
                categoryTotals: categoryTotals(for: $0.value, in: currencyCode),
                currencyCode: currencyCode
            )
        }
        .sorted { $0.monthStart < $1.monthStart }
    }

    /// Flattened (month, category) data points for a stacked bar chart.
    public static func monthlyCategoryTotals(
        for expenses: [Expense],
        in currencyCode: String,
        calendar: Calendar = .current
    ) -> [MonthlyCategoryTotal] {
        monthlySummaries(for: expenses, in: currencyCode, calendar: calendar).flatMap { summary in
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
