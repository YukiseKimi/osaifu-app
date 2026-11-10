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

    private var settings: Preferences? {
        preferences.max { $0.updatedAt < $1.updatedAt }
    }

    private var countsForeignSpend: Bool { settings?.countsForeignSpend ?? false }

    private var rateByCurrency: [String: Decimal] {
        BudgetReader.rateByCurrency(rates, homeCurrencyCode: homeCurrencyCode)
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
                                in: range.interval(),
                                homeCurrencyCode: homeCurrencyCode,
                                countsForeignSpend: countsForeignSpend,
                                rates: rateByCurrency
                            ),
                            title: "\(range.title), by category"
                        )
                    }
                    .padding(16)
                }
            }
            .moodBackground()
            .navigationTitle("Dashboard")
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
