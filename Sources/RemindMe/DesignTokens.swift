import SwiftUI
import AppKit

// MARK: - Spacing

enum Space {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

// MARK: - Radii

enum Radius {
    static let row: CGFloat = 6
    static let field: CGFloat = 6
    static let sheet: CGFloat = 10
    static let window: CGFloat = 12
}

// MARK: - Motion

enum Motion {
    static let insert   = Animation.spring(response: 0.30, dampingFraction: 0.85)
    static let settle   = Animation.spring(response: 0.35, dampingFraction: 0.85)
    static let tint     = Animation.easeInOut(duration: 0.18)
    static let complete = Animation.easeOut(duration: 0.18)
    static let window   = Animation.easeOut(duration: 0.22)

    /// Returns the animation, downgraded to a plain cross-fade when the user prefers reduced motion.
    static func respecting(_ reduceMotion: Bool, _ anim: Animation) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : anim
    }
}

// MARK: - Colors

extension Color {
    /// Urgent. Warm but not alarming. The only literal brand color in the UI.
    static let rmUrgent = Color(
        light: Color(red: 0.961, green: 0.529, blue: 0.122),  // #F5871F
        dark:  Color(red: 1.000, green: 0.624, blue: 0.039)   // #FF9F0A
    )

    /// Solid fallback under .regularMaterial in the floating window.
    static let rmWindowFallback = Color(
        light: Color(red: 0.984, green: 0.984, blue: 0.992),  // #FBFBFD
        dark:  Color(red: 0.118, green: 0.118, blue: 0.118)   // #1E1E1E
    )

    init(light: Color, dark: Color) {
        let lightNS = NSColor(light)
        let darkNS = NSColor(dark)
        let dynamic = NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark ? darkNS : lightNS
        }
        self = Color(nsColor: dynamic)
    }
}
