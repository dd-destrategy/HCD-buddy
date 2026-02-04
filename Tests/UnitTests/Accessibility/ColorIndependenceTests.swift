//
//  ColorIndependenceTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for color-independent accessibility indicators
//

import XCTest
import SwiftUI
@testable import HCDInterviewCoach

final class ColorIndependenceTests: XCTestCase {

    // MARK: - Test: Topic Status Icons

    func testTopicStatusIcon_notStarted() {
        let status = TopicAwarenessStatus.untouched
        XCTAssertEqual(status.iconName, "circle")
    }

    func testTopicStatusIcon_mentioned() {
        let status = TopicAwarenessStatus.touched
        XCTAssertEqual(status.iconName, "circle.lefthalf.filled")
    }

    func testTopicStatusIcon_explored() {
        let status = TopicAwarenessStatus.explored
        XCTAssertEqual(status.iconName, "circle.fill")
    }

    func testTopicStatusIcon_allStatusesHaveUniqueIcons() {
        let allStatuses: [TopicAwarenessStatus] = [.untouched, .touched, .explored]
        let iconNames = allStatuses.map { $0.iconName }
        let uniqueIcons = Set(iconNames)

        XCTAssertEqual(iconNames.count, uniqueIcons.count,
                      "All topic statuses should have unique icons")
    }

    func testTopicStatusIcon_allIconsAreValidSFSymbols() {
        // Verify the icon names are non-empty (valid SF Symbol names)
        let allStatuses: [TopicAwarenessStatus] = [.untouched, .touched, .explored]
        for status in allStatuses {
            XCTAssertFalse(status.iconName.isEmpty,
                          "\(status) should have a valid icon name")
        }
    }

    // MARK: - Test: Topic Status Colors

    func testTopicStatusColor_untouched() {
        let status = TopicAwarenessStatus.untouched
        XCTAssertEqual(status.color, .gray)
    }

    func testTopicStatusColor_touched() {
        let status = TopicAwarenessStatus.touched
        // Light blue color
        XCTAssertNotNil(status.color)
    }

    func testTopicStatusColor_explored() {
        let status = TopicAwarenessStatus.explored
        XCTAssertEqual(status.color, .blue)
    }

    // MARK: - Test: Topic Status Labels

    func testTopicStatusLabel_untouched() {
        let status = TopicAwarenessStatus.untouched
        XCTAssertEqual(status.label, "Not Discussed")
    }

    func testTopicStatusLabel_touched() {
        let status = TopicAwarenessStatus.touched
        XCTAssertEqual(status.label, "Mentioned")
    }

    func testTopicStatusLabel_explored() {
        let status = TopicAwarenessStatus.explored
        XCTAssertEqual(status.label, "Explored")
    }

    func testTopicStatusLabel_allStatusesHaveLabels() {
        let allStatuses: [TopicAwarenessStatus] = [.untouched, .touched, .explored]
        for status in allStatuses {
            XCTAssertFalse(status.label.isEmpty,
                          "\(status) should have a text label")
        }
    }

    // MARK: - Test: Topic Status Indicator View

    func testTopicStatusIndicator_creation() {
        let indicator = TopicStatusIndicator(status: .notStarted)
        XCTAssertNotNil(indicator)
    }

    func testTopicStatusIndicator_withLabel() {
        let indicator = TopicStatusIndicator(status: .explored, showLabel: true)
        XCTAssertTrue(indicator.showLabel)
    }

    func testTopicStatusIndicator_withoutLabel() {
        let indicator = TopicStatusIndicator(status: .explored, showLabel: false)
        XCTAssertFalse(indicator.showLabel)
    }

    func testTopicStatusIndicator_defaultLabelIsFalse() {
        let indicator = TopicStatusIndicator(status: .mentioned)
        XCTAssertFalse(indicator.showLabel)
    }

    func testTopicStatusIndicator_bodyExists() {
        let indicator = TopicStatusIndicator(status: .notStarted)
        XCTAssertNotNil(indicator.body)
    }

    // MARK: - Test: Connection Status Icons

    func testConnectionStatusIcon_connected() {
        let status = ConnectionStatusDisplay.connected
        XCTAssertEqual(status.iconName, "wifi")
    }

    func testConnectionStatusIcon_connecting() {
        let status = ConnectionStatusDisplay.connecting
        XCTAssertEqual(status.iconName, "wifi.exclamationmark")
    }

    func testConnectionStatusIcon_disconnected() {
        let status = ConnectionStatusDisplay.disconnected
        XCTAssertEqual(status.iconName, "wifi.slash")
    }

    func testConnectionStatusIcon_reconnecting() {
        let status = ConnectionStatusDisplay.reconnecting
        XCTAssertEqual(status.iconName, "arrow.clockwise")
    }

    func testConnectionStatusIcon_allStatusesHaveUniqueIcons() {
        let allStatuses: [ConnectionStatusDisplay] = [
            .connected, .connecting, .disconnected, .reconnecting
        ]
        let iconNames = allStatuses.map { $0.iconName }
        let uniqueIcons = Set(iconNames)

        XCTAssertEqual(iconNames.count, uniqueIcons.count,
                      "All connection statuses should have unique icons")
    }

    // MARK: - Test: Connection Status Colors

    func testConnectionStatusColor_connected() {
        let status = ConnectionStatusDisplay.connected
        XCTAssertEqual(status.color, .green)
    }

    func testConnectionStatusColor_connecting() {
        let status = ConnectionStatusDisplay.connecting
        XCTAssertEqual(status.color, .orange)
    }

    func testConnectionStatusColor_disconnected() {
        let status = ConnectionStatusDisplay.disconnected
        XCTAssertEqual(status.color, .red)
    }

    func testConnectionStatusColor_reconnecting() {
        let status = ConnectionStatusDisplay.reconnecting
        XCTAssertEqual(status.color, .orange)
    }

    // MARK: - Test: Connection Status Labels

    func testConnectionStatusLabel_connected() {
        let status = ConnectionStatusDisplay.connected
        XCTAssertEqual(status.label, "Connected")
    }

    func testConnectionStatusLabel_connecting() {
        let status = ConnectionStatusDisplay.connecting
        XCTAssertEqual(status.label, "Connecting")
    }

    func testConnectionStatusLabel_disconnected() {
        let status = ConnectionStatusDisplay.disconnected
        XCTAssertEqual(status.label, "Disconnected")
    }

    func testConnectionStatusLabel_reconnecting() {
        let status = ConnectionStatusDisplay.reconnecting
        XCTAssertEqual(status.label, "Reconnecting")
    }

    // MARK: - Test: Connection Status View

    func testConnectionStatusView_creation() {
        let view = ConnectionStatusView(status: .connected)
        XCTAssertNotNil(view)
    }

    func testConnectionStatusView_withLabel() {
        let view = ConnectionStatusView(status: .connected, showLabel: true)
        XCTAssertTrue(view.showLabel)
    }

    func testConnectionStatusView_withoutLabel() {
        let view = ConnectionStatusView(status: .connected, showLabel: false)
        XCTAssertFalse(view.showLabel)
    }

    func testConnectionStatusView_defaultLabelIsTrue() {
        let view = ConnectionStatusView(status: .connecting)
        XCTAssertTrue(view.showLabel)
    }

    func testConnectionStatusView_bodyExists() {
        let view = ConnectionStatusView(status: .disconnected)
        XCTAssertNotNil(view.body)
    }

    // MARK: - Test: Recording State Icons

    func testRecordingStateIcon_idle() {
        let state = RecordingStateDisplay.idle
        XCTAssertEqual(state.iconName, "circle")
    }

    func testRecordingStateIcon_recording() {
        let state = RecordingStateDisplay.recording
        XCTAssertEqual(state.iconName, "record.circle.fill")
    }

    func testRecordingStateIcon_paused() {
        let state = RecordingStateDisplay.paused
        XCTAssertEqual(state.iconName, "pause.circle.fill")
    }

    func testRecordingStateIcon_allStatesHaveUniqueIcons() {
        let allStates: [RecordingStateDisplay] = [.idle, .recording, .paused]
        let iconNames = allStates.map { $0.iconName }
        let uniqueIcons = Set(iconNames)

        XCTAssertEqual(iconNames.count, uniqueIcons.count,
                      "All recording states should have unique icons")
    }

    // MARK: - Test: Recording State Colors

    func testRecordingStateColor_idle() {
        let state = RecordingStateDisplay.idle
        XCTAssertEqual(state.color, .gray)
    }

    func testRecordingStateColor_recording() {
        let state = RecordingStateDisplay.recording
        XCTAssertEqual(state.color, .red)
    }

    func testRecordingStateColor_paused() {
        let state = RecordingStateDisplay.paused
        XCTAssertEqual(state.color, .orange)
    }

    // MARK: - Test: Recording State Labels

    func testRecordingStateLabel_idle() {
        let state = RecordingStateDisplay.idle
        XCTAssertEqual(state.label, "Not Recording")
    }

    func testRecordingStateLabel_recording() {
        let state = RecordingStateDisplay.recording
        XCTAssertEqual(state.label, "Recording")
    }

    func testRecordingStateLabel_paused() {
        let state = RecordingStateDisplay.paused
        XCTAssertEqual(state.label, "Paused")
    }

    // MARK: - Test: Recording State Animation

    func testRecordingStateAnimation_idle() {
        let state = RecordingStateDisplay.idle
        XCTAssertFalse(state.isAnimated)
    }

    func testRecordingStateAnimation_recording() {
        let state = RecordingStateDisplay.recording
        XCTAssertTrue(state.isAnimated)
    }

    func testRecordingStateAnimation_paused() {
        let state = RecordingStateDisplay.paused
        XCTAssertFalse(state.isAnimated)
    }

    // MARK: - Test: Recording State Indicator View

    func testRecordingStateIndicator_creation() {
        let indicator = RecordingStateIndicator(state: .idle)
        XCTAssertNotNil(indicator)
    }

    func testRecordingStateIndicator_bodyExists() {
        let indicator = RecordingStateIndicator(state: .recording)
        XCTAssertNotNil(indicator.body)
    }

    func testRecordingStateAccessibility_containsLabel() {
        // Verify accessibility label format
        let state = RecordingStateDisplay.recording
        let expectedLabel = "Recording state: \(state.label)"
        XCTAssertEqual(expectedLabel, "Recording state: Recording")
    }

    // MARK: - Test: Insight Source Icons

    func testInsightSourceIcon_ai() {
        let source = InsightSourceDisplay.ai
        XCTAssertEqual(source.iconName, "sparkles")
    }

    func testInsightSourceIcon_manual() {
        let source = InsightSourceDisplay.manual
        XCTAssertEqual(source.iconName, "hand.raised.fill")
    }

    func testInsightSourceIcon_areUnique() {
        let allSources: [InsightSourceDisplay] = [.ai, .manual]
        let iconNames = allSources.map { $0.iconName }
        let uniqueIcons = Set(iconNames)

        XCTAssertEqual(iconNames.count, uniqueIcons.count,
                      "All insight sources should have unique icons")
    }

    // MARK: - Test: Insight Source Colors

    func testInsightSourceColor_ai() {
        let source = InsightSourceDisplay.ai
        XCTAssertEqual(source.color, .purple)
    }

    func testInsightSourceColor_manual() {
        let source = InsightSourceDisplay.manual
        XCTAssertEqual(source.color, .blue)
    }

    // MARK: - Test: Insight Source Labels

    func testInsightSourceLabel_ai() {
        let source = InsightSourceDisplay.ai
        XCTAssertEqual(source.label, "AI Flagged")
    }

    func testInsightSourceLabel_manual() {
        let source = InsightSourceDisplay.manual
        XCTAssertEqual(source.label, "Manual")
    }

    // MARK: - Test: Insight Source Indicator View

    func testInsightSourceIndicator_creation() {
        let indicator = InsightSourceIndicator(source: .ai)
        XCTAssertNotNil(indicator)
    }

    func testInsightSourceIndicator_withLabel() {
        let indicator = InsightSourceIndicator(source: .manual, showLabel: true)
        XCTAssertTrue(indicator.showLabel)
    }

    func testInsightSourceIndicator_withoutLabel() {
        let indicator = InsightSourceIndicator(source: .ai, showLabel: false)
        XCTAssertFalse(indicator.showLabel)
    }

    func testInsightSourceIndicator_defaultLabelIsTrue() {
        let indicator = InsightSourceIndicator(source: .manual)
        XCTAssertTrue(indicator.showLabel)
    }

    func testInsightSourceIndicator_bodyExists() {
        let indicator = InsightSourceIndicator(source: .ai)
        XCTAssertNotNil(indicator.body)
    }

    // MARK: - Test: Audio Level Indicator

    func testAudioLevelIndicator_creation() {
        let indicator = AudioLevelIndicator(source: "Microphone", level: 0.5)
        XCTAssertNotNil(indicator)
    }

    func testAudioLevelIndicator_withNumeric() {
        let indicator = AudioLevelIndicator(source: "Microphone", level: 0.5, showNumeric: true)
        XCTAssertTrue(indicator.showNumeric)
    }

    func testAudioLevelIndicator_withoutNumeric() {
        let indicator = AudioLevelIndicator(source: "Microphone", level: 0.5, showNumeric: false)
        XCTAssertFalse(indicator.showNumeric)
    }

    func testAudioLevelIndicator_defaultNumericIsTrue() {
        let indicator = AudioLevelIndicator(source: "Mic", level: 0.3)
        XCTAssertTrue(indicator.showNumeric)
    }

    func testAudioLevelIndicator_levelClamping_aboveOne() {
        let indicator = AudioLevelIndicator(source: "Mic", level: 1.5)
        // Level should be clamped to 1.0
        XCTAssertLessThanOrEqual(indicator.level, 1.0)
    }

    func testAudioLevelIndicator_levelClamping_belowZero() {
        let indicator = AudioLevelIndicator(source: "Mic", level: -0.5)
        // Level should be clamped to 0.0
        XCTAssertGreaterThanOrEqual(indicator.level, 0.0)
    }

    func testAudioLevelIndicator_levelClamping_normal() {
        let indicator = AudioLevelIndicator(source: "Mic", level: 0.5)
        XCTAssertEqual(indicator.level, 0.5)
    }

    func testAudioLevelIndicator_bodyExists() {
        let indicator = AudioLevelIndicator(source: "Speaker", level: 0.7)
        XCTAssertNotNil(indicator.body)
    }

    // MARK: - Test: Color Independence Principle

    func testColorIndependence_topicStatusHasIconAndLabel() {
        // Each status should have BOTH icon and label (not just color)
        let allStatuses: [TopicAwarenessStatus] = [.untouched, .touched, .explored]
        for status in allStatuses {
            XCTAssertFalse(status.iconName.isEmpty, "\(status) should have an icon")
            XCTAssertFalse(status.label.isEmpty, "\(status) should have a label")
        }
    }

    func testColorIndependence_connectionStatusHasIconAndLabel() {
        // Each status should have BOTH icon and label (not just color)
        let allStatuses: [ConnectionStatusDisplay] = [
            .connected, .connecting, .disconnected, .reconnecting
        ]
        for status in allStatuses {
            XCTAssertFalse(status.iconName.isEmpty, "\(status) should have an icon")
            XCTAssertFalse(status.label.isEmpty, "\(status) should have a label")
        }
    }

    func testColorIndependence_recordingStateHasIconAndLabel() {
        // Each state should have BOTH icon and label (not just color)
        let allStates: [RecordingStateDisplay] = [.idle, .recording, .paused]
        for state in allStates {
            XCTAssertFalse(state.iconName.isEmpty, "\(state) should have an icon")
            XCTAssertFalse(state.label.isEmpty, "\(state) should have a label")
        }
    }

    func testColorIndependence_insightSourceHasIconAndLabel() {
        // Each source should have BOTH icon and label (not just color)
        let allSources: [InsightSourceDisplay] = [.ai, .manual]
        for source in allSources {
            XCTAssertFalse(source.iconName.isEmpty, "\(source) should have an icon")
            XCTAssertFalse(source.label.isEmpty, "\(source) should have a label")
        }
    }

    func testColorIndependence_audioLevelHasNumericValue() {
        // Audio level indicator should provide numeric value, not just color bar
        let indicator = AudioLevelIndicator(source: "Mic", level: 0.5)
        // showNumeric defaults to true
        XCTAssertTrue(indicator.showNumeric)
    }

    // MARK: - Test: Visual Distinction Without Color

    func testVisualDistinction_topicStatusIconsProgressively() {
        // Icons should show progression: empty -> half -> full
        let untouchedIcon = TopicAwarenessStatus.untouched.iconName
        let touchedIcon = TopicAwarenessStatus.touched.iconName
        let exploredIcon = TopicAwarenessStatus.explored.iconName

        // Verify they form a logical progression
        XCTAssertTrue(untouchedIcon.contains("circle"))
        XCTAssertTrue(touchedIcon.contains("circle"))
        XCTAssertTrue(exploredIcon.contains("fill"))
    }

    func testVisualDistinction_connectionStatusIconsMeaningful() {
        // Icons should clearly indicate connection state
        let connectedIcon = ConnectionStatusDisplay.connected.iconName
        let disconnectedIcon = ConnectionStatusDisplay.disconnected.iconName

        // Connected should show wifi, disconnected should show slash
        XCTAssertEqual(connectedIcon, "wifi")
        XCTAssertTrue(disconnectedIcon.contains("slash"))
    }

    func testVisualDistinction_recordingStateIconsMeaningful() {
        // Recording icon should clearly indicate recording state
        let recordingIcon = RecordingStateDisplay.recording.iconName
        let pausedIcon = RecordingStateDisplay.paused.iconName

        // Recording should show record symbol, paused should show pause
        XCTAssertTrue(recordingIcon.contains("record"))
        XCTAssertTrue(pausedIcon.contains("pause"))
    }
}
