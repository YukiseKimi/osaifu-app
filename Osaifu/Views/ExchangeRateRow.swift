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

    var body: some View {
        LabeledContent("1 \(currencyCode)") {
            HStack(spacing: 6) {
                TextField("rate", text: $text)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
                Text(homeCurrencyCode)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: loadOnce)
        .onChange(of: text) { _, typed in save(typed) }
    }

    private func loadOnce() {
        guard !hasLoaded else { return }
        hasLoaded = true
        guard let rate = try? ExchangeRate.rate(from: currencyCode, to: homeCurrencyCode, in: modelContext) else { return }
        text = rate.formatted(.number.grouping(.never))
    }

    /// An empty field, or text that is not a number, means no rate, and the
    /// expenses in that currency stay out of the totals.
    private func save(_ typed: String) {
        guard hasLoaded else { return }
        let rate = Money.decimal(fromTyped: typed) ?? 0
        _ = try? ExchangeRate.setRate(rate, from: currencyCode, to: homeCurrencyCode, in: modelContext)
        WidgetRefresh.afterChange()
    }
}
