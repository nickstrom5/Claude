import SwiftUI

/// One place for the look. Dark, warm accent, rounded type. Deliberately not "AI gradient".
enum Theme {
    static let background = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let surface = Color(red: 0.12, green: 0.12, blue: 0.15)
    static let surfaceRaised = Color(red: 0.17, green: 0.17, blue: 0.21)
    static let accent = Color(red: 0.98, green: 0.82, blue: 0.35)   // warm shelf-wood yellow
    static let accentSoft = accent.opacity(0.18)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)
    static let danger = Color(red: 0.98, green: 0.42, blue: 0.38)
    static let success = Color(red: 0.45, green: 0.86, blue: 0.58)

    static let cornerRadius: CGFloat = 20
    static let horizontalPadding: CGFloat = 24

    enum Font {
        static func display(_ size: CGFloat = 40) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        static let title = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let headline = SwiftUI.Font.system(size: 18, weight: .semibold, design: .rounded)
        static let body = SwiftUI.Font.system(size: 17, weight: .regular, design: .rounded)
        static let caption = SwiftUI.Font.system(size: 13, weight: .medium, design: .rounded)
        static func mono(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded).monospacedDigit()
        }
    }
}
