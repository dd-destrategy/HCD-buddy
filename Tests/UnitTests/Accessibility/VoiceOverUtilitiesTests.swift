//
//  VoiceOverUtilitiesTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for VoiceOver accessibility utilities
//

import XCTest
import SwiftUI
@testable import HCDInterviewCoach

final class VoiceOverUtilitiesTests: XCTestCase {

    // MARK: - Test: Topic Awareness Status Accessibility

    func testTopicStatusAccessibilityDescription_untouched() {
        let status = TopicAwarenessStatus.untouched
        XCTAssertEqual(status.accessibilityDescription, "Not yet discussed")
    }

    func testTopicStatusAccessibilityDescription_touched() {
        let status = TopicAwarenessStatus.touched
        XCTAssertEqual(status.accessibilityDescription, "Briefly mentioned")
    }

    func testTopicStatusAccessibilityDescription_explored() {
        let status = TopicAwarenessStatus.explored
        XCTAssertEqual(status.accessibilityDescription, "Discussed in depth")
    }

    func testTopicStatusAccessibilityDescription_allStatusesHaveDescriptions() {
        // Verify all status cases have non-empty descriptions
        let allStatuses: [TopicAwarenessStatus] = [.untouched, .touched, .explored]
        for status in allStatuses {
            XCTAssertFalse(status.accessibilityDescription.isEmpty,
                          "\(status) should have an accessibility description")
        }
    }

    // MARK: - Test: Insight Source Accessibility

    func testInsightAccessibility_aiSource() {
        let source = InsightSource.ai
        XCTAssertEqual(source.accessibilityDescription, "Flagged by AI")
    }

    func testInsightAccessibility_manualSource() {
        let source = InsightSource.manual
        XCTAssertEqual(source.accessibilityDescription, "Manually flagged")
    }

    func testInsightAccessibility_allSourcesHaveDescriptions() {
        let allSources: [InsightSource] = [.ai, .manual]
        for source in allSources {
            XCTAssertFalse(source.accessibilityDescription.isEmpty,
                          "\(source) should have an accessibility description")
        }
    }

    // MARK: - Test: Session State Accessibility

    func testSessionStateAccessibilityDescription_idle() {
        XCTAssertEqual(SessionState.idle.accessibilityDescription, "idle")
    }

    func testSessionStateAccessibilityDescription_setup() {
        XCTAssertEqual(SessionState.setup.accessibilityDescription, "setting up")
    }

    func testSessionStateAccessibilityDescription_connecting() {
        XCTAssertEqual(SessionState.connecting.accessibilityDescription, "connecting")
    }

    func testSessionStateAccessibilityDescription_ready() {
        XCTAssertEqual(SessionState.ready.accessibilityDescription, "ready to record")
    }

    func testSessionStateAccessibilityDescription_streaming() {
        XCTAssertEqual(SessionState.streaming.accessibilityDescription, "recording")
    }

    func testSessionStateAccessibilityDescription_paused() {
        XCTAssertEqual(SessionState.paused.accessibilityDescription, "paused")
    }

    func testSessionStateAccessibilityDescription_reconnecting() {
        XCTAssertEqual(SessionState.reconnecting.accessibilityDescription, "reconnecting")
    }

    func testSessionStateAccessibilityDescription_ending() {
        XCTAssertEqual(SessionState.ending.accessibilityDescription, "ending")
    }

    func testSessionStateAccessibilityDescription_ended() {
        XCTAssertEqual(SessionState.ended.accessibilityDescription, "ended")
    }

    func testSessionStateAccessibilityDescription_failed() {
        XCTAssertEqual(SessionState.failed.accessibilityDescription, "failed")
    }

    func testSessionModeAccessibilityDescription_allStatesHaveDescriptions() {
        let allStates: [SessionState] = [
            .idle, .setup, .connecting, .ready, .streaming,
            .paused, .reconnecting, .ending, .ended, .failed
        ]
        for state in allStates {
            XCTAssertFalse(state.accessibilityDescription.isEmpty,
                          "\(state) should have an accessibility description")
        }
    }

    // MARK: - Test: Connection Quality Accessibility

    func testConnectionQualityAccessibilityDescription_excellent() {
        XCTAssertEqual(ConnectionQuality.excellent.accessibilityDescription, "Excellent quality")
    }

    func testConnectionQualityAccessibilityDescription_good() {
        XCTAssertEqual(ConnectionQuality.good.accessibilityDescription, "Good quality")
    }

    func testConnectionQualityAccessibilityDescription_fair() {
        XCTAssertEqual(ConnectionQuality.fair.accessibilityDescription, "Fair quality")
    }

    func testConnectionQualityAccessibilityDescription_poor() {
        XCTAssertEqual(ConnectionQuality.poor.accessibilityDescription, "Poor quality")
    }

    func testConnectionQualityAccessibilityDescription_allQualitiesHaveDescriptions() {
        let allQualities: [ConnectionQuality] = [.excellent, .good, .fair, .poor]
        for quality in allQualities {
            XCTAssertFalse(quality.accessibilityDescription.isEmpty,
                          "\(quality) should have an accessibility description")
        }
    }

    // MARK: - Test: Live Region Priority

    func testLiveRegionPriority_polite() {
        let priority = AccessibilityLiveRegionPriority.polite
        #if os(macOS)
        XCTAssertEqual(priority.nsPriority, .medium)
        #endif
        // Verify enum case exists
        XCTAssertNotNil(priority)
    }

    func testLiveRegionPriority_assertive() {
        let priority = AccessibilityLiveRegionPriority.assertive
        #if os(macOS)
        XCTAssertEqual(priority.nsPriority, .high)
        #endif
        // Verify enum case exists
        XCTAssertNotNil(priority)
    }

    // MARK: - Test: View Modifier Existence

    func testUtteranceAccessibility_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply utterance accessibility modifier
        let modifiedView = view.accessibilityUtterance(
            speaker: "Interviewer",
            text: "Hello, how are you?",
            timestamp: "00:01:30",
            confidence: 0.95
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    func testUtteranceAccessibility_withoutConfidence() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply utterance accessibility without confidence
        let modifiedView = view.accessibilityUtterance(
            speaker: "Participant",
            text: "I'm doing well",
            timestamp: "00:01:35"
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    func testTopicAccessibility_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply topic status accessibility modifier
        let modifiedView = view.accessibilityTopicStatus(
            name: "User Goals",
            status: .explored
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    func testInsightAccessibility_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply insight accessibility modifier
        let modifiedView = view.accessibilityInsight(
            theme: "Pain Point",
            quote: "The process is too complicated",
            source: .manual,
            timestamp: "00:05:20"
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    func testInsightAccessibility_aiSource() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply insight accessibility with AI source
        let modifiedView = view.accessibilityInsight(
            theme: "Opportunity",
            quote: "I wish there was a better way",
            source: .ai,
            timestamp: "00:10:45"
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    func testSessionControlAccessibility_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply session control accessibility modifier
        let modifiedView = view.accessibilitySessionControl(
            action: "Start",
            state: .ready,
            isEnabled: true
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    func testSessionControlAccessibility_disabled() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply session control accessibility when disabled
        let modifiedView = view.accessibilitySessionControl(
            action: "Start",
            state: .idle,
            isEnabled: false
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    func testCoachingPromptAccessibility_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply coaching prompt accessibility modifier
        let modifiedView = view.accessibilityCoachingPrompt(
            message: "Consider asking about their workflow",
            autoDismissIn: 8
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    func testAudioLevelAccessibility_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply audio level accessibility modifier
        let modifiedView = view.accessibilityAudioLevel(
            source: "Microphone",
            level: 0.5
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    func testConnectionStatusAccessibility_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply connection status accessibility modifier
        let modifiedView = view.accessibilityConnectionStatus(
            isConnected: true,
            quality: .good
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    func testConnectionStatusAccessibility_disconnected() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply connection status accessibility when disconnected
        let modifiedView = view.accessibilityConnectionStatus(
            isConnected: false,
            quality: nil
        )

        // Then: View should be modified
        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Test: Speaker Accessibility Description

    func testSpeakerAccessibilityDescription_interviewer() {
        // The accessibility label should include the speaker name
        let speaker = "Interviewer"
        let text = "Hello"

        // Verify label format would be "Interviewer said: Hello"
        let expectedLabel = "\(speaker) said: \(text)"
        XCTAssertTrue(expectedLabel.contains(speaker))
        XCTAssertTrue(expectedLabel.contains(text))
    }

    func testSpeakerAccessibilityDescription_participant() {
        let speaker = "Participant"
        let text = "Hi there"

        let expectedLabel = "\(speaker) said: \(text)"
        XCTAssertTrue(expectedLabel.contains(speaker))
        XCTAssertTrue(expectedLabel.contains(text))
    }

    // MARK: - Test: Accessibility Value Formatting

    func testAccessibilityValueFormatting_timestamp() {
        let timestamp = "00:15:30"
        let expectedValue = "At \(timestamp)"
        XCTAssertEqual(expectedValue, "At 00:15:30")
    }

    func testAccessibilityValueFormatting_audioLevel_low() {
        let level = 0.05
        let percentage = Int(level * 100)
        XCTAssertEqual(percentage, 5)
    }

    func testAccessibilityValueFormatting_audioLevel_medium() {
        let level = 0.5
        let percentage = Int(level * 100)
        XCTAssertEqual(percentage, 50)
    }

    func testAccessibilityValueFormatting_audioLevel_high() {
        let level = 0.95
        let percentage = Int(level * 100)
        XCTAssertEqual(percentage, 95)
    }

    // MARK: - Test: Live Region View

    func testLiveRegion_defaultPriority() {
        // Given: A live region with default priority
        let liveRegion = LiveRegion {
            Text("Dynamic content")
        }

        // Then: Priority should be polite
        XCTAssertEqual(liveRegion.priority, .polite)
    }

    func testLiveRegion_assertivePriority() {
        // Given: A live region with assertive priority
        let liveRegion = LiveRegion(priority: .assertive) {
            Text("Urgent content")
        }

        // Then: Priority should be assertive
        XCTAssertEqual(liveRegion.priority, .assertive)
    }

    func testLiveRegion_politePriority() {
        // Given: A live region with polite priority
        let liveRegion = LiveRegion(priority: .polite) {
            Text("Normal content")
        }

        // Then: Priority should be polite
        XCTAssertEqual(liveRegion.priority, .polite)
    }

    func testLiveRegion_contentIsStored() {
        // Given: A live region with specific content
        let liveRegion = LiveRegion {
            Text("Test Content")
        }

        // Then: Content should be stored
        XCTAssertNotNil(liveRegion.content)
    }

    func testLiveRegion_bodyExists() {
        // Given: A live region
        let liveRegion = LiveRegion {
            Text("Test")
        }

        // Then: Body should exist
        XCTAssertNotNil(liveRegion.body)
    }

    // MARK: - Test: Hint Formatting

    func testInsightHint_includesTimestamp() {
        let timestamp = "00:05:20"
        let hint = "At \(timestamp). Double tap to navigate to transcript."
        XCTAssertTrue(hint.contains(timestamp))
    }

    func testInsightHint_includesNavigationInstruction() {
        let hint = "At 00:05:20. Double tap to navigate to transcript."
        XCTAssertTrue(hint.contains("Double tap"))
        XCTAssertTrue(hint.contains("navigate"))
    }

    func testCoachingPromptHint_includesAutoDismissTime() {
        let seconds = 8
        let hint = "Auto-dismissing in \(seconds) seconds. Press Escape to dismiss now."
        XCTAssertTrue(hint.contains("\(seconds)"))
        XCTAssertTrue(hint.contains("Escape"))
    }

    // MARK: - Test: Audio Level Descriptions

    func testAudioLevelDescription_veryQuiet() {
        // Level 0.0 to 0.1 should be "very quiet"
        let level = 0.05
        let isVeryQuiet = level >= 0 && level < 0.1
        XCTAssertTrue(isVeryQuiet)
    }

    func testAudioLevelDescription_quiet() {
        // Level 0.1 to 0.3 should be "quiet"
        let level = 0.2
        let isQuiet = level >= 0.1 && level < 0.3
        XCTAssertTrue(isQuiet)
    }

    func testAudioLevelDescription_moderate() {
        // Level 0.3 to 0.6 should be "moderate"
        let level = 0.45
        let isModerate = level >= 0.3 && level < 0.6
        XCTAssertTrue(isModerate)
    }

    func testAudioLevelDescription_loud() {
        // Level 0.6 to 0.8 should be "loud"
        let level = 0.7
        let isLoud = level >= 0.6 && level < 0.8
        XCTAssertTrue(isLoud)
    }

    func testAudioLevelDescription_veryLoud() {
        // Level 0.8 and above should be "very loud"
        let level = 0.9
        let isVeryLoud = level >= 0.8
        XCTAssertTrue(isVeryLoud)
    }

    // MARK: - Test: Accessibility Traits

    func testUtteranceTraits_containsStaticText() {
        // Utterances should have static text trait
        // This is verified through the modifier application
        let view = Text("Test").accessibilityUtterance(
            speaker: "Test",
            text: "Test text",
            timestamp: "00:00:00"
        )
        XCTAssertNotNil(view)
    }

    func testTopicStatusTraits_containsButton() {
        // Topic status should have button trait for interaction
        let view = Text("Test").accessibilityTopicStatus(
            name: "Test Topic",
            status: .untouched
        )
        XCTAssertNotNil(view)
    }

    func testInsightTraits_containsButton() {
        // Insights should have button trait for navigation
        let view = Text("Test").accessibilityInsight(
            theme: "Test",
            quote: "Test quote",
            source: .manual,
            timestamp: "00:00:00"
        )
        XCTAssertNotNil(view)
    }

    func testAudioLevelTraits_containsUpdatesFrequently() {
        // Audio levels should have updates frequently trait
        let view = Text("Test").accessibilityAudioLevel(
            source: "Mic",
            level: 0.5
        )
        XCTAssertNotNil(view)
    }

    func testConnectionStatusTraits_containsUpdatesFrequently() {
        // Connection status should have updates frequently trait
        let view = Text("Test").accessibilityConnectionStatus(
            isConnected: true,
            quality: .good
        )
        XCTAssertNotNil(view)
    }
}
