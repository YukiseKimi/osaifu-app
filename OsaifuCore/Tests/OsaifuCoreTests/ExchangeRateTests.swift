import Testing
import Foundation
import SwiftData
@testable import OsaifuCore

@Suite("Rates the user types")
struct ExchangeRateTests {

    private func context() throws -> ModelContext {
        ModelContext(try StoreSetup.makeInMemoryContainer())
    }

    @Test("No rate until the user gives one")
    func noRateAtFirst() throws {
        #expect(try ExchangeRate.rate(from: "USD", to: "JPY", in: try context()) == nil)
    }

    @Test("A rate is kept for its pair, and changing it keeps one row")
    func oneRowForEachPair() throws {
        let context = try context()
        try ExchangeRate.setRate(155, from: "USD", to: "JPY", in: context)
        try ExchangeRate.setRate(160, from: "USD", to: "JPY", in: context)
        try ExchangeRate.setRate(170, from: "EUR", to: "JPY", in: context)

        #expect(try ExchangeRate.rate(from: "USD", to: "JPY", in: context) == 160)
        #expect(try ExchangeRate.rate(from: "EUR", to: "JPY", in: context) == 170)
        #expect(try context.fetchCount(FetchDescriptor<ExchangeRate>()) == 2)
    }

    @Test("A rate of zero counts as no rate")
    func zeroIsNoRate() throws {
        let context = try context()
        try ExchangeRate.setRate(0, from: "USD", to: "JPY", in: context)
        #expect(try ExchangeRate.rate(from: "USD", to: "JPY", in: context) == nil)
    }

    @Test("Converting rounds once, at the end")
    func convertingRoundsOnce() {
        // $12.80 at 155 yen to the dollar is 1,984 yen.
        let dollars = Money(minorUnits: 1280, currencyCode: "USD")
        #expect(dollars.converted(to: "JPY", rate: 155) == Money(minorUnits: 1984, currencyCode: "JPY"))

        // 1,000 yen at 0.0064 dollars to the yen is $6.40.
        let yen = Money(minorUnits: 1000, currencyCode: "JPY")
        #expect(yen.converted(to: "USD", rate: Decimal(string: "0.0064")!) == Money(minorUnits: 640, currencyCode: "USD"))
    }

    @Test("Converting to its own currency changes nothing")
    func sameCurrencyIsUntouched() {
        let yen = Money(minorUnits: 1000, currencyCode: "JPY")
        #expect(yen.converted(to: "JPY", rate: 999) == yen)
    }

    @Test("The two budget switches start off")
    func switchesStartOff() throws {
        let context = try context()
        let preferences = try Preferences.current(in: context, fallbackCurrencyCode: "JPY")
        #expect(!preferences.carriesRemainderOver)
        #expect(!preferences.countsForeignSpend)

        preferences.setCarriesRemainderOver(true)
        #expect(preferences.carriesRemainderOver)
    }
}
