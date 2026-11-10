import Charts
import OsaifuModel
import SwiftUI

/// What each year spent. The amount sits on the bar, so the chart needs no
/// scale beside it.
struct YearBars: View {
    let years: [SpendBucket]

    var body: some View {
        DashboardCard(title: "Each year") {
            if years.isEmpty {
                Text("Nothing recorded yet.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(height: 140)
            } else {
                Chart(years) { year in
                    BarMark(
                        x: .value("Year", year.name),
                        y: .value("Spent", year.total.plotValue),
                        width: .fixed(54)
                    )
                    .cornerRadius(4)
                    .foregroundStyle(Color.appAccent.opacity(0.85))
                    .annotation(position: .top) {
                        Text(year.total.formatted())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 150)
                .accessibilityLabel("Spending for each year")
            }
        }
    }
}

#Preview {
    YearBars(years: [2023, 2024, 2025, 2026].map { year in
        SpendBucket(
            id: "\(year)",
            name: String(year),
            date: Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!,
            category: nil,
            total: Money(minorUnits: year * 500, currencyCode: "JPY")
        )
    })
    .padding()
}
