//
//  CoachingPreferences.swift
//  HCD Interview Coach
//
//  EPIC E6: Coaching Engine
//  User preferences storage for coaching configuration
//

import Foundation
import Combine

// MARK: - Coaching Preferences

/// Manages user preferences for the coaching system.
/// Preferences are persisted using UserDefaults.
///
/// Following the silence-first philosophy:
/// - Coaching is DEFAULT OFF for the first session
/// - User must explicitly enable coaching
/// - Preferences persist across sessions
@MainActor
final class CoachingPreferences: ObservableObject {

    // MARK: - Singleton

    static let shared = CoachingPreferences()

    // MARK: - Published Properties

    /// Whether the user has completed the initial coaching opt-in flow
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }

    /// Current coaching level (off, minimal, balanced, active)
    @Published var coachingLevel: CoachingLevel {
        didSet {
            defaults.set(coachingLevel.rawValue, forKey: Keys.coachingLevel)
        }
    }

    /// Whether coaching is enabled globally
    @Published var isCoachingEnabled: Bool {
        didSet {
            defaults.set(isCoachingEnabled, forKey: Keys.isCoachingEnabled)
        }
    }

    /// Custom sensitivity multiplier (0.5-2.0)
    @Published var customSensitivity: Double {
        didSet {
            defaults.set(customSensitivity, forKey: Keys.customSensitivity)
        }
    }

    /// Whether to show visual notification badge on prompts
    @Published var showNotificationBadge: Bool {
        didSet {
            defaults.set(showNotificationBadge, forKey: Keys.showNotificationBadge)
        }
    }

    /// Whether to play subtle sound when prompt appears
    @Published var playSoundOnPrompt: Bool {
        didSet {
            defaults.set(playSoundOnPrompt, forKey: Keys.playSoundOnPrompt)
        }
    }

    /// Preferred position for coaching overlay
    @Published var overlayPosition: OverlayPosition {
        didSet {
            defaults.set(overlayPosition.rawValue, forKey: Keys.overlayPosition)
        }
    }

    /// Auto-dismiss duration override (nil = use default from thresholds)
    @Published var customAutoDismissDuration: TimeInterval? {
        didSet {
            if let duration = customAutoDismissDuration {
                defaults.set(duration, forKey: Keys.customAutoDismissDuration)
            } else {
                defaults.removeObject(forKey: Keys.customAutoDismissDuration)
            }
        }
    }

    /// Number of sessions completed (used for adaptive behavior)
    @Published private(set) var sessionsCompleted: Int {
        didSet {
            defaults.set(sessionsCompleted, forKey: Keys.sessionsCompleted)
        }
    }

    /// Total prompts shown across all sessions
    @Published private(set) var totalPromptsShown: Int {
        didSet {
            defaults.set(totalPromptsShown, forKey: Keys.totalPromptsShown)
        }
    }

    /// Total prompts accepted across all sessions
    @Published private(set) var totalPromptsAccepted: Int {
        didSet {
            defaults.set(totalPromptsAccepted, forKey: Keys.totalPromptsAccepted)
        }
    }

    /// Total prompts dismissed across all sessions
    @Published private(set) var totalPromptsDismissed: Int {
        didSet {
            defaults.set(totalPromptsDismissed, forKey: Keys.totalPromptsDismissed)
        }
    }

    // MARK: - Private Properties

    private let defaults: UserDefaults

    // MARK: - Keys

    private enum Keys {
        static let hasCompletedOnboarding = "coaching.hasCompletedOnboarding"
        static let coachingLevel = "coaching.level"
        static let isCoachingEnabled = "coaching.isEnabled"
        static let customSensitivity = "coaching.customSensitivity"
        static let showNotificationBadge = "coaching.showNotificationBadge"
        static let playSoundOnPrompt = "coaching.playSoundOnPrompt"
        static let overlayPosition = "coaching.overlayPosition"
        static let customAutoDismissDuration = "coaching.customAutoDismissDuration"
        static let sessionsCompleted = "coaching.sessionsCompleted"
        static let totalPromptsShown = "coaching.totalPromptsShown"
        static let totalPromptsAccepted = "coaching.totalPromptsAccepted"
        static let totalPromptsDismissed = "coaching.totalPromptsDismissed"
    }

    // MARK: - Initialization

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load persisted values with silence-first defaults
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)

        // SILENCE-FIRST: Default to OFF until user explicitly enables
        self.isCoachingEnabled = defaults.object(forKey: Keys.isCoachingEnabled) as? Bool ?? false

        // Default to balanced level when enabled
        if let levelString = defaults.string(forKey: Keys.coachingLevel),
           let level = CoachingLevel(rawValue: levelString) {
            self.coachingLevel = level
        } else {
            self.coachingLevel = .balanced
        }

        self.customSensitivity = defaults.object(forKey: Keys.customSensitivity) as? Double ?? 1.0
        self.showNotificationBadge = defaults.object(forKey: Keys.showNotificationBadge) as? Bool ?? true
        self.playSoundOnPrompt = defaults.object(forKey: Keys.playSoundOnPrompt) as? Bool ?? false

        if let positionString = defaults.string(forKey: Keys.overlayPosition),
           let position = OverlayPosition(rawValue: positionString) {
            self.overlayPosition = position
        } else {
            self.overlayPosition = .bottomRight
        }

        if defaults.object(forKey: Keys.customAutoDismissDuration) != nil {
            self.customAutoDismissDuration = defaults.double(forKey: Keys.customAutoDismissDuration)
        } else {
            self.customAutoDismissDuration = nil
        }

        self.sessionsCompleted = defaults.integer(forKey: Keys.sessionsCompleted)
        self.totalPromptsShown = defaults.integer(forKey: Keys.totalPromptsShown)
        self.totalPromptsAccepted = defaults.integer(forKey: Keys.totalPromptsAccepted)
        self.totalPromptsDismissed = defaults.integer(forKey: Keys.totalPromptsDismissed)
    }

    // MARK: - Computed Properties

    /// Whether this is the user's first session
    var isFirstSession: Bool {
        sessionsCompleted == 0
    }

    /// Whether coaching should actually be active (considering all factors)
    var shouldShowCoaching: Bool {
        // SILENCE-FIRST: Must be explicitly enabled
        guard isCoachingEnabled else { return false }

        // Must have completed onboarding
        guard hasCompletedOnboarding else { return false }

        // Must not be in "off" mode
        guard coachingLevel != .off else { return false }

        return true
    }

    /// Current effective thresholds based on preferences
    var effectiveThresholds: CoachingThresholds {
        var thresholds = coachingLevel.thresholds

        // Apply custom sensitivity
        thresholds = CoachingThresholds(
            minimumConfidence: thresholds.minimumConfidence,
            cooldownDuration: thresholds.cooldownDuration,
            speechCooldown: thresholds.speechCooldown,
            maxPromptsPerSession: thresholds.maxPromptsPerSession,
            autoDismissDuration: customAutoDismissDuration ?? thresholds.autoDismissDuration,
            fadeInDuration: thresholds.fadeInDuration,
            fadeOutDuration: thresholds.fadeOutDuration,
            sensitivityMultiplier: customSensitivity
        )

        return thresholds
    }

    /// Acceptance rate for prompts (0.0-1.0)
    var acceptanceRate: Double {
        guard totalPromptsShown > 0 else { return 0.0 }
        return Double(totalPromptsAccepted) / Double(totalPromptsShown)
    }

    /// Dismissal rate for prompts (0.0-1.0)
    var dismissalRate: Double {
        guard totalPromptsShown > 0 else { return 0.0 }
        return Double(totalPromptsDismissed) / Double(totalPromptsShown)
    }

    // MARK: - Methods

    /// Mark the onboarding flow as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
        AppLogger.shared.info("Coaching onboarding completed")
    }

    /// Enable coaching with the specified level
    func enable(level: CoachingLevel = .balanced) {
        isCoachingEnabled = true
        coachingLevel = level
        AppLogger.shared.info("Coaching enabled at level: \(level.displayName)")
    }

    /// Disable coaching
    func disable() {
        isCoachingEnabled = false
        AppLogger.shared.info("Coaching disabled")
    }

    /// Record that a session was completed
    func recordSessionCompleted() {
        sessionsCompleted += 1
        AppLogger.shared.info("Session completed. Total sessions: \(sessionsCompleted)")
    }

    /// Record that a prompt was shown
    func recordPromptShown() {
        totalPromptsShown += 1
    }

    /// Record that a prompt was accepted
    func recordPromptAccepted() {
        totalPromptsAccepted += 1
    }

    /// Record that a prompt was dismissed
    func recordPromptDismissed() {
        totalPromptsDismissed += 1
    }

    /// Reset all statistics (keeps preferences)
    func resetStatistics() {
        sessionsCompleted = 0
        totalPromptsShown = 0
        totalPromptsAccepted = 0
        totalPromptsDismissed = 0
        AppLogger.shared.info("Coaching statistics reset")
    }

    /// Reset all preferences to defaults
    func resetToDefaults() {
        hasCompletedOnboarding = false
        isCoachingEnabled = false
        coachingLevel = .balanced
        customSensitivity = 1.0
        showNotificationBadge = true
        playSoundOnPrompt = false
        overlayPosition = .bottomRight
        customAutoDismissDuration = nil
        resetStatistics()
        AppLogger.shared.info("Coaching preferences reset to defaults")
    }
}

// MARK: - Overlay Position

/// Preferred position for the coaching overlay
enum OverlayPosition: String, CaseIterable, Codable {
    case topLeft = "topLeft"
    case topRight = "topRight"
    case bottomLeft = "bottomLeft"
    case bottomRight = "bottomRight"
    case center = "center"

    var displayName: String {
        switch self {
        case .topLeft:
            return "Top Left"
        case .topRight:
            return "Top Right"
        case .bottomLeft:
            return "Bottom Left"
        case .bottomRight:
            return "Bottom Right"
        case .center:
            return "Center"
        }
    }

    var alignment: (horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
        switch self {
        case .topLeft:
            return (.leading, .top)
        case .topRight:
            return (.trailing, .top)
        case .bottomLeft:
            return (.leading, .bottom)
        case .bottomRight:
            return (.trailing, .bottom)
        case .center:
            return (.center, .center)
        }
    }
}

// MARK: - Horizontal/Vertical Alignment Stubs

/// Horizontal alignment for overlay positioning
enum HorizontalAlignment {
    case leading
    case center
    case trailing
}

/// Vertical alignment for overlay positioning
enum VerticalAlignment {
    case top
    case center
    case bottom
}
