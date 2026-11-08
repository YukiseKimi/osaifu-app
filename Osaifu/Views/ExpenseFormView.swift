import SwiftUI
import SwiftData
import OsaifuCore

/// A form for creating a new expense or editing an existing one.
///
/// Pass an existing `Expense` to edit it in place; pass nothing to add a new
/// one. Field edits are kept in local state and only committed on Save, so
/// Cancel discards any changes.
struct ExpenseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = Currency.defaultCode

    /// The expense being edited, or `nil` when adding a new one.
    var expense: Expense?

    @State private var amountText: String = ""
    @State private var category: ExpenseCategory = .food
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var editingCurrency: String = ""
    @State private var hasLoaded = false

    private var isEditing: Bool { expense != nil }

    /// An expense keeps the currency it was entered in. A new one takes the
    /// home currency.
    private var activeCurrency: String {
        editingCurrency.isEmpty ? currencyCode : editingCurrency
    }

    private var typedMoney: Money? {
        Money(typed: amountText, currencyCode: activeCurrency)
    }

    private var isValid: Bool { (typedMoney?.minorUnits ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount (\(activeCurrency))") {
                    TextField("Amount", text: $amountText)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }
                }
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note (optional)", text: $note)
                }
            }
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    /// Copies the edited expense's values into the form fields exactly once.
    private func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        guard let expense else { return }
        amountText = expense.money.decimalValue.formatted(.number.grouping(.never))
        editingCurrency = expense.currencyCode
        category = expense.category
        date = expense.date
        note = expense.note
    }

    private func save() {
        guard let money = typedMoney, money.minorUnits > 0 else { return }
        if let expense {
            // Edit in place; SwiftData autosaves and syncs the change.
            expense.money = money
            expense.category = category
            expense.date = date
            expense.note = note
            expense.updatedAt = .now
        } else {
            modelContext.insert(Expense(money: money, category: category, note: note, date: date))
        }
        dismiss()
    }
}
