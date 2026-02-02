//
//  CoachingThresholds.swift
//  HCD Interview Coach
//
//  EPIC E6: Coaching Engine
//  Configurable thresholds for the silence-first coaching system
//

import Foundation

// MARK: - Coaching Thresholds

/// Configurable thresholds for the coaching engine.
/// Following the silence-first philosophy, these defaults are intentionally conservative
/// to minimize interruptions during interviews.
struct CoachingThresholds {

    // MARK: - Timing Thresholds

    /// Minimum confidence level (0.0-1.0) required before showing a prompt.
    /// Default: 0.85 (85%) - Only show highly confident suggestions
    let minimumConfidence: Double

    /// Cooldown period in seconds between coaching prompts.
    /// Default: 120 seconds (2 minutes) - Prevents prompt fatigue
    let cooldownDuration: TimeInterval

    /// Delay in seconds to wait after any speech before showing a prompt.
    /// Default: 5 seconds - Ensures natural conversation flow isn't interrupted
    let speechCooldown: TimeInterval

    /// Maximum number of prompts allowed per session.
    /// Default: 3 - Maintains focus on the interview, not the coach
    let maxPromptsPerSession: Int

    /// Auto-dismiss duration in seconds for prompts.
    /// Default: 8 seconds - Prompts fade naturally if not interacted with
    let autoDismissDuration: TimeInterval

    // MARK: - Animation Thresholds

    /// Duration for fade-in animation in seconds.
    let fadeInDuration: TimeInterval

    /// Duration for fade-out animation in seconds.
    let fadeOutDuration: TimeInterval

    // MARK: - Sensitivity Levels

    /// Sensitivity adjustment factor (0.5 = half as sensitive, 2.0 = twice as sensitive)
    /// Affects how readily the system shows prompts.
    let sensitivityMultiplier: Double

    // MARK: - Initializer

    init(
        minimumConfidence: Double = 0.85,
        cooldownDuration: TimeInterval = 120.0,
        speechCooldown: TimeInterval = 5.0,
        maxPromptsPerSession: Int = 3,
        autoDismissDuration: TimeInterval = 8.0,
        fadeInDuration: TimeInterval = 0.3,
        fadeOutDuration: TimeInterval = 0.25,
        sensitivityMultiplier: Double = 1.0
    ) {
        self.minimumConfidence = min(1.0, max(0.0, minimumConfidence))
        self.cooldownDuration = max(0, cooldownDuration)
        self.speechCooldown = max(0, speechCooldown)
        self.maxPromptsPerSession = max(0, maxPromptsPerSession)
        self.autoDismissDuration = max(1, autoDismissDuration)
        self.fadeInDuration = max(0.1, fadeInDuration)
        self.fadeOutDuration = max(0.1, fadeOutDuration)
        self.sensitivityMultiplier = min(3.0, max(0.1, sensitivityMultiplier))
    }

    // MARK: - Preset Configurations

    /// Default conservative thresholds following silence-first philosophy
    static let `default` = CoachingThresholds()

    /// Minimal intervention - for experienced researchers
    static let minimal = CoachingThresholds(
        minimumConfidence: 0.95,
        cooldownDuration: 180.0,
        speechCooldown: 8.0,
        maxPromptsPerSession: 2,
        autoDismissDuration: 6.0,
        sensitivityMultiplier: 0.5
    )

    /// Balanced - moderate intervention level
    static let balanced = CoachingThresholds(
        minimumConfidence: 0.80,
        cooldownDuration: 90.0,
        speechCooldown: 4.0,
        maxPromptsPerSession: 4,
        autoDismissDuration: 10.0,
        sensitivityMultiplier: 1.0
    )

    /// Active - for new researchers who want more guidance
    static let active = CoachingThresholds(
        minimumConfidence: 0.70,
        cooldownDuration: 60.0,
        speechCooldown: 3.0,
        maxPromptsPerSession: 6,
        autoDismissDuration: 12.0,
        sensitivityMultiplier: 1.5
    )

    // MARK: - Computed Properties

    /// Effective confidence threshold after applying sensitivity multiplier
    var effectiveConfidenceThreshold: Double {
        // Higher sensitivity = lower threshold (easier to trigger)
        // sensitivityMultiplier of 2.0 halves the threshold
        let adjusted = minimumConfidence / sensitivityMultiplier
        return min(1.0, max(0.5, adjusted))
    }

    /// Effective cooldown after applying sensitivity multiplier
    var effectiveCooldown: TimeInterval {
        // Higher sensitivity = shorter cooldown
        return cooldownDuration / sensitivityMultiplier
    }
}

// MARK: - Threshold Level Enum

/// Predefined coaching sensitivity levels
enum CoachingLevel: String, CaseIterable, Codable {
    case off = "off"
    case minimal = "minimal"
    case balanced = "balanced"
    case active = "active"

    var displayName: String {
        switch self {
        case .off:
            return "Off"
        case .minimal:
            return "Minimal"
        case .balanced:
            return "Balanced"
        case .active:
            return "Active"
        }
    }

    var description: String {
        switch self {
        case .off:
            return "No coaching prompts will be shown"
        case .minimal:
            return "Only essential prompts for experienced researchers"
        case .balanced:
            return "Moderate guidance for most situations"
        case .active:
            return "More frequent prompts for learning researchers"
        }
    }

    var thresholds: CoachingThresholds {
        switch self {
        case .off:
            return CoachingThresholds(maxPromptsPerSession: 0)
        case .minimal:
            return .minimal
        case .balanced:
            return .balanced
        case .active:
            return .active
        }
    }

    var icon: String {
        switch self {
        case .off:
            return "speaker.slash"
        case .minimal:
            return "speaker.wave.1"
        case .balanced:
            return "speaker.wave.2"
        case .active:
            return "speaker.wave.3"
        }
    }
}

// MARK: - Function Call Types

/// Types of coaching function calls that can be received from the AI
enum CoachingFunctionType: String, Codable {
    /// Suggest a follow-up question
    case suggestFollowUp = "suggest_follow_up"

    /// Prompt to explore a topic deeper
    case exploreDeeper = "explore_deeper"

    /// Remind about an uncovered topic
    case uncoveredTopic = "uncovered_topic"

    /// Suggest a pivot to maintain engagement
    case suggestPivot = "suggest_pivot"

    /// Encourage the researcher
    case encouragement = "encouragement"

    /// General coaching tip
    case generalTip = "general_tip"

    var displayName: String {
        switch self {
        case .suggestFollowUp:
            return "Follow-up Suggestion"
        case .exploreDeeper:
            return "Explore Deeper"
        case .uncoveredTopic:
            return "Uncovered Topic"
        case .suggestPivot:
            return "Suggested Pivot"
        case .encouragement:
            return "Encouragement"
        case .generalTip:
            return "Tip"
        }
    }

    var icon: String {
        switch self {
        case .suggestFollowUp:
            return "bubble.right"
        case .exploreDeeper:
            return "arrow.down.right.circle"
        case .uncoveredTopic:
            return "exclamationmark.circle"
        case .suggestPivot:
            return "arrow.triangle.branch"
        case .encouragement:
            return "hand.thumbsup"
        case .generalTip:
            return "lightbulb"
        }
    }

    /// Priority level (lower = higher priority)
    var priority: Int {
        switch self {
        case .uncoveredTopic:
            return 1
        case .suggestFollowUp:
            return 2
        case .exploreDeeper:
            return 3
        case .suggestPivot:
            return 4
        case .encouragement:
            return 5
        case .generalTip:
            return 6
        }
    }
}
