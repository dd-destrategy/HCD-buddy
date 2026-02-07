//
//  FocusModeManagerTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for FocusModeManager focus mode switching and persistence
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class FocusModeManagerTests: XCTestCase {

    var manager: FocusModeManager!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Use an ephemeral UserDefaults suite to isolate test state
        let suiteName = "com.hcdinterviewcoach.tests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        manager = FocusModeManager(defaults: testDefaults)
    }

    override func tearDown() {
        // Clean up the test defaults suite
        if let suiteName = testDefaults.volatileDomainNames.first {
            testDefaults.removePersistentDomain(forName: suiteName)
        }
        testDefaults.removePersistentDomain(
            forName: "com.hcdinterviewcoach.tests"
        )
        manager = nil
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Test: Default Mode

    func testDefaultMode_isAnalysis() {
        // Given: A fresh manager with no persisted state
        // (testDefaults has no saved mode)

        // Then: Default mode should be .analysis
        XCTAssertEqual(manager.currentMode, .analysis)
    }

    func testDefaultMode_allPanelsVisible() {
        // Given: Default .analysis mode

        // Then: All panels should be visible
        XCTAssertTrue(manager.panelVisibility.showTranscript)
        XCTAssertTrue(manager.panelVisibility.showTopics)
        XCTAssertTrue(manager.panelVisibility.showInsights)
        XCTAssertTrue(manager.panelVisibility.showCoaching)
        XCTAssertTrue(manager.panelVisibility.showTalkTime)
    }

    // MARK: - Test: Each Mode Sets Correct Panel Visibility

    func testInterviewMode_transcriptOnly() {
        // When: Switch to interview mode
        manager.setMode(.interview)

        // Then: Only transcript should be visible
        XCTAssertEqual(manager.currentMode, .interview)
        XCTAssertTrue(manager.panelVisibility.showTranscript)
        XCTAssertFalse(manager.panelVisibility.showTopics)
        XCTAssertFalse(manager.panelVisibility.showInsights)
        XCTAssertFalse(manager.panelVisibility.showCoaching)
        XCTAssertFalse(manager.panelVisibility.showTalkTime)
    }

    func testCoachedMode_transcriptCoachingTalkTime() {
        // When: Switch to coached mode
        manager.setMode(.coached)

        // Then: Transcript, coaching, and talk-time should be visible
        XCTAssertEqual(manager.currentMode, .coached)
        XCTAssertTrue(manager.panelVisibility.showTranscript)
        XCTAssertFalse(manager.panelVisibility.showTopics)
        XCTAssertFalse(manager.panelVisibility.showInsights)
        XCTAssertTrue(manager.panelVisibility.showCoaching)
        XCTAssertTrue(manager.panelVisibility.showTalkTime)
    }

    func testAnalysisMode_allPanelsVisible() {
        // Given: Start in a different mode
        manager.setMode(.interview)
        XCTAssertEqual(manager.currentMode, .interview)

        // When: Switch to analysis mode
        manager.setMode(.analysis)

        // Then: All panels should be visible
        XCTAssertEqual(manager.currentMode, .analysis)
        XCTAssertTrue(manager.panelVisibility.showTranscript)
        XCTAssertTrue(manager.panelVisibility.showTopics)
        XCTAssertTrue(manager.panelVisibility.showInsights)
        XCTAssertTrue(manager.panelVisibility.showCoaching)
        XCTAssertTrue(manager.panelVisibility.showTalkTime)
    }

    func testCustomMode_defaultsToAllVisible() {
        // When: Switch to custom mode (with no prior custom config)
        manager.setMode(.custom)

        // Then: Default custom should have all panels visible
        XCTAssertEqual(manager.currentMode, .custom)
        XCTAssertTrue(manager.panelVisibility.showTranscript)
        XCTAssertTrue(manager.panelVisibility.showTopics)
        XCTAssertTrue(manager.panelVisibility.showInsights)
        XCTAssertTrue(manager.panelVisibility.showCoaching)
        XCTAssertTrue(manager.panelVisibility.showTalkTime)
    }

    // MARK: - Test: Toggle Panel Switches to Custom Mode

    func testTogglePanel_switchesToCustomMode() {
        // Given: In analysis mode (not custom)
        XCTAssertEqual(manager.currentMode, .analysis)

        // When: Toggle a panel
        manager.togglePanel(.topics)

        // Then: Should switch to custom mode
        XCTAssertEqual(manager.currentMode, .custom)
    }

    func testTogglePanel_togglesVisibility() {
        // Given: In analysis mode with all panels visible
        XCTAssertTrue(manager.panelVisibility.showTopics)

        // When: Toggle topics off
        manager.togglePanel(.topics)

        // Then: Topics should be hidden
        XCTAssertFalse(manager.panelVisibility.showTopics)
        // Other panels should remain visible
        XCTAssertTrue(manager.panelVisibility.showTranscript)
        XCTAssertTrue(manager.panelVisibility.showInsights)
        XCTAssertTrue(manager.panelVisibility.showCoaching)
        XCTAssertTrue(manager.panelVisibility.showTalkTime)
    }

    func testTogglePanel_doubleToggle_restoresState() {
        // Given: Analysis mode
        manager.togglePanel(.insights)  // Now custom mode, insights off
        XCTAssertFalse(manager.panelVisibility.showInsights)

        // When: Toggle again
        manager.togglePanel(.insights)

        // Then: Insights should be visible again
        XCTAssertTrue(manager.panelVisibility.showInsights)
    }

    func testTogglePanel_inCustomMode_staysCustom() {
        // Given: Already in custom mode
        manager.setMode(.custom)
        XCTAssertEqual(manager.currentMode, .custom)

        // When: Toggle a panel
        manager.togglePanel(.coaching)

        // Then: Should remain in custom mode
        XCTAssertEqual(manager.currentMode, .custom)
        XCTAssertFalse(manager.panelVisibility.showCoaching)
    }

    // MARK: - Test: Mode Persistence

    func testModePersists_toUserDefaults() {
        // When: Set mode to interview
        manager.setMode(.interview)

        // Then: UserDefaults should contain the mode
        let savedMode = testDefaults.string(forKey: FocusModeManager.modeDefaultsKey)
        XCTAssertEqual(savedMode, FocusMode.interview.rawValue)
    }

    func testModeRestored_fromUserDefaults() {
        // Given: Save a mode to defaults
        testDefaults.set(FocusMode.coached.rawValue, forKey: FocusModeManager.modeDefaultsKey)

        // When: Create a new manager
        let restoredManager = FocusModeManager(defaults: testDefaults)

        // Then: Mode should be restored
        XCTAssertEqual(restoredManager.currentMode, .coached)
        // Panel visibility should match coached defaults
        XCTAssertTrue(restoredManager.panelVisibility.showTranscript)
        XCTAssertTrue(restoredManager.panelVisibility.showCoaching)
        XCTAssertTrue(restoredManager.panelVisibility.showTalkTime)
        XCTAssertFalse(restoredManager.panelVisibility.showTopics)
        XCTAssertFalse(restoredManager.panelVisibility.showInsights)
    }

    func testInvalidPersistedMode_fallsBackToAnalysis() {
        // Given: Invalid mode string in defaults
        testDefaults.set("nonexistent_mode", forKey: FocusModeManager.modeDefaultsKey)

        // When: Create a new manager
        let restoredManager = FocusModeManager(defaults: testDefaults)

        // Then: Should fall back to .analysis
        XCTAssertEqual(restoredManager.currentMode, .analysis)
    }

    func testCustomVisibilityPersists() {
        // Given: Custom mode with a specific panel configuration
        manager.setMode(.custom)
        manager.togglePanel(.topics)     // topics off
        manager.togglePanel(.insights)   // insights off

        // Verify current state
        XCTAssertFalse(manager.panelVisibility.showTopics)
        XCTAssertFalse(manager.panelVisibility.showInsights)
        XCTAssertTrue(manager.panelVisibility.showTranscript)

        // When: Create a new manager from the same defaults
        let restoredManager = FocusModeManager(defaults: testDefaults)

        // Then: Custom visibility should be restored
        XCTAssertEqual(restoredManager.currentMode, .custom)
        XCTAssertFalse(restoredManager.panelVisibility.showTopics)
        XCTAssertFalse(restoredManager.panelVisibility.showInsights)
        XCTAssertTrue(restoredManager.panelVisibility.showTranscript)
        XCTAssertTrue(restoredManager.panelVisibility.showCoaching)
        XCTAssertTrue(restoredManager.panelVisibility.showTalkTime)
    }

    // MARK: - Test: setMode Does Not Change When Already Active

    func testSetMode_sameMode_noChange() {
        // Given: In analysis mode
        let initialVisibility = manager.panelVisibility

        // When: Set the same mode again
        manager.setMode(.analysis)

        // Then: Visibility should not change, mode stays the same
        XCTAssertEqual(manager.currentMode, .analysis)
        XCTAssertEqual(manager.panelVisibility, initialVisibility)
    }

    // MARK: - Test: isPanelVisible

    func testIsPanelVisible_reflectsVisibility() {
        // Given: Analysis mode (all visible)
        XCTAssertTrue(manager.isPanelVisible(.transcript))
        XCTAssertTrue(manager.isPanelVisible(.topics))
        XCTAssertTrue(manager.isPanelVisible(.insights))
        XCTAssertTrue(manager.isPanelVisible(.coaching))
        XCTAssertTrue(manager.isPanelVisible(.talkTime))

        // When: Switch to interview mode
        manager.setMode(.interview)

        // Then: Only transcript should be visible
        XCTAssertTrue(manager.isPanelVisible(.transcript))
        XCTAssertFalse(manager.isPanelVisible(.topics))
        XCTAssertFalse(manager.isPanelVisible(.insights))
        XCTAssertFalse(manager.isPanelVisible(.coaching))
        XCTAssertFalse(manager.isPanelVisible(.talkTime))
    }

    // MARK: - Test: setPanel

    func testSetPanel_setsVisibility() {
        // Given: Analysis mode with all visible
        XCTAssertTrue(manager.isPanelVisible(.topics))

        // When: Set topics to hidden
        manager.setPanel(.topics, visible: false)

        // Then: Topics should be hidden, mode should be custom
        XCTAssertFalse(manager.isPanelVisible(.topics))
        XCTAssertEqual(manager.currentMode, .custom)
    }

    func testSetPanel_noOpWhenAlreadySet() {
        // Given: Analysis mode with all visible
        let initialMode = manager.currentMode

        // When: Set transcript to visible (already visible)
        manager.setPanel(.transcript, visible: true)

        // Then: Mode should not change (no-op)
        XCTAssertEqual(manager.currentMode, initialMode)
    }

    // MARK: - Test: PanelVisibility

    func testPanelVisibility_visibleCount() {
        let allVisible = PanelVisibility(
            showTranscript: true,
            showTopics: true,
            showInsights: true,
            showCoaching: true,
            showTalkTime: true
        )
        XCTAssertEqual(allVisible.visibleCount, 5)

        let noneVisible = PanelVisibility(
            showTranscript: false,
            showTopics: false,
            showInsights: false,
            showCoaching: false,
            showTalkTime: false
        )
        XCTAssertEqual(noneVisible.visibleCount, 0)

        let someVisible = PanelVisibility(
            showTranscript: true,
            showTopics: false,
            showInsights: true,
            showCoaching: false,
            showTalkTime: true
        )
        XCTAssertEqual(someVisible.visibleCount, 3)
    }

    func testPanelVisibility_toggling() {
        let visibility = PanelVisibility(
            showTranscript: true,
            showTopics: true,
            showInsights: true,
            showCoaching: true,
            showTalkTime: true
        )

        let toggled = visibility.toggling(.topics)
        XCTAssertFalse(toggled.showTopics)
        XCTAssertTrue(toggled.showTranscript)

        let toggledBack = toggled.toggling(.topics)
        XCTAssertTrue(toggledBack.showTopics)
    }

    // MARK: - Test: FocusMode Properties

    func testFocusMode_allCasesCount() {
        XCTAssertEqual(FocusMode.allCases.count, 4)
    }

    func testFocusMode_displayNames() {
        XCTAssertEqual(FocusMode.interview.displayName, "Interview")
        XCTAssertEqual(FocusMode.coached.displayName, "Coached")
        XCTAssertEqual(FocusMode.analysis.displayName, "Analysis")
        XCTAssertEqual(FocusMode.custom.displayName, "Custom")
    }

    func testFocusMode_descriptions() {
        XCTAssertFalse(FocusMode.interview.description.isEmpty)
        XCTAssertFalse(FocusMode.coached.description.isEmpty)
        XCTAssertFalse(FocusMode.analysis.description.isEmpty)
        XCTAssertFalse(FocusMode.custom.description.isEmpty)
    }

    func testFocusMode_keyEquivalents() {
        // Interview, coached, and analysis have key equivalents
        XCTAssertNotNil(FocusMode.interview.keyEquivalent)
        XCTAssertNotNil(FocusMode.coached.keyEquivalent)
        XCTAssertNotNil(FocusMode.analysis.keyEquivalent)
        // Custom does not have a key equivalent
        XCTAssertNil(FocusMode.custom.keyEquivalent)
    }

    // MARK: - Test: Panel Properties

    func testPanel_allCasesCount() {
        XCTAssertEqual(Panel.allCases.count, 5)
    }

    func testPanel_displayNames() {
        XCTAssertEqual(Panel.transcript.displayName, "Transcript")
        XCTAssertEqual(Panel.topics.displayName, "Topics")
        XCTAssertEqual(Panel.insights.displayName, "Insights")
        XCTAssertEqual(Panel.coaching.displayName, "Coaching")
        XCTAssertEqual(Panel.talkTime.displayName, "Talk Time")
    }

    func testPanel_icons() {
        // Each panel should have a non-empty icon
        for panel in Panel.allCases {
            XCTAssertFalse(panel.icon.isEmpty, "\(panel.displayName) should have an icon")
        }
    }

    // MARK: - Test: Transition State

    func testIsTransitioning_startsAsFalse() {
        XCTAssertFalse(manager.isTransitioning)
    }
}
