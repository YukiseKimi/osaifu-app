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

private func budget(_ minorUnits: Int, currency: String = "JPY", active: Bool = true, updated: Date) -> Budget {
    let row = Budget(limit: Money(minorUnits: minorUnits, currencyCode: currency))
    row.isActive = active
    row.updatedAt = updated
    return row
}

private func rate(_ value: Decimal, from: String, to: String, isSet: Bool = true) -> ExchangeRate {
    ExchangeRate(currencyCode: from, homeCurrencyCode: to, rate: isSet ? value : 0)
}

/// BudgetReader is the one path the Budget tab, the line on This Month, the
/// Home Screen widget and the watch all read through. Nothing covered it.
@Suite("The one budget reader")
struct BudgetReaderTests {

    @Test("The newest active limit wins")
    func newestActiveWins() {
        let rows = [
            budget(100_000, updated: day(2026, 1, 1)),
            budget(200_000, updated: day(2026, 6, 1))
        ]
        #expect(BudgetReader.activeBudget(rows)?.limitMinorUnits == 200_000)
    }

    @Test("A limit the user removed is not the active one")
    func removedIsNotActive() {
        let rows = [
            budget(100_000, updated: day(2026, 1, 1)),
            budget(200_000, active: false, updated: day(2026, 6, 1))
        ]
        #expect(BudgetReader.activeBudget(rows)?.limitMinorUnits == 100_000)
    }

    @Test("With no row at all there is no limit")
    func noRowsNoLimit() {
        #expect(BudgetReader.activeBudget([]) == nil)
    }

    @Test("Only the rates for this home currency, and only the filled ones")
    func ratesAreFiltered() {
        let rates = [
            rate(150, from: "USD", to: "JPY"),
            rate(0, from: "EUR", to: "JPY", isSet: false),
            rate(1.1, from: "USD", to: "EUR")
        ]
        let found = AppSettings.ratesByCurrency(rates, homeCurrencyCode: "JPY")
        #expect(found == ["USD": 150])
    }

    @Test("No limit set means no progress to draw")
    func noProgressWithoutALimit() {
        let progress = BudgetReader.progress(
            expenses: [], budgets: [],
            settings: AppSettings(homeCurrencyCode: "JPY")
        )
        #expect(progress == nil)
    }

    @Test("The reader reads the newest settings row")
    func newestSettingsWin() {
        let older = Preferences(homeCurrencyCode: "JPY")
        older.countsForeignSpend = false
        older.updatedAt = day(2026, 1, 1)
        let newer = Preferences(homeCurrencyCode: "JPY")
        newer.countsForeignSpend = true
        newer.updatedAt = day(2026, 6, 1)

        let dollars = Expense(
            money: Money(minorUnits: 1_000, currencyCode: "USD"),
            category: .food,
            date: .now
        )

        let progress = BudgetReader.progress(
            expenses: [dollars],
            budgets: [budget(100_000, updated: day(2026, 1, 1))],
            settings: AppSettings.from(
                preferences: [older, newer],
                rates: [rate(150, from: "USD", to: "JPY")]
            )
        )
        // The newer row counts other currencies, so the ten dollars land.
        #expect(progress?.spent.minorUnits == 1_500)
        #expect(progress?.leftOutCount == 0)
    }

    @Test("A limit in another currency needs a rate")
    func staleLimitNeedsARate() {
        let rows = [budget(100_000, currency: "JPY", updated: day(2026, 1, 1))]
        let inDollars = AppSettings(homeCurrencyCode: "USD")
        let withARate = AppSettings(
            homeCurrencyCode: "USD",
            rates: ["JPY": Decimal(string: "0.0065")!]
        )
        #expect(BudgetReader.limitNeedingRate(budgets: rows, settings: inDollars) != nil)
        #expect(BudgetReader.limitNeedingRate(budgets: rows, settings: withARate) == nil)
        #expect(BudgetReader.limitNeedingRate(
            budgets: rows, settings: AppSettings(homeCurrencyCode: "JPY")
        ) == nil)
    }
}
