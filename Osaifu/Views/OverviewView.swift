import SwiftUI
import SwiftData
import Charts
import OsaifuCore

/// The current month at a glance: a donut chart of spending by category, the
/// running total, and a per-category list. New expenses are added from here.
struct OverviewView: View {
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Environment(\.homeCurrencyCode) private var currencyCode
    @State private var isAddingExpense = false

    private var monthExpenses: [Expense] {
        ExpenseAnalytics.expenses(allExpenses, inMonthOf: .now)
    }

    private var categoryTotals: [CategoryTotal] {
        ExpenseAnalytics.categoryTotals(for: monthExpenses, in: currencyCode)
    }

    private var monthTotal: Money {
        Money.sum(monthExpenses.map(\.money), in: currencyCode)
    }

    /// Expenses that another currency keeps out of the total.
    private var otherCurrencies: [Expense] {
        ExpenseAnalytics.inOtherCurrencies(monthExpenses, than: currencyCode)
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
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Expense", systemImage: "plus") {
                        isAddingExpense = true
                    }
                }
            }
            .sheet(isPresented: $isAddingExpense) {
                ExpenseFormView()
            }
        }
    }

    private var content: some View {
        List {
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
