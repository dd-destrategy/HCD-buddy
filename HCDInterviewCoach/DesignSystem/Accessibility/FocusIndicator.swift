//
//  FocusIndicator.swift
//  HCDInterviewCoach
//
//  Created by Agent E13
//  EPIC E13: Accessibility - Focus Indicators
//

import SwiftUI

// MARK: - Focus Indicator Modifier

/// Provides a consistent, high-contrast focus indicator
/// Meets WCAG 2.1 AA contrast requirements (3:1 minimum)
struct FocusIndicator: ViewModifier {

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    let style: FocusIndicatorStyle

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .strokeBorder(
                        focusColor,
                        lineWidth: isFocused ? style.lineWidth : 0
                    )
                    .animation(.easeInOut(duration: 0.15), value: isFocused)
            )
            .accessibilityAddTraits(isFocused ? .isSelected : [])
    }

    private var focusColor: Color {
        switch colorScheme {
        case .light:
            return style.lightModeColor
        case .dark:
            return style.darkModeColor
        @unknown default:
            return .accentColor
        }
    }
}

// MARK: - Focus Indicator Styles

struct FocusIndicatorStyle {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let lightModeColor: Color
    let darkModeColor: Color

    static let `default` = FocusIndicatorStyle(
        cornerRadius: 4,
        lineWidth: 2,
        lightModeColor: Color.blue,
        darkModeColor: Color.cyan
    )

    static let button = FocusIndicatorStyle(
        cornerRadius: 6,
        lineWidth: 2,
        lightModeColor: Color.blue.opacity(0.8),
        darkModeColor: Color.cyan.opacity(0.8)
    )

    static let list = FocusIndicatorStyle(
        cornerRadius: 4,
        lineWidth: 2,
        lightModeColor: Color.blue,
        darkModeColor: Color.cyan
    )

    static let panel = FocusIndicatorStyle(
        cornerRadius: 8,
        lineWidth: 3,
        lightModeColor: Color.blue.opacity(0.6),
        darkModeColor: Color.cyan.opacity(0.6)
    )
}

// MARK: - View Extensions

extension View {

    /// Adds a standard focus indicator to the view
    func focusIndicator(style: FocusIndicatorStyle = .default) -> some View {
        modifier(FocusIndicator(style: style))
    }

    /// Adds a button-style focus indicator
    func buttonFocusIndicator() -> some View {
        modifier(FocusIndicator(style: .button))
    }

    /// Adds a list item focus indicator
    func listFocusIndicator() -> some View {
        modifier(FocusIndicator(style: .list))
    }

    /// Adds a panel focus indicator
    func panelFocusIndicator() -> some View {
        modifier(FocusIndicator(style: .panel))
    }
}

// MARK: - Enhanced Focus Ring

/// Enhanced focus ring with glow effect for high visibility
struct EnhancedFocusRing: ViewModifier {

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var keyboardNav: KeyboardNavigationHelper

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .overlay {
                if isFocused && keyboardNav.shouldShowEnhancedFocus {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(focusColor, lineWidth: 2)
                        .shadow(color: focusColor.opacity(0.5), radius: 4, x: 0, y: 0)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                }
            }
    }

    private var focusColor: Color {
        colorScheme == .dark ? .cyan : .blue
    }
}

extension View {

    /// Adds an enhanced focus ring with glow effect
    /// Only appears when user is navigating via keyboard
    func enhancedFocusRing() -> some View {
        modifier(EnhancedFocusRing())
    }
}

// MARK: - Focus Debugging

#if DEBUG
/// Visual debug overlay showing focus state
struct FocusDebugOverlay: ViewModifier {

    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .overlay(alignment: .topTrailing) {
                if isFocused {
                    Text("FOCUSED")
                        .font(.caption2)
                        .padding(4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
    }
}

extension View {

    /// Adds a debug overlay showing focus state
    /// Only available in debug builds
    func debugFocus() -> some View {
        modifier(FocusDebugOverlay())
    }
}
#endif
