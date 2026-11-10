import OsaifuModel
import SwiftUI

/// What the watch shows after a save: the amount it took, and what is left
/// today, so the user can act on it at the till.
struct SavedView: View {
    let money: Money
    let category: ExpenseCategory?
    /// Nil while the user has set no monthly limit.
    let progress: BudgetProgress?
    /// What the month has spent, for a user with no limit set.
    let spent: Money
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 5) {
            Text("Saved")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(money.formatted())
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if let category {
                Text(category.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let progress {
                ProgressView(value: progress.fraction)
                    .tint(progress.isOver ? .red : .green)
                Text("\(progress.leftToday().formatted()) left today")
                    .font(.caption2)
                    .foregroundStyle(progress.isOver ? .red : .secondary)
                    .lineLimit(1)
            } else {
                Text("\(spent.formatted()) this month")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button("Done", action: onDone)
                .buttonStyle(.bordered)
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    SavedView(
        money: Money(minorUnits: 1_280, currencyCode: "JPY"),
        category: .food,
        progress: BudgetProgress(
            baseLimit: Money(minorUnits: 120_000, currencyCode: "JPY"),
            carriedOver: Money.zero("JPY"),
            limit: Money(minorUnits: 120_000, currencyCode: "JPY"),
            spent: Money(minorUnits: 101_400, currencyCode: "JPY"),
            leftOutCount: 0
        ),
        spent: Money(minorUnits: 101_400, currencyCode: "JPY"),
        onDone: {}
    )
}
