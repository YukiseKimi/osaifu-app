import AppIntents
import OsaifuCore

/// The categories, as Siri and the Shortcuts app offer them.
///
/// AppIntents refuses an enum that lives in another module, so this one
/// mirrors `ExpenseCategory` in the app target. The initializer switches over
/// every case with no default, so a new category stops the build here until
/// it is added to both.
enum CategoryChoice: String, AppEnum, CaseIterable {
    case food
    case groceries
    case transport
    case housing
    case utilities
    case health
    case entertainment
    case shopping
    case education
    case travel
    case other

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"

    static let caseDisplayRepresentations: [CategoryChoice: DisplayRepresentation] = [
        .food: "Food & Dining",
        .groceries: "Groceries",
        .transport: "Transport",
        .housing: "Housing",
        .utilities: "Utilities",
        .health: "Health",
        .entertainment: "Entertainment",
        .shopping: "Shopping",
        .education: "Education",
        .travel: "Travel",
        .other: "Other",
    ]

    init(_ category: ExpenseCategory) {
        switch category {
        case .food: self = .food
        case .groceries: self = .groceries
        case .transport: self = .transport
        case .housing: self = .housing
        case .utilities: self = .utilities
        case .health: self = .health
        case .entertainment: self = .entertainment
        case .shopping: self = .shopping
        case .education: self = .education
        case .travel: self = .travel
        case .other: self = .other
        }
    }

    var category: ExpenseCategory {
        switch self {
        case .food: .food
        case .groceries: .groceries
        case .transport: .transport
        case .housing: .housing
        case .utilities: .utilities
        case .health: .health
        case .entertainment: .entertainment
        case .shopping: .shopping
        case .education: .education
        case .travel: .travel
        case .other: .other
        }
    }
}
