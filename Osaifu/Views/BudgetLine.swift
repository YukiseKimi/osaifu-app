import SwiftUI
import SwiftData
import OsaifuModel

/// One line at the top of This Month: what is left of the limit, or how far
/// the month has gone over it. It draws nothing while no limit is set.
struct BudgetLine: View {
    @Environment(\.settings) private var settings
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [Budget]

    /// This month's figures need this month and a little before it, not five
    /// years of rows. The window is fixed when the screen is made.
    init() {
        let since = ExpenseAnalytics.windowStart()
        _allExpenses = Query(
            filter: #Predicate<Expense> { $0.date >= since },
            sort: \Expense.date,
            order: .reverse
        )
    }

    private var progress: BudgetProgress? {
        BudgetReader.progress(
            expenses: allExpenses, budgets: budgets, settings: settings
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
