import Foundation

/// A category's summed amount; one data point in a breakdown or chart.
struct CategoryTotal: Identifiable {
    let category: ExpenseCategory
    let total: Double
    var id: ExpenseCategory { category }
}

/// All spending within a single calendar month, broken down by category.
struct MonthlySummary: Identifiable {
    let monthStart: Date
    let categoryTotals: [CategoryTotal]
    var id: Date { monthStart }
    var total: Double { categoryTotals.reduce(0) { $0 + $1.total } }
}

/// A single (month, category) data point used by the stacked history chart.
struct MonthlyCategoryTotal: Identifiable {
    let monthStart: Date
    let category: ExpenseCategory
    let total: Double
    var id: String { "\(monthStart.timeIntervalSinceReferenceDate)-\(category.rawValue)" }
}

/// Pure functions that turn raw `Expense` records into chart-ready aggregates.
enum ExpenseAnalytics {
    /// Totals per category, sorted from highest to lowest spending.
    static func categoryTotals(for expenses: [Expense]) -> [CategoryTotal] {
        Dictionary(grouping: expenses, by: \.category)
            .map { CategoryTotal(category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    /// The subset of `expenses` falling in the same calendar month as `date`.
    static func expenses(_ expenses: [Expense], inMonthOf date: Date, calendar: Calendar = .current) -> [Expense] {
        expenses.filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
    }

    /// One summary per month that has spending, sorted oldest to newest.
    static func monthlySummaries(for expenses: [Expense], calendar: Calendar = .current) -> [MonthlySummary] {
        Dictionary(grouping: expenses) { startOfMonth($0.date, calendar: calendar) }
            .map { MonthlySummary(monthStart: $0.key, categoryTotals: categoryTotals(for: $0.value)) }
            .sorted { $0.monthStart < $1.monthStart }
    }

    /// Flattened (month, category) data points for a stacked bar chart.
    static func monthlyCategoryTotals(for expenses: [Expense], calendar: Calendar = .current) -> [MonthlyCategoryTotal] {
        monthlySummaries(for: expenses, calendar: calendar).flatMap { summary in
            summary.categoryTotals.map {
                MonthlyCategoryTotal(monthStart: summary.monthStart, category: $0.category, total: $0.total)
            }
        }
    }

    /// The first instant of the calendar month containing `date`.
    static func startOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}

extension Double {
    /// Formats the value as currency using the given ISO 4217 currency code.
    func currencyFormatted(code: String) -> String {
        formatted(.currency(code: code))
    }
}
