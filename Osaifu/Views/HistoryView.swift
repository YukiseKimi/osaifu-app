import SwiftUI
import SwiftData
import Charts
import OsaifuCore

/// Month-by-month spending history: a stacked bar chart across months plus a
/// per-month, per-category breakdown below it.
struct HistoryView: View {
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Environment(\.homeCurrencyCode) private var currencyCode

    @Query private var preferences: [Preferences]
    @Query private var rates: [ExchangeRate]

    /// The one settings row decides whether another currency counts.
    private var countsForeignSpend: Bool {
        preferences.max { $0.updatedAt < $1.updatedAt }?.countsForeignSpend ?? false
    }

    private var rateByCurrency: [String: Decimal] {
        BudgetReader.rateByCurrency(rates, homeCurrencyCode: currencyCode)
    }

    private var summaries: [MonthlySummary] {
        ExpenseAnalytics.monthlySummaries(
            for: allExpenses, in: currencyCode,
            countsForeignSpend: countsForeignSpend, rates: rateByCurrency
        )
    }

    private var chartRows: [MonthlyCategoryTotal] {
        ExpenseAnalytics.monthlyCategoryTotals(
            for: allExpenses, in: currencyCode,
            countsForeignSpend: countsForeignSpend, rates: rateByCurrency
        )
    }

    /// Categories that actually appear in the data, in a stable order, so the
    /// chart's colors and legend stay consistent.
    private var usedCategories: [ExpenseCategory] {
        ExpenseCategory.allCases.filter { category in
            chartRows.contains { $0.category == category }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if summaries.isEmpty {
                    ContentUnavailableView(
                        "No History Yet",
                        systemImage: "calendar",
                        description: Text("Your monthly spending appears here once you add expenses.")
                    )
                } else {
                    List {
                        Section("Monthly Spending") {
                            chart
                                .listRowBackground(Color.clear)
                        }
                        ForEach(summaries.reversed()) { summary in
                            Section(summary.monthStart.formatted(.dateTime.month(.wide).year())) {
                                ForEach(summary.categoryTotals) { item in
                                    HStack(spacing: 12) {
                                        CategoryIcon(category: item.category, size: 30)
                                        Text(item.category.title)
                                        Spacer()
                                        Text(item.total.formatted())
                                            .monospacedDigit()
                                    }
                                }
                                HStack {
                                    Text("Total").bold()
                                    Spacer()
                                    Text(summary.total.formatted())
                                        .bold()
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }
            }
            .moodBackground()
            .navigationTitle("History")
        }
    }

    private var chart: some View {
        Chart(chartRows) { row in
            BarMark(
                x: .value("Month", row.monthStart, unit: .month),
                y: .value("Amount", row.total.plotValue)
            )
            .foregroundStyle(by: .value("Category", row.category.title))
            .cornerRadius(4)
        }
        .chartForegroundStyleScale(
            domain: usedCategories.map(\.title),
            range: usedCategories.map(\.color)
        )
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .frame(height: 260)
        .padding(.vertical, 8)
    }
}
