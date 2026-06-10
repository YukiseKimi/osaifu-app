import SwiftUI

/// The set of common expense categories the user can choose from.
enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
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

    var id: String { rawValue }

    /// Human-readable name shown throughout the UI.
    var title: String {
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
    var systemImage: String {
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

    /// A stable color so each category looks the same in every chart and list.
    var color: Color {
        switch self {
        case .food: .orange
        case .groceries: .green
        case .transport: .blue
        case .housing: .brown
        case .utilities: .yellow
        case .health: .red
        case .entertainment: .purple
        case .shopping: .pink
        case .education: .indigo
        case .travel: .teal
        case .other: .gray
        }
    }
}
