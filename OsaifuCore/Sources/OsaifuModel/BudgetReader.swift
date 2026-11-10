import Foundation

/// Turns what the views query into one BudgetProgress, so the Budget tab,
/// the line on This Month, the widget and the watch cannot drift apart.
public enum BudgetReader {

    /// The newest limit the user has not removed.
    public static func activeBudget(_ budgets: [Budget]) -> Budget? {
        budgets.filter(\.isActive).max { $0.updatedAt < $1.updatedAt }
    }

    /// The limit that no rate can bring into the home currency, or nil when
    /// there is no such trouble. The Budget screen says so rather than draw a
    /// bar that means nothing.
    public static func limitNeedingRate(budgets: [Budget], settings: AppSettings) -> Money? {
        guard let budget = activeBudget(budgets) else { return nil }
        let converted = ExpenseAnalytics.limitInHomeCurrency(
            budget.limit,
            homeCurrencyCode: settings.homeCurrencyCode,
            rates: settings.rates
        )
        return converted == nil ? budget.limit : nil
    }

    /// Where the month stands, or nil when no limit is set, or when the limit
    /// is in a currency this month cannot be measured against.
    public static func progress(
        expenses: [Expense],
        budgets: [Budget],
        settings: AppSettings,
        month: Date = .now
    ) -> BudgetProgress? {
        guard let budget = activeBudget(budgets) else { return nil }
        return ExpenseAnalytics.progress(
            limit: budget.limit,
            expenses: expenses,
            month: month,
            homeCurrencyCode: settings.homeCurrencyCode,
            carriesRemainderOver: settings.carriesRemainderOver,
            countsForeignSpend: settings.countsForeignSpend,
            rates: settings.rates
        )
    }
}
