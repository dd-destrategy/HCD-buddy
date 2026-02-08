import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Platform-agnostic color helper that maps semantic color names to their
/// platform-specific equivalents (NSColor on macOS, UIColor on iOS).
enum PlatformColor {
    /// Window/screen background
    static var windowBackground: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .systemBackground)
        #endif
    }

    /// Secondary/control background
    static var controlBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #endif
    }

    /// Under-page/grouped background
    static var underPageBackground: Color {
        #if os(macOS)
        return Color(nsColor: .underPageBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #endif
    }

    /// Control/tertiary background
    static var controlColor: Color {
        #if os(macOS)
        return Color(nsColor: .controlColor)
        #elseif os(iOS)
        return Color(uiColor: .tertiarySystemBackground)
        #endif
    }

    /// Separator
    static var separator: Color {
        #if os(macOS)
        return Color(nsColor: .separatorColor)
        #elseif os(iOS)
        return Color(uiColor: .separator)
        #endif
    }

    /// Create a Color from a hex string, cross-platform
    static func color(hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return Color(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// Cross-platform hex color extension
#if canImport(UIKit)
import UIKit
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
#endif
