//
//  CulturalContextTests.swift
//  HCD Interview Coach Tests
//
//  Unit tests for CulturalContext, CulturalPreset, FormalityLevel,
//  and CulturalContextManager
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class CulturalContextTests: XCTestCase {

    // MARK: - Properties

    private var tempFileURL: URL!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_cultural_context_\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFileURL)
        tempFileURL = nil
        super.tearDown()
    }

    // MARK: - CulturalPreset: Display Names

    func testCulturalPreset_allCasesHaveDisplayNames() {
        for preset in CulturalPreset.allCases {
            XCTAssertFalse(preset.displayName.isEmpty, "\(preset.rawValue) should have a display name")
        }
    }

    func testCulturalPreset_westernDisplayName() {
        XCTAssertEqual(CulturalPreset.western.displayName, "Western")
    }

    func testCulturalPreset_eastAsianDisplayName() {
        XCTAssertEqual(CulturalPreset.eastAsian.displayName, "East Asian")
    }

    func testCulturalPreset_latinAmericanDisplayName() {
        XCTAssertEqual(CulturalPreset.latinAmerican.displayName, "Latin American")
    }

    func testCulturalPreset_middleEasternDisplayName() {
        XCTAssertEqual(CulturalPreset.middleEastern.displayName, "Middle Eastern")
    }

    func testCulturalPreset_customDisplayName() {
        XCTAssertEqual(CulturalPreset.custom.displayName, "Custom")
    }

    // MARK: - CulturalPreset: Descriptions and Icons

    func testCulturalPreset_allCasesHaveDescriptions() {
        for preset in CulturalPreset.allCases {
            XCTAssertFalse(preset.description.isEmpty, "\(preset.rawValue) should have a description")
        }
    }

    func testCulturalPreset_allCasesHaveIcons() {
        for preset in CulturalPreset.allCases {
            XCTAssertFalse(preset.icon.isEmpty, "\(preset.rawValue) should have an icon")
        }
    }

    // MARK: - CulturalContext: Preset Factory

    func testCulturalContext_westernPreset() {
        let context = CulturalContext.preset(.western)

        XCTAssertEqual(context.preset, .western)
        XCTAssertEqual(context.silenceToleranceSeconds, 5.0)
        XCTAssertEqual(context.questionPacingMultiplier, 1.0)
        XCTAssertEqual(context.interruptionSensitivity, 0.5)
        XCTAssertEqual(context.formalityLevel, .casual)
        XCTAssertTrue(context.showCoachingExplanations)
        XCTAssertTrue(context.enableBiasAlerts)
    }

    func testCulturalContext_eastAsianPreset() {
        let context = CulturalContext.preset(.eastAsian)

        XCTAssertEqual(context.preset, .eastAsian)
        XCTAssertEqual(context.silenceToleranceSeconds, 12.0)
        XCTAssertEqual(context.questionPacingMultiplier, 1.5)
        XCTAssertEqual(context.interruptionSensitivity, 0.8)
        XCTAssertEqual(context.formalityLevel, .formal)
    }

    func testCulturalContext_latinAmericanPreset() {
        let context = CulturalContext.preset(.latinAmerican)

        XCTAssertEqual(context.preset, .latinAmerican)
        XCTAssertEqual(context.silenceToleranceSeconds, 4.0)
        XCTAssertEqual(context.questionPacingMultiplier, 0.8)
        XCTAssertEqual(context.interruptionSensitivity, 0.3)
        XCTAssertEqual(context.formalityLevel, .casual)
    }

    func testCulturalContext_middleEasternPreset() {
        let context = CulturalContext.preset(.middleEastern)

        XCTAssertEqual(context.preset, .middleEastern)
        XCTAssertEqual(context.silenceToleranceSeconds, 8.0)
        XCTAssertEqual(context.questionPacingMultiplier, 1.3)
        XCTAssertEqual(context.interruptionSensitivity, 0.7)
        XCTAssertEqual(context.formalityLevel, .formal)
    }

    func testCulturalContext_customPresetUsesWesternDefaults() {
        let context = CulturalContext.preset(.custom)

        XCTAssertEqual(context.preset, .custom)
        XCTAssertEqual(context.silenceToleranceSeconds, 5.0)
        XCTAssertEqual(context.questionPacingMultiplier, 1.0)
        XCTAssertEqual(context.interruptionSensitivity, 0.5)
        XCTAssertEqual(context.formalityLevel, .casual)
    }

    // MARK: - CulturalContext: Default

    func testCulturalContext_defaultIsWestern() {
        let context = CulturalContext.default

        XCTAssertEqual(context.preset, .western)
        XCTAssertEqual(context.silenceToleranceSeconds, 5.0)
        XCTAssertEqual(context.questionPacingMultiplier, 1.0)
    }

    // MARK: - CulturalContext: Equatable

    func testCulturalContext_equatable() {
        let a = CulturalContext.preset(.western)
        let b = CulturalContext.preset(.western)
        let c = CulturalContext.preset(.eastAsian)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - FormalityLevel

    func testFormalityLevel_allCasesHaveDisplayNames() {
        for level in FormalityLevel.allCases {
            XCTAssertFalse(level.displayName.isEmpty, "\(level.rawValue) should have a display name")
        }
    }

    func testFormalityLevel_displayNames() {
        XCTAssertEqual(FormalityLevel.casual.displayName, "Casual")
        XCTAssertEqual(FormalityLevel.neutral.displayName, "Neutral")
        XCTAssertEqual(FormalityLevel.formal.displayName, "Formal")
    }

    // MARK: - CulturalContextManager: Update Preset

    func testManager_updatePreset_changesContext() {
        let manager = CulturalContextManager(storageURL: tempFileURL)

        manager.updatePreset(.eastAsian)

        XCTAssertEqual(manager.context.preset, .eastAsian)
        XCTAssertEqual(manager.context.silenceToleranceSeconds, 12.0)
        XCTAssertEqual(manager.context.questionPacingMultiplier, 1.5)
    }

    func testManager_updatePreset_persistsToDisk() {
        // Given: Save a preset
        let manager1 = CulturalContextManager(storageURL: tempFileURL)
        manager1.updatePreset(.latinAmerican)

        // When: Create a new manager pointing to same file
        let manager2 = CulturalContextManager(storageURL: tempFileURL)

        // Then: Should load the persisted preset
        XCTAssertEqual(manager2.context.preset, .latinAmerican)
        XCTAssertEqual(manager2.context.silenceToleranceSeconds, 4.0)
    }

    // MARK: - CulturalContextManager: Update Context

    func testManager_updateContext_appliesCustomValues() {
        let manager = CulturalContextManager(storageURL: tempFileURL)

        var customContext = CulturalContext.preset(.custom)
        customContext.silenceToleranceSeconds = 15.0
        customContext.questionPacingMultiplier = 1.8
        customContext.interruptionSensitivity = 0.9
        customContext.formalityLevel = .formal

        manager.updateContext(customContext)

        XCTAssertEqual(manager.context.preset, .custom)
        XCTAssertEqual(manager.context.silenceToleranceSeconds, 15.0)
        XCTAssertEqual(manager.context.questionPacingMultiplier, 1.8)
        XCTAssertEqual(manager.context.interruptionSensitivity, 0.9)
        XCTAssertEqual(manager.context.formalityLevel, .formal)
    }

    func testManager_updateContext_persistsCustomValues() {
        let manager1 = CulturalContextManager(storageURL: tempFileURL)

        var customContext = CulturalContext.preset(.custom)
        customContext.silenceToleranceSeconds = 18.0
        manager1.updateContext(customContext)

        let manager2 = CulturalContextManager(storageURL: tempFileURL)

        XCTAssertEqual(manager2.context.silenceToleranceSeconds, 18.0)
    }

    // MARK: - CulturalContextManager: Adjusted Thresholds

    func testManager_adjustedThresholds_westernIsBaseline() {
        let manager = CulturalContextManager(storageURL: tempFileURL)
        manager.updatePreset(.western)

        let base = CoachingThresholds.default
        let adjusted = manager.adjustedThresholds(base: base)

        // Western: silence=5s (5/5=1.0x), pacing=1.0x
        XCTAssertEqual(adjusted.speechCooldown, base.speechCooldown, accuracy: 0.01)
        XCTAssertEqual(adjusted.cooldownDuration, base.cooldownDuration, accuracy: 0.01)
    }

    func testManager_adjustedThresholds_eastAsianSlowsDown() {
        let manager = CulturalContextManager(storageURL: tempFileURL)
        manager.updatePreset(.eastAsian)

        let base = CoachingThresholds.default
        let adjusted = manager.adjustedThresholds(base: base)

        // East Asian: silence=12s (12/5=2.4x), pacing=1.5x
        let expectedSpeechCooldown = base.speechCooldown * (12.0 / 5.0)
        let expectedCooldown = base.cooldownDuration * 1.5

        XCTAssertEqual(adjusted.speechCooldown, expectedSpeechCooldown, accuracy: 0.01)
        XCTAssertEqual(adjusted.cooldownDuration, expectedCooldown, accuracy: 0.01)
    }

    func testManager_adjustedThresholds_latinAmericanSpeedsUp() {
        let manager = CulturalContextManager(storageURL: tempFileURL)
        manager.updatePreset(.latinAmerican)

        let base = CoachingThresholds.default
        let adjusted = manager.adjustedThresholds(base: base)

        // Latin American: silence=4s (4/5=0.8x), pacing=0.8x
        let expectedSpeechCooldown = base.speechCooldown * (4.0 / 5.0)
        let expectedCooldown = base.cooldownDuration * 0.8

        XCTAssertEqual(adjusted.speechCooldown, expectedSpeechCooldown, accuracy: 0.01)
        XCTAssertEqual(adjusted.cooldownDuration, expectedCooldown, accuracy: 0.01)
    }

    func testManager_adjustedThresholds_middleEasternModerate() {
        let manager = CulturalContextManager(storageURL: tempFileURL)
        manager.updatePreset(.middleEastern)

        let base = CoachingThresholds.default
        let adjusted = manager.adjustedThresholds(base: base)

        // Middle Eastern: silence=8s (8/5=1.6x), pacing=1.3x
        let expectedSpeechCooldown = base.speechCooldown * (8.0 / 5.0)
        let expectedCooldown = base.cooldownDuration * 1.3

        XCTAssertEqual(adjusted.speechCooldown, expectedSpeechCooldown, accuracy: 0.01)
        XCTAssertEqual(adjusted.cooldownDuration, expectedCooldown, accuracy: 0.01)
    }

    func testManager_adjustedThresholds_preservesOtherValues() {
        let manager = CulturalContextManager(storageURL: tempFileURL)
        manager.updatePreset(.eastAsian)

        let base = CoachingThresholds.default
        let adjusted = manager.adjustedThresholds(base: base)

        // Non-cultural fields should remain unchanged
        XCTAssertEqual(adjusted.minimumConfidence, base.minimumConfidence)
        XCTAssertEqual(adjusted.maxPromptsPerSession, base.maxPromptsPerSession)
        XCTAssertEqual(adjusted.autoDismissDuration, base.autoDismissDuration)
        XCTAssertEqual(adjusted.fadeInDuration, base.fadeInDuration)
        XCTAssertEqual(adjusted.fadeOutDuration, base.fadeOutDuration)
        XCTAssertEqual(adjusted.sensitivityMultiplier, base.sensitivityMultiplier)
    }

    // MARK: - CulturalContextManager: Default State

    func testManager_defaultState_isWestern() {
        let manager = CulturalContextManager(storageURL: tempFileURL)

        XCTAssertEqual(manager.context.preset, .western)
        XCTAssertEqual(manager.context.silenceToleranceSeconds, 5.0)
    }

    func testManager_loadsDefaultWhenFileDoesNotExist() {
        let nonExistentURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("nonexistent_\(UUID().uuidString).json")

        let manager = CulturalContextManager(storageURL: nonExistentURL)

        XCTAssertEqual(manager.context, CulturalContext.default)
    }
}
