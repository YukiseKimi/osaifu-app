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
                VStack(alignment: .trailing, spacing: 2) {
                    Text(progress.isOver
                         ? Money(minorUnits: -progress.remaining.minorUnits, currencyCode: progress.remaining.currencyCode).formatted()
                         : progress.remaining.formatted())
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(progress.isOver ? Color.red : .green)

                    // A month is too large a number to act on at the till.
                    // The watch has said what today has left since the day it
                    // shipped; there was no reason the phone should not.
                    // A month that is over has nothing left today, and saying
                    // "0 left today" under a red figure only says it twice.
                    if !progress.isOver {
                        Text("\(progress.leftToday().formatted()) left today")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}
