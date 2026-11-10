import Testing
import Foundation
import SwiftData
@testable import OsaifuCore

@Suite("Preferences")
struct PreferencesTests {

    @Test("The first read makes one row, with the currency it is given")
    func firstReadMakesOneRow() throws {
        let context = ModelContext(try StoreSetup.makeInMemoryContainer())

        let row = try Preferences.current(in: context, fallbackCurrencyCode: "JPY")

        #expect(row.homeCurrencyCode == "JPY")
        #expect(try context.fetchCount(FetchDescriptor<Preferences>()) == 1)
    }

    @Test("A second read gives the same row")
    func secondReadGivesTheSameRow() throws {
        let context = ModelContext(try StoreSetup.makeInMemoryContainer())

        let first = try Preferences.current(in: context, fallbackCurrencyCode: "JPY")
        first.setHomeCurrencyCode("EUR")
        let second = try Preferences.current(in: context, fallbackCurrencyCode: "JPY")

        #expect(second.homeCurrencyCode == "EUR")
        #expect(try context.fetchCount(FetchDescriptor<Preferences>()) == 1)
    }

    @Test("Two rows from two devices become the one that changed last")
    func duplicatesBecomeTheNewest() throws {
        let context = ModelContext(try StoreSetup.makeInMemoryContainer())
        let older = Preferences(homeCurrencyCode: "USD")
        older.updatedAt = Date(timeIntervalSince1970: 1_000)
        let newer = Preferences(homeCurrencyCode: "GBP")
        newer.updatedAt = Date(timeIntervalSince1970: 2_000)
        context.insert(older)
        context.insert(newer)
        try context.save()

        let row = try Preferences.current(in: context, fallbackCurrencyCode: "JPY")

        #expect(row.homeCurrencyCode == "GBP")
        #expect(try context.fetchCount(FetchDescriptor<Preferences>()) == 1)
    }

    @Test("A row that CloudKit made with no currency takes the fallback")
    func emptyRowTakesTheFallback() throws {
        let context = ModelContext(try StoreSetup.makeInMemoryContainer())
        let empty = Preferences(homeCurrencyCode: "")
        context.insert(empty)
        try context.save()

        let row = try Preferences.current(in: context, fallbackCurrencyCode: "KRW")

        #expect(row.homeCurrencyCode == "KRW")
    }

    @Test("Setting the currency moves the timestamp")
    func settingTheCurrencyMovesTheTimestamp() throws {
        let row = Preferences(homeCurrencyCode: "JPY")
        let before = row.updatedAt
        row.setHomeCurrencyCode("USD")
        #expect(row.updatedAt > before)
    }
}
