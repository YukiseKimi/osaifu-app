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

private func row(_ code: String, carries: Bool = false, foreign: Bool = false, updated: Date) -> Preferences {
    let made = Preferences(homeCurrencyCode: code)
    made.carriesRemainderOver = carries
    made.countsForeignSpend = foreign
    made.updatedAt = updated
    return made
}

/// The one place the settings are worked out. It used to be eleven.
@Suite("The settings, as one value")
struct SettingsTests {

    @Test("The row that changed last wins")
    func newestRowWins() {
        let settings = AppSettings.from(preferences: [
            row("JPY", updated: day(2026, 1, 1)),
            row("USD", carries: true, foreign: true, updated: day(2026, 6, 1))
        ])
        #expect(settings.homeCurrencyCode == "USD")
        #expect(settings.carriesRemainderOver)
        #expect(settings.countsForeignSpend)
    }

    @Test("A row with no currency falls through to the one given")
    func emptyCodeFallsThrough() {
        let settings = AppSettings.from(
            preferences: [row("", updated: day(2026, 6, 1))],
            fallbackCurrencyCode: "GBP"
        )
        #expect(settings.homeCurrencyCode == "GBP")
    }

    @Test("With no row at all the fallback stands")
    func noRowsUseTheFallback() {
        #expect(AppSettings.from(preferences: [], fallbackCurrencyCode: "EUR").homeCurrencyCode == "EUR")
    }

    @Test("The switches are off until a row says otherwise")
    func switchesStartOff() {
        let settings = AppSettings.from(preferences: [], fallbackCurrencyCode: "EUR")
        #expect(!settings.carriesRemainderOver)
        #expect(!settings.countsForeignSpend)
        #expect(settings.rates.isEmpty)
    }

    @Test("Only the rates for this home currency, and only the filled ones")
    func ratesAreFiltered() {
        let settings = AppSettings.from(
            preferences: [row("JPY", updated: day(2026, 1, 1))],
            rates: [
                ExchangeRate(currencyCode: "USD", homeCurrencyCode: "JPY", rate: 150),
                ExchangeRate(currencyCode: "EUR", homeCurrencyCode: "JPY", rate: 0),
                ExchangeRate(currencyCode: "USD", homeCurrencyCode: "EUR", rate: 1.1)
            ]
        )
        #expect(settings.rates == ["USD": 150])
    }

    @Test("The rates follow the currency the newest row names")
    func ratesFollowTheNewestRow() {
        let settings = AppSettings.from(
            preferences: [
                row("JPY", updated: day(2026, 1, 1)),
                row("EUR", updated: day(2026, 6, 1))
            ],
            rates: [
                ExchangeRate(currencyCode: "USD", homeCurrencyCode: "JPY", rate: 150),
                ExchangeRate(currencyCode: "USD", homeCurrencyCode: "EUR", rate: 1.1)
            ]
        )
        #expect(settings.homeCurrencyCode == "EUR")
        #expect(settings.rates == ["USD": Decimal(string: "1.1")!])
    }

    @Test("What one expense is worth here follows the switch and the rate")
    func amountFollowsTheRules() {
        let dollars = Expense(
            money: Money(minorUnits: 1_000, currencyCode: "USD"),
            category: .food,
            date: .now
        )
        let off = AppSettings(homeCurrencyCode: "JPY")
        let on = AppSettings(homeCurrencyCode: "JPY", countsForeignSpend: true, rates: ["USD": 150])
        #expect(off.amount(of: dollars) == nil)
        #expect(on.amount(of: dollars)?.minorUnits == 1_500)
    }
}
