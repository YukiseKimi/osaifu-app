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

private func progress(limit: Int, spent: Int) -> BudgetProgress {
    let money = { Money(minorUnits: $0, currencyCode: "JPY") }
    return BudgetProgress(
        baseLimit: money(limit),
        carriedOver: Money.zero("JPY"),
        limit: money(limit),
        spent: money(spent),
        leftOutCount: 0
    )
}

@Suite("What is left today")
struct LeftTodayTests {

    @Test("The days that remain count today")
    func daysLeftCountsToday() {
        let month = progress(limit: 0, spent: 0)
        #expect(month.daysLeft(on: day(2026, 11, 10), calendar: utc) == 21)
        #expect(month.daysLeft(on: day(2026, 11, 30), calendar: utc) == 1)
        #expect(month.daysLeft(on: day(2026, 11, 1), calendar: utc) == 30)
        #expect(month.daysLeft(on: day(2026, 2, 1), calendar: utc) == 28)
    }

    @Test("What is left is spread over the days that remain")
    func leftIsSpread() {
        let month = progress(limit: 120_000, spent: 99_000)
        #expect(month.leftToday(on: day(2026, 11, 10), calendar: utc).minorUnits == 1_000)
    }

    @Test("The last day of the month keeps all of what is left")
    func lastDayKeepsAll() {
        let month = progress(limit: 120_000, spent: 99_000)
        #expect(month.leftToday(on: day(2026, 11, 30), calendar: utc).minorUnits == 21_000)
    }

    @Test("A month over its limit has nothing left today")
    func overTheLimitIsZero() {
        let month = progress(limit: 120_000, spent: 130_000)
        #expect(month.leftToday(on: day(2026, 11, 10), calendar: utc).minorUnits == 0)
    }

    @Test("The figure keeps the currency of the limit")
    func keepsCurrency() {
        let month = progress(limit: 120_000, spent: 0)
        #expect(month.leftToday(on: day(2026, 11, 10), calendar: utc).currencyCode == "JPY")
    }
}
