import SwiftUI
import OsaifuCore

extension Color {
    /// The app's signature accent — a vivid violet used for tint and glows.
    static let appAccent = Color(hex: 0x7C5CFF)
}

extension View {
    /// Adds a soft, layered neon glow in the given color.
    func glow(_ color: Color, radius: CGFloat = 6) -> some View {
        shadow(color: color.opacity(0.55), radius: radius)
            .shadow(color: color.opacity(0.30), radius: radius * 2.2)
    }

    /// Places the view over the ambient mood background and hides the default
    /// scrollable-container background so the glow shows through.
    func moodBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(MoodBackground())
    }
}

/// An ambient, scheme-adaptive backdrop with soft colored glows that gives the
/// app a livelier, "glowy" feel behind its content.
struct MoodBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Rectangle().fill(.background)
                Circle()
                    .fill(Color.appAccent.opacity(0.30))
                    .frame(width: w * 0.95)
                    .blur(radius: 100)
                    .offset(x: -w * 0.32, y: -h * 0.20)
                Circle()
                    .fill(Color(hex: 0x00D1C1).opacity(0.22))
                    .frame(width: w * 0.85)
                    .blur(radius: 100)
                    .offset(x: w * 0.42, y: h * 0.10)
                Circle()
                    .fill(Color(hex: 0xF15BB5).opacity(0.16))
                    .frame(width: w * 0.70)
                    .blur(radius: 100)
                    .offset(x: w * 0.10, y: h * 0.52)
            }
        }
        .ignoresSafeArea()
    }
}

/// The user's chosen appearance: follow the system, or force light/dark.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    /// The color scheme to force, or `nil` to follow the device setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// A category's icon rendered as a glossy, glowing rounded badge.
struct CategoryIcon: View {
    let category: ExpenseCategory
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: category.systemImage)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(category.gradient)
            )
            .glow(category.color, radius: 5)
    }
}
