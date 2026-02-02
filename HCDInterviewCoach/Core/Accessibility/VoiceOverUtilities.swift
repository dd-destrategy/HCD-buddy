//
//  VoiceOverUtilities.swift
//  HCDInterviewCoach
//
//  Created by Agent E13
//  EPIC E13: Accessibility - VoiceOver Support
//

import SwiftUI

// MARK: - Accessibility Extensions for Core Types

extension TopicAwareness {
    var accessibilityDescription: String {
        switch self {
        case .notCovered:
            return "Not yet discussed"
        case .partialCoverage:
            return "Briefly mentioned"
        case .fullyCovered:
            return "Discussed in depth"
        case .skipped:
            return "Skipped"
        }
    }
}

extension InsightSource {
    var accessibilityDescription: String {
        switch self {
        case .aiGenerated:
            return "Flagged by AI"
        case .userAdded:
            return "Manually flagged"
        case .automated:
            return "Automatically flagged"
        }
    }
}

extension SessionState {
    var accessibilityDescription: String {
        switch self {
        case .idle:
            return "idle"
        case .configuring:
            return "setting up"
        case .ready:
            return "ready to record"
        case .running:
            return "recording"
        case .paused:
            return "paused"
        case .ending:
            return "ending"
        case .ended:
            return "ended"
        case .error:
            return "error occurred"
        case .failed:
            return "failed"
        }
    }
}

extension ConnectionQuality {
    var accessibilityDescription: String {
        switch self {
        case .excellent:
            return "Excellent quality"
        case .good:
            return "Good quality"
        case .fair:
            return "Fair quality"
        case .poor:
            return "Poor quality"
        case .disconnected:
            return "Disconnected"
        }
    }
}

// MARK: - VoiceOver Extensions

extension View {

    /// Configures accessibility for an utterance in the transcript
    /// Provides rich semantic information about speaker and content
    func accessibilityUtterance(
        speaker: String,
        text: String,
        timestamp: String,
        confidence: Double? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(speaker) said: \(text)")
            .accessibilityValue("At \(timestamp)")
            .accessibilityHint("Double tap to edit speaker. Swipe up or down for more actions.")
            .accessibilityAddTraits(.isStaticText)
    }

    /// Configures accessibility for topic status display
    /// Announces both the topic name and its coverage status
    func accessibilityTopicStatus(
        name: String,
        status: TopicAwareness
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(name)")
            .accessibilityValue("\(status.accessibilityDescription)")
            .accessibilityHint("Double tap to manually adjust status")
            .accessibilityAddTraits(.isButton)
    }

    /// Configures accessibility for insight items
    /// Provides context about the insight and navigation options
    func accessibilityInsight(
        theme: String,
        quote: String,
        source: InsightSource,
        timestamp: String
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(theme) insight")
            .accessibilityValue(quote)
            .accessibilityHint("\(source.accessibilityDescription). At \(timestamp). Double tap to navigate to transcript.")
            .accessibilityAddTraits(.isButton)
    }

    /// Configures accessibility for session controls
    /// Announces current state and available actions
    func accessibilitySessionControl(
        action: String,
        state: SessionState,
        isEnabled: Bool
    ) -> some View {
        self
            .accessibilityLabel("\(action) session")
            .accessibilityValue("Session is \(state.accessibilityDescription)")
            .accessibilityHint(isEnabled ? "Double tap to \(action.lowercased())" : "Not available")
            .accessibilityAddTraits(.isButton)
            .disabled(!isEnabled)
    }

    /// Configures accessibility for coaching prompts
    /// Announces the prompt with appropriate urgency
    func accessibilityCoachingPrompt(
        message: String,
        autoDismissIn seconds: Int
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Coaching suggestion")
            .accessibilityValue(message)
            .accessibilityHint("Auto-dismissing in \(seconds) seconds. Press Escape to dismiss now.")
            .accessibilityAddTraits(.isStaticText)
    }

    /// Configures accessibility for audio level meters
    /// Provides numeric level information
    func accessibilityAudioLevel(
        source: String,
        level: Double
    ) -> some View {
        let percentage = Int(level * 100)
        let description = levelDescription(for: level)

        return self
            .accessibilityLabel("\(source) audio level")
            .accessibilityValue("\(percentage) percent, \(description)")
            .accessibilityAddTraits(.updatesFrequently)
    }

    /// Configures accessibility for connection status
    /// Announces connection state and quality
    func accessibilityConnectionStatus(
        isConnected: Bool,
        quality: ConnectionQuality?
    ) -> some View {
        let status = isConnected ? "Connected" : "Disconnected"
        let qualityText = quality?.accessibilityDescription ?? ""

        return self
            .accessibilityLabel("Connection status")
            .accessibilityValue("\(status). \(qualityText)")
            .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Helper Functions

    private func levelDescription(for level: Double) -> String {
        switch level {
        case 0..<0.1:
            return "very quiet"
        case 0.1..<0.3:
            return "quiet"
        case 0.3..<0.6:
            return "moderate"
        case 0.6..<0.8:
            return "loud"
        default:
            return "very loud"
        }
    }
}

// MARK: - Live Region

/// A container that announces content changes to screen readers
/// Used for dynamic content that updates frequently
struct LiveRegion<Content: View>: View {

    let priority: AccessibilityLiveRegionPriority
    let content: Content

    init(
        priority: AccessibilityLiveRegionPriority = .polite,
        @ViewBuilder content: () -> Content
    ) {
        self.priority = priority
        self.content = content()
    }

    var body: some View {
        content
            .accessibilityAddTraits(.updatesFrequently)
    }
}

enum AccessibilityLiveRegionPriority {
    case polite
    case assertive

    #if os(macOS)
    var nsPriority: NSAccessibilityPriorityLevel {
        switch self {
        case .polite:
            return .medium
        case .assertive:
            return .high
        }
    }
    #endif
}
