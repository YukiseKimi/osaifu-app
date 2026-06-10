import SwiftUI
import SwiftData
import Charts

/// The current month at a glance: a donut chart of spending by category, the
/// running total, and a per-category list. New expenses are added from here.
struct OverviewView: View {
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @AppStorage("currencyCode") private var currencyCode = Currency.defaultCode
    @State private var isAddingExpense = false

    private var monthExpenses: [Expense] {
        ExpenseAnalytics.expenses(allExpenses, inMonthOf: .now)
    }

    private var categoryTotals: [CategoryTotal] {
        ExpenseAnalytics.categoryTotals(for: monthExpenses)
    }

    private var monthTotal: Double {
        monthExpenses.reduce(0) { $0 + $1.amount }
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
                    CategoryRow(item: item, monthTotal: monthTotal, currencyCode: currencyCode)
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
                    angle: .value("Amount", item.total),
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
                    Text(monthTotal.currencyFormatted(code: currencyCode))
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
    let monthTotal: Double
    let currencyCode: String

    private var share: Double {
        monthTotal > 0 ? item.total / monthTotal : 0
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
            Text(item.total.currencyFormatted(code: currencyCode))
                .monospacedDigit()
        }
    }
}
