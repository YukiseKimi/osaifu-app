import Testing
import Foundation
@testable import OsaifuCore

/// A fixed calendar, so a test gives the same answer in every time zone.
private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    utc.date(from: DateComponents(year: year, month: month, day: day))!
}

@Suite("Expense analytics")
struct ExpenseAnalyticsTests {

    @Test("Totals sum by category, highest first")
    func categoryTotalsSumAndSort() {
        let totals = ExpenseAnalytics.categoryTotals(for: [
            Expense(amount: 10, category: .food, date: day(2026, 6, 1)),
            Expense(amount: 5, category: .transport, date: day(2026, 6, 2)),
            Expense(amount: 7, category: .food, date: day(2026, 6, 3))
        ])
        #expect(totals.map(\.category) == [.food, .transport])
        #expect(totals.map(\.total) == [17, 5])
    }

    @Test("A category with no expense does not appear")
    func categoryTotalsLeaveOutEmpty() {
        let totals = ExpenseAnalytics.categoryTotals(for: [
            Expense(amount: 1, category: .food, date: day(2026, 6, 1))
        ])
        #expect(totals.map(\.category) == [.food])
    }

    @Test("No expense gives no total")
    func categoryTotalsOfNothing() {
        #expect(ExpenseAnalytics.categoryTotals(for: []).isEmpty)
    }

    @Test("A month holds only its own expenses")
    func monthHoldsOnlyItsOwn() {
        let june = Expense(amount: 10, category: .food, date: day(2026, 6, 30))
        let july = Expense(amount: 20, category: .food, date: day(2026, 7, 1))
        let found = ExpenseAnalytics.expenses([june, july], inMonthOf: day(2026, 6, 15), calendar: utc)
        #expect(found.map(\.amount) == [10])
    }

    @Test("Summaries run oldest first, and each one totals its categories")
    func summariesRunOldestFirst() {
        let summaries = ExpenseAnalytics.monthlySummaries(for: [
            Expense(amount: 20, category: .food, date: day(2026, 7, 1)),
            Expense(amount: 10, category: .food, date: day(2026, 6, 2)),
            Expense(amount: 5, category: .travel, date: day(2026, 6, 20))
        ], calendar: utc)
        #expect(summaries.map(\.monthStart) == [day(2026, 6, 1), day(2026, 7, 1)])
        #expect(summaries.map(\.total) == [15, 20])
    }

    @Test("The history chart gets one point for each month and category")
    func onePointForEachMonthAndCategory() {
        let rows = ExpenseAnalytics.monthlyCategoryTotals(for: [
            Expense(amount: 10, category: .food, date: day(2026, 6, 2)),
            Expense(amount: 5, category: .food, date: day(2026, 6, 9)),
            Expense(amount: 5, category: .travel, date: day(2026, 6, 20))
        ], calendar: utc)
        #expect(rows.count == 2)
        #expect(Set(rows.map(\.id)).count == 2)
        #expect(rows.first { $0.category == .food }?.total == 15)
    }

    @Test("A month starts on its first day")
    func monthStartsOnItsFirstDay() {
        #expect(ExpenseAnalytics.startOfMonth(day(2026, 6, 17), calendar: utc) == day(2026, 6, 1))
    }

    @Test("An unknown category identifier reads as other")
    func unknownCategoryReadsAsOther() {
        let expense = Expense(amount: 1, category: .food, date: day(2026, 6, 1))
        expense.categoryID = "crypto"
        #expect(expense.category == .other)
    }
}
