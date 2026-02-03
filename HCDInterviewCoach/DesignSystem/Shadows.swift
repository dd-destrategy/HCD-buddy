import SwiftUI

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum Shadows {
    static let small = ShadowStyle(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    static let large = ShadowStyle(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
}

extension View {
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
