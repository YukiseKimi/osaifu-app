import SwiftUI
import SwiftData
import OsaifuCore

/// The fast way in: an amount on a keypad, a category from four chips, Save.
/// The date, the note and any other currency live behind More.
struct QuickEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.settings) private var settings
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    @State private var typed = ""
    @State private var category: ExpenseCategory?
    @State private var isShowingForm = false

    /// The four the user picks most, so the common expense is one tap.
    private var chips: [ExpenseCategory] {
        ExpenseAnalytics.favouriteCategories(for: allExpenses)
    }

    private var chosen: ExpenseCategory? { category ?? chips.first }

    private var money: Money? { Money(typed: typed, currencyCode: settings.homeCurrencyCode) }

    private var isValid: Bool { (money?.minorUnits ?? 0) > 0 }

    private var separator: String { Locale.current.decimalSeparator ?? "." }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                amount
                chipRow
                keypad
                saveButton
            }
            .padding()
            .moodBackground()
            .navigationTitle("New Expense")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("More") { isShowingForm = true }
                }
            }
            .sheet(isPresented: $isShowingForm) {
                ExpenseFormView(initialAmountText: typed, initialCategory: chosen)
            }
        }
    }

    private var amount: some View {
        VStack(spacing: 2) {
            Text(typed.isEmpty ? "0" : typed)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: typed)
            Text(settings.homeCurrencyCode)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Amount \(typed.isEmpty ? "0" : typed) \(settings.homeCurrencyCode)")
    }

    private var chipRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(chips) { option in
                    Button {
                        category = option
                    } label: {
                        Label(option.title, systemImage: option.systemImage)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(chosen == option ? option.color : .secondary)
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var keypad: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], [separator, "0", "\u{232B}"]], id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { key in
                        Button { press(key) } label: {
                            Text(key)
                                .font(.title2)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel(key == "\u{232B}" ? "Delete" : key)
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button("Save", action: save)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(!isValid)
    }

    private func press(_ key: String) {
        switch key {
        case "\u{232B}":
            if !typed.isEmpty { typed.removeLast() }
        case separator:
            guard !typed.contains(separator) else { return }
            typed += typed.isEmpty ? "0\(separator)" : separator
        default:
            typed += key
        }
    }

    private func save() {
        guard let money, money.minorUnits > 0, let chosen else { return }
        modelContext.insert(Expense(money: money, category: chosen))
        // SwiftData writes on its own schedule. An expense the user has
        // just added must not wait for it: the app can be killed first.
        try? modelContext.save()
        WidgetRefresh.afterChange()
        dismiss()
    }
}
