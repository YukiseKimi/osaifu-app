import SwiftUI
import SwiftData
import OsaifuModel
import OsaifuSync

/// The two questions the app cannot answer for itself, asked once.
///
/// Which currency the totals are in, and what the month may spend. Both
/// already have an answer — the device's currency, and no limit at all — so
/// this is a confirmation and not a form, and it can be waved away.
///
/// The limit is here because it is what the app is for. Without one, This
/// Month can only say what has gone; with one, it says what is left, and
/// what is left today. It sat behind a tab and an empty state, which is a
/// poor place for the first thing a person should do.
struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currencyCode = Currency.defaultCode
    @State private var limitText = ""

    /// Every currency the picker offers, with the device's own at the top
    /// when the curated list does not already name it.
    private var currencies: [Currency] {
        if Currency.common.contains(where: { $0.code == currencyCode }) {
            return Currency.common
        }
        return [Currency(code: currencyCode, symbol: currencyCode)] + Currency.common
    }

    private var limit: Money? {
        Money(typed: limitText, currencyCode: currencyCode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Home currency", selection: $currencyCode) {
                        ForEach(currencies) { currency in
                            Text("\(currency.symbol)  \(currency.code)").tag(currency.code)
                        }
                    }
                    .accessibilityIdentifier(A11yID.Welcome.currency)
                } header: {
                    Text("Currency")
                } footer: {
                    Text("Totals and budgets use this. An expense keeps the currency you entered it in.")
                }

                Section {
                    TextField("Amount", text: $limitText)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                        .accessibilityIdentifier(A11yID.Welcome.limit)
                } header: {
                    Text("Monthly limit (\(currencyCode))")
                } footer: {
                    Text("Osaifu then says what is left of the month, and what is left today. Leave it empty if you would rather not set one; Budget can set it later.")
                }
            }
            .navigationTitle("Welcome to Osaifu")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start", action: start)
                        .accessibilityIdentifier(A11yID.Welcome.start)
                }
            }
            .moodBackground()
            .interactiveDismissDisabled()
        }
    }

    /// Writes both answers, and saves: the widget and the complication read
    /// the store on disk, and a person who sets a limit here and force-quits
    /// should not come back to find no limit.
    private func start() {
        if let row = try? Preferences.current(in: modelContext, fallbackCurrencyCode: currencyCode) {
            row.setHomeCurrencyCode(currencyCode)
        }
        if let limit, limit.minorUnits > 0 {
            _ = try? Budget.setLimit(limit, in: modelContext)
        }
        try? modelContext.save()
        WidgetRefresh.afterChange()
        dismiss()
    }
}

#Preview {
    WelcomeView()
        .modelContainer(for: Expense.self, inMemory: true)
}
