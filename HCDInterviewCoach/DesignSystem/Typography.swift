import SwiftUI

/// Typography tokens with Dynamic Type support on iOS.
/// On macOS, fixed sizes are used (desktop viewing distance).
/// On iOS, text styles map to Dynamic Type categories for accessibility.
enum Typography {
    #if os(iOS)
    static let display = Font.largeTitle.weight(.bold)
    static let heading1 = Font.title.weight(.semibold)
    static let heading2 = Font.title3.weight(.semibold)
    static let heading3 = Font.headline
    static let body = Font.body
    static let bodyMedium = Font.body.weight(.medium)
    static let caption = Font.caption
    static let small = Font.caption2
    #else
    static let display = Font.system(size: 32, weight: .bold)
    static let heading1 = Font.system(size: 24, weight: .semibold)
    static let heading2 = Font.system(size: 18, weight: .semibold)
    static let heading3 = Font.system(size: 16, weight: .semibold)
    static let body = Font.system(size: 14, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .medium)
    static let caption = Font.system(size: 12, weight: .regular)
    static let small = Font.system(size: 10, weight: .regular)
    #endif
}
