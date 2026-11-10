import Testing
import Foundation
@testable import OsaifuCore

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    utc.date(from: DateComponents(year: year, month: month, day: day))!
}

private func spend(_ amount: Int, _ category: ExpenseCategory, _ date: Date, currency: String = "JPY") -> Expense {
    Expense(money: Money(minorUnits: amount, currencyCode: currency), category: category, date: date)
}

@Suite("The buckets the dashboard draws")
struct SpendBucketsTests {

    private func byCategory(
        _ expenses: [Expense],
        limit: Int = 5,
        countsForeign: Bool = false,
        rates: [String: Decimal] = [:]
    ) -> [SpendBucket] {
        ExpenseAnalytics.byCategory(
            expenses, homeCurrencyCode: "JPY",
            countsForeignSpend: countsForeign, rates: rates, limit: limit
        )
    }

    @Test("The largest category comes first")
    func largestFirst() {
        let buckets = byCategory([
            spend(1_000, .food, day(2026, 11, 2)),
            spend(3_000, .transport, day(2026, 11, 3)),
            spend(2_000, .groceries, day(2026, 11, 4))
        ])
        #expect(buckets.map(\.category) == [.transport, .groceries, .food])
        #expect(buckets[0].total.minorUnits == 3_000)
    }

    @Test("Everything past the limit becomes one slice, last")
    func restRollsUp() {
        let buckets = byCategory([
            spend(5_000, .food, day(2026, 11, 2)),
            spend(4_000, .groceries, day(2026, 11, 2)),
            spend(300, .transport, day(2026, 11, 2)),
            spend(200, .health, day(2026, 11, 2))
        ], limit: 2)
        #expect(buckets.count == 3)
        #expect(buckets.last?.category == nil)
        #expect(buckets.last?.name == "Other")
        #expect(buckets.last?.total.minorUnits == 500)
    }

    @Test("No slice is rolled up when the categories fit")
    func noRestWhenTheyFit() {
        let buckets = byCategory([spend(1_000, .food, day(2026, 11, 2))], limit: 5)
        #expect(buckets.count == 1)
        #expect(buckets.allSatisfy { $0.category != nil })
    }

    @Test("A period keeps out what falls outside it")
    func rangeFilters() {
        let november = DateInterval(start: day(2026, 11, 1), end: day(2026, 12, 1))
        let buckets = ExpenseAnalytics.byCategory(
            [spend(1_000, .food, day(2026, 10, 30)), spend(2_000, .food, day(2026, 11, 5))],
            in: november, homeCurrencyCode: "JPY",
            countsForeignSpend: false, rates: [:]
        )
        #expect(buckets.count == 1)
        #expect(buckets[0].total.minorUnits == 2_000)
    }

    @Test("Another currency is left out until the user gives a rate")
    func foreignNeedsARate() {
        let expenses = [spend(1_000, .food, day(2026, 11, 2)), spend(100, .food, day(2026, 11, 3), currency: "USD")]
        #expect(byCategory(expenses)[0].total.minorUnits == 1_000)
        #expect(byCategory(expenses, countsForeign: true, rates: ["USD": 150])[0].total.minorUnits == 1_150)
    }

    @Test("A year always has twelve bars")
    func twelveMonths() {
        let months = ExpenseAnalytics.byMonth(
            [spend(1_000, .food, day(2026, 4, 2))], of: day(2026, 7, 1),
            homeCurrencyCode: "JPY", countsForeignSpend: false, rates: [:], calendar: utc
        )
        #expect(months.count == 12)
        #expect(months[3].total.minorUnits == 1_000)
        #expect(months[0].total.minorUnits == 0)
    }

    @Test("Another year does not reach this year's bars")
    func monthsKeepToTheirYear() {
        let months = ExpenseAnalytics.byMonth(
            [spend(9_000, .food, day(2025, 4, 2))], of: day(2026, 1, 1),
            homeCurrencyCode: "JPY", countsForeignSpend: false, rates: [:], calendar: utc
        )
        #expect(months.allSatisfy { $0.total.minorUnits == 0 })
    }

    @Test("A year with no expense has no bar, and the oldest comes first")
    func yearsSkipTheEmpty() {
        let years = ExpenseAnalytics.byYear(
            [spend(1_000, .food, day(2024, 4, 2)), spend(2_000, .food, day(2026, 4, 2))],
            homeCurrencyCode: "JPY", countsForeignSpend: false, rates: [:], calendar: utc
        )
        #expect(years.map(\.name) == ["2024", "2026"])
        #expect(years[1].total.minorUnits == 2_000)
    }
}
