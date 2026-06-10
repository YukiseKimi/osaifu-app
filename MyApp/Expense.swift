import Foundation
import SwiftData

/// A single expense entry.
///
/// The model is intentionally CloudKit-compatible: every stored property has a
/// default value and there are no unique constraints, which is what lets
/// SwiftData sync the data through iCloud across the user's devices.
@Model
final class Expense {
    var amount: Double = 0
    var categoryID: String = ExpenseCategory.other.rawValue
    var note: String = ""
    var date: Date = Date.now

    /// Strongly-typed accessor layered over the stored `categoryID` raw value.
    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryID) ?? .other }
        set { categoryID = newValue.rawValue }
    }

    init(amount: Double, category: ExpenseCategory, note: String = "", date: Date = .now) {
        self.amount = amount
        self.categoryID = category.rawValue
        self.note = note
        self.date = date
    }
}
