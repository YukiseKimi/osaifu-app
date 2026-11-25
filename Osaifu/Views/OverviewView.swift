import SwiftUI
import SwiftData
import Charts
import OsaifuModel
import OsaifuUI

/// The current month at a glance: a donut chart of spending by category, the
/// running total, and a per-category list. New expenses are added from here.
struct OverviewView: View {
    @Environment(SyncMonitor.self) private var sync
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Environment(\.settings) private var settings
    @State private var isAddingExpense = false

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

    private var monthExpenses: [Expense] {
        ExpenseAnalytics.expenses(allExpenses, inMonthOf: .now)
    }

    private var categoryTotals: [CategoryTotal] {
        ExpenseAnalytics.categoryTotals(
            for: monthExpenses, in: settings.homeCurrencyCode,
            countsForeignSpend: settings.countsForeignSpend, rates: settings.rates
        )
    }

    private var monthTotal: Money {
        ExpenseAnalytics.spend(
            in: monthExpenses, month: .now, homeCurrencyCode: settings.homeCurrencyCode,
            countsForeignSpend: settings.countsForeignSpend, rates: settings.rates
        ).total
    }

    /// Expenses no total can count: another currency, and no rate for it.
    private var otherCurrencies: [Expense] {
        ExpenseAnalytics.leftOut(
            monthExpenses, homeCurrencyCode: settings.homeCurrencyCode,
            countsForeignSpend: settings.countsForeignSpend, rates: settings.rates
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if monthExpenses.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(A11yID.Overview.list)
            .moodBackground()
            .navigationTitle("This Month")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    SyncBadge(account: sync.account, isConnecting: sync.isConnecting)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Expense", systemImage: "plus") {
                        isAddingExpense = true
                    }
                    .accessibilityIdentifier(A11yID.Overview.add)
                }
            }
            .sheet(isPresented: $isAddingExpense) {
                QuickEntryView()
            }
        }
    }

    private var content: some View {
        List {
            if sync.showsNotice {
                Section {
                    SyncNotice(account: sync.account)
                }
                .listRowBackground(Color.clear)
            }
            Section {
                BudgetLine()
            }
            Section {
                OverviewChart(totals: categoryTotals, monthTotal: monthTotal)
                    .listRowBackground(Color.clear)
            }
            Section("Categories") {
                ForEach(categoryTotals) { item in
                    CategoryRow(item: item, monthTotal: monthTotal)
                }
            }
            if !otherCurrencies.isEmpty {
                Section {
                    OtherCurrenciesSection(expenses: otherCurrencies)
                } header: {
                    Text("Other Currencies")
                } footer: {
                    Text("These are left out of the total, because a total of two currencies would be wrong.")
                }
            }
        }
    }

    private var emptyState: some View {
        // The budget line belongs here too: a month with no expense yet is
        // exactly when "you have this much to spend" is worth reading.
        VStack(spacing: 20) {
            BudgetLine()
                .padding(.horizontal)
            emptyMessage
        }
    }

    private var emptyMessage: some View {
        ContentUnavailableView {
            Label("No Expenses Yet", systemImage: "chart.pie")
        } description: {
            Text("Tap the + button to add your first expense for this month.")
        } actions: {
            Button("Add Expense") { isAddingExpense = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

/// The donut chart of this month's spending, the total in the hole, and the
/// glow halo behind the chart in the largest category's color.
private struct OverviewChart: View {
    let totals: [CategoryTotal]
    let monthTotal: Money

    /// Color used for the glow halo behind the donut (largest category).
    private var glowColor: Color {
        totals.first?.category.color ?? .appAccent
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(Date.now, format: .dateTime.month(.wide).year())
                .font(.headline)
                .foregroundStyle(.secondary)
            Chart(totals) { item in
                SectorMark(
                    angle: .value("Amount", item.total.plotValue),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value("Category", item.category.title.localizedInApp))
            }
            .chartForegroundStyleScale(
                domain: totals.map(\.category.title.localizedInApp),
                range: totals.map(\.category.color)
            )
            .chartLegend(.hidden)
            .frame(height: 240)
            .background {
                Circle()
                    .fill(RadialGradient(
                        colors: [glowColor.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 150
                    ))
                    .blur(radius: 28)
            }
            .overlay {
                VStack {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(monthTotal.formatted())
                        .font(.title2.bold())
                        .glow(glowColor, radius: 4)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

/// The expenses that no total can count, listed so the user can still see them.
private struct OtherCurrenciesSection: View {
    let expenses: [Expense]

    var body: some View {
        ForEach(expenses) { expense in
            HStack(spacing: 12) {
                CategoryIcon(category: expense.category, size: 30)
                Text(expense.category.title.localizedInApp)
                Spacer()
                Text(expense.money.formatted())
                    .monospacedDigit()
            }
        }
    }
}

/// One row in the category breakdown list, showing the category, its share of
/// the month's total, and its amount.
private struct CategoryRow: View {
    let item: CategoryTotal
    let monthTotal: Money

    private var share: Double {
        monthTotal.minorUnits > 0 ? Double(item.total.minorUnits) / Double(monthTotal.minorUnits) : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: item.category)
            VStack(alignment: .leading) {
                Text(item.category.title.localizedInApp)
                Text(share, format: .percent.precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(item.total.formatted())
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(A11yID.Overview.categoryRow(item.category.rawValue))
        .accessibilityValue(item.total.formatted())
    }
}
