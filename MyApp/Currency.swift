import Foundation

/// A selectable currency used to format every amount in the app.
struct Currency: Identifiable, Hashable {
    let code: String
    let symbol: String

    var id: String { code }

    /// The localized currency name, e.g. "Japanese Yen".
    var localizedName: String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    /// The currency code used before the user picks one, taken from the device locale.
    static let defaultCode = Locale.current.currency?.identifier ?? "USD"

    /// A curated list of common currencies offered in Settings.
    static let common: [Currency] = [
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
