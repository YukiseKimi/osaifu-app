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

    /// A vivid, stable color so each category looks the same — and pops — in
    /// every chart, badge, and list.
    var color: Color {
        switch self {
        case .food: Color(hex: 0xFF5E5B)
        case .groceries: Color(hex: 0x2ED573)
        case .transport: Color(hex: 0x4AA8FF)
        case .housing: Color(hex: 0xFFB020)
        case .utilities: Color(hex: 0xFFD23F)
        case .health: Color(hex: 0xFF4D7D)
        case .entertainment: Color(hex: 0x9B5DE5)
        case .shopping: Color(hex: 0xF15BB5)
        case .education: Color(hex: 0x5D7CFF)
        case .travel: Color(hex: 0x00D1C1)
        case .other: Color(hex: 0x8E9AAB)
        }
    }

    /// A glossy gradient derived from the category color, used for icon badges.
    var gradient: LinearGradient {
        LinearGradient(
            colors: [color.mix(with: .white, by: 0.18), color.mix(with: .black, by: 0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
