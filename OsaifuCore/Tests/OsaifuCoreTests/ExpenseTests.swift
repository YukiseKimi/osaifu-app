import Testing
import Foundation
@testable import OsaifuModel

/// The record itself: what it stores, and what it makes of what it stores.
@Suite("An expense")
struct ExpenseTests {

    /// A category arrives from iCloud as a raw string, which a newer build
    /// may name and this one may not.
    @Test("An unknown category identifier reads as other")
    func unknownCategoryReadsAsOther() {
        let expense = Expense(money: Money(minorUnits: 100, currencyCode: "JPY"), category: .food)
        expense.categoryID = "crypto"
        #expect(expense.category == .other)
    }

    @Test("A category round-trips through its raw value")
    func categoryRoundTrips() {
        let expense = Expense(money: Money(minorUnits: 100, currencyCode: "JPY"), category: .food)
        for category in ExpenseCategory.allCases {
            expense.category = category
            #expect(expense.categoryID == category.rawValue)
            #expect(expense.category == category)
        }
    }

    @Test("The two stamps are equal on a new row")
    func stampsStartEqual() {
        let expense = Expense(money: Money(minorUnits: 100, currencyCode: "JPY"), category: .food)
        #expect(expense.createdAt == expense.updatedAt)
    }
}
