import Foundation

/// One slice of a pie, or one bar of a chart: what it stands for, and what it
/// spent. The dashboard draws nothing that is not one of these.
public struct SpendBucket: Identifiable, Sendable, Equatable {
    public let id: String
    /// What the chart writes beside the slice or under the bar.
    public let name: String
    /// The month or the year the bucket stands for. On a category bucket it
    /// is the start of the period.
    public let date: Date
    /// Nil on a bar of time, and on the bucket that rolls up the rest.
    public let category: ExpenseCategory?
    public let total: Money

    public init(id: String, name: String, date: Date, category: ExpenseCategory?, total: Money) {
        self.id = id
        self.name = name
        self.date = date
        self.category = category
        self.total = total
    }
}

public extension ExpenseAnalytics {

    /// What one expense is worth in the home currency, or nil when no rate
    /// can carry it there.
    ///
    /// It follows the same two rules as the monthly total: another currency
    /// counts only when the user turned the switch on and gave a rate. So a
    /// chart and the budget never disagree.
    static func homeAmount(
        of expense: Expense,
        homeCurrencyCode: String,
        countsForeignSpend: Bool,
        rates: [String: Decimal]
    ) -> Money? {
        if expense.currencyCode == homeCurrencyCode { return expense.money }
        guard countsForeignSpend, let rate = rates[expense.currencyCode], rate > 0 else { return nil }
        return expense.money.converted(to: homeCurrencyCode, rate: rate)
    }

    /// What each category spent in one period, largest first.
    ///
    /// Eleven slices is not a chart anyone reads, so only the largest
    /// `limit` keep their own slice and the rest become one. The roll-up
    /// bucket carries no category, and it always comes last.
    static func byCategory(
        _ expenses: [Expense],
        in range: DateInterval? = nil,
        homeCurrencyCode: String,
        countsForeignSpend: Bool,
        rates: [String: Decimal],
        limit: Int = 5,
        restName: String = "Other"
    ) -> [SpendBucket] {
        var totals: [ExpenseCategory: Int] = [:]
        for expense in expenses where range?.contains(expense.date) ?? true {
            guard let money = homeAmount(
                of: expense, homeCurrencyCode: homeCurrencyCode,
                countsForeignSpend: countsForeignSpend, rates: rates
            ) else { continue }
            totals[expense.category, default: 0] += money.minorUnits
        }

        let start = range?.start ?? .distantPast
        let sorted = totals
            .filter { $0.value > 0 }
            // The category breaks a tie, so two equal totals keep one order
            // from one redraw to the next.
            .sorted { $0.value == $1.value ? $0.key.rawValue < $1.key.rawValue : $0.value > $1.value }

        var buckets = sorted.prefix(limit).map { category, minorUnits in
            SpendBucket(
                id: category.rawValue,
                name: category.title,
                date: start,
                category: category,
                total: Money(minorUnits: minorUnits, currencyCode: homeCurrencyCode)
            )
        }

        let rest = sorted.dropFirst(limit).reduce(0) { $0 + $1.value }
        if rest > 0 {
            buckets.append(
                SpendBucket(
                    id: "rest",
                    name: restName,
                    date: start,
                    category: nil,
                    total: Money(minorUnits: rest, currencyCode: homeCurrencyCode)
                )
            )
        }
        return buckets
    }

    /// One bar for each month of one year, January to December.
    ///
    /// A month with no expense keeps its bar at zero, so the axis does not
    /// move as the year fills up.
    static func byMonth(
        _ expenses: [Expense],
        of year: Date,
        homeCurrencyCode: String,
        countsForeignSpend: Bool,
        rates: [String: Decimal],
        calendar: Calendar = .current
    ) -> [SpendBucket] {
        let yearNumber = calendar.component(.year, from: year)
        var totals: [Int: Int] = [:]
        for expense in expenses where calendar.component(.year, from: expense.date) == yearNumber {
            guard let money = homeAmount(
                of: expense, homeCurrencyCode: homeCurrencyCode,
                countsForeignSpend: countsForeignSpend, rates: rates
            ) else { continue }
            totals[calendar.component(.month, from: expense.date), default: 0] += money.minorUnits
        }

        return (1...12).compactMap { month in
            guard let start = calendar.date(from: DateComponents(year: yearNumber, month: month, day: 1)) else {
                return nil
            }
            return SpendBucket(
                id: "\(yearNumber)-\(month)",
                name: start.formatted(.dateTime.month(.abbreviated)),
                date: start,
                category: nil,
                total: Money(minorUnits: totals[month] ?? 0, currencyCode: homeCurrencyCode)
            )
        }
    }

    /// One bar for each year that holds an expense, oldest first.
    static func byYear(
        _ expenses: [Expense],
        homeCurrencyCode: String,
        countsForeignSpend: Bool,
        rates: [String: Decimal],
        calendar: Calendar = .current
    ) -> [SpendBucket] {
        var totals: [Int: Int] = [:]
        for expense in expenses {
            guard let money = homeAmount(
                of: expense, homeCurrencyCode: homeCurrencyCode,
                countsForeignSpend: countsForeignSpend, rates: rates
            ) else { continue }
            totals[calendar.component(.year, from: expense.date), default: 0] += money.minorUnits
        }

        return totals.keys.sorted().compactMap { year in
            guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else {
                return nil
            }
            return SpendBucket(
                id: "\(year)",
                name: String(year),
                date: start,
                category: nil,
                total: Money(minorUnits: totals[year] ?? 0, currencyCode: homeCurrencyCode)
            )
        }
    }
}
