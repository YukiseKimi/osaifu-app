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

    @State private var amount: Double = 0
    @State private var category: ExpenseCategory = .food
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var hasLoaded = false

    private var isEditing: Bool { expense != nil }
    private var isValid: Bool { amount > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount (\(currencyCode))") {
                    TextField("Amount", value: $amount, format: .number)
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
        amount = expense.amount
        category = expense.category
        date = expense.date
        note = expense.note
    }

    private func save() {
        guard amount > 0 else { return }
        if let expense {
            // Edit in place; SwiftData autosaves and syncs the change.
            expense.amount = amount
            expense.category = category
            expense.date = date
            expense.note = note
        } else {
            modelContext.insert(Expense(amount: amount, category: category, note: note, date: date))
        }
        dismiss()
    }
}
