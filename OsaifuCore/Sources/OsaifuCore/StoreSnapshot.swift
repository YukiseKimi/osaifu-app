import Foundation
import SwiftData

/// What a widget needs from the store, read in one go.
///
/// The Home Screen widget and the watch complication each used to carry
/// their own copy of this, which is how two widgets can disagree.
public struct StoreSnapshot: Sendable, Equatable {
    /// The currency the figures are in.
    public let homeCurrencyCode: String
    /// What the month has spent.
    public let spent: Money
    /// Where the month stands, or nil when the user has set no limit, or
    /// when the limit is in a currency this month cannot be measured against.
    public let progress: BudgetProgress?

    public init(homeCurrencyCode: String, spent: Money, progress: BudgetProgress?) {
        self.homeCurrencyCode = homeCurrencyCode
        self.spent = spent
        self.progress = progress
    }

    /// What is left of the month, or nil with no limit to be left of.
    public var remaining: Money? { progress?.remaining }
}

public extension StoreSnapshot {

    /// An empty snapshot, for a widget that cannot reach the store. It shows
    /// zero rather than nothing, so the Home Screen never sits blank.
    static func empty(now: Date = .now) -> StoreSnapshot {
        StoreSnapshot(
            homeCurrencyCode: Currency.defaultCode,
            spent: Money.zero(Currency.defaultCode),
            progress: nil
        )
    }

    /// Reads the shared store once.
    @MainActor
    static func read(now: Date = .now) -> StoreSnapshot {
        guard let container = try? StoreSetup.makeContainer() else { return .empty(now: now) }
        let context = ModelContext(container)
        return make(
            expenses: (try? context.fetch(FetchDescriptor<Expense>())) ?? [],
            budgets: (try? context.fetch(FetchDescriptor<Budget>())) ?? [],
            preferences: (try? context.fetch(FetchDescriptor<Preferences>())) ?? [],
            rates: (try? context.fetch(FetchDescriptor<ExchangeRate>())) ?? [],
            now: now
        )
    }

    /// The same, from rows already in hand. It opens nothing, so it takes
    /// tests with no store and no simulator.
    static func make(
        expenses: [Expense],
        budgets: [Budget],
        preferences: [Preferences],
        rates: [ExchangeRate],
        now: Date = .now
    ) -> StoreSnapshot {
        let settings = preferences.max { $0.updatedAt < $1.updatedAt }
        let home = settings.map(\.homeCurrencyCode).flatMap { $0.isEmpty ? nil : $0 }
            ?? Currency.defaultCode

        let progress = BudgetReader.progress(
            expenses: expenses, budgets: budgets, preferences: preferences,
            rates: rates, homeCurrencyCode: home, month: now
        )

        let spent = progress?.spent ?? ExpenseAnalytics.spend(
            in: expenses, month: now, homeCurrencyCode: home,
            countsForeignSpend: settings?.countsForeignSpend ?? false,
            rates: BudgetReader.rateByCurrency(rates, homeCurrencyCode: home)
        ).total

        return StoreSnapshot(homeCurrencyCode: home, spent: spent, progress: progress)
    }
}
