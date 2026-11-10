import SwiftUI
import SwiftData
import OsaifuCore

/// One line at the top of This Month: what is left of the limit, or how far
/// the month has gone over it. It draws nothing while no limit is set.
struct BudgetLine: View {
    @Environment(\.homeCurrencyCode) private var currencyCode
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [Budget]
    @Query private var preferences: [Preferences]
    @Query private var rates: [ExchangeRate]

    private var progress: BudgetProgress? {
        BudgetReader.progress(
            expenses: allExpenses, budgets: budgets, preferences: preferences,
            rates: rates, homeCurrencyCode: currencyCode
        )
    }

    var body: some View {
        if let progress {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.isOver ? "Over by" : "Left this month")
                        .font(.subheadline)
                    Text("Of \(progress.limit.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(progress.isOver
                     ? Money(minorUnits: -progress.remaining.minorUnits, currencyCode: progress.remaining.currencyCode).formatted()
                     : progress.remaining.formatted())
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(progress.isOver ? Color.red : .green)
            }
        }
    }
}
