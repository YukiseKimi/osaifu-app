import Foundation
import SwiftData

/// The first shape of the store: the amount is a `Double`, and there is no
/// identifier and no currency on an expense.
public enum OsaifuSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    public static var models: [any PersistentModel.Type] { [Expense.self] }
}

/// The second shape: an expense keeps whole minor units, its own currency, a
/// stable identifier and two timestamps. It still holds the old `amount`, so
/// the migration can read it. Version 3 drops that property.
public enum OsaifuSchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    public static var models: [any PersistentModel.Type] { [Expense.self] }
}

public enum OsaifuMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [OsaifuSchemaV1.self, OsaifuSchemaV2.self]
    }

    public static var stages: [MigrationStage] { [v1ToV2] }

    /// The new properties arrive with their defaults, then this stage fills the
    /// minor units from each old `Double` amount.
    static let v1ToV2 = MigrationStage.custom(
        fromVersion: OsaifuSchemaV1.self,
        toVersion: OsaifuSchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            try fillMinorUnits(in: context, currencyCode: legacyDisplayCurrencyCode())
        }
    )

    /// The first version formatted every amount with one display currency, kept
    /// in UserDefaults, so that is the currency each old amount was entered in.
    static func legacyDisplayCurrencyCode() -> String {
        UserDefaults.standard.string(forKey: "currencyCode") ?? Currency.defaultCode
    }

    /// Fills `minorUnits` and `currencyCode` for every expense that has none.
    static func fillMinorUnits(in context: ModelContext, currencyCode: String) throws {
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        for expense in expenses where expense.minorUnits == 0 {
            expense.money = Money(decimal: Decimal(expense.amount), currencyCode: currencyCode)
            // Version 1 kept no timestamps, so the date of the expense is the
            // only truth there is for these two.
            expense.createdAt = expense.date
            expense.updatedAt = expense.date
        }
        if context.hasChanges {
            try context.save()
        }
    }
}
