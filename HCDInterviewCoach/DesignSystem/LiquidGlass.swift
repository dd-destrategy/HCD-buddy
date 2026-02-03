//
//  LiquidGlass.swift
//  HCDInterviewCoach
//
//  Liquid Glass UI System - Modern glassmorphism design system
//  with impressive visual effects for macOS.
//

import SwiftUI

// MARK: - Glass Material Styles

/// Material styles for glass effects, ranging from subtle to bold
enum GlassMaterial {
    /// Subtle, barely visible blur - for background overlays
    case ultraThin
    /// Light frosted glass - for secondary panels
    case thin
    /// Standard glass effect - for most UI elements
    case regular
    /// Heavy frosted glass - for prominent cards
    case thick
    /// Reflective, metallic glass - for accent elements
    case chrome

    /// Returns the corresponding SwiftUI Material
    var material: Material {
        switch self {
        case .ultraThin:
            return .ultraThinMaterial
        case .thin:
            return .thinMaterial
        case .regular:
            return .regularMaterial
        case .thick:
            return .thickMaterial
        case .chrome:
            return .bar
        }
    }

    /// Background opacity for the glass tint
    var tintOpacity: Double {
        switch self {
        case .ultraThin: return 0.02
        case .thin: return 0.05
        case .regular: return 0.08
        case .thick: return 0.12
        case .chrome: return 0.15
        }
    }

    /// Shadow intensity for depth
    var shadowOpacity: Double {
        switch self {
        case .ultraThin: return 0.05
        case .thin: return 0.08
        case .regular: return 0.12
        case .thick: return 0.18
        case .chrome: return 0.25
        }
    }
}

// MARK: - Glass Border Styles

/// Border gradient styles for glass elements
enum GlassBorderStyle {
    /// No border
    case none
    /// Subtle white-to-transparent gradient for depth
    case subtle
    /// Standard glass border
    case standard
    /// Rainbow shimmer for active/highlighted states
    case rainbow
    /// Accent color glow for focused elements
    case accent(Color)
    /// Custom gradient
    case custom(Gradient)

    /// Returns the gradient for the border
    func gradient(colorScheme: ColorScheme) -> Gradient {
        switch self {
        case .none:
            return Gradient(colors: [.clear])

        case .subtle:
            return Gradient(colors: [
                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                Color.clear,
                Color.white.opacity(colorScheme == .dark ? 0.03 : 0.05)
            ])

        case .standard:
            return Gradient(colors: [
                Color.white.opacity(colorScheme == .dark ? 0.25 : 0.6),
                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2),
                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3)
            ])

        case .rainbow:
            return Gradient(colors: [
                Color.purple.opacity(0.6),
                Color.blue.opacity(0.6),
                Color.cyan.opacity(0.6),
                Color.green.opacity(0.6),
                Color.yellow.opacity(0.6),
                Color.orange.opacity(0.6),
                Color.red.opacity(0.6),
                Color.purple.opacity(0.6)
            ])

        case .accent(let color):
            return Gradient(colors: [
                color.opacity(0.8),
                color.opacity(0.4),
                color.opacity(0.2),
                color.opacity(0.6)
            ])

        case .custom(let gradient):
            return gradient
        }
    }
}

// MARK: - Liquid Glass View Modifier

/// Primary modifier that applies the liquid glass effect to any view
struct LiquidGlassModifier: ViewModifier {
    let material: GlassMaterial
    let cornerRadius: CGFloat
    let borderStyle: GlassBorderStyle
    let borderWidth: CGFloat
    let shadowRadius: CGFloat
    let enableHover: Bool
    let enablePress: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var shimmerPhase: CGFloat = 0

    init(
        material: GlassMaterial = .regular,
        cornerRadius: CGFloat = CornerRadius.large,
        borderStyle: GlassBorderStyle = .standard,
        borderWidth: CGFloat = 1,
        shadowRadius: CGFloat = 8,
        enableHover: Bool = true,
        enablePress: Bool = false
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.borderStyle = borderStyle
        self.borderWidth = borderWidth
        self.shadowRadius = shadowRadius
        self.enableHover = enableHover
        self.enablePress = enablePress
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundLayer)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(borderOverlay)
            .overlay(shimmerOverlay)
            .shadow(
                color: Color.black.opacity(material.shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
            .shadow(
                color: Color.black.opacity(material.shadowOpacity * 0.3),
                radius: shadowRadius / 4,
                x: 0,
                y: 2
            )
            .scaleEffect(pressScale)
            .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .onHover { hovering in
                if enableHover {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        isHovered = hovering
                    }
                }
            }
            .simultaneousGesture(
                enablePress ? DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
                : nil
            )
    }

    // MARK: - Background Layer

    @ViewBuilder
    private var backgroundLayer: some View {
        if reduceTransparency {
            // Solid background for reduced transparency mode
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color(white: 0.15)
                    : Color(white: 0.95))
        } else {
            ZStack {
                // Base material blur
                material.material

                // Color tint overlay
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(material.tintOpacity)
                            : Color.black.opacity(material.tintOpacity * 0.5)
                    )

                // Hover highlight
                if isHovered && enableHover {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.05)
                                : Color.white.opacity(0.3)
                        )
                }
            }
        }
    }

    // MARK: - Border Overlay

    @ViewBuilder
    private var borderOverlay: some View {
        if case .none = borderStyle {
            EmptyView()
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    AngularGradient(
                        gradient: borderStyle.gradient(colorScheme: colorScheme),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    lineWidth: borderWidth
                )
        }
    }

    // MARK: - Shimmer Overlay

    @ViewBuilder
    private var shimmerOverlay: some View {
        if isHovered && !reduceMotion {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0)
                        ]),
                        startPoint: UnitPoint(x: shimmerPhase - 0.5, y: shimmerPhase - 0.5),
                        endPoint: UnitPoint(x: shimmerPhase + 0.5, y: shimmerPhase + 0.5)
                    )
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        shimmerPhase = 1.5
                    }
                }
                .onDisappear {
                    shimmerPhase = 0
                }
        }
    }

    // MARK: - Press Scale

    private var pressScale: CGFloat {
        if enablePress && isPressed {
            return 0.98
        }
        return 1.0
    }
}

// MARK: - Glass Card Modifier

/// Optimized modifier for content cards (insights, topics, etc.)
struct GlassCardModifier: ViewModifier {
    let isSelected: Bool
    let accentColor: Color?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .modifier(LiquidGlassModifier(
                material: .regular,
                cornerRadius: CornerRadius.large,
                borderStyle: isSelected
                    ? .accent(accentColor ?? .accentColor)
                    : .subtle,
                borderWidth: isSelected ? 1.5 : 1,
                shadowRadius: isSelected ? 12 : 6,
                enableHover: true,
                enablePress: true
            ))
    }
}

// MARK: - Glass Panel Modifier

/// Optimized modifier for side panels (transcript, coaching sidebar)
struct GlassPanelModifier: ViewModifier {
    let edge: Edge

    @Environment(\.colorScheme) private var colorScheme

    private var cornerRadii: RectangleCornerRadii {
        switch edge {
        case .leading:
            return RectangleCornerRadii(
                topLeading: 0,
                bottomLeading: 0,
                bottomTrailing: CornerRadius.xl,
                topTrailing: CornerRadius.xl
            )
        case .trailing:
            return RectangleCornerRadii(
                topLeading: CornerRadius.xl,
                bottomLeading: CornerRadius.xl,
                bottomTrailing: 0,
                topTrailing: 0
            )
        case .top:
            return RectangleCornerRadii(
                topLeading: 0,
                bottomLeading: CornerRadius.xl,
                bottomTrailing: CornerRadius.xl,
                topTrailing: 0
            )
        case .bottom:
            return RectangleCornerRadii(
                topLeading: CornerRadius.xl,
                bottomLeading: 0,
                bottomTrailing: 0,
                topTrailing: CornerRadius.xl
            )
        }
    }

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .clipShape(UnevenRoundedRectangle(cornerRadii: cornerRadii, style: .continuous))
            .overlay(
                UnevenRoundedRectangle(cornerRadii: cornerRadii, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.5),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Glass Button Modifier

/// Optimized modifier for interactive buttons
struct GlassButtonModifier: ViewModifier {
    let isActive: Bool
    let style: GlassButtonStyle

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    @State private var isPressed = false

    enum GlassButtonStyle {
        case primary
        case secondary
        case destructive
        case ghost
    }

    private var accentColor: Color {
        switch style {
        case .primary: return .accentColor
        case .secondary: return colorScheme == .dark ? .white : .black
        case .destructive: return .red
        case .ghost: return .clear
        }
    }

    func body(content: Content) -> some View {
        content
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(buttonBorder)
            .shadow(
                color: isActive ? accentColor.opacity(0.3) : .black.opacity(0.1),
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 1 : 2
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { isHovered = $0 }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if isEnabled { isPressed = true } }
                    .onEnded { _ in isPressed = false }
            )
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if style == .ghost {
            Color.clear
        } else if isActive {
            ZStack {
                accentColor.opacity(0.2)
                if isHovered {
                    accentColor.opacity(0.1)
                }
            }
        } else {
            ZStack {
                Material.ultraThinMaterial
                if isHovered {
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3)
                }
            }
        }
    }

    @ViewBuilder
    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        isActive ? accentColor.opacity(0.5) : Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                        isActive ? accentColor.opacity(0.2) : Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Glass Toolbar Modifier

/// Optimized modifier for toolbar backgrounds
struct GlassToolbarModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(.bar)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1)
                    .offset(y: -0.5),
                alignment: .top
            )
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(height: 0.5),
                alignment: .bottom
            )
    }
}

// MARK: - Glass Sheet Modifier

/// Optimized modifier for modal sheets
struct GlassSheetModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(sheetBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
            .overlay(sheetBorder)
            .shadow(color: .black.opacity(0.3), radius: 40, x: 0, y: 20)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var sheetBackground: some View {
        if reduceTransparency {
            colorScheme == .dark
                ? Color(white: 0.12)
                : Color(white: 0.98)
        } else {
            ZStack {
                Material.thickMaterial
                Color.white.opacity(colorScheme == .dark ? 0.03 : 0.5)
            }
        }
    }

    private var sheetBorder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.7),
                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2),
                        Color.clear,
                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
    }
}

// MARK: - Glass Floating Modifier

/// Optimized modifier for floating elements (coaching prompts, tooltips)
struct GlassFloatingModifier: ViewModifier {
    let isActive: Bool
    let pulseAnimation: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var glowPhase: CGFloat = 0
    @State private var floatOffset: CGFloat = 0

    init(isActive: Bool = true, pulseAnimation: Bool = false) {
        self.isActive = isActive
        self.pulseAnimation = pulseAnimation
    }

    func body(content: Content) -> some View {
        content
            .background(floatingBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .overlay(floatingBorder)
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
            .shadow(color: Color.accentColor.opacity(isActive ? 0.2 : 0), radius: 15, x: 0, y: 0)
            .offset(y: floatOffset)
            .onAppear {
                if pulseAnimation && !reduceMotion {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        floatOffset = -4
                        glowPhase = 1
                    }
                }
            }
    }

    @ViewBuilder
    private var floatingBackground: some View {
        if reduceTransparency {
            colorScheme == .dark
                ? Color(white: 0.18)
                : Color(white: 0.96)
        } else {
            ZStack {
                Material.regularMaterial
                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.4)

                // Animated glow effect
                if isActive && !reduceMotion {
                    RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.accentColor.opacity(0.1 * glowPhase),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                }
            }
        }
    }

    private var floatingBorder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
            .stroke(
                AngularGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.3 : 0.8),
                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                        Color.white.opacity(colorScheme == .dark ? 0.3 : 0.8)
                    ],
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                lineWidth: 1.5
            )
    }
}

// MARK: - Light Refraction Effect

/// Simulates light refraction on edges for enhanced glass realism
struct LightRefractionModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                        Color.clear,
                        Color.clear,
                        Color.clear,
                        Color.black.opacity(colorScheme == .dark ? 0.1 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
            )
    }
}

// MARK: - Shimmer Animation Effect

/// Standalone shimmer effect for loading states or highlights
struct ShimmerEffectModifier: ViewModifier {
    let isAnimating: Bool
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    init(isAnimating: Bool = true, color: Color = .white) {
        self.isAnimating = isAnimating
        self.color = color
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isAnimating && !reduceMotion {
                        LinearGradient(
                            colors: [
                                color.opacity(0),
                                color.opacity(0.2),
                                color.opacity(0.4),
                                color.opacity(0.2),
                                color.opacity(0)
                            ],
                            startPoint: UnitPoint(x: phase - 0.5, y: phase - 0.5),
                            endPoint: UnitPoint(x: phase, y: phase)
                        )
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                phase = 1.5
                            }
                        }
                    }
                }
                .allowsHitTesting(false)
            )
    }
}

// MARK: - Glow Effect

/// Adds a colored glow around elements
struct GlowEffectModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var intensity: CGFloat = 0.5

    init(color: Color = .accentColor, radius: CGFloat = 10, isActive: Bool = true) {
        self.color = color
        self.radius = radius
        self.isActive = isActive
    }

    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color.opacity(0.5 * intensity) : .clear, radius: radius)
            .shadow(color: isActive ? color.opacity(0.3 * intensity) : .clear, radius: radius * 2)
            .onAppear {
                if isActive && !reduceMotion {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        intensity = 1.0
                    }
                }
            }
    }
}

// MARK: - View Extensions

extension View {

    // MARK: - Primary Liquid Glass Modifier

    /// Applies the liquid glass effect with full customization
    /// - Parameters:
    ///   - material: The glass material style (default: .regular)
    ///   - cornerRadius: Corner radius for the glass shape (default: CornerRadius.large)
    ///   - borderStyle: Style for the glass border (default: .standard)
    ///   - enableHover: Enable hover effects (default: true)
    ///   - enablePress: Enable press/scale effects (default: false)
    func liquidGlass(
        material: GlassMaterial = .regular,
        cornerRadius: CGFloat = CornerRadius.large,
        borderStyle: GlassBorderStyle = .standard,
        enableHover: Bool = true,
        enablePress: Bool = false
    ) -> some View {
        modifier(LiquidGlassModifier(
            material: material,
            cornerRadius: cornerRadius,
            borderStyle: borderStyle,
            enableHover: enableHover,
            enablePress: enablePress
        ))
    }

    // MARK: - Specialized Glass Modifiers

    /// Glass card style for content cards (insights, topics, etc.)
    /// - Parameters:
    ///   - isSelected: Whether the card is in a selected state
    ///   - accentColor: Optional accent color for selected state
    func glassCard(isSelected: Bool = false, accentColor: Color? = nil) -> some View {
        modifier(GlassCardModifier(isSelected: isSelected, accentColor: accentColor))
    }

    /// Glass panel style for side panels (transcript, coaching sidebar)
    /// - Parameter edge: The edge the panel is attached to
    func glassPanel(edge: Edge = .trailing) -> some View {
        modifier(GlassPanelModifier(edge: edge))
    }

    /// Glass button style for interactive buttons
    /// - Parameters:
    ///   - isActive: Whether the button is in an active/toggled state
    ///   - style: The button style variant
    func glassButton(
        isActive: Bool = false,
        style: GlassButtonModifier.GlassButtonStyle = .secondary
    ) -> some View {
        modifier(GlassButtonModifier(isActive: isActive, style: style))
    }

    /// Glass toolbar style for navigation/tool bars
    func glassToolbar() -> some View {
        modifier(GlassToolbarModifier())
    }

    /// Glass sheet style for modal/popover sheets
    func glassSheet() -> some View {
        modifier(GlassSheetModifier())
    }

    /// Glass floating style for floating elements (coaching prompts, tooltips)
    /// - Parameters:
    ///   - isActive: Whether to show glow effects
    ///   - pulseAnimation: Whether to animate with a floating pulse
    func glassFloating(isActive: Bool = true, pulseAnimation: Bool = false) -> some View {
        modifier(GlassFloatingModifier(isActive: isActive, pulseAnimation: pulseAnimation))
    }

    // MARK: - Effect Modifiers

    /// Adds light refraction effect to enhance glass realism
    func lightRefraction() -> some View {
        modifier(LightRefractionModifier())
    }

    /// Adds a shimmer animation effect
    /// - Parameters:
    ///   - isAnimating: Whether the shimmer is active
    ///   - color: The shimmer color (default: white)
    func shimmerEffect(isAnimating: Bool = true, color: Color = .white) -> some View {
        modifier(ShimmerEffectModifier(isAnimating: isAnimating, color: color))
    }

    /// Adds a glow effect around the view
    /// - Parameters:
    ///   - color: The glow color
    ///   - radius: The glow radius
    ///   - isActive: Whether the glow is visible
    func glowEffect(color: Color = .accentColor, radius: CGFloat = 10, isActive: Bool = true) -> some View {
        modifier(GlowEffectModifier(color: color, radius: radius, isActive: isActive))
    }
}

// MARK: - Preview Provider

#if DEBUG
struct LiquidGlass_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background gradient to show glass effects
            LinearGradient(
                colors: [.purple, .blue, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // Glass Card
                Text("Glass Card")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .glassCard(isSelected: false)

                // Selected Glass Card
                Text("Selected Card")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .glassCard(isSelected: true, accentColor: .orange)

                // Glass Button Row
                HStack(spacing: Spacing.md) {
                    Text("Primary")
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .glassButton(isActive: true, style: .primary)

                    Text("Secondary")
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .glassButton(style: .secondary)
                }

                // Floating element
                VStack(spacing: Spacing.sm) {
                    Text("Coaching Prompt")
                        .font(.headline)
                    Text("Consider asking an open-ended question")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .glassFloating(pulseAnimation: true)

                // Material variants
                HStack(spacing: Spacing.md) {
                    ForEach([GlassMaterial.ultraThin, .thin, .regular, .thick, .chrome], id: \.self) { material in
                        Text(materialName(material))
                            .font(.caption)
                            .padding(Spacing.sm)
                            .liquidGlass(material: material, cornerRadius: CornerRadius.medium)
                    }
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    static func materialName(_ material: GlassMaterial) -> String {
        switch material {
        case .ultraThin: return "Ultra"
        case .thin: return "Thin"
        case .regular: return "Regular"
        case .thick: return "Thick"
        case .chrome: return "Chrome"
        }
    }
}
#endif
