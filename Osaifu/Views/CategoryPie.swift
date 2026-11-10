import Charts
import OsaifuCore
import SwiftUI

/// Where the money of the period went. The list beside the pie names each
/// slice and its amount, so the chart needs no legend saying the same thing.
struct CategoryPie: View {
    let slices: [SpendBucket]
    let title: String

    var body: some View {
        DashboardCard(title: title) {
            if slices.isEmpty {
                Text("Nothing in this period.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(height: 170)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 20) {
                        pie
                        list
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        pie
                        list
                    }
                }
            }
        }
    }

    private var pie: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Spent", slice.total.plotValue),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .cornerRadius(3)
            .foregroundStyle(color(of: slice))
        }
        .chartLegend(.hidden)
        .frame(width: 170, height: 170)
        .accessibilityLabel("Spending by category")
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(slices) { slice in
                HStack(spacing: 8) {
                    Circle()
                        .fill(color(of: slice))
                        .frame(width: 9, height: 9)
                    Text(slice.name)
                        .font(.callout)
                        .lineLimit(1)
                    Spacer(minLength: 12)
                    Text(slice.total.formatted())
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// The rolled-up slice has no category, so it takes the quiet colour.
    private func color(of slice: SpendBucket) -> Color {
        slice.category?.color ?? .secondary
    }
}

#Preview {
    CategoryPie(
        slices: [
            SpendBucket(id: "food", name: "Food & Dining", date: .now, category: .food,
                        total: Money(minorUnits: 28_400, currencyCode: "JPY")),
            SpendBucket(id: "groceries", name: "Groceries", date: .now, category: .groceries,
                        total: Money(minorUnits: 19_100, currencyCode: "JPY")),
            SpendBucket(id: "rest", name: "Other", date: .now, category: nil,
                        total: Money(minorUnits: 21_800, currencyCode: "JPY"))
        ],
        title: "This month, by category"
    )
    .padding()
}
