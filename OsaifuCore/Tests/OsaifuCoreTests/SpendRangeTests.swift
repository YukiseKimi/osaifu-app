import Testing
import Foundation
@testable import OsaifuModel

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    utc.date(from: DateComponents(year: year, month: month, day: day))!
}

@Suite("The period the dashboard draws")
struct SpendRangeTests {

    @Test("This month starts on the first and ends on the next first")
    func monthInterval() {
        let period = SpendRange.month.interval(containing: day(2026, 11, 10), calendar: utc)
        #expect(period?.start == day(2026, 11, 1))
        #expect(period?.end == day(2026, 12, 1))
    }

    @Test("This year holds every month of that year")
    func yearInterval() {
        let period = SpendRange.year.interval(containing: day(2026, 11, 10), calendar: utc)
        #expect(period?.start == day(2026, 1, 1))
        #expect(period?.contains(day(2026, 3, 20)) == true)
        #expect(period?.contains(day(2025, 12, 31)) == false)
    }

    @Test("All has no period, so nothing is filtered out")
    func allHasNoInterval() {
        #expect(SpendRange.all.interval(containing: day(2026, 11, 10), calendar: utc) == nil)
    }
}

@Suite("The window a month's figures need")
struct MonthWindowTests {

    @Test("It starts at the first of the month before")
    func startsAMonthBefore() {
        #expect(ExpenseAnalytics.windowStart(forMonthOf: day(2026, 11, 10), calendar: utc) == day(2026, 10, 1))
        #expect(ExpenseAnalytics.windowStart(forMonthOf: day(2026, 1, 20), calendar: utc) == day(2025, 12, 1))
    }

    @Test("It always covers the last thirty days, which the pad reads")
    func coversThirtyDays() {
        for day0 in [day(2026, 11, 1), day(2026, 11, 15), day(2026, 11, 30), day(2026, 3, 1)] {
            let window = ExpenseAnalytics.windowStart(forMonthOf: day0, calendar: utc)
            let thirtyDaysBack = utc.date(byAdding: .day, value: -30, to: day0)!
            #expect(window <= thirtyDaysBack)
        }
    }
}
