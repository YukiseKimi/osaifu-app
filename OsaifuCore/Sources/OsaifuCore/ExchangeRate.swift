import Foundation
import SwiftData

/// What one unit of another currency is worth in the home currency.
///
/// The user types it. Nothing is fetched, so the number is theirs and the app
/// works with no network. A rate of 155 means one unit of `currencyCode` is
/// 155 units of `homeCurrencyCode`.
@Model
public final class ExchangeRate {
    public var currencyCode: String = ""
    public var homeCurrencyCode: String = ""
    public var rate: Decimal = 0
    public var updatedAt: Date = Date.now

    public init(currencyCode: String, homeCurrencyCode: String, rate: Decimal) {
        self.currencyCode = currencyCode
        self.homeCurrencyCode = homeCurrencyCode
        self.rate = rate
        self.updatedAt = .now
    }

    /// True while the rate says nothing, which is how a row starts.
    public var isSet: Bool { rate > 0 }
}

public extension ExchangeRate {
    /// Every rate the user has given, newest first for each pair.
    static func all(in context: ModelContext) throws -> [ExchangeRate] {
        try context.fetch(FetchDescriptor<ExchangeRate>(sortBy: [SortDescriptor(\.currencyCode)]))
    }

    /// The rate for one pair, or nil when the user has not given one.
    static func rate(from currencyCode: String, to homeCurrencyCode: String, in context: ModelContext) throws -> Decimal? {
        let row = try all(in: context).first {
            $0.currencyCode == currencyCode && $0.homeCurrencyCode == homeCurrencyCode && $0.isSet
        }
        return row?.rate
    }

    /// Writes the rate for one pair, making the row when there is none.
    @discardableResult
    static func setRate(_ rate: Decimal, from currencyCode: String, to homeCurrencyCode: String, in context: ModelContext) throws -> ExchangeRate {
        let rows = try all(in: context).filter {
            $0.currencyCode == currencyCode && $0.homeCurrencyCode == homeCurrencyCode
        }
        if let row = rows.first {
            row.rate = rate
            row.updatedAt = .now
            for duplicate in rows.dropFirst() { context.delete(duplicate) }
            try context.save()
            return row
        }
        let made = ExchangeRate(currencyCode: currencyCode, homeCurrencyCode: homeCurrencyCode, rate: rate)
        context.insert(made)
        try context.save()
        return made
    }
}

public extension Money {
    /// This amount in the home currency, at the given rate.
    ///
    /// It rounds once, at the end, to the home currency's minor units.
    func converted(to homeCurrencyCode: String, rate: Decimal) -> Money {
        guard currencyCode != homeCurrencyCode else { return self }
        return Money(decimal: decimalValue * rate, currencyCode: homeCurrencyCode)
    }
}
