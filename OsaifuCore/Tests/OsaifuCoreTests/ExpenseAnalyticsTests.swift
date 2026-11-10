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

/// Yen has no minor digits, so a minor unit is a whole yen and the sums read
/// the way they do on the screen.
private func yen(_ amount: Int, _ category: ExpenseCategory, _ date: Date) -> Expense {
    Expense(money: Money(minorUnits: amount, currencyCode: "JPY"), category: category, date: date)
}

@Suite("Expense analytics")
struct ExpenseAnalyticsTests {

    @Test("Totals sum by category, highest first")
    func categoryTotalsSumAndSort() {
        let totals = ExpenseAnalytics.categoryTotals(for: [
            yen(1000, .food, day(2026, 6, 1)),
            yen(500, .transport, day(2026, 6, 2)),
            yen(700, .food, day(2026, 6, 3))
        ], in: "JPY")
        #expect(totals.map(\.category) == [.food, .transport])
        #expect(totals.map(\.total.minorUnits) == [1700, 500])
        #expect(totals.allSatisfy { $0.total.currencyCode == "JPY" })
    }

    @Test("A category with no expense does not appear")
    func categoryTotalsLeaveOutEmpty() {
        let totals = ExpenseAnalytics.categoryTotals(for: [yen(100, .food, day(2026, 6, 1))], in: "JPY")
        #expect(totals.map(\.category) == [.food])
    }

    @Test("No expense gives no total")
    func categoryTotalsOfNothing() {
        #expect(ExpenseAnalytics.categoryTotals(for: [], in: "JPY").isEmpty)
    }

    @Test("A total leaves out an expense in another currency")
    func totalsLeaveOutAnotherCurrency() {
        let expenses = [
            yen(1000, .food, day(2026, 6, 1)),
            Expense(money: Money(minorUnits: 4000, currencyCode: "USD"), category: .travel, date: day(2026, 6, 2))
        ]
        let totals = ExpenseAnalytics.categoryTotals(for: expenses, in: "JPY")
        #expect(totals.map(\.total.minorUnits) == [1000])
        #expect(ExpenseAnalytics.inOtherCurrencies(expenses, than: "JPY").count == 1)
        #expect(ExpenseAnalytics.inOtherCurrencies(expenses, than: "JPY").first?.currencyCode == "USD")
    }

    @Test("A month holds only its own expenses")
    func monthHoldsOnlyItsOwn() {
        let june = yen(1000, .food, day(2026, 6, 30))
        let july = yen(2000, .food, day(2026, 7, 1))
        let found = ExpenseAnalytics.expenses([june, july], inMonthOf: day(2026, 6, 15), calendar: utc)
        #expect(found.map(\.money.minorUnits) == [1000])
    }

    @Test("Summaries run oldest first, and each one totals its categories")
    func summariesRunOldestFirst() {
        let summaries = ExpenseAnalytics.monthlySummaries(for: [
            yen(2000, .food, day(2026, 7, 1)),
            yen(1000, .food, day(2026, 6, 2)),
            yen(500, .travel, day(2026, 6, 20))
        ], in: "JPY", calendar: utc)
        #expect(summaries.map(\.monthStart) == [day(2026, 6, 1), day(2026, 7, 1)])
        #expect(summaries.map(\.total.minorUnits) == [1500, 2000])
    }

    @Test("The history chart gets one point for each month and category")
    func onePointForEachMonthAndCategory() {
        let rows = ExpenseAnalytics.monthlyCategoryTotals(for: [
            yen(1000, .food, day(2026, 6, 2)),
            yen(500, .food, day(2026, 6, 9)),
            yen(500, .travel, day(2026, 6, 20))
        ], in: "JPY", calendar: utc)
        #expect(rows.count == 2)
        #expect(Set(rows.map(\.id)).count == 2)
        #expect(rows.first { $0.category == .food }?.total.minorUnits == 1500)
    }

    @Test("Two equal totals keep one order")
    func equalTotalsKeepOneOrder() {
        let totals = ExpenseAnalytics.categoryTotals(for: [
            yen(2000, .transport, day(2026, 6, 1)),
            yen(2000, .health, day(2026, 6, 2)),
            yen(2000, .food, day(2026, 6, 3))
        ], in: "JPY")
        #expect(totals.map(\.category) == [.food, .health, .transport])
    }

    @Test("A month starts on its first day")
    func monthStartsOnItsFirstDay() {
        #expect(ExpenseAnalytics.startOfMonth(day(2026, 6, 17), calendar: utc) == day(2026, 6, 1))
    }

    @Test("An unknown category identifier reads as other")
    func unknownCategoryReadsAsOther() {
        let expense = yen(100, .food, day(2026, 6, 1))
        expense.categoryID = "crypto"
        #expect(expense.category == .other)
    }
}
