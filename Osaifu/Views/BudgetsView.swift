import SwiftUI
import SwiftData
import OsaifuModel

/// The month against its limit: what is left, how far the month has gone, and
/// which categories took it. The categories carry no limit of their own.
struct BudgetsView: View {
    @Environment(\.settings) private var settings
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [Budget]
    @State private var isEditingLimit = false

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

    /// The newest limit the user has not removed.
    private var budget: Budget? { BudgetReader.activeBudget(budgets) }

    private var progress: BudgetProgress? {
        BudgetReader.progress(
            expenses: allExpenses, budgets: budgets, settings: settings
        )
    }

    private var monthExpenses: [Expense] {
        ExpenseAnalytics.expenses(allExpenses, inMonthOf: .now)
    }

    private var categoryTotals: [CategoryTotal] {
        ExpenseAnalytics.categoryTotals(
            for: monthExpenses, in: settings.homeCurrencyCode,
            countsForeignSpend: settings.countsForeignSpend, rates: settings.rates
        )
    }

    /// A limit set while another currency was home, which no rate can bring
    /// across. The screen says so rather than draw a bar that means nothing.
    private var limitNeedingRate: Money? {
        BudgetReader.limitNeedingRate(budgets: budgets, settings: settings)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let progress {
                    content(progress)
                } else if let staleLimit = limitNeedingRate {
                    limitInAnotherCurrency(staleLimit)
                } else {
                    noLimit
                }
            }
            .moodBackground()
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(budget == nil ? "Set a Limit" : "Edit", systemImage: budget == nil ? "plus" : "pencil") {
                        isEditingLimit = true
                    }
                }
            }
            .sheet(isPresented: $isEditingLimit) {
                BudgetLimitView(budget: latestBudget)
            }
        }
    }

    /// The row to edit, even when the user removed its limit, so the amount
    /// they had comes back in the field.
    private var latestBudget: Budget? {
        budgets.max { $0.updatedAt < $1.updatedAt }
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

    /// The limit and the home currency no longer match, so there is no honest
    /// figure to draw until the user gives a rate or sets a new limit.
    private func limitInAnotherCurrency(_ limit: Money) -> some View {
        ContentUnavailableView {
            Label("Limit in Another Currency", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Your limit is \(limit.formatted()), and your home currency is now \(settings.homeCurrencyCode). Give a rate for \(limit.currencyCode) in Settings, or set a new limit.")
        } actions: {
            Button("Set a New Limit") { isEditingLimit = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var noLimit: some View {
        ContentUnavailableView {
            Label("No Monthly Limit", systemImage: "target")
        } description: {
            Text("Set a limit for the month and this screen shows what is left of it.")
        } actions: {
            Button("Set a Limit") { isEditingLimit = true }
                .buttonStyle(.borderedProminent)
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
