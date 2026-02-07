//
//  CoachingTimingSettingsTests.swift
//  HCD Interview Coach Tests
//
//  Feature A: Customizable Coaching Timing & Predictable Mode
//  Unit tests for CoachingTimingSettings, AutoDismissPreset, and CoachingDeliveryMode
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class CoachingTimingSettingsTests: XCTestCase {

    // MARK: - Properties

    var timingSettings: CoachingTimingSettings!
    var testDefaults: UserDefaults!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        let suiteName = "com.hcd.test.timing.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        timingSettings = CoachingTimingSettings(defaults: testDefaults)
    }

    override func tearDown() {
        let suiteName = testDefaults.volatileDomainNames.first
        if let name = suiteName {
            testDefaults.removePersistentDomain(forName: name)
        }
        timingSettings = nil
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestPrompt(
        type: CoachingFunctionType = .suggestFollowUp,
        text: String = "Test prompt text",
        confidence: Double = 0.90,
        timestamp: TimeInterval = 0.0
    ) -> CoachingPrompt {
        return CoachingPrompt(
            type: type,
            text: text,
            reason: "Test reason",
            confidence: confidence,
            timestamp: timestamp
        )
    }

    // MARK: - AutoDismissPreset Duration Tests

    func testAutoDismissPreset_quickDuration() {
        XCTAssertEqual(AutoDismissPreset.quick.duration, 5.0)
    }

    func testAutoDismissPreset_standardDuration() {
        XCTAssertEqual(AutoDismissPreset.standard.duration, 8.0)
    }

    func testAutoDismissPreset_relaxedDuration() {
        XCTAssertEqual(AutoDismissPreset.relaxed.duration, 15.0)
    }

    func testAutoDismissPreset_extendedDuration() {
        XCTAssertEqual(AutoDismissPreset.extended.duration, 30.0)
    }

    func testAutoDismissPreset_manualDurationIsNil() {
        XCTAssertNil(AutoDismissPreset.manual.duration)
    }

    func testAutoDismissPreset_allCasesCount() {
        XCTAssertEqual(AutoDismissPreset.allCases.count, 5)
    }

    func testAutoDismissPreset_displayNames() {
        XCTAssertEqual(AutoDismissPreset.quick.displayName, "Quick")
        XCTAssertEqual(AutoDismissPreset.standard.displayName, "Standard")
        XCTAssertEqual(AutoDismissPreset.relaxed.displayName, "Relaxed")
        XCTAssertEqual(AutoDismissPreset.extended.displayName, "Extended")
        XCTAssertEqual(AutoDismissPreset.manual.displayName, "Manual")
    }

    func testAutoDismissPreset_descriptionsNotEmpty() {
        for preset in AutoDismissPreset.allCases {
            XCTAssertFalse(preset.description.isEmpty, "Description should not be empty for \(preset.rawValue)")
        }
    }

    // MARK: - CoachingDeliveryMode Tests

    func testDeliveryMode_allCasesCount() {
        XCTAssertEqual(CoachingDeliveryMode.allCases.count, 3)
    }

    func testDeliveryMode_displayNames() {
        XCTAssertEqual(CoachingDeliveryMode.realtime.displayName, "Real-time")
        XCTAssertEqual(CoachingDeliveryMode.pull.displayName, "Pull")
        XCTAssertEqual(CoachingDeliveryMode.preview.displayName, "Preview")
    }

    func testDeliveryMode_iconsNotEmpty() {
        for mode in CoachingDeliveryMode.allCases {
            XCTAssertFalse(mode.icon.isEmpty, "Icon should not be empty for \(mode.rawValue)")
        }
    }

    func testDeliveryMode_descriptionsNotEmpty() {
        for mode in CoachingDeliveryMode.allCases {
            XCTAssertFalse(mode.description.isEmpty, "Description should not be empty for \(mode.rawValue)")
        }
    }

    // MARK: - Default Values Tests

    func testDefaultAutoDismissPreset() {
        XCTAssertEqual(timingSettings.autoDismissPreset, .standard)
    }

    func testDefaultDeliveryMode() {
        XCTAssertEqual(timingSettings.deliveryMode, .realtime)
    }

    func testDefaultPullQueueIsEmpty() {
        XCTAssertTrue(timingSettings.pullModeQueue.isEmpty)
        XCTAssertEqual(timingSettings.pullQueueCount, 0)
    }

    func testDefaultPreviewLogIsEmpty() {
        XCTAssertTrue(timingSettings.previewLog.isEmpty)
        XCTAssertEqual(timingSettings.previewLogCount, 0)
    }

    // MARK: - Effective Auto-Dismiss Duration Tests

    func testEffectiveAutoDismissDuration_standard() {
        timingSettings.autoDismissPreset = .standard
        XCTAssertEqual(timingSettings.effectiveAutoDismissDuration, 8.0)
    }

    func testEffectiveAutoDismissDuration_quick() {
        timingSettings.autoDismissPreset = .quick
        XCTAssertEqual(timingSettings.effectiveAutoDismissDuration, 5.0)
    }

    func testEffectiveAutoDismissDuration_relaxed() {
        timingSettings.autoDismissPreset = .relaxed
        XCTAssertEqual(timingSettings.effectiveAutoDismissDuration, 15.0)
    }

    func testEffectiveAutoDismissDuration_extended() {
        timingSettings.autoDismissPreset = .extended
        XCTAssertEqual(timingSettings.effectiveAutoDismissDuration, 30.0)
    }

    func testEffectiveAutoDismissDuration_manualIsNil() {
        timingSettings.autoDismissPreset = .manual
        XCTAssertNil(timingSettings.effectiveAutoDismissDuration)
    }

    // MARK: - Pull Queue Tests

    func testEnqueueForPull_addsPromptToQueue() {
        let prompt = createTestPrompt()
        timingSettings.enqueueForPull(prompt)

        XCTAssertEqual(timingSettings.pullQueueCount, 1)
        XCTAssertTrue(timingSettings.hasPendingPullPrompts)
    }

    func testEnqueueForPull_multiplePrompts() {
        let prompt1 = createTestPrompt(type: .suggestFollowUp, timestamp: 1.0)
        let prompt2 = createTestPrompt(type: .exploreDeeper, timestamp: 2.0)
        let prompt3 = createTestPrompt(type: .generalTip, timestamp: 3.0)

        timingSettings.enqueueForPull(prompt1)
        timingSettings.enqueueForPull(prompt2)
        timingSettings.enqueueForPull(prompt3)

        XCTAssertEqual(timingSettings.pullQueueCount, 3)
    }

    func testEnqueueForPull_sortsByPriority() {
        // generalTip has priority 6, uncoveredTopic has priority 1
        let lowPriority = createTestPrompt(type: .generalTip, timestamp: 1.0)
        let highPriority = createTestPrompt(type: .uncoveredTopic, timestamp: 2.0)

        timingSettings.enqueueForPull(lowPriority)
        timingSettings.enqueueForPull(highPriority)

        // After sorting, uncoveredTopic (priority 1) should be first
        XCTAssertEqual(timingSettings.pullModeQueue.first?.type, .uncoveredTopic)
        XCTAssertEqual(timingSettings.pullModeQueue.last?.type, .generalTip)
    }

    func testPullNextPrompt_returnsAndRemovesFirst() {
        let prompt1 = createTestPrompt(type: .suggestFollowUp, text: "First prompt", timestamp: 1.0)
        let prompt2 = createTestPrompt(type: .generalTip, text: "Second prompt", timestamp: 2.0)

        timingSettings.enqueueForPull(prompt1)
        timingSettings.enqueueForPull(prompt2)

        let pulled = timingSettings.pullNextPrompt()

        // suggestFollowUp has priority 2, generalTip has priority 6, so suggestFollowUp is first
        XCTAssertNotNil(pulled)
        XCTAssertEqual(pulled?.type, .suggestFollowUp)
        XCTAssertEqual(timingSettings.pullQueueCount, 1)
    }

    func testPullNextPrompt_emptyQueueReturnsNil() {
        let pulled = timingSettings.pullNextPrompt()
        XCTAssertNil(pulled)
    }

    func testPullNextPrompt_drainsQueue() {
        let prompt = createTestPrompt()
        timingSettings.enqueueForPull(prompt)

        let pulled = timingSettings.pullNextPrompt()
        XCTAssertNotNil(pulled)
        XCTAssertEqual(timingSettings.pullQueueCount, 0)
        XCTAssertFalse(timingSettings.hasPendingPullPrompts)

        let pulledAgain = timingSettings.pullNextPrompt()
        XCTAssertNil(pulledAgain)
    }

    func testClearPullQueue_removesAllPrompts() {
        timingSettings.enqueueForPull(createTestPrompt(timestamp: 1.0))
        timingSettings.enqueueForPull(createTestPrompt(timestamp: 2.0))
        timingSettings.enqueueForPull(createTestPrompt(timestamp: 3.0))
        XCTAssertEqual(timingSettings.pullQueueCount, 3)

        timingSettings.clearPullQueue()

        XCTAssertEqual(timingSettings.pullQueueCount, 0)
        XCTAssertTrue(timingSettings.pullModeQueue.isEmpty)
        XCTAssertFalse(timingSettings.hasPendingPullPrompts)
    }

    // MARK: - Preview Log Tests

    func testLogPreview_addsPromptToLog() {
        let prompt = createTestPrompt()
        timingSettings.logPreview(prompt)

        XCTAssertEqual(timingSettings.previewLogCount, 1)
        XCTAssertEqual(timingSettings.previewLog.first?.type, .suggestFollowUp)
    }

    func testLogPreview_multiplePrompts() {
        let prompt1 = createTestPrompt(type: .suggestFollowUp, timestamp: 1.0)
        let prompt2 = createTestPrompt(type: .exploreDeeper, timestamp: 2.0)

        timingSettings.logPreview(prompt1)
        timingSettings.logPreview(prompt2)

        XCTAssertEqual(timingSettings.previewLogCount, 2)
    }

    func testLogPreview_preservesInsertionOrder() {
        let prompt1 = createTestPrompt(type: .suggestFollowUp, timestamp: 1.0)
        let prompt2 = createTestPrompt(type: .generalTip, timestamp: 2.0)
        let prompt3 = createTestPrompt(type: .uncoveredTopic, timestamp: 3.0)

        timingSettings.logPreview(prompt1)
        timingSettings.logPreview(prompt2)
        timingSettings.logPreview(prompt3)

        // Preview log preserves insertion order (not sorted by priority)
        XCTAssertEqual(timingSettings.previewLog[0].type, .suggestFollowUp)
        XCTAssertEqual(timingSettings.previewLog[1].type, .generalTip)
        XCTAssertEqual(timingSettings.previewLog[2].type, .uncoveredTopic)
    }

    func testClearPreviewLog_removesAllEntries() {
        timingSettings.logPreview(createTestPrompt(timestamp: 1.0))
        timingSettings.logPreview(createTestPrompt(timestamp: 2.0))
        XCTAssertEqual(timingSettings.previewLogCount, 2)

        timingSettings.clearPreviewLog()

        XCTAssertEqual(timingSettings.previewLogCount, 0)
        XCTAssertTrue(timingSettings.previewLog.isEmpty)
    }

    // MARK: - UserDefaults Persistence Tests

    func testPersistence_autoDismissPreset() {
        timingSettings.autoDismissPreset = .extended

        // Create a new instance with the same defaults
        let restored = CoachingTimingSettings(defaults: testDefaults)
        XCTAssertEqual(restored.autoDismissPreset, .extended)
    }

    func testPersistence_deliveryMode() {
        timingSettings.deliveryMode = .pull

        let restored = CoachingTimingSettings(defaults: testDefaults)
        XCTAssertEqual(restored.deliveryMode, .pull)
    }

    func testPersistence_previewMode() {
        timingSettings.deliveryMode = .preview

        let restored = CoachingTimingSettings(defaults: testDefaults)
        XCTAssertEqual(restored.deliveryMode, .preview)
    }

    func testPersistence_manualPreset() {
        timingSettings.autoDismissPreset = .manual

        let restored = CoachingTimingSettings(defaults: testDefaults)
        XCTAssertEqual(restored.autoDismissPreset, .manual)
        XCTAssertNil(restored.effectiveAutoDismissDuration)
    }

    // MARK: - Reset Tests

    func testResetToDefaults_restoresAllSettings() {
        // Change everything
        timingSettings.autoDismissPreset = .extended
        timingSettings.deliveryMode = .pull
        timingSettings.enqueueForPull(createTestPrompt())
        timingSettings.logPreview(createTestPrompt(timestamp: 1.0))

        // Reset
        timingSettings.resetToDefaults()

        // Verify defaults restored
        XCTAssertEqual(timingSettings.autoDismissPreset, .standard)
        XCTAssertEqual(timingSettings.deliveryMode, .realtime)
        XCTAssertTrue(timingSettings.pullModeQueue.isEmpty)
        XCTAssertTrue(timingSettings.previewLog.isEmpty)
    }

    // MARK: - Codable Tests

    func testAutoDismissPreset_rawValues() {
        XCTAssertEqual(AutoDismissPreset.quick.rawValue, "quick")
        XCTAssertEqual(AutoDismissPreset.standard.rawValue, "standard")
        XCTAssertEqual(AutoDismissPreset.relaxed.rawValue, "relaxed")
        XCTAssertEqual(AutoDismissPreset.extended.rawValue, "extended")
        XCTAssertEqual(AutoDismissPreset.manual.rawValue, "manual")
    }

    func testDeliveryMode_rawValues() {
        XCTAssertEqual(CoachingDeliveryMode.realtime.rawValue, "realtime")
        XCTAssertEqual(CoachingDeliveryMode.pull.rawValue, "pull")
        XCTAssertEqual(CoachingDeliveryMode.preview.rawValue, "preview")
    }

    func testAutoDismissPreset_initFromRawValue() {
        XCTAssertEqual(AutoDismissPreset(rawValue: "quick"), .quick)
        XCTAssertEqual(AutoDismissPreset(rawValue: "standard"), .standard)
        XCTAssertEqual(AutoDismissPreset(rawValue: "relaxed"), .relaxed)
        XCTAssertEqual(AutoDismissPreset(rawValue: "extended"), .extended)
        XCTAssertEqual(AutoDismissPreset(rawValue: "manual"), .manual)
        XCTAssertNil(AutoDismissPreset(rawValue: "invalid"))
    }

    func testDeliveryMode_initFromRawValue() {
        XCTAssertEqual(CoachingDeliveryMode(rawValue: "realtime"), .realtime)
        XCTAssertEqual(CoachingDeliveryMode(rawValue: "pull"), .pull)
        XCTAssertEqual(CoachingDeliveryMode(rawValue: "preview"), .preview)
        XCTAssertNil(CoachingDeliveryMode(rawValue: "invalid"))
    }
}
