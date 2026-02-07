//
//  FocusModeManager.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  Controls which panels are visible during a session, providing
//  preset focus modes and custom panel configurations.
//

import Foundation
import SwiftUI

// MARK: - Panel

/// Represents a toggleable UI panel in the session view
enum Panel: String, CaseIterable, Codable, Sendable {
    case transcript = "transcript"
    case topics = "topics"
    case insights = "insights"
    case coaching = "coaching"
    case talkTime = "talkTime"

    /// Human-readable name for the panel
    var displayName: String {
        switch self {
        case .transcript:
            return "Transcript"
        case .topics:
            return "Topics"
        case .insights:
            return "Insights"
        case .coaching:
            return "Coaching"
        case .talkTime:
            return "Talk Time"
        }
    }

    /// SF Symbol icon for the panel
    var icon: String {
        switch self {
        case .transcript:
            return "text.alignleft"
        case .topics:
            return "list.bullet"
        case .insights:
            return "lightbulb.fill"
        case .coaching:
            return "bubble.left.and.text.bubble.right.fill"
        case .talkTime:
            return "chart.bar.fill"
        }
    }
}

// MARK: - Panel Visibility

/// Tracks which panels are currently visible in the session layout
struct PanelVisibility: Equatable, Codable, Sendable {
    var showTranscript: Bool
    var showTopics: Bool
    var showInsights: Bool
    var showCoaching: Bool
    var showTalkTime: Bool

    /// Returns whether the specified panel is visible
    func isVisible(_ panel: Panel) -> Bool {
        switch panel {
        case .transcript:
            return showTranscript
        case .topics:
            return showTopics
        case .insights:
            return showInsights
        case .coaching:
            return showCoaching
        case .talkTime:
            return showTalkTime
        }
    }

    /// Returns a new PanelVisibility with the specified panel toggled
    func toggling(_ panel: Panel) -> PanelVisibility {
        var copy = self
        switch panel {
        case .transcript:
            copy.showTranscript.toggle()
        case .topics:
            copy.showTopics.toggle()
        case .insights:
            copy.showInsights.toggle()
        case .coaching:
            copy.showCoaching.toggle()
        case .talkTime:
            copy.showTalkTime.toggle()
        }
        return copy
    }

    /// Number of visible panels
    var visibleCount: Int {
        [showTranscript, showTopics, showInsights, showCoaching, showTalkTime]
            .filter { $0 }
            .count
    }
}

// MARK: - Focus Mode

/// Preset layout modes that control panel visibility during sessions.
///
/// Each mode is designed for a specific workflow:
/// - `.interview`: Minimal distractions for focused interviewing
/// - `.coached`: Balanced view with AI assistance
/// - `.analysis`: Full visibility for post-session or detailed review
/// - `.custom`: User-defined panel configuration
enum FocusMode: String, CaseIterable, Codable, Sendable {
    /// Transcript only, full screen, minimal distractions
    case interview = "interview"
    /// Transcript + coaching prompts + talk-time indicator
    case coached = "coached"
    /// All panels visible for full analysis
    case analysis = "analysis"
    /// User-defined panel visibility
    case custom = "custom"

    /// Human-readable name for the mode
    var displayName: String {
        switch self {
        case .interview:
            return "Interview"
        case .coached:
            return "Coached"
        case .analysis:
            return "Analysis"
        case .custom:
            return "Custom"
        }
    }

    /// Brief description of the mode's purpose
    var description: String {
        switch self {
        case .interview:
            return "Transcript only — full screen, minimal distractions"
        case .coached:
            return "Transcript + coaching prompts + talk-time indicator"
        case .analysis:
            return "All panels visible for comprehensive review"
        case .custom:
            return "Your custom panel configuration"
        }
    }

    /// SF Symbol icon for the mode
    var icon: String {
        switch self {
        case .interview:
            return "text.alignleft"
        case .coached:
            return "bubble.left.and.text.bubble.right"
        case .analysis:
            return "rectangle.split.3x1"
        case .custom:
            return "slider.horizontal.3"
        }
    }

    /// The default panel visibility for this mode
    var defaultVisibility: PanelVisibility {
        switch self {
        case .interview:
            return PanelVisibility(
                showTranscript: true,
                showTopics: false,
                showInsights: false,
                showCoaching: false,
                showTalkTime: false
            )
        case .coached:
            return PanelVisibility(
                showTranscript: true,
                showTopics: false,
                showInsights: false,
                showCoaching: true,
                showTalkTime: true
            )
        case .analysis:
            return PanelVisibility(
                showTranscript: true,
                showTopics: true,
                showInsights: true,
                showCoaching: true,
                showTalkTime: true
            )
        case .custom:
            // Custom defaults to all visible; actual state is managed separately
            return PanelVisibility(
                showTranscript: true,
                showTopics: true,
                showInsights: true,
                showCoaching: true,
                showTalkTime: true
            )
        }
    }

    /// Keyboard shortcut equivalent for this mode (used in menu items)
    var keyEquivalent: KeyEquivalent? {
        switch self {
        case .interview:
            return "1"
        case .coached:
            return "2"
        case .analysis:
            return "3"
        case .custom:
            return nil
        }
    }

    /// Event modifiers for the keyboard shortcut
    var keyModifiers: EventModifiers {
        [.command, .shift]
    }
}

// MARK: - Focus Mode Manager

/// Manages the active focus mode and panel visibility during sessions.
///
/// Persists the last-used mode to UserDefaults so it can be restored when
/// the app relaunches. Automatically switches to `.custom` mode when individual
/// panels are toggled.
@MainActor
final class FocusModeManager: ObservableObject {

    // MARK: - Published Properties

    /// The currently active focus mode
    @Published private(set) var currentMode: FocusMode {
        didSet {
            persistMode()
        }
    }

    /// Current panel visibility configuration
    @Published private(set) var panelVisibility: PanelVisibility {
        didSet {
            persistCustomVisibility()
        }
    }

    /// Whether a mode transition animation is in progress
    @Published private(set) var isTransitioning: Bool = false

    // MARK: - Constants

    /// UserDefaults key for persisting the current mode
    static let modeDefaultsKey = "com.hcdinterviewcoach.focusMode"

    /// UserDefaults key for persisting custom panel visibility
    static let customVisibilityDefaultsKey = "com.hcdinterviewcoach.customPanelVisibility"

    // MARK: - Dependencies

    private let defaults: UserDefaults

    // MARK: - Initialization

    /// Creates a FocusModeManager, restoring the last-used mode from UserDefaults
    /// - Parameter defaults: The UserDefaults store (injectable for testing)
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Restore persisted mode
        let restoredMode = Self.restoreMode(from: defaults)
        self.currentMode = restoredMode

        // Restore or derive panel visibility
        if restoredMode == .custom {
            self.panelVisibility = Self.restoreCustomVisibility(from: defaults)
                ?? restoredMode.defaultVisibility
        } else {
            self.panelVisibility = restoredMode.defaultVisibility
        }

        AppLogger.shared.info("FocusModeManager initialized with mode: \(restoredMode.displayName)")
    }

    // MARK: - Public Methods

    /// Switches to the specified focus mode with animation.
    ///
    /// Updates panel visibility to the mode's default configuration.
    /// For `.custom` mode, restores the previously saved custom configuration.
    ///
    /// - Parameter mode: The focus mode to activate
    func setMode(_ mode: FocusMode) {
        guard mode != currentMode else { return }

        isTransitioning = true

        withAnimation(.easeInOut(duration: AnimationTiming.normal)) {
            currentMode = mode

            if mode == .custom {
                // Restore persisted custom visibility or use defaults
                panelVisibility = Self.restoreCustomVisibility(from: defaults)
                    ?? mode.defaultVisibility
            } else {
                panelVisibility = mode.defaultVisibility
            }
        }

        // End transition after animation completes
        Task {
            try? await Task.sleep(nanoseconds: UInt64(AnimationTiming.normal * 1_000_000_000))
            isTransitioning = false
        }

        AppLogger.shared.info("Focus mode changed to: \(mode.displayName)")
    }

    /// Toggles visibility of the specified panel.
    ///
    /// If the current mode is not `.custom`, automatically switches to `.custom`
    /// mode first, preserving the current panel state before toggling.
    ///
    /// - Parameter panel: The panel to toggle
    func togglePanel(_ panel: Panel) {
        if currentMode != .custom {
            // Switch to custom mode, preserving current visibility
            currentMode = .custom
        }

        withAnimation(.easeInOut(duration: AnimationTiming.fast)) {
            panelVisibility = panelVisibility.toggling(panel)
        }

        AppLogger.shared.debug("Panel toggled: \(panel.displayName), visible: \(panelVisibility.isVisible(panel))")
    }

    /// Sets visibility of a specific panel without affecting mode.
    ///
    /// If the current mode is not `.custom`, automatically switches to `.custom`.
    ///
    /// - Parameters:
    ///   - panel: The panel to update
    ///   - visible: Whether the panel should be visible
    func setPanel(_ panel: Panel, visible: Bool) {
        let currentlyVisible = panelVisibility.isVisible(panel)
        guard currentlyVisible != visible else { return }
        togglePanel(panel)
    }

    /// Whether the specified panel is currently visible
    /// - Parameter panel: The panel to check
    /// - Returns: true if the panel is visible
    func isPanelVisible(_ panel: Panel) -> Bool {
        panelVisibility.isVisible(panel)
    }

    // MARK: - Persistence

    /// Saves the current mode to UserDefaults
    private func persistMode() {
        defaults.set(currentMode.rawValue, forKey: Self.modeDefaultsKey)
    }

    /// Saves custom panel visibility to UserDefaults
    private func persistCustomVisibility() {
        guard currentMode == .custom else { return }
        if let data = try? JSONEncoder().encode(panelVisibility) {
            defaults.set(data, forKey: Self.customVisibilityDefaultsKey)
        }
    }

    /// Restores the focus mode from UserDefaults
    /// - Parameter defaults: The UserDefaults store to read from
    /// - Returns: The restored mode, or `.analysis` as the default
    private static func restoreMode(from defaults: UserDefaults) -> FocusMode {
        guard let rawValue = defaults.string(forKey: modeDefaultsKey),
              let mode = FocusMode(rawValue: rawValue) else {
            return .analysis
        }
        return mode
    }

    /// Restores custom panel visibility from UserDefaults
    /// - Parameter defaults: The UserDefaults store to read from
    /// - Returns: The restored visibility, or nil if not found
    private static func restoreCustomVisibility(from defaults: UserDefaults) -> PanelVisibility? {
        guard let data = defaults.data(forKey: customVisibilityDefaultsKey),
              let visibility = try? JSONDecoder().decode(PanelVisibility.self, from: data) else {
            return nil
        }
        return visibility
    }
}
