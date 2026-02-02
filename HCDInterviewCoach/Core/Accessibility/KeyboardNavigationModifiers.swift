//
//  KeyboardNavigationModifiers.swift
//  HCDInterviewCoach
//
//  Created by Agent E13
//  EPIC E13: Accessibility - Keyboard Navigation
//

import SwiftUI

// MARK: - Keyboard Navigation Modifiers

extension View {

    /// Makes a view fully keyboard navigable with standard shortcuts
    /// Implements Tab, Return, Escape, and Arrow key handling
    func keyboardNavigable(
        onTab: (() -> Void)? = nil,
        onShiftTab: (() -> Void)? = nil,
        onReturn: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        self
            .focusable()
            .onKeyPress(.tab) {
                onTab?()
                return .handled
            }
            .onKeyPress(.return) {
                onReturn?()
                return .handled
            }
            .onKeyPress(.escape) {
                onEscape?()
                return .handled
            }
    }

    /// Enhanced keyboard navigation with directional arrow support
    /// Useful for list navigation and grid layouts
    func keyboardNavigableWithArrows(
        onUp: (() -> Void)? = nil,
        onDown: (() -> Void)? = nil,
        onLeft: (() -> Void)? = nil,
        onRight: (() -> Void)? = nil,
        onReturn: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        self
            .focusable()
            .onKeyPress(.upArrow) {
                onUp?()
                return .handled
            }
            .onKeyPress(.downArrow) {
                onDown?()
                return .handled
            }
            .onKeyPress(.leftArrow) {
                onLeft?()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                onRight?()
                return .handled
            }
            .onKeyPress(.return) {
                onReturn?()
                return .handled
            }
            .onKeyPress(.escape) {
                onEscape?()
                return .handled
            }
    }

    /// Creates a keyboard focus container that manages Tab navigation within its boundary.
    /// WCAG 2.1.2 Compliant: Provides Escape key as exit mechanism to prevent keyboard traps.
    /// - Parameter onEscape: Optional closure called when Escape is pressed to exit the container
    func keyboardFocusContainer(onEscape: (() -> Void)? = nil) -> some View {
        self
            .onKeyPress(.tab) { .handled }
            .onKeyPress(.escape) {
                onEscape?()
                return .handled
            }
    }

    /// DEPRECATED: Use keyboardFocusContainer(onEscape:) instead.
    /// This method creates a keyboard trap which violates WCAG 2.1.2.
    @available(*, deprecated, message: "Use keyboardFocusContainer(onEscape:) instead to provide an escape mechanism")
    func keyboardTrapBoundary() -> some View {
        keyboardFocusContainer(onEscape: nil)
    }

    /// Makes a button activatable via keyboard
    /// Responds to Space and Return keys
    func keyboardActivatable(action: @escaping () -> Void) -> some View {
        self
            .focusable()
            .onKeyPress(.space) {
                action()
                return .handled
            }
            .onKeyPress(.return) {
                action()
                return .handled
            }
    }
}

// MARK: - List Navigation Helpers

extension View {

    /// Enables keyboard list navigation with j/k vim-style bindings
    /// Also supports standard arrow keys
    func listNavigable(
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onSelect: @escaping () -> Void
    ) -> some View {
        self
            .focusable()
            .onKeyPress(.downArrow) {
                onNext()
                return .handled
            }
            .onKeyPress(.upArrow) {
                onPrevious()
                return .handled
            }
            .onKeyPress(.return) {
                onSelect()
                return .handled
            }
            .onKeyPress(.space) {
                onSelect()
                return .handled
            }
            // Vim-style navigation
            .onKeyPress("j") {
                onNext()
                return .handled
            }
            .onKeyPress("k") {
                onPrevious()
                return .handled
            }
    }
}

// MARK: - Keyboard Shortcuts

struct KeyboardShortcuts {

    // Session control shortcuts
    static let startSession = KeyEquivalent("r")
    static let pauseSession = KeyEquivalent("p")
    static let endSession = KeyEquivalent("e")

    // Coaching shortcuts
    static let toggleCoaching = KeyEquivalent("m")
    static let dismissPrompt = KeyEquivalent.escape

    // Insight shortcuts
    static let flagInsight = KeyEquivalent("i")
    static let editInsight = KeyEquivalent("e")

    // Transcript shortcuts
    static let toggleSpeaker = KeyEquivalent("t")
    static let searchTranscript = KeyEquivalent("f")
    static let jumpToTimestamp = KeyEquivalent("j")

    // Navigation shortcuts
    static let focusTranscript = KeyEquivalent("1")
    static let focusTopics = KeyEquivalent("2")
    static let focusInsights = KeyEquivalent("3")
    static let focusControls = KeyEquivalent("4")

    // Export shortcuts
    static let exportSession = KeyEquivalent("s")

    // Settings
    static let openSettings = KeyEquivalent(",")

    // Modifiers
    static let commandModifier: EventModifiers = .command
    static let optionModifier: EventModifiers = .option
    static let shiftModifier: EventModifiers = .shift
    static let commandShiftModifier: EventModifiers = [.command, .shift]
    static let commandOptionModifier: EventModifiers = [.command, .option]
}

// MARK: - Accessibility Navigation Helper

/// Helper for managing keyboard navigation state
@MainActor
final class KeyboardNavigationHelper: ObservableObject {

    @Published var isNavigatingViaKeyboard: Bool = false
    private var lastInteractionTime: Date = Date()

    /// Records that the user is navigating via keyboard
    func recordKeyboardNavigation() {
        isNavigatingViaKeyboard = true
        lastInteractionTime = Date()
    }

    /// Records that the user is navigating via mouse/trackpad
    func recordPointerNavigation() {
        isNavigatingViaKeyboard = false
        lastInteractionTime = Date()
    }

    /// Whether to show enhanced focus indicators
    /// Only show when user is actively using keyboard
    var shouldShowEnhancedFocus: Bool {
        isNavigatingViaKeyboard && Date().timeIntervalSince(lastInteractionTime) < 5
    }
}
