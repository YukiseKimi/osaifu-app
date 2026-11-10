import Foundation
import SwiftData

/// The limit for one calendar month, in the home currency.
///
/// There is one of these, for the month as a whole. A limit for each category
/// is another property on this model, which costs one lightweight stage, so
/// the shape does not stand in the way of adding it later.
@Model
public final class Budget {
    public var id: UUID = UUID()

    /// The limit, in the whole minor units of `currencyCode`.
    public var limitMinorUnits: Int = 0

    /// The home currency as it was when the user set the limit.
    public var currencyCode: String = ""

    /// A limit the user removed stays as a row, so the amount comes back if
    /// they set one again.
    public var isActive: Bool = true

    public var updatedAt: Date = Date.now

    public var limit: Money {
        get { Money(minorUnits: limitMinorUnits, currencyCode: currencyCode) }
        set {
            limitMinorUnits = newValue.minorUnits
            currencyCode = newValue.currencyCode
            updatedAt = .now
        }
    }

    public init(limit: Money) {
        self.id = UUID()
        self.limitMinorUnits = limit.minorUnits
        self.currencyCode = limit.currencyCode
        self.isActive = true
        self.updatedAt = .now
    }
}

public extension Budget {
    /// The one budget, or nil when the user has set no limit.
    ///
    /// Two devices with no network can each make a row, as they can for the
    /// settings, so this keeps the row that changed last and deletes the rest.
    static func current(in context: ModelContext) throws -> Budget? {
        var descriptor = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        descriptor.fetchLimit = 50
        let rows = try context.fetch(descriptor)
        guard let newest = rows.first else { return nil }
        if rows.count > 1 {
            for duplicate in rows.dropFirst() { context.delete(duplicate) }
            try context.save()
        }
        return newest.isActive ? newest : nil
    }

    /// Sets the limit, making the row when there is none.
    @discardableResult
    static func setLimit(_ limit: Money, in context: ModelContext) throws -> Budget {
        var descriptor = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        if let row = try context.fetch(descriptor).first {
            row.limit = limit
            row.isActive = true
            try context.save()
            return row
        }
        let made = Budget(limit: limit)
        context.insert(made)
        try context.save()
        return made
    }

    /// Takes the limit away, and keeps the amount for next time.
    static func removeLimit(in context: ModelContext) throws {
        let rows = try context.fetch(FetchDescriptor<Budget>())
        for row in rows {
            row.isActive = false
            row.updatedAt = .now
        }
        if context.hasChanges { try context.save() }
    }
}
