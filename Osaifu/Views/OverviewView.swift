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

    /// Color used for the glow halo behind the donut (largest category).
    private var glowColor: Color {
        categoryTotals.first?.category.color ?? .appAccent
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
                chart
                    .listRowBackground(Color.clear)
            }
            Section("Categories") {
                ForEach(categoryTotals) { item in
                    CategoryRow(item: item, monthTotal: monthTotal)
                }
            }
            if !otherCurrencies.isEmpty {
                Section {
                    ForEach(otherCurrencies) { expense in
                        HStack(spacing: 12) {
                            CategoryIcon(category: expense.category, size: 30)
                            Text(expense.category.title)
                            Spacer()
                            Text(expense.money.formatted())
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text("Other Currencies")
                } footer: {
                    Text("These are left out of the total, because a total of two currencies would be wrong.")
                }
            }
        }
    }

    private var chart: some View {
        VStack(spacing: 12) {
            Text(Date.now, format: .dateTime.month(.wide).year())
                .font(.headline)
                .foregroundStyle(.secondary)
            Chart(categoryTotals) { item in
                SectorMark(
                    angle: .value("Amount", item.total.plotValue),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value("Category", item.category.title))
            }
            .chartForegroundStyleScale(
                domain: categoryTotals.map(\.category.title),
                range: categoryTotals.map(\.category.color)
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
