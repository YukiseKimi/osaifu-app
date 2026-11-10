import Foundation

/// Turns what the views query into one BudgetProgress, so the Budget tab and
/// the line on This Month cannot drift apart.
public enum BudgetReader {

    /// The newest limit the user has not removed.
    public static func activeBudget(_ budgets: [Budget]) -> Budget? {
        budgets.filter(\.isActive).max { $0.updatedAt < $1.updatedAt }
    }

    /// The rates for the home currency that the user actually filled in.
    public static func rateByCurrency(_ rates: [ExchangeRate], homeCurrencyCode: String) -> [String: Decimal] {
        Dictionary(
            rates.filter { $0.homeCurrencyCode == homeCurrencyCode && $0.isSet }
                .map { ($0.currencyCode, $0.rate) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// The limit that no rate can bring into the home currency, or nil when
    /// there is no such trouble. The Budget screen says so rather than draw a
    /// bar that means nothing.
    public static func limitNeedingRate(
        budgets: [Budget],
        rates: [ExchangeRate],
        homeCurrencyCode: String
    ) -> Money? {
        guard let budget = activeBudget(budgets) else { return nil }
        let converted = ExpenseAnalytics.limitInHomeCurrency(
            budget.limit,
            homeCurrencyCode: homeCurrencyCode,
            rates: rateByCurrency(rates, homeCurrencyCode: homeCurrencyCode)
        )
        return converted == nil ? budget.limit : nil
    }

    /// Where the month stands, or nil when no limit is set, or when the limit
    /// is in a currency this month cannot be measured against.
    public static func progress(
        expenses: [Expense],
        budgets: [Budget],
        preferences: [Preferences],
        rates: [ExchangeRate],
        homeCurrencyCode: String,
        month: Date = .now
    ) -> BudgetProgress? {
        guard let budget = activeBudget(budgets) else { return nil }
        let settings = preferences.max { $0.updatedAt < $1.updatedAt }
        return ExpenseAnalytics.progress(
            limit: budget.limit,
            expenses: expenses,
            month: month,
            homeCurrencyCode: homeCurrencyCode,
            carriesRemainderOver: settings?.carriesRemainderOver ?? false,
            countsForeignSpend: settings?.countsForeignSpend ?? false,
            rates: rateByCurrency(rates, homeCurrencyCode: homeCurrencyCode)
        )
    }
}
