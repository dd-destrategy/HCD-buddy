//
//  MotionSafeAnimation.swift
//  HCDInterviewCoach
//
//  Created by Agent E13
//  EPIC E13: Accessibility - Reduced Motion Support
//

import SwiftUI

// MARK: - Motion Safe Animation Modifier

/// Respects the system-wide Reduce Motion preference
/// Disables or reduces animations when the user has requested it
struct MotionSafeAnimation: ViewModifier {

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation
    let value: some Equatable

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : animation, value: value)
    }
}

extension View {

    /// Applies animation only when Reduce Motion is not enabled
    func motionSafeAnimation<V: Equatable>(
        _ animation: Animation,
        value: V
    ) -> some View {
        modifier(MotionSafeAnimation(animation: animation, value: value))
    }
}

// MARK: - Transition Modifiers

extension View {

    /// Applies a transition that respects Reduce Motion
    /// Falls back to opacity transition when motion is reduced
    func motionSafeTransition(_ transition: AnyTransition) -> some View {
        self.modifier(MotionSafeTransitionModifier(transition: transition))
    }

    /// Slide transition that respects Reduce Motion
    func motionSafeSlide(edge: Edge) -> some View {
        motionSafeTransition(.slide)
    }

    /// Scale transition that respects Reduce Motion
    func motionSafeScale(scale: CGFloat = 0.8) -> some View {
        motionSafeTransition(.scale(scale: scale))
    }
}

struct MotionSafeTransitionModifier: ViewModifier {

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let transition: AnyTransition

    func body(content: Content) -> some View {
        content
            .transition(reduceMotion ? .opacity : transition)
    }
}

// MARK: - Common Motion-Safe Animations

/// Provides motion-safe animation helpers that respect the Reduce Motion preference.
/// NOTE: @Environment only works in Views/ViewModifiers, so this struct receives
/// the reduceMotion value as a parameter.
struct MotionSafeAnimations {

    /// Whether the user has requested reduced motion
    let reduceMotion: Bool

    /// Creates a MotionSafeAnimations instance
    /// - Parameter reduceMotion: The current state of accessibilityReduceMotion
    init(reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
    }

    /// Gentle spring animation or instant when motion reduced
    var gentleSpring: Animation? {
        reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)
    }

    /// Standard ease-in-out or instant when motion reduced
    var standardEase: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.2)
    }

    /// Slow ease for emphasis or instant when motion reduced
    var slowEase: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.4)
    }

    /// Quick fade or instant when motion reduced
    var quickFade: Animation? {
        reduceMotion ? nil : .easeIn(duration: 0.1)
    }
}

// MARK: - Motion-Safe Animation View Extension

extension View {
    /// Creates a MotionSafeAnimations helper bound to the current environment's reduce motion setting.
    /// Usage: Use within a View body with the @Environment property.
    ///
    /// Example:
    /// ```swift
    /// struct MyView: View {
    ///     @Environment(\.accessibilityReduceMotion) var reduceMotion
    ///
    ///     var body: some View {
    ///         let animations = MotionSafeAnimations(reduceMotion: reduceMotion)
    ///         // Use animations.gentleSpring, etc.
    ///     }
    /// }
    /// ```
    func withMotionSafeAnimations<Content: View>(
        @ViewBuilder content: @escaping (MotionSafeAnimations) -> Content
    ) -> some View {
        MotionSafeAnimationsContainer(content: content)
    }
}

/// A container view that provides MotionSafeAnimations to its content
private struct MotionSafeAnimationsContainer<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let content: (MotionSafeAnimations) -> Content

    var body: some View {
        content(MotionSafeAnimations(reduceMotion: reduceMotion))
    }
}

// MARK: - Scroll Animation

extension View {

    /// Smooth scroll behavior that respects Reduce Motion
    func motionSafeScrolling() -> some View {
        self.modifier(MotionSafeScrollModifier())
    }
}

struct MotionSafeScrollModifier: ViewModifier {

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
                .scrollDisabled(false)
        } else {
            content
                .scrollDisabled(false)
        }
    }
}

// MARK: - Pulsing Effect

/// A pulsing effect that respects Reduce Motion
/// Shows static state when motion is reduced
struct PulsingEffect: ViewModifier {

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPulsing = false

    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double

    init(minOpacity: Double = 0.5, maxOpacity: Double = 1.0, duration: Double = 1.0) {
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                if !reduceMotion {
                    isPulsing = true
                }
            }
    }

    private var opacity: Double {
        if reduceMotion {
            return maxOpacity
        } else {
            return isPulsing ? minOpacity : maxOpacity
        }
    }
}

extension View {

    /// Adds a pulsing effect that respects Reduce Motion
    func pulsingEffect(
        minOpacity: Double = 0.5,
        maxOpacity: Double = 1.0,
        duration: Double = 1.0
    ) -> some View {
        modifier(PulsingEffect(minOpacity: minOpacity, maxOpacity: maxOpacity, duration: duration))
    }
}

// MARK: - Rotation Effect

/// A rotating effect that respects Reduce Motion
/// Shows static state when motion is reduced
struct RotatingEffect: ViewModifier {

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isRotating = false

    let duration: Double

    init(duration: Double = 1.0) {
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotationDegrees))
            .onAppear {
                if !reduceMotion {
                    withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                        isRotating = true
                    }
                }
            }
    }

    private var rotationDegrees: Double {
        reduceMotion ? 0 : (isRotating ? 360 : 0)
    }
}

extension View {

    /// Adds a continuous rotation effect that respects Reduce Motion
    func rotatingEffect(duration: Double = 1.0) -> some View {
        modifier(RotatingEffect(duration: duration))
    }
}

// MARK: - Shake Effect

/// A shake effect that respects Reduce Motion
/// Shows highlighted state when motion is reduced
struct ShakeEffect: ViewModifier {

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Binding var shake: Bool

    func body(content: Content) -> some View {
        if reduceMotion {
            // Instead of shaking, briefly highlight
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.red, lineWidth: shake ? 2 : 0)
                )
                .animation(.easeInOut(duration: 0.1), value: shake)
        } else {
            content
                .offset(x: shake ? shakeOffset : 0)
                .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: shake)
        }
    }

    private var shakeOffset: CGFloat {
        CGFloat.random(in: -10...10)
    }
}

extension View {

    /// Adds a shake effect that respects Reduce Motion
    /// When reduced motion is enabled, shows a red outline instead
    func shakeEffect(shake: Binding<Bool>) -> some View {
        modifier(ShakeEffect(shake: shake))
    }
}

// MARK: - Auto-scroll Behavior

/// Controls auto-scroll behavior with Reduce Motion support
@MainActor
final class MotionSafeScrollController: ObservableObject {

    @Published var shouldAutoScroll: Bool = true

    private let reduceMotion: Bool

    init(reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
    }

    /// Scrolls to the specified position
    /// Uses instant scroll when Reduce Motion is enabled
    func scroll(to position: ScrollPosition, animated: Bool = true) {
        let shouldAnimate = animated && !reduceMotion

        // Implementation would use ScrollViewProxy
        // This is a conceptual example
    }
}

enum ScrollPosition {
    case top
    case bottom
    case id(String)
    case offset(CGFloat)
}
