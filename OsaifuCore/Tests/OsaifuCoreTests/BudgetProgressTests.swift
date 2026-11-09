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

private func yen(_ amount: Int, _ date: Date) -> Expense {
    Expense(money: Money(minorUnits: amount, currencyCode: "JPY"), category: .food, date: date)
}

private let limit = Money(minorUnits: 120_000, currencyCode: "JPY")

@Suite("Where the month stands")
struct BudgetProgressTests {

    private func progress(
        _ expenses: [Expense],
        month: Date = day(2026, 11, 15),
        carries: Bool = false,
        countsForeign: Bool = false,
        rates: [String: Decimal] = [:]
    ) -> BudgetProgress {
        ExpenseAnalytics.progress(
            limit: limit, expenses: expenses, month: month,
            carriesRemainderOver: carries, countsForeignSpend: countsForeign,
            rates: rates, calendar: utc
        )
    }

    @Test("A month with no expense has the whole limit left")
    func nothingSpent() {
        let state = progress([])
        #expect(state.spent == Money.zero("JPY"))
        #expect(state.remaining == limit)
        #expect(state.fraction == 0)
        #expect(!state.isOver)
    }

    @Test("Only this month's expenses count")
    func onlyThisMonth() {
        let state = progress([
            yen(30_000, day(2026, 11, 2)),
            yen(50_000, day(2026, 10, 30))
        ])
        #expect(state.spent.minorUnits == 30_000)
        #expect(state.remaining.minorUnits == 90_000)
    }

    @Test("Over the limit gives a negative remainder")
    func overTheLimit() {
        let state = progress([yen(130_000, day(2026, 11, 3))])
        #expect(state.isOver)
        #expect(state.remaining.minorUnits == -10_000)
        #expect(state.fraction == 1, "the bar stops at full")
    }

    @Test("An expense in another currency is left out, and counted")
    func foreignLeftOut() {
        let dollars = Expense(money: Money(minorUnits: 4000, currencyCode: "USD"), category: .travel, date: day(2026, 11, 4))
        let state = progress([yen(10_000, day(2026, 11, 2)), dollars])
        #expect(state.spent.minorUnits == 10_000)
        #expect(state.leftOutCount == 1)
    }

    @Test("With the switch and a rate, it counts at that rate")
    func foreignCountedAtTheRate() {
        let dollars = Expense(money: Money(minorUnits: 4000, currencyCode: "USD"), category: .travel, date: day(2026, 11, 4))
        let state = progress([yen(10_000, day(2026, 11, 2)), dollars],
                             countsForeign: true, rates: ["USD": 155])
        // $40.00 at 155 is 6,200 yen.
        #expect(state.spent.minorUnits == 16_200)
        #expect(state.leftOutCount == 0)
    }

    @Test("The switch without a rate still leaves it out")
    func switchWithoutARate() {
        let dollars = Expense(money: Money(minorUnits: 4000, currencyCode: "USD"), category: .travel, date: day(2026, 11, 4))
        let state = progress([dollars], countsForeign: true, rates: [:])
        #expect(state.spent == Money.zero("JPY"))
        #expect(state.leftOutCount == 1)
    }

    @Test("What was left of last month carries over, once it is on")
    func carriesWhatWasLeft() {
        let expenses = [yen(100_000, day(2026, 10, 10)), yen(30_000, day(2026, 11, 2))]

        let off = progress(expenses)
        #expect(off.carriedOver == Money.zero("JPY"))
        #expect(off.limit == limit)

        let on = progress(expenses, carries: true)
        #expect(on.carriedOver.minorUnits == 20_000)
        #expect(on.limit.minorUnits == 140_000)
        #expect(on.remaining.minorUnits == 110_000)
    }

    @Test("A month that went over does not follow the user into the next one")
    func overspendDoesNotCarry() {
        let expenses = [yen(150_000, day(2026, 10, 10))]
        let state = progress(expenses, carries: true)
        #expect(state.carriedOver == Money.zero("JPY"))
        #expect(state.limit == limit)
    }
}
