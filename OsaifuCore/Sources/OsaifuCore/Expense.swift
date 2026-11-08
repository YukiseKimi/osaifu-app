import Foundation
import SwiftData

/// A single expense entry.
///
/// The model is intentionally CloudKit-compatible: every stored property has a
/// default value and there are no unique constraints, which is what lets
/// SwiftData sync the data through iCloud across the user's devices.
@Model
public final class Expense {
    public var amount: Double = 0
    public var categoryID: String = ExpenseCategory.other.rawValue
    public var note: String = ""
    public var date: Date = Date.now

    /// Strongly-typed accessor layered over the stored `categoryID` raw value.
    public var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryID) ?? .other }
        set { categoryID = newValue.rawValue }
    }

    public init(amount: Double, category: ExpenseCategory, note: String = "", date: Date = .now) {
        self.amount = amount
        self.categoryID = category.rawValue
        self.note = note
        self.date = date
    }
}
