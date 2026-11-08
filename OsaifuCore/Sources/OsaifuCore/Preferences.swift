import Foundation
import SwiftData

/// The settings that follow the user across devices: one row in the store, so
/// iCloud carries it to the iPhone, the iPad, the Mac and the watch.
@Model
public final class Preferences {
    /// The currency that totals and budgets are in. An expense keeps the
    /// currency it was entered in, which can differ from this one.
    public var homeCurrencyCode: String = ""

    public var updatedAt: Date = Date.now

    public init(homeCurrencyCode: String) {
        self.homeCurrencyCode = homeCurrencyCode
        self.updatedAt = .now
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

    /// The currency the first version of the app displayed, so an existing user
    /// keeps the currency they chose.
    static func legacyCurrencyCode() -> String {
        UserDefaults.standard.string(forKey: "currencyCode") ?? Currency.defaultCode
    }
}
