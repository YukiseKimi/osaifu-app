import Foundation

/// Where one month stands against its limit.
public struct BudgetProgress: Sendable, Equatable {
    /// The limit the user set.
    public let baseLimit: Money
    /// What was left of last month, zero while the switch is off.
    public let carriedOver: Money
    /// What this month may spend: the limit plus anything carried over.
    public let limit: Money
    /// What this month has spent, in the home currency.
    public let spent: Money
    /// Expenses this month that no rate could convert, so they are left out.
    public let leftOutCount: Int

    public init(baseLimit: Money, carriedOver: Money, limit: Money, spent: Money, leftOutCount: Int) {
        self.baseLimit = baseLimit
        self.carriedOver = carriedOver
        self.limit = limit
        self.spent = spent
        self.leftOutCount = leftOutCount
    }

    /// What is left. It goes negative once the month is over its limit.
    public var remaining: Money {
        Money(minorUnits: limit.minorUnits - spent.minorUnits, currencyCode: limit.currencyCode)
    }

    /// 0 to 1, for the bar. It stops at 1, and `isOver` says the rest.
    public var fraction: Double {
        guard limit.minorUnits > 0 else { return 0 }
        return min(1, max(0, Double(spent.minorUnits) / Double(limit.minorUnits)))
    }

    public var isOver: Bool { spent.minorUnits > limit.minorUnits }
}

public extension ExpenseAnalytics {

    /// What one month spent in the home currency, and how many of its
    /// expenses no rate could convert.
    ///
    /// An expense in another currency counts only when the user turned the
    /// switch on and gave a rate for that currency. Anything else is left
    /// out and counted, so the screen can say how many.
    static func spend(
        in expenses: [Expense],
        month: Date,
        homeCurrencyCode: String,
        countsForeignSpend: Bool,
        rates: [String: Decimal],
        calendar: Calendar = .current
    ) -> (total: Money, leftOutCount: Int) {
        var minorUnits = 0
        var leftOut = 0
        for expense in self.expenses(expenses, inMonthOf: month, calendar: calendar) {
            if expense.currencyCode == homeCurrencyCode {
                minorUnits += expense.minorUnits
            } else if countsForeignSpend, let rate = rates[expense.currencyCode], rate > 0 {
                minorUnits += expense.money.converted(to: homeCurrencyCode, rate: rate).minorUnits
            } else {
                leftOut += 1
            }
        }
        return (Money(minorUnits: minorUnits, currencyCode: homeCurrencyCode), leftOut)
    }

    /// Where the month stands against the limit.
    ///
    /// A carried remainder reads the month before this one against the same
    /// limit. Only what was left carries: a month that went over does not
    /// follow the user into the next one.
    static func progress(
        limit: Money,
        expenses: [Expense],
        month: Date,
        carriesRemainderOver: Bool,
        countsForeignSpend: Bool,
        rates: [String: Decimal],
        calendar: Calendar = .current
    ) -> BudgetProgress {
        let home = limit.currencyCode
        let thisMonth = spend(
            in: expenses, month: month, homeCurrencyCode: home,
            countsForeignSpend: countsForeignSpend, rates: rates, calendar: calendar
        )

        var carried = Money.zero(home)
        if carriesRemainderOver,
           let lastMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth(month, calendar: calendar)) {
            let before = spend(
                in: expenses, month: lastMonth, homeCurrencyCode: home,
                countsForeignSpend: countsForeignSpend, rates: rates, calendar: calendar
            )
            carried = Money(minorUnits: max(0, limit.minorUnits - before.total.minorUnits), currencyCode: home)
        }

        return BudgetProgress(
            baseLimit: limit,
            carriedOver: carried,
            limit: Money(minorUnits: limit.minorUnits + carried.minorUnits, currencyCode: home),
            spent: thisMonth.total,
            leftOutCount: thisMonth.leftOutCount
        )
    }
}
