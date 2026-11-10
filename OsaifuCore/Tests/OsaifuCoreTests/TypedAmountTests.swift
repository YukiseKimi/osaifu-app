import Testing
import Foundation
@testable import OsaifuCore

/// What a person types, in their own locale, and what the app must store.
/// A wrong answer here is money quietly lost, so each case is pinned.
@Suite("A typed amount")
struct TypedAmountTests {

    @Test("A grouped amount keeps every digit", arguments: [
        ("en_US", "1,280", 128000),
        ("en_US", "1,280.50", 128050),
        ("de_DE", "1.280,50", 128050),
        ("fr_FR", "1 280,50", 128050),
        ("ja_JP", "1,280", 128000)
    ])
    func groupedAmounts(locale: String, typed: String, minorUnits: Int) {
        let money = Money(typed: typed, currencyCode: "USD", locale: Locale(identifier: locale))
        #expect(money?.minorUnits == minorUnits, "\(locale) read \(typed) as \(money?.minorUnits ?? -1)")
    }

    @Test("A decimal separator reads the same in every locale", arguments: [
        ("en_US", "12.8", 1280),
        ("de_DE", "12,8", 1280),
        ("fr_FR", "12,8", 1280),
        ("de_DE", "12.8", 1280),
        ("fr_FR", "12.8", 1280),
        ("en_US", "12,8", 1280)
    ])
    func decimalSeparators(locale: String, typed: String, minorUnits: Int) {
        let money = Money(typed: typed, currencyCode: "USD", locale: Locale(identifier: locale))
        #expect(money?.minorUnits == minorUnits, "\(locale) read \(typed) as \(money?.minorUnits ?? -1)")
    }

    @Test("Text that is not a plain number gives no amount", arguments: [
        "", "   ", "free", "12.8.9", "1,2,3", "12-8", "$12", "12 dollars", "--5", "."
    ])
    func rubbishIsRefused(typed: String) {
        #expect(Money(typed: typed, currencyCode: "USD", locale: Locale(identifier: "en_US")) == nil,
                "\(typed) should be refused")
    }

    @Test("A whole number needs no separator at all")
    func wholeNumbers() {
        #expect(Money(typed: "1280", currencyCode: "JPY", locale: Locale(identifier: "ja_JP"))?.minorUnits == 1280)
        #expect(Money(typed: "-5.5", currencyCode: "USD", locale: Locale(identifier: "en_US"))?.minorUnits == -550)
        #expect(Money(typed: ".5", currencyCode: "USD", locale: Locale(identifier: "en_US"))?.minorUnits == 50)
    }

    @Test("The minor digits of a currency are the same on every call")
    func minorDigitsAreCached() {
        #expect(Money.minorDigits(of: "JPY") == 0)
        #expect(Money.minorDigits(of: "JPY") == 0)
        #expect(Money.minorDigits(of: "USD") == 2)
        #expect(Money.minorDigits(of: "USD") == 2)
    }
}
