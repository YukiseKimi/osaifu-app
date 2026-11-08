import Testing
import CloudKit
import Foundation
import SwiftData
@testable import OsaifuCore

@Suite("Sync status")
struct SyncStatusTests {

    @Test("An empty store has no last change")
    func emptyStoreHasNoChange() throws {
        let context = ModelContext(try StoreSetup.makeInMemoryContainer())
        #expect(try SyncStatus.lastChange(in: context) == nil)
    }

    @Test("The last change is the newest one, whichever expense it is on")
    func lastChangeIsTheNewest() throws {
        let context = ModelContext(try StoreSetup.makeInMemoryContainer())
        let older = Expense(money: Money(minorUnits: 100, currencyCode: "JPY"), category: .food)
        older.updatedAt = Date(timeIntervalSince1970: 1_000)
        let newer = Expense(money: Money(minorUnits: 200, currencyCode: "JPY"), category: .travel)
        newer.updatedAt = Date(timeIntervalSince1970: 2_000)
        context.insert(older)
        context.insert(newer)
        try context.save()

        #expect(try SyncStatus.lastChange(in: context) == Date(timeIntervalSince1970: 2_000))
    }

    @Test("Only an available account syncs")
    func onlyAvailableSyncs() {
        #expect(CloudAccount.available.syncs)
        #expect(!CloudAccount.noAccount.syncs)
        #expect(!CloudAccount.restricted.syncs)
        #expect(!CloudAccount.unknown.syncs)
    }
}

@Suite("The iCloud account read")
struct CloudAccountTests {

    @Test("Each CloudKit status maps to one state", arguments: [
        (CKAccountStatus.available, CloudAccount.available),
        (.noAccount, .noAccount),
        (.restricted, .restricted),
        (.couldNotDetermine, .unknown),
        (.temporarilyUnavailable, .unknown)
    ])
    func statusMapping(status: CKAccountStatus, state: CloudAccount) {
        #expect(SyncStatus.state(for: status) == state)
    }

    // No test calls SyncStatus.account() itself. CKContainer(identifier:)
    // traps in a process that the container is not in the entitlements of,
    // which takes the whole test run down with signal 5. The timeout in that
    // function is checked in the running app instead.

}
