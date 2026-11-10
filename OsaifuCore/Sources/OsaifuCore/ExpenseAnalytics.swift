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
    /// Totals per category in the home currency, highest first.
    ///
    /// One currency rule serves every screen: `homeAmount(of:)` decides what
    /// an expense is worth here, so the pie on This Month, the History chart
    /// and the iPad dashboard can never disagree about a month.
    public static func categoryTotals(
        for expenses: [Expense],
        in homeCurrencyCode: String,
        countsForeignSpend: Bool = false,
        rates: [String: Decimal] = [:]
    ) -> [CategoryTotal] {
        var totals: [ExpenseCategory: Int] = [:]
        for expense in expenses {
            guard let money = homeAmount(
                of: expense, homeCurrencyCode: homeCurrencyCode,
                countsForeignSpend: countsForeignSpend, rates: rates
            ) else { continue }
            totals[expense.category, default: 0] += money.minorUnits
        }

        return totals
            .map { CategoryTotal(category: $0.key, total: Money(minorUnits: $0.value, currencyCode: homeCurrencyCode)) }
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

    /// The expenses that no total can count: another currency, and no rate
    /// the user has given carries them into the home currency.
    public static func leftOut(
        _ expenses: [Expense],
        homeCurrencyCode: String,
        countsForeignSpend: Bool = false,
        rates: [String: Decimal] = [:]
    ) -> [Expense] {
        expenses.filter {
            homeAmount(
                of: $0, homeCurrencyCode: homeCurrencyCode,
                countsForeignSpend: countsForeignSpend, rates: rates
            ) == nil
        }
    }

    /// One summary per month that has spending, sorted oldest to newest.
    public static func monthlySummaries(
        for expenses: [Expense],
        in homeCurrencyCode: String,
        countsForeignSpend: Bool = false,
        rates: [String: Decimal] = [:],
        calendar: Calendar = .current
    ) -> [MonthlySummary] {
        Dictionary(grouping: expenses) { startOfMonth($0.date, calendar: calendar) }
            .map { month, expenses in
                MonthlySummary(
                    monthStart: month,
                    categoryTotals: categoryTotals(
                        for: expenses, in: homeCurrencyCode,
                        countsForeignSpend: countsForeignSpend, rates: rates
                    ),
                    currencyCode: homeCurrencyCode
                )
            }
            // A month whose every expense was left out has nothing to show.
            .filter { !$0.categoryTotals.isEmpty }
            .sorted { $0.monthStart < $1.monthStart }
    }

    /// Flattened (month, category) data points for a stacked bar chart.
    public static func monthlyCategoryTotals(
        for expenses: [Expense],
        in homeCurrencyCode: String,
        countsForeignSpend: Bool = false,
        rates: [String: Decimal] = [:],
        calendar: Calendar = .current
    ) -> [MonthlyCategoryTotal] {
        monthlySummaries(
            for: expenses, in: homeCurrencyCode,
            countsForeignSpend: countsForeignSpend, rates: rates, calendar: calendar
        ).flatMap { summary in
            summary.categoryTotals.map {
                MonthlyCategoryTotal(monthStart: summary.monthStart, category: $0.category, total: $0.total)
            }
        }
    }

    /// The categories this user picks most, most used first.
    ///
    /// It counts the expenses of the last `days` days, so a change of habit
    /// shows within a month. When those do not fill `limit` places, the rest
    /// of the list follows in its own order, so the pad always has four
    /// chips to show, even on a first launch.
    public static func favouriteCategories(
        for expenses: [Expense],
        within days: Int = 30,
        limit: Int = 4,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ExpenseCategory] {
        let since = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        let counts = expenses
            .filter { $0.date >= since && $0.date <= now }
            .reduce(into: [ExpenseCategory: Int]()) { counts, expense in
                counts[expense.category, default: 0] += 1
            }

        let used = counts
            .sorted { left, right in
                left.value == right.value
                    ? left.key.rawValue < right.key.rawValue
                    : left.value > right.value
            }
            .map(\.key)

        let rest = ExpenseCategory.allCases.filter { !used.contains($0) }
        return Array((used + rest).prefix(limit))
    }

    /// The first instant of the calendar month containing `date`.
    public static func startOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}
