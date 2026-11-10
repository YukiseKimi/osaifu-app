import Testing
import Foundation
import SwiftData
@testable import OsaifuModel

@Suite("The monthly limit")
struct BudgetTests {

    private func context() throws -> ModelContext {
        ModelContext(try StoreSetup.makeInMemoryContainer())
    }

    @Test("No limit until the user sets one")
    func noLimitAtFirst() throws {
        #expect(try Budget.current(in: try context()) == nil)
    }

    @Test("Setting the limit makes the one row")
    func settingMakesTheRow() throws {
        let context = try context()
        try Budget.setLimit(Money(minorUnits: 120_000, currencyCode: "JPY"), in: context)

        let budget = try #require(try Budget.current(in: context))
        #expect(budget.limit == Money(minorUnits: 120_000, currencyCode: "JPY"))
        #expect(try context.fetchCount(FetchDescriptor<Budget>()) == 1)
    }

    @Test("Setting it again changes the same row")
    func settingAgainChangesTheRow() throws {
        let context = try context()
        try Budget.setLimit(Money(minorUnits: 120_000, currencyCode: "JPY"), in: context)
        try Budget.setLimit(Money(minorUnits: 90_000, currencyCode: "JPY"), in: context)

        #expect(try Budget.current(in: context)?.limit.minorUnits == 90_000)
        #expect(try context.fetchCount(FetchDescriptor<Budget>()) == 1)
    }

    @Test("Removing the limit hides it but keeps the amount")
    func removingKeepsTheAmount() throws {
        let context = try context()
        try Budget.setLimit(Money(minorUnits: 120_000, currencyCode: "JPY"), in: context)
        try Budget.removeLimit(in: context)

        #expect(try Budget.current(in: context) == nil)
        #expect(try context.fetch(FetchDescriptor<Budget>()).first?.limitMinorUnits == 120_000)

        try Budget.setLimit(Money(minorUnits: 120_000, currencyCode: "JPY"), in: context)
        #expect(try Budget.current(in: context) != nil)
    }

    @Test("Two rows from two devices become the one that changed last")
    func duplicatesBecomeTheNewest() throws {
        let context = try context()
        let older = Budget(limit: Money(minorUnits: 50_000, currencyCode: "JPY"))
        older.updatedAt = Date(timeIntervalSince1970: 1_000)
        let newer = Budget(limit: Money(minorUnits: 80_000, currencyCode: "JPY"))
        newer.updatedAt = Date(timeIntervalSince1970: 2_000)
        context.insert(older)
        context.insert(newer)
        try context.save()

        #expect(try Budget.current(in: context)?.limitMinorUnits == 80_000)
        #expect(try context.fetchCount(FetchDescriptor<Budget>()) == 1)
    }
}
