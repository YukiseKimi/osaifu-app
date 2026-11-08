import Foundation
import SwiftData

/// A single expense entry.
///
/// The model is CloudKit-compatible: every stored property has a default value
/// and there are no unique constraints, which is what lets SwiftData sync the
/// data through iCloud across the user's devices.
@Model
public final class Expense {
    /// A stable identifier, the same on each device. Deep links and the watch
    /// app use it to name one expense.
    public var id: UUID = UUID()

    /// The amount, in the whole minor units of `currencyCode`: 1280 is ¥1,280
    /// and $12.80.
    public var minorUnits: Int = 0

    /// The currency the user entered the amount in. It never changes with the
    /// home currency.
    public var currencyCode: String = ""

    public var categoryID: String = ExpenseCategory.other.rawValue
    public var note: String = ""
    public var date: Date = Date.now
    public var createdAt: Date = Date.now
    public var updatedAt: Date = Date.now

    /// The amount as the first version of the app stored it. Only the migration
    /// reads it, and version 3 of the schema drops it. Nothing else may use it.
    public var amount: Double = 0

    /// The amount and its currency together.
    public var money: Money {
        get { Money(minorUnits: minorUnits, currencyCode: currencyCode) }
        set {
            minorUnits = newValue.minorUnits
            currencyCode = newValue.currencyCode
        }
    }

    /// Strongly-typed accessor layered over the stored `categoryID` raw value.
    public var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryID) ?? .other }
        set { categoryID = newValue.rawValue }
    }

    public init(money: Money, category: ExpenseCategory, note: String = "", date: Date = .now) {
        self.id = UUID()
        self.minorUnits = money.minorUnits
        self.currencyCode = money.currencyCode
        self.categoryID = category.rawValue
        self.note = note
        self.date = date
        // One reading of the clock, so the two stamps are equal on a new row.
        let now = Date.now
        self.createdAt = now
        self.updatedAt = now
    }

}
