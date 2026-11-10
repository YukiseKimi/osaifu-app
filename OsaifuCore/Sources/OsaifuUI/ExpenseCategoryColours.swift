import SwiftUI
import OsaifuModel

/// What a category looks like. The colours live here, not beside the records,
/// so the model layer needs no UI framework.
public extension ExpenseCategory {
    /// A vivid, stable color so each category looks the same — and pops — in
    /// every chart, badge, and list.
    public var color: Color {
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
    public var gradient: LinearGradient {
        LinearGradient(
            colors: [color.mix(with: .white, by: 0.18), color.mix(with: .black, by: 0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
