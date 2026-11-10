import Foundation
import SwiftData

/// The settings that follow the user across devices: one row in the store, so
/// iCloud carries it to the iPhone, the iPad, the Mac and the watch.
@Model
public final class Preferences {
    /// The currency that totals and budgets are in. An expense keeps the
    /// currency it was entered in, which can differ from this one.
    public var homeCurrencyCode: String = ""

    /// Off: each month starts at the full limit. On: what was left of last
    /// month is added to this month's limit.
    public var carriesRemainderOver: Bool = false

    /// Off: an expense in another currency is left out of the totals and the
    /// budget, as it is today. On: it is converted with the rate the user gave.
    public var countsForeignSpend: Bool = false

    public var updatedAt: Date = Date.now

    public init(homeCurrencyCode: String) {
        self.homeCurrencyCode = homeCurrencyCode
        self.updatedAt = .now
    }

    public func setCarriesRemainderOver(_ on: Bool) {
        carriesRemainderOver = on
        updatedAt = .now
    }

    public func setCountsForeignSpend(_ on: Bool) {
        countsForeignSpend = on
        updatedAt = .now
    }

    public func setHomeCurrencyCode(_ code: String) {
        homeCurrencyCode = code
        updatedAt = .now
    }
}

public extension Preferences {
    /// The one settings row.
    ///
    /// Two devices with no network can each make their own row, and CloudKit
    /// then delivers both. This keeps the row that changed last and deletes the
    /// rest, so the answer is the same on every device.
    static func current(in context: ModelContext, fallbackCurrencyCode: String) throws -> Preferences {
        var descriptor = FetchDescriptor<Preferences>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        descriptor.fetchLimit = 50
        let rows = try context.fetch(descriptor)

        guard let newest = rows.first else {
            let made = Preferences(homeCurrencyCode: fallbackCurrencyCode)
            context.insert(made)
            try context.save()
            return made
        }

        if rows.count > 1 {
            for duplicate in rows.dropFirst() {
                context.delete(duplicate)
            }
            try context.save()
        }
        if newest.homeCurrencyCode.isEmpty {
            newest.setHomeCurrencyCode(fallbackCurrencyCode)
            try context.save()
        }
        return newest
    }

    /// The currency the first version of the app displayed, so an existing
    /// user keeps the currency they chose.
    ///
    /// The old app wrote it into its own defaults, which a widget and the
    /// watch cannot read. The App Group can be read by all of them, so the
    /// answer is looked for there first and mirrored there when it is found
    /// in the app's own defaults. Before that mirroring has happened once,
    /// an extension falls through to the device's currency, as it always did.
    static func legacyCurrencyCode() -> String {
        let shared = UserDefaults(suiteName: StoreSetup.appGroupID)
        if let code = shared?.string(forKey: legacyCurrencyKey) { return code }
        if let code = UserDefaults.standard.string(forKey: legacyCurrencyKey) {
            shared?.set(code, forKey: legacyCurrencyKey)
            return code
        }
        return Currency.defaultCode
    }

    /// The key the first version of the app wrote the display currency under.
    static var legacyCurrencyKey: String { "currencyCode" }
}
