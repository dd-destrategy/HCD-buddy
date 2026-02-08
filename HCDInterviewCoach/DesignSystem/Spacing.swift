import SwiftUI

/// Spacing tokens with responsive values for mobile screens.
/// On macOS, standard desktop spacing is used.
/// On iPhone, larger spacing values are reduced for screen economy.
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16

    #if os(iOS)
    static var xl: CGFloat {
        UIDevice.current.userInterfaceIdiom == .phone ? 20 : 24
    }
    static var xxl: CGFloat {
        UIDevice.current.userInterfaceIdiom == .phone ? 32 : 40
    }
    #else
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 40
    #endif

    /// Minimum recommended touch target size (44pt per HIG)
    static let touchTarget: CGFloat = 44
}
