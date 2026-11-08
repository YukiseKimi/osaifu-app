import Testing
import Foundation
import SwiftData
@testable import OsaifuCore

@Suite("The migration to minor units")
struct MigrationTests {

    /// An expense as version 1 of the store held it: a Double amount, no
    /// currency and no minor units.
    private func legacyExpense(amount: Double) -> Expense {
        let expense = Expense(money: Money(minorUnits: 0, currencyCode: ""), category: .food)
        expense.amount = amount
        expense.minorUnits = 0
        expense.currencyCode = ""
        return expense
    }

    @Test("An old amount in a two-digit currency becomes minor units")
    func fillsATwoDigitCurrency() throws {
        let context = ModelContext(try StoreSetup.makeInMemoryContainer())
        let expense = legacyExpense(amount: 12.8)
        context.insert(expense)

        try OsaifuMigrationPlan.fillMinorUnits(in: context, currencyCode: "USD")

        #expect(expense.minorUnits == 1280)
        #expect(expense.currencyCode == "USD")
        #expect(expense.money.decimalValue == Decimal(string: "12.80"))
    }

    @Test("An old amount in yen keeps its whole number")
    func fillsYen() throws {
        let context = ModelContext(try StoreSetup.makeInMemoryContainer())
        let expense = legacyExpense(amount: 1280)
        context.insert(expense)

        try OsaifuMigrationPlan.fillMinorUnits(in: context, currencyCode: "JPY")

        #expect(expense.minorUnits == 1280)
        #expect(expense.money.decimalValue == Decimal(1280))
    }

    @Test("An expense that already has minor units is left alone")
    func leavesFilledExpensesAlone() throws {
        let context = ModelContext(try StoreSetup.makeInMemoryContainer())
        let expense = Expense(money: Money(minorUnits: 500, currencyCode: "EUR"), category: .travel)
        expense.amount = 999
        context.insert(expense)

        try OsaifuMigrationPlan.fillMinorUnits(in: context, currencyCode: "USD")

        #expect(expense.minorUnits == 500)
        #expect(expense.currencyCode == "EUR")
    }

    @Test("The timestamps of a migrated expense follow its date")
    func timestampsFollowTheDate() throws {
        let context = ModelContext(try StoreSetup.makeInMemoryContainer())
        let when = Date(timeIntervalSince1970: 1_600_000_000)
        let expense = legacyExpense(amount: 10)
        expense.date = when
        context.insert(expense)

        try OsaifuMigrationPlan.fillMinorUnits(in: context, currencyCode: "USD")

        #expect(expense.createdAt == when)
        #expect(expense.updatedAt == when)
    }

    @Test("A backup is made of a store that exists, and skipped when there is none")
    func backsUpOnlyAnExistingStore() throws {
        let folder = URL.temporaryDirectory.appending(path: "osaifu-backup-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let missing = folder.appending(path: "default.store")
        #expect(try StoreSetup.backUpStore(at: missing) == nil)

        try Data("expenses".utf8).write(to: missing)
        let copy = try StoreSetup.backUpStore(at: missing)
        let copyURL = try #require(copy)
        #expect(FileManager.default.fileExists(atPath: copyURL.path))
        #expect(try Data(contentsOf: copyURL) == Data("expenses".utf8))
        #expect(copyURL.lastPathComponent.hasPrefix("default-"))
    }
}

@Suite("Moving the store into the App Group")
struct StoreCopyTests {

    private func makeFolder() throws -> URL {
        let folder = URL.temporaryDirectory.appending(path: "osaifu-copy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    @Test("The store and the two files beside it are copied")
    func copiesTheWholeStore() throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let old = folder.appending(path: "old/default.store")
        try FileManager.default.createDirectory(at: old.deletingLastPathComponent(), withIntermediateDirectories: true)
        for suffix in ["", "-wal", "-shm"] {
            try Data(suffix.utf8).write(to: URL(filePath: old.path + suffix))
        }
        let new = folder.appending(path: "group/default.store")

        #expect(try StoreSetup.copyStoreIfNeeded(from: old, to: new) == true)

        for suffix in ["", "-wal", "-shm"] {
            #expect(FileManager.default.fileExists(atPath: new.path + suffix))
        }
        #expect(FileManager.default.fileExists(atPath: old.path), "the old store stays where it is")
    }

    @Test("A store that is already in the group is left alone")
    func doesNotCopyTwice() throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let old = folder.appending(path: "old.store")
        let new = folder.appending(path: "new.store")
        try Data("old".utf8).write(to: old)
        try Data("new".utf8).write(to: new)

        #expect(try StoreSetup.copyStoreIfNeeded(from: old, to: new) == false)
        #expect(try Data(contentsOf: new) == Data("new".utf8))
    }

    @Test("A first launch has no store to copy")
    func nothingToCopy() throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(try StoreSetup.copyStoreIfNeeded(
            from: folder.appending(path: "missing.store"),
            to: folder.appending(path: "new.store")
        ) == false)
    }
}
