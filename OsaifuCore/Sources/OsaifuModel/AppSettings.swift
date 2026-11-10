import Foundation

/// Everything the app's own settings decide, as one value.
///
/// It is `AppSettings` rather than `Settings` because SwiftUI already has a
/// `Settings` scene on the Mac, and the two names collide there.
///
/// It exists because the same three questions — which currency are the
/// totals in, does a remainder carry over, does another currency count —
/// were answered in eleven places across the app, the widgets and the
/// watch, each with its own copy of the rules. Two of those copies had
/// already drifted apart. One type answers them once.
public struct AppSettings: Sendable, Equatable {

    /// The currency that totals and budgets are in. An expense keeps the
    /// currency it was entered in, which can differ from this one.
    public let homeCurrencyCode: String

    /// Off: each month starts at the full limit.
    public let carriesRemainderOver: Bool

    /// Off: an expense in another currency stays out of the totals.
    public let countsForeignSpend: Bool

    /// The rates the user filled in for this home currency, by the currency
    /// they convert from.
    public let rates: [String: Decimal]

    public init(
        homeCurrencyCode: String,
        carriesRemainderOver: Bool = false,
        countsForeignSpend: Bool = false,
        rates: [String: Decimal] = [:]
    ) {
        self.homeCurrencyCode = homeCurrencyCode
        self.carriesRemainderOver = carriesRemainderOver
        self.countsForeignSpend = countsForeignSpend
        self.rates = rates
    }
}

public extension AppSettings {

    /// Reads the rows that every screen already queries.
    ///
    /// Two devices with no network can each make their own settings row, and
    /// CloudKit then delivers both. The row that changed last wins, which is
    /// the same answer on every device.
    static func from(
        preferences: [Preferences],
        rates: [ExchangeRate] = [],
        fallbackCurrencyCode: String = Preferences.legacyCurrencyCode()
    ) -> AppSettings {
        let newest = preferences.max { $0.updatedAt < $1.updatedAt }
        let code = newest.map(\.homeCurrencyCode).flatMap { $0.isEmpty ? nil : $0 }
            ?? fallbackCurrencyCode

        return AppSettings(
            homeCurrencyCode: code,
            carriesRemainderOver: newest?.carriesRemainderOver ?? false,
            countsForeignSpend: newest?.countsForeignSpend ?? false,
            rates: ratesByCurrency(rates, homeCurrencyCode: code)
        )
    }

    /// The rates for one home currency that the user actually filled in.
    static func ratesByCurrency(
        _ rates: [ExchangeRate],
        homeCurrencyCode: String
    ) -> [String: Decimal] {
        Dictionary(
            rates.filter { $0.homeCurrencyCode == homeCurrencyCode && $0.isSet }
                .map { ($0.currencyCode, $0.rate) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// What one expense is worth here, or nil when no rate carries it.
    func amount(of expense: Expense) -> Money? {
        ExpenseAnalytics.homeAmount(
            of: expense,
            homeCurrencyCode: homeCurrencyCode,
            countsForeignSpend: countsForeignSpend,
            rates: rates
        )
    }
}
