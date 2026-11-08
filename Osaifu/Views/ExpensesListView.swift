import SwiftUI
import SwiftData
import OsaifuCore

/// A chronological list of every expense, grouped into month sections with the
/// newest month first. Tap a row to edit it; swipe to delete.
struct ExpensesListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode = Currency.defaultCode
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var expenseToEdit: Expense?

    /// Expenses grouped by the start of their month, newest month first.
    private var months: [(month: Date, expenses: [Expense])] {
        Dictionary(grouping: expenses) { ExpenseAnalytics.startOfMonth($0.date) }
            .map { (month: $0.key, expenses: $0.value) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        NavigationStack {
            Group {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses Yet",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Expenses you add will be listed here by month.")
                    )
                } else {
                    List {
                        ForEach(months, id: \.month) { group in
                            Section(group.month.formatted(.dateTime.month(.wide).year())) {
                                ForEach(group.expenses) { expense in
                                    Button {
                                        expenseToEdit = expense
                                    } label: {
                                        ExpenseRow(expense: expense, currencyCode: currencyCode)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    delete(group.expenses, at: offsets)
                                }
                            }
                        }
                    }
                }
            }
            .moodBackground()
            .navigationTitle("Expenses")
            #if os(iOS)
            .toolbar { EditButton() }
            #endif
            .sheet(item: $expenseToEdit) { expense in
                ExpenseFormView(expense: expense)
            }
        }
    }

    private func delete(_ groupExpenses: [Expense], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(groupExpenses[index])
        }
    }
}

/// A single expense row: category icon, title, optional note, amount, and date.
private struct ExpenseRow: View {
    let expense: Expense
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: expense.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category.title)
                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount.currencyFormatted(code: currencyCode))
                    .monospacedDigit()
                Text(expense.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}
