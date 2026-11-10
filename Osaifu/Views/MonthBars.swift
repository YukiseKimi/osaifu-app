import Charts
import OsaifuModel
import SwiftUI

/// What each month of one year spent. Twelve bars, so the axis does not move
/// as the year fills up.
struct MonthBars: View {
    let months: [SpendBucket]
    let title: String
    /// The month the pie follows, or nil while the pie follows the range.
    @Binding var chosen: Date?

    private var calendar: Calendar { .current }

    private func isChosen(_ month: SpendBucket) -> Bool {
        guard let chosen else { return true }
        return calendar.isDate(month.date, equalTo: chosen, toGranularity: .month)
    }

    var body: some View {
        DashboardCard(title: title) {
            Chart(months) { month in
                BarMark(
                    x: .value("Month", month.date, unit: .month),
                    y: .value("Spent", month.total.plotValue)
                )
                .cornerRadius(4)
                .foregroundStyle(Color.appAccent)
                .opacity(isChosen(month) ? 1 : 0.4)
            }
            // Apple's own selection gesture on iOS is a two-finger tap, which
            // nobody finds. One tap does the same job here. The gesture sets
            // the month itself rather than through a selection binding: the
            // same bar tapped twice does not change a binding, so a toggle
            // hung off one would never fire.
            .chartGesture { proxy in
                SpatialTapGesture().onEnded { tap in
                    guard let date: Date = proxy.value(atX: tap.location.x),
                          let month = calendar.dateInterval(of: .month, for: date)?.start
                    else { return }
                    // A second tap on the chosen month gives the range back.
                    chosen = (month == chosen) ? nil : month
                }
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
        title: "Each month of 2026",
        chosen: .constant(nil)
    )
    .padding()
}
