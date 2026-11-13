import Foundation

/// A selectable currency used to format every amount in the app.
public struct Currency: Identifiable, Hashable, Sendable {
    public let code: String
    public let symbol: String

    public init(code: String, symbol: String) {
        self.code = code
        self.symbol = symbol
    }

    public var id: String { code }

    /// The localized currency name, e.g. "Japanese Yen".
    public var localizedName: String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    /// The currency code used before the user picks one, taken from the device locale.
    public static let defaultCode = Locale.current.currency?.identifier ?? "USD"

    /// The sign for one currency code, for a face that has room for a glyph
    /// and not a word: "¥", "$", "£".
    ///
    /// A watch complication showed a yen sign whatever the home currency was,
    /// which told a reader in dollars the wrong thing about their own money.
    /// A currency this list does not name shows its code instead, which is
    /// three characters and never wrong.
    public static func symbol(forCode code: String) -> String {
        common.first { $0.code == code }?.symbol ?? code
    }

    /// A curated list of common currencies offered in Settings.
    public static let common: [Currency] = [
        Currency(code: "USD", symbol: "$"),
        Currency(code: "EUR", symbol: "€"),
        Currency(code: "GBP", symbol: "£"),
        Currency(code: "JPY", symbol: "¥"),
        Currency(code: "CNY", symbol: "¥"),
        Currency(code: "KRW", symbol: "₩"),
        Currency(code: "INR", symbol: "₹"),
        Currency(code: "CAD", symbol: "$"),
        Currency(code: "AUD", symbol: "$"),
        Currency(code: "SGD", symbol: "$"),
        Currency(code: "HKD", symbol: "$"),
        Currency(code: "CHF", symbol: "CHF"),
    ]
}
