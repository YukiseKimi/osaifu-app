import Testing
import Foundation
@testable import OsaifuModel

@Suite("Money")
struct MoneyTests {

    @Test("The system knows how many minor digits a currency has")
    func minorDigitsPerCurrency() {
        #expect(Money.minorDigits(of: "JPY") == 0)
        #expect(Money.minorDigits(of: "USD") == 2)
        #expect(Money.minorDigits(of: "KRW") == 0)
    }

    @Test("Minor units read as a decimal amount")
    func minorUnitsAsDecimal() {
        #expect(Money(minorUnits: 1280, currencyCode: "USD").decimalValue == Decimal(string: "12.80"))
        #expect(Money(minorUnits: 1280, currencyCode: "JPY").decimalValue == Decimal(1280))
        #expect(Money(minorUnits: -550, currencyCode: "USD").decimalValue == Decimal(string: "-5.50"))
    }

    @Test("A typed amount becomes minor units")
    func typedAmount() {
        #expect(Money(typed: "12.8", currencyCode: "USD")?.minorUnits == 1280)
        #expect(Money(typed: "12.84", currencyCode: "USD")?.minorUnits == 1284)
        #expect(Money(typed: "1280", currencyCode: "JPY")?.minorUnits == 1280)
        #expect(Money(typed: "1280.6", currencyCode: "JPY")?.minorUnits == 1281)
    }

    @Test("Text that is not a number gives no amount")
    func typedRubbish() {
        #expect(Money(typed: "", currencyCode: "USD") == nil)
        #expect(Money(typed: "free", currencyCode: "USD") == nil)
    }

    @Test("A sum of minor units is exact, where a Double drifts")
    func sumIsExact() {
        let cents = (1...10).map { _ in Money(minorUnits: 10, currencyCode: "USD") }
        #expect(Money.sum(cents, in: "USD").minorUnits == 100)
        let drift = (1...10).reduce(0.0) { sum, _ in sum + 0.1 }
        #expect(drift != 1.0)
    }

    @Test("A total leaves out every other currency")
    func totalLeavesOutOtherCurrencies() {
        let amounts = [
            Money(minorUnits: 1000, currencyCode: "JPY"),
            Money(minorUnits: 500, currencyCode: "USD"),
            Money(minorUnits: 2000, currencyCode: "JPY")
        ]
        #expect(Money.sum(amounts, in: "JPY").minorUnits == 3000)
        #expect(Money.sum(amounts, in: "USD").minorUnits == 500)
        #expect(Money.sum(amounts, in: "EUR") == Money.zero("EUR"))
    }
}
