import Foundation
import Synchronization

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

    /// The answers so far. A NumberFormatter costs more than the lookup, and
    /// every row of a list asks for the same few currencies.
    private static let knownMinorDigits = Mutex<[String: Int]>([:])

    /// The minor digits the system records for a currency: 0 for JPY, 2 for USD.
    public static func minorDigits(of currencyCode: String) -> Int {
        knownMinorDigits.withLock { known in
            if let digits = known[currencyCode] { return digits }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            let digits = formatter.maximumFractionDigits
            known[currencyCode] = digits
            return digits
        }
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

    /// The amount as a Double, for a chart axis only. Never add these: a
    /// Double drifts, which is why the store keeps minor units.
    public var plotValue: Double {
        NSDecimalNumber(decimal: decimalValue).doubleValue
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

    /// Reads what a person typed, in their own locale: "1,280.50" in the
    /// United States, "1.280,50" in Germany, "1280" anywhere.
    ///
    /// It returns nil for anything that is not a plain number. Foundation's own
    /// parsers read a valid prefix and stop, which turns "1,280" into 1 and
    /// loses most of the amount without a word.
    public init?(typed text: String, currencyCode: String, locale: Locale = .current) {
        guard let value = Self.decimal(fromTyped: text, locale: locale) else { return nil }
        self.init(decimal: value, currencyCode: currencyCode)
    }

    /// Reads a typed decimal in the reader's locale, with no truncation. It
    /// is public because a typed exchange rate needs the same care.
    public static func decimal(fromTyped text: String, locale: Locale = .current) -> Decimal? {
        var cleaned = text.filter { !$0.isWhitespace }
        guard !cleaned.isEmpty else { return nil }

        if let grouping = locale.groupingSeparator, !grouping.isEmpty {
            cleaned = removingGrouping(cleaned, separator: grouping)
        }

        // Whatever separator is left must be the decimal one, and there can be
        // only one of it.
        guard cleaned.filter({ $0 == "." || $0 == "," }).count <= 1 else { return nil }
        cleaned = cleaned.replacingOccurrences(of: ",", with: ".")

        guard cleaned.wholeMatch(of: /-?\d+(\.\d+)?/) != nil
                || cleaned.wholeMatch(of: /-?\.\d+/) != nil
        else { return nil }

        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Removes a grouping separator only where it truly groups, which is where
    /// three digits follow it. In a locale that groups with a dot, "12.8" is
    /// still twelve point eight, not one hundred and twenty eight.
    static func removingGrouping(_ text: String, separator: String) -> String {
        let parts = text.components(separatedBy: separator)
        guard parts.count > 1 else { return text }

        let head = parts[0].hasPrefix("-") ? String(parts[0].dropFirst()) : parts[0]
        guard (1...3).contains(head.count), head.allSatisfy(\.isNumber) else { return text }
        for part in parts.dropFirst() where part.prefix(while: \.isNumber).count != 3 {
            return text
        }
        return parts.joined()
    }

    /// Adds the amounts in one currency, and leaves every other currency out.
    public static func sum(_ amounts: [Money], in currencyCode: String) -> Money {
        let total = amounts
            .filter { $0.currencyCode == currencyCode }
            .reduce(0) { $0 + $1.minorUnits }
        return Money(minorUnits: total, currencyCode: currencyCode)
    }
}
