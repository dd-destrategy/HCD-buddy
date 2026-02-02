//
//  TopicCoverageStatus.swift
//  HCD Interview Coach
//
//  EPIC E7: Topic Awareness
//  Coverage status levels for research topics
//

import SwiftUI

// MARK: - Topic Coverage Status

/// Represents the coverage depth of a research topic during an interview session.
/// Status progression: Not Started -> Mentioned -> Explored -> Deep Dive
///
/// Each level includes:
/// - Distinct SF Symbol icon for visual differentiation
/// - Color coding for quick status recognition
/// - Shape variations for color-blind accessibility
/// - Accessibility labels for VoiceOver support
enum TopicCoverageStatus: Int, CaseIterable, Codable, Identifiable {
    case notStarted = 0
    case mentioned = 1
    case explored = 2
    case deepDive = 3

    var id: Int { rawValue }

    // MARK: - Display Properties

    /// Human-readable display name for the status
    var displayName: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .mentioned:
            return "Mentioned"
        case .explored:
            return "Explored"
        case .deepDive:
            return "Deep Dive"
        }
    }

    /// Short label for compact displays
    var shortLabel: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .mentioned:
            return "Mentioned"
        case .explored:
            return "Explored"
        case .deepDive:
            return "Deep"
        }
    }

    /// Detailed description of what this status means
    var description: String {
        switch self {
        case .notStarted:
            return "This topic has not been discussed yet"
        case .mentioned:
            return "This topic has been briefly mentioned in conversation"
        case .explored:
            return "This topic has been discussed with some detail"
        case .deepDive:
            return "This topic has been thoroughly explored with rich detail"
        }
    }

    // MARK: - Visual Indicators

    /// SF Symbol icon name for the status
    /// Icons are chosen to provide clear visual distinction independent of color
    var iconName: String {
        switch self {
        case .notStarted:
            return "circle.dashed"
        case .mentioned:
            return "circle.bottomhalf.filled"
        case .explored:
            return "circle.inset.filled"
        case .deepDive:
            return "checkmark.circle.fill"
        }
    }

    /// Alternative icon for smaller displays
    var compactIconName: String {
        switch self {
        case .notStarted:
            return "circle"
        case .mentioned:
            return "circle.lefthalf.filled"
        case .explored:
            return "circle.fill"
        case .deepDive:
            return "star.circle.fill"
        }
    }

    /// Primary color for the status indicator
    var color: Color {
        switch self {
        case .notStarted:
            return .gray
        case .mentioned:
            return .blue.opacity(0.6)
        case .explored:
            return .blue
        case .deepDive:
            return .green
        }
    }

    /// Background color for status badges
    var backgroundColor: Color {
        color.opacity(0.15)
    }

    /// Border color for status indicators
    var borderColor: Color {
        color.opacity(0.3)
    }

    // MARK: - Accessibility

    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        "Topic status: \(displayName)"
    }

    /// Accessibility hint explaining the current state
    var accessibilityHint: String {
        switch self {
        case .notStarted:
            return "Double tap to cycle status forward. This topic awaits discussion."
        case .mentioned:
            return "Double tap to cycle status forward. Explore further to increase coverage."
        case .explored:
            return "Double tap to cycle status forward. Consider deeper probing questions."
        case .deepDive:
            return "Double tap to cycle status. Topic fully covered."
        }
    }

    /// Accessibility value representing progress (0-100%)
    var accessibilityValue: String {
        "\(progressPercentage)% complete"
    }

    // MARK: - Progress Calculation

    /// Progress percentage for visual indicators
    var progressPercentage: Int {
        switch self {
        case .notStarted:
            return 0
        case .mentioned:
            return 33
        case .explored:
            return 66
        case .deepDive:
            return 100
        }
    }

    /// Progress as a decimal value (0.0 - 1.0)
    var progressValue: Double {
        Double(progressPercentage) / 100.0
    }

    // MARK: - Status Transitions

    /// Returns the next status in the cycle
    var next: TopicCoverageStatus {
        switch self {
        case .notStarted:
            return .mentioned
        case .mentioned:
            return .explored
        case .explored:
            return .deepDive
        case .deepDive:
            return .notStarted
        }
    }

    /// Returns the previous status in the cycle
    var previous: TopicCoverageStatus {
        switch self {
        case .notStarted:
            return .deepDive
        case .mentioned:
            return .notStarted
        case .explored:
            return .mentioned
        case .deepDive:
            return .explored
        }
    }

    /// Whether this status indicates the topic has been started
    var hasBeenStarted: Bool {
        self != .notStarted
    }

    /// Whether this status indicates full coverage
    var isComplete: Bool {
        self == .deepDive
    }

    // MARK: - Factory Methods

    /// Creates a status from a numeric coverage score (0.0 - 1.0)
    static func from(coverageScore: Double) -> TopicCoverageStatus {
        switch coverageScore {
        case 0..<0.15:
            return .notStarted
        case 0.15..<0.45:
            return .mentioned
        case 0.45..<0.75:
            return .explored
        default:
            return .deepDive
        }
    }

    /// Creates a status from mention count and depth indicators
    static func from(mentionCount: Int, hasFollowUp: Bool, hasDetail: Bool) -> TopicCoverageStatus {
        if mentionCount == 0 {
            return .notStarted
        } else if !hasFollowUp && !hasDetail {
            return .mentioned
        } else if hasFollowUp && !hasDetail {
            return .explored
        } else {
            return .deepDive
        }
    }
}

// MARK: - Comparable Conformance

extension TopicCoverageStatus: Comparable {
    static func < (lhs: TopicCoverageStatus, rhs: TopicCoverageStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Accessibility Extensions

extension TopicCoverageStatus {
    /// Full accessibility description for VoiceOver
    var accessibilityDescription: String {
        "\(displayName): \(description)"
    }
}
