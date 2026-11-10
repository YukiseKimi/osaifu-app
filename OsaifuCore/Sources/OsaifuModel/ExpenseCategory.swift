import Foundation

/// The set of common expense categories the user can choose from.
public enum ExpenseCategory: String, CaseIterable, Identifiable, Codable, Sendable {
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

    public var id: String { rawValue }

    /// Human-readable name shown throughout the UI.
    public var title: String {
        switch self {
        case .food: "Food & Dining"
        case .groceries: "Groceries"
        case .transport: "Transport"
        case .housing: "Housing"
        case .utilities: "Utilities"
        case .health: "Health"
        case .entertainment: "Entertainment"
        case .shopping: "Shopping"
        case .education: "Education"
        case .travel: "Travel"
        case .other: "Other"
        }
    }

    /// SF Symbol used to represent the category.
    public var systemImage: String {
        switch self {
        case .food: "fork.knife"
        case .groceries: "cart.fill"
        case .transport: "car.fill"
        case .housing: "house.fill"
        case .utilities: "bolt.fill"
        case .health: "cross.case.fill"
        case .entertainment: "gamecontroller.fill"
        case .shopping: "bag.fill"
        case .education: "book.fill"
        case .travel: "airplane"
        case .other: "ellipsis.circle.fill"
        }
    }

}
