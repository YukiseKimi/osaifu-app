import SwiftUI
import SwiftData
import OsaifuCore

/// Sets the limit for the month, changes it, or takes it away.
///
/// Taking it away keeps the amount, so setting one again offers it back.
struct BudgetLimitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.settings) private var settings

    /// The limit as it stands, or nil when there is none yet.
    var budget: Budget?

    @State private var amountText = ""
    @State private var hasLoaded = false

    private var typedLimit: Money? {
        Money(typed: amountText, currencyCode: settings.homeCurrencyCode)
    }

    private var isValid: Bool { (typedLimit?.minorUnits ?? 0) > 0 }

    private var hasLimit: Bool { budget?.isActive == true }

    var body: some View {
        NavigationStack {
            Form {
                Section("Limit (\(settings.homeCurrencyCode))") {
                    TextField("Amount", text: $amountText)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                }
                if hasLimit {
                    Section {
                        Button("Remove the limit", role: .destructive, action: remove)
                    } footer: {
                        Text("The expenses stay. The amount is kept, so setting a limit again offers it back.")
                    }
                }
            }
            .navigationTitle(hasLimit ? "Monthly Limit" : "New Limit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!isValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: loadOnce)
        }
    }

    /// A removed limit keeps its amount, so the field offers it again.
    private func loadOnce() {
        guard !hasLoaded else { return }
        hasLoaded = true
        guard let budget, budget.limitMinorUnits > 0 else { return }
        amountText = budget.limit.decimalValue.formatted(.number.grouping(.never))
    }

    private func save() {
        guard let limit = typedLimit, limit.minorUnits > 0 else { return }
        _ = try? Budget.setLimit(limit, in: modelContext)
        WidgetRefresh.afterChange()
        dismiss()
    }

    private func remove() {
        try? Budget.removeLimit(in: modelContext)
        WidgetRefresh.afterChange()
        dismiss()
    }
}
