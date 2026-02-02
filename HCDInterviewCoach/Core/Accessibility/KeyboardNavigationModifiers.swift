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
            .onKeyPress(.tab) { press in
                if press.modifiers.contains(.shift) {
                    onShiftTab?()
                } else {
                    onTab?()
                }
                return .handled
            }
            .onKeyPress(.return) { _ in
                onReturn?()
                return .handled
            }
            .onKeyPress(.escape) { _ in
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
            .onKeyPress(.upArrow) { _ in
                onUp?()
                return .handled
            }
            .onKeyPress(.downArrow) { _ in
                onDown?()
                return .handled
            }
            .onKeyPress(.leftArrow) { _ in
                onLeft?()
                return .handled
            }
            .onKeyPress(.rightArrow) { _ in
                onRight?()
                return .handled
            }
            .onKeyPress(.return) { _ in
                onReturn?()
                return .handled
            }
            .onKeyPress(.escape) { _ in
                onEscape?()
                return .handled
            }
    }

    /// Marks a view as a keyboard trap boundary
    /// Focus cannot escape this boundary without explicit action
    func keyboardTrapBoundary() -> some View {
        self.onKeyPress(.tab) { press in
            // Prevent tab from leaving this boundary
            return .handled
        }
    }

    /// Makes a button activatable via keyboard
    /// Responds to Space and Return keys
    func keyboardActivatable(action: @escaping () -> Void) -> some View {
        self
            .focusable()
            .onKeyPress(.space) { _ in
                action()
                return .handled
            }
            .onKeyPress(.return) { _ in
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
            .onKeyPress(.downArrow) { _ in
                onNext()
                return .handled
            }
            .onKeyPress(.upArrow) { _ in
                onPrevious()
                return .handled
            }
            .onKeyPress(.return) { _ in
                onSelect()
                return .handled
            }
            .onKeyPress(.space) { _ in
                onSelect()
                return .handled
            }
            // Vim-style navigation
            .onKeyPress("j") { _ in
                onNext()
                return .handled
            }
            .onKeyPress("k") { _ in
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
    static let dismissPrompt = KeyEquivalent(.escape)

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
