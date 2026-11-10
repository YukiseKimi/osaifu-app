import OsaifuCore
import SwiftData
import SwiftUI

/// The dashboard: the charts that a wide screen has room for. The phone
/// never opens it.
struct DashboardView: View {
    @Environment(\.homeCurrencyCode) private var homeCurrencyCode
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var preferences: [Preferences]
    @Query private var rates: [ExchangeRate]

    @State private var range: SpendRange = .month

    /// The month the user tapped on the chart. It overrules the range for
    /// the pie, and nothing else.
    @State private var chosenMonth: Date?

    private var settings: Preferences? {
        preferences.max { $0.updatedAt < $1.updatedAt }
    }

    private var countsForeignSpend: Bool { settings?.countsForeignSpend ?? false }

    private var rateByCurrency: [String: Decimal] {
        BudgetReader.rateByCurrency(rates, homeCurrencyCode: homeCurrencyCode)
    }

    /// The period the pie draws: the month the user tapped, else the range.
    private var pieInterval: DateInterval? {
        guard let chosenMonth else { return range.interval() }
        return Calendar.current.dateInterval(of: .month, for: chosenMonth)
    }

    private var pieTitle: String {
        guard let chosenMonth else { return "\(range.title), by category" }
        return "\(chosenMonth.formatted(.dateTime.month(.wide).year())), by category"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "Nothing to chart yet",
                        systemImage: "chart.pie",
                        description: Text("Add an expense and the charts fill in.")
                    )
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                        CategoryPie(
                            slices: ExpenseAnalytics.byCategory(
                                expenses,
                                in: pieInterval,
                                homeCurrencyCode: homeCurrencyCode,
                                countsForeignSpend: countsForeignSpend,
                                rates: rateByCurrency
                            ),
                            title: pieTitle
                        )

                        MonthBars(
                            months: ExpenseAnalytics.byMonth(
                                expenses,
                                of: .now,
                                homeCurrencyCode: homeCurrencyCode,
                                countsForeignSpend: countsForeignSpend,
                                rates: rateByCurrency
                            ),
                            title: "Each month of \(Date.now.formatted(.dateTime.year()))",
                            chosen: $chosenMonth
                        )

                        YearBars(
                            years: ExpenseAnalytics.byYear(
                                expenses,
                                homeCurrencyCode: homeCurrencyCode,
                                countsForeignSpend: countsForeignSpend,
                                rates: rateByCurrency
                            )
                        )
                        .gridCellColumns(2)
                    }
                    .padding(16)
                }
            }
            .moodBackground()
            .navigationTitle("Dashboard")
            // A new range is a new question, so the month goes back to none.
            .onChange(of: range) { _, _ in chosenMonth = nil }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker("Range", selection: $range) {
                        ForEach(SpendRange.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}

/// One chart in a box, so the three sit on the page as one set.
struct DashboardCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Expense.self, inMemory: true)
}
