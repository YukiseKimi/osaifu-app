import SwiftUI
import SwiftData
import OsaifuCore

/// The month against its limit: what is left, how far the month has gone, and
/// which categories took it. The categories carry no limit of their own.
struct BudgetsView: View {
    @Environment(\.homeCurrencyCode) private var currencyCode
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [Budget]
    @Query private var preferences: [Preferences]
    @Query private var rates: [ExchangeRate]

    /// The newest limit the user has not removed.
    private var budget: Budget? {
        budgets.filter(\.isActive).max { $0.updatedAt < $1.updatedAt }
    }

    private var settings: Preferences? {
        preferences.max { $0.updatedAt < $1.updatedAt }
    }

    private var rateByCurrency: [String: Decimal] {
        Dictionary(
            rates.filter { $0.homeCurrencyCode == currencyCode && $0.isSet }
                .map { ($0.currencyCode, $0.rate) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private var progress: BudgetProgress? {
        guard let budget else { return nil }
        return ExpenseAnalytics.progress(
            limit: budget.limit,
            expenses: allExpenses,
            month: .now,
            carriesRemainderOver: settings?.carriesRemainderOver ?? false,
            countsForeignSpend: settings?.countsForeignSpend ?? false,
            rates: rateByCurrency
        )
    }

    private var monthExpenses: [Expense] {
        ExpenseAnalytics.expenses(allExpenses, inMonthOf: .now)
    }

    private var categoryTotals: [CategoryTotal] {
        ExpenseAnalytics.categoryTotals(for: monthExpenses, in: currencyCode)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let progress {
                    content(progress)
                } else {
                    noLimit
                }
            }
            .moodBackground()
            .navigationTitle("Budget")
        }
    }

    private func content(_ progress: BudgetProgress) -> some View {
        List {
            Section {
                BudgetSummary(progress: progress)
                    .listRowBackground(Color.clear)
            }
            if !categoryTotals.isEmpty {
                Section("Where it went") {
                    ForEach(categoryTotals) { item in
                        CategoryShareRow(item: item, spent: progress.spent)
                    }
                }
            }
            if progress.leftOutCount > 0 {
                Section {
                    Label(
                        "^[\(progress.leftOutCount) expense](inflect: true) in another currency",
                        systemImage: "exclamationmark.circle"
                    )
                    .foregroundStyle(.secondary)
                } footer: {
                    Text("Left out of the total. Settings, under FX Currency, can count them at a rate you give.")
                }
            }
        }
    }

    private var noLimit: some View {
        ContentUnavailableView {
            Label("No Monthly Limit", systemImage: "target")
        } description: {
            Text("Set a limit for the month and this screen shows what is left of it.")
        }
    }
}

/// The one number, with the bar under it.
private struct BudgetSummary: View {
    let progress: BudgetProgress

    private var tint: Color {
        if progress.isOver { return .red }
        return progress.fraction > 0.85 ? .orange : .green
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(Date.now, format: .dateTime.month(.wide).year())
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(progress.remaining.formatted())
                .font(.largeTitle.bold())
                .monospacedDigit()
                .foregroundStyle(progress.isOver ? Color.red : .primary)

            Text(progress.isOver ? "over the limit" : "left of \(progress.limit.formatted())")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: progress.fraction)
                .tint(tint)

            if progress.carriedOver.minorUnits > 0 {
                Text("Includes \(progress.carriedOver.formatted()) carried from last month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

/// One category's share of what the month spent.
private struct CategoryShareRow: View {
    let item: CategoryTotal
    let spent: Money

    private var share: Double {
        spent.minorUnits > 0 ? Double(item.total.minorUnits) / Double(spent.minorUnits) : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: item.category, size: 30)
            VStack(alignment: .leading) {
                Text(item.category.title)
                Text(share, format: .percent.precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(item.total.formatted())
                .monospacedDigit()
        }
    }
}
