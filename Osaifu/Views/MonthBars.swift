import Charts
import OsaifuCore
import SwiftUI

/// What each month of one year spent. Twelve bars, so the axis does not move
/// as the year fills up.
struct MonthBars: View {
    let months: [SpendBucket]
    let title: String

    var body: some View {
        DashboardCard(title: title) {
            Chart(months) { month in
                BarMark(
                    x: .value("Month", month.date, unit: .month),
                    y: .value("Spent", month.total.plotValue)
                )
                .cornerRadius(4)
                .foregroundStyle(Color.appAccent)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount, format: .number.notation(.compactName).precision(.fractionLength(0)))
                        }
                    }
                }
            }
            .frame(height: 170)
            .accessibilityLabel("Spending for each month")
        }
    }
}

#Preview {
    MonthBars(
        months: (1...12).map { month in
            SpendBucket(
                id: "\(month)",
                name: "\(month)",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: month, day: 1))!,
                category: nil,
                total: Money(minorUnits: month * 9_000, currencyCode: "JPY")
            )
        },
        title: "Each month of 2026"
    )
    .padding()
}
