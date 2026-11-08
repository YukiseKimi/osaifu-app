import SwiftUI
import SwiftData
import OsaifuCore

/// App preferences: appearance, the display currency, plus developer-friendly
/// tools for populating and clearing sample data.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncMonitor.self) private var sync
    @Environment(\.homeCurrencyCode) private var currencyCode
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @Query private var expenses: [Expense]

    @State private var showingDeleteConfirmation = false

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
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceRaw) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Picker("Home currency", selection: homeCurrency) {
                        ForEach(currencies) { currency in
                            Text("\(currency.symbol)  \(currency.code) — \(currency.localizedName)")
                                .tag(currency.code)
                        }
                    }
                } header: {
                    Text("Currency")
                } footer: {
                    Text("Totals and budgets use the home currency. An expense keeps the currency you entered it in.")
                }
                Section {
                    LabeledContent("Sync") {
                        HStack(spacing: 6) {
                            SyncBadge(account: sync.account)
                            Text(sync.title)
                                .foregroundStyle(sync.account.syncs ? Color.green : .secondary)
                        }
                    }
                    LabeledContent("Last change") {
                        if let lastChange = sync.lastChange {
                            Text(lastChange, format: .relative(presentation: .named))
                        } else {
                            Text("No expenses yet")
                        }
                    }
                } header: {
                    Text("iCloud")
                } footer: {
                    Text("Osaifu keeps your expenses in your private iCloud database. iCloud decides when it sends them, so a change can take a moment to reach another device.")
                }
                Section("Preview") {
                    LabeledContent("Example", value: Money(minorUnits: 123456, currencyCode: currencyCode).formatted())
                }
                Section {
                    Button {
                        SampleData.insert(into: modelContext, currencyCode: currencyCode)
                    } label: {
                        Label("Add Sample Data", systemImage: "wand.and.stars")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete All Expenses", systemImage: "trash")
                    }
                    .disabled(expenses.isEmpty)
                } header: {
                    Text("Data")
                } footer: {
                    Text("Sample data adds randomized expenses across the last several months for trying out the charts.")
                }
            }
            .moodBackground()
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all expenses?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All (\(expenses.count))", role: .destructive, action: deleteAll)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every expense and can't be undone.")
            }
        }
    }

    /// Writes the pick to the synced settings row.
    private var homeCurrency: Binding<String> {
        Binding(
            get: { currencyCode },
            set: { code in
                guard let row = try? Preferences.current(in: modelContext, fallbackCurrencyCode: code) else { return }
                row.setHomeCurrencyCode(code)
            }
        )
    }

    private func deleteAll() {
        for expense in expenses {
            modelContext.delete(expense)
        }
    }
}
