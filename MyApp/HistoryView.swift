import SwiftUI
import SwiftData
import Charts

/// Month-by-month spending history: a stacked bar chart across months plus a
/// per-month, per-category breakdown below it.
struct HistoryView: View {
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @AppStorage("currencyCode") private var currencyCode = Currency.defaultCode

    private var summaries: [MonthlySummary] {
        ExpenseAnalytics.monthlySummaries(for: allExpenses)
    }

    private var chartRows: [MonthlyCategoryTotal] {
        ExpenseAnalytics.monthlyCategoryTotals(for: allExpenses)
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
                        }
                        ForEach(summaries.reversed()) { summary in
                            Section(summary.monthStart.formatted(.dateTime.month(.wide).year())) {
                                ForEach(summary.categoryTotals) { item in
                                    HStack {
                                        Image(systemName: item.category.systemImage)
                                            .foregroundStyle(item.category.color)
                                            .frame(width: 28)
                                        Text(item.category.title)
                                        Spacer()
                                        Text(item.total.currencyFormatted(code: currencyCode))
                                            .monospacedDigit()
                                    }
                                }
                                HStack {
                                    Text("Total").bold()
                                    Spacer()
                                    Text(summary.total.currencyFormatted(code: currencyCode))
                                        .bold()
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private var chart: some View {
        Chart(chartRows) { row in
            BarMark(
                x: .value("Month", row.monthStart, unit: .month),
                y: .value("Amount", row.total)
            )
            .foregroundStyle(by: .value("Category", row.category.title))
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
