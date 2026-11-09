import Foundation
import OsaifuCore

/// Turns what the views query into one BudgetProgress, so the Budget tab and
/// the line on This Month cannot drift apart.
enum BudgetReader {

    /// The newest limit the user has not removed.
    static func activeBudget(_ budgets: [Budget]) -> Budget? {
        budgets.filter(\.isActive).max { $0.updatedAt < $1.updatedAt }
    }

    /// The rates for the home currency that the user actually filled in.
    static func rateByCurrency(_ rates: [ExchangeRate], homeCurrencyCode: String) -> [String: Decimal] {
        Dictionary(
            rates.filter { $0.homeCurrencyCode == homeCurrencyCode && $0.isSet }
                .map { ($0.currencyCode, $0.rate) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// Where the month stands, or nil when no limit is set.
    static func progress(
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
            carriesRemainderOver: settings?.carriesRemainderOver ?? false,
            countsForeignSpend: settings?.countsForeignSpend ?? false,
            rates: rateByCurrency(rates, homeCurrencyCode: homeCurrencyCode)
        )
    }
}
