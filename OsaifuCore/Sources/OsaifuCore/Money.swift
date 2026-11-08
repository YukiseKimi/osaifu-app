import Foundation

/// An amount of money: whole minor units, and the currency they are in.
///
/// 1280 minor units is ¥1,280 in JPY, which has no minor digits, and $12.80 in
/// USD, which has two. The app stores minor units, so a sum of expenses is
/// exact. A `Double` drifts: 0.1 + 0.2 is not 0.3.
public struct Money: Hashable, Sendable {
    public let minorUnits: Int
    public let currencyCode: String

    public init(minorUnits: Int, currencyCode: String) {
        self.minorUnits = minorUnits
        self.currencyCode = currencyCode
    }

    public static func zero(_ currencyCode: String) -> Money {
        Money(minorUnits: 0, currencyCode: currencyCode)
    }

    /// The minor digits the system records for a currency: 0 for JPY, 2 for USD.
    public static func minorDigits(of currencyCode: String) -> Int {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.maximumFractionDigits
    }

    public var minorDigits: Int { Self.minorDigits(of: currencyCode) }

    /// The amount as a decimal: 12.80 for 1280 USD minor units.
    public var decimalValue: Decimal {
        Decimal(
            sign: minorUnits < 0 ? .minus : .plus,
            exponent: -minorDigits,
            significand: Decimal(abs(minorUnits))
        )
    }

    /// The amount in the reader's locale, with the currency symbol.
    public func formatted() -> String {
        decimalValue.formatted(.currency(code: currencyCode))
    }

    /// Rounds a decimal amount to the currency's minor units.
    public init(decimal: Decimal, currencyCode: String) {
        var scaled = decimal * pow(Decimal(10), Self.minorDigits(of: currencyCode))
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        self.init(
            minorUnits: NSDecimalNumber(decimal: rounded).intValue,
            currencyCode: currencyCode
        )
    }

    /// Reads what a person typed, such as "12.8" or "1,280". Returns nil for
    /// anything that is not a number.
    public init?(typed text: String, currencyCode: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let value = Decimal(string: trimmed, locale: .current) ?? Decimal(string: trimmed) else {
            return nil
        }
        self.init(decimal: value, currencyCode: currencyCode)
    }

    /// Adds the amounts in one currency, and leaves every other currency out.
    public static func sum(_ amounts: [Money], in currencyCode: String) -> Money {
        let total = amounts
            .filter { $0.currencyCode == currencyCode }
            .reduce(0) { $0 + $1.minorUnits }
        return Money(minorUnits: total, currencyCode: currencyCode)
    }
}
