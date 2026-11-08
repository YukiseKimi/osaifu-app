import SwiftUI
import SwiftData
import OsaifuCore

/// App preferences: appearance, the display currency, plus developer-friendly
/// tools for populating and clearing sample data.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode = Currency.defaultCode
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
                Section("Currency") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies) { currency in
                            Text("\(currency.symbol)  \(currency.code) — \(currency.localizedName)")
                                .tag(currency.code)
                        }
                    }
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

    private func deleteAll() {
        for expense in expenses {
            modelContext.delete(expense)
        }
    }
}
