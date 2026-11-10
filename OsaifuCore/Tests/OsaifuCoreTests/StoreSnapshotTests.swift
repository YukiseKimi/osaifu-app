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

private let november = day(2026, 11, 15)

private func yen(_ minorUnits: Int, _ date: Date = november) -> Expense {
    Expense(money: Money(minorUnits: minorUnits, currencyCode: "JPY"), category: .food, date: date)
}

private func settings(_ code: String) -> Preferences {
    Preferences(homeCurrencyCode: code)
}

/// The one read both widgets do. It used to be a copy in each of them.
@Suite("The snapshot a widget reads")
struct StoreSnapshotTests {

    @Test("With no limit it still says what the month has spent")
    func spendWithNoLimit() {
        let snapshot = StoreSnapshot.make(
            expenses: [yen(1_000), yen(2_000)],
            budgets: [], preferences: [settings("JPY")], rates: [],
            now: november
        )
        #expect(snapshot.spent.minorUnits == 3_000)
        #expect(snapshot.progress == nil)
        #expect(snapshot.remaining == nil)
    }

    @Test("With a limit it says where the month stands")
    func progressWithALimit() {
        let budget = Budget(limit: Money(minorUnits: 10_000, currencyCode: "JPY"))
        let snapshot = StoreSnapshot.make(
            expenses: [yen(4_000)],
            budgets: [budget], preferences: [settings("JPY")], rates: [],
            now: november
        )
        #expect(snapshot.spent.minorUnits == 4_000)
        #expect(snapshot.remaining?.minorUnits == 6_000)
    }

    @Test("Another month's expense is not this month's spending")
    func onlyThisMonth() {
        let snapshot = StoreSnapshot.make(
            expenses: [yen(1_000, day(2026, 10, 15))],
            budgets: [], preferences: [settings("JPY")], rates: [],
            now: november
        )
        #expect(snapshot.spent.minorUnits == 0)
    }

    @Test("With no settings row it falls back to the device currency")
    func fallsBackToTheDevice() {
        let snapshot = StoreSnapshot.make(
            expenses: [], budgets: [], preferences: [], rates: [], now: november
        )
        #expect(snapshot.homeCurrencyCode == Currency.defaultCode)
    }

    @Test("An empty snapshot shows zero, not nothing")
    func emptyShowsZero() {
        #expect(StoreSnapshot.empty().spent.minorUnits == 0)
        #expect(StoreSnapshot.empty().progress == nil)
    }
}
