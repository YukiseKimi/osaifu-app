import SwiftUI

public extension Color {
    /// Creates a color from a 24-bit RGB hex value, e.g. `Color(hex: 0xFF5E5B)`.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
