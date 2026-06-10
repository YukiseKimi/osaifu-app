import SwiftUI

/// App preferences. Currently lets the user choose the currency used to format
/// every amount throughout the app.
struct SettingsView: View {
    @AppStorage("currencyCode") private var currencyCode = Currency.defaultCode

    /// The currency choices, always including the current selection so the
    /// picker can highlight it even if it isn't in the curated list.
    private var currencies: [Currency] {
        if Currency.common.contains(where: { $0.code == currencyCode }) {
            return Currency.common
        }
        return Currency.common + [Currency(code: currencyCode, symbol: currencyCode)]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Currency") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies) { currency in
                            Text("\(currency.symbol)  \(currency.code) — \(currency.localizedName)")
                                .tag(currency.code)
                        }
                    }
                }
                Section("Preview") {
                    LabeledContent("Example", value: 1234.56.currencyFormatted(code: currencyCode))
                }
            }
            .navigationTitle("Settings")
        }
    }
}
