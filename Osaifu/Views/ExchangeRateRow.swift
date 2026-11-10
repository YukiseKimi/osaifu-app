import SwiftUI
import SwiftData
import OsaifuCore

/// One typed rate: how many units of the home currency one unit of another
/// currency is worth. The user types it, and nothing is fetched.
struct ExchangeRateRow: View {
    @Environment(\.modelContext) private var modelContext
    let currencyCode: String
    let homeCurrencyCode: String

    @State private var text = ""
    @State private var hasLoaded = false

    /// What is in the store, so a field the user opened and left alone
    /// writes nothing.
    @State private var saved = ""

    @FocusState private var isFocused: Bool

    var body: some View {
        LabeledContent("1 \(currencyCode)") {
            HStack(spacing: 6) {
                TextField("rate", text: $text)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .focused($isFocused)
                    .onSubmit(commit)
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
                Text(homeCurrencyCode)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: loadOnce)
        // A rate is written when the user finishes with the field, not on
        // each key: every write is a row in the store and a push to iCloud,
        // and "155" is three of them.
        .onChange(of: isFocused) { _, focused in
            if !focused { commit() }
        }
        .onDisappear(perform: commit)
    }

    private func loadOnce() {
        guard !hasLoaded else { return }
        hasLoaded = true
        guard let rate = try? ExchangeRate.rate(from: currencyCode, to: homeCurrencyCode, in: modelContext) else { return }
        text = rate.formatted(.number.grouping(.never))
        saved = text
    }

    /// An empty field, or text that is not a number, means no rate, and the
    /// expenses in that currency stay out of the totals.
    private func commit() {
        guard hasLoaded, text != saved else { return }
        saved = text
        let rate = Money.decimal(fromTyped: text) ?? 0
        _ = try? ExchangeRate.setRate(rate, from: currencyCode, to: homeCurrencyCode, in: modelContext)
        WidgetRefresh.afterChange()
    }
}
