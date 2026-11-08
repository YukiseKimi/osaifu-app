import Foundation
import SwiftData

/// Generates randomized example expenses so the charts and lists can be
/// explored (and sync tested) without manual data entry.
public enum SampleData {
    /// Plausible per-category amount ranges, to make the sample look realistic.
    private static let typicalAmounts: [ExpenseCategory: ClosedRange<Double>] = [
        .food: 8...45,
        .groceries: 20...140,
        .transport: 2...60,
        .housing: 600...1800,
        .utilities: 30...220,
        .health: 10...300,
        .entertainment: 8...90,
        .shopping: 15...250,
        .education: 20...400,
        .travel: 50...900,
        .other: 5...120,
    ]

    /// A small pool of optional notes (weighted toward empty).
    private static let sampleNotes = ["", "", "", "Card", "Online", "Cash", "Monthly"]

    /// Inserts a spread of expenses across the last `monthsBack` months,
    /// including the current month up to today.
    @MainActor
    public static func insert(into context: ModelContext, monthsBack: Int = 6) {
        let calendar = Calendar.current
        let today = Date.now

        for monthOffset in 0..<monthsBack {
            guard let anchor = calendar.date(byAdding: .month, value: -monthOffset, to: today) else { continue }
            let startOfMonth = ExpenseAnalytics.startOfMonth(anchor, calendar: calendar)
            let daysInMonth = calendar.range(of: .day, in: .month, for: anchor)?.count ?? 28
            // Don't place expenses in the future within the current month.
            let maxDay = monthOffset == 0 ? calendar.component(.day, from: today) : daysInMonth

            for _ in 0..<Int.random(in: 6...12) {
                let category = ExpenseCategory.allCases.randomElement() ?? .other
                let range = typicalAmounts[category] ?? 5...100
                let amount = (Double.random(in: range) * 100).rounded() / 100
                let day = Int.random(in: 1...max(1, maxDay))
                let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) ?? startOfMonth
                let note = sampleNotes.randomElement() ?? ""
                context.insert(Expense(amount: amount, category: category, note: note, date: date))
            }
        }
    }
}
