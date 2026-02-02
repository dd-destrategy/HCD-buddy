//
//  FocusManagerTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for FocusManager accessibility focus management
//

import XCTest
import SwiftUI
@testable import HCDInterviewCoach

@MainActor
final class FocusManagerTests: XCTestCase {

    var focusManager: FocusManager!

    override func setUp() {
        super.setUp()
        focusManager = FocusManager()
    }

    override func tearDown() {
        focusManager = nil
        super.tearDown()
    }

    // MARK: - Test: Initial Focus Area

    func testInitialFocusArea() {
        // Given: A newly created FocusManager

        // Then: Default focus should be on controls
        XCTAssertEqual(focusManager.currentFocus, .controls)
    }

    func testInitialPreviousFocus_isNil() {
        // Given: A newly created FocusManager

        // Then: Previous focus should be nil
        XCTAssertNil(focusManager.previousFocus)
    }

    func testInitialFocusCycling_isEnabled() {
        // Given: A newly created FocusManager

        // Then: Focus cycling should be enabled by default
        XCTAssertTrue(focusManager.enableFocusCycling)
    }

    // MARK: - Test: Set Focus Area

    func testSetFocusArea_transcript() {
        // Given: Focus manager with default focus

        // When: Move focus to transcript
        focusManager.moveFocus(to: .transcript)

        // Then: Current focus should be transcript
        XCTAssertEqual(focusManager.currentFocus, .transcript)
    }

    func testSetFocusArea_topics() {
        // When: Move focus to topics
        focusManager.moveFocus(to: .topics)

        // Then: Current focus should be topics
        XCTAssertEqual(focusManager.currentFocus, .topics)
    }

    func testSetFocusArea_insights() {
        // When: Move focus to insights
        focusManager.moveFocus(to: .insights)

        // Then: Current focus should be insights
        XCTAssertEqual(focusManager.currentFocus, .insights)
    }

    func testSetFocusArea_controls() {
        // When: Move focus away and back to controls
        focusManager.moveFocus(to: .transcript)
        focusManager.moveFocus(to: .controls)

        // Then: Current focus should be controls
        XCTAssertEqual(focusManager.currentFocus, .controls)
    }

    func testSetFocusArea_search() {
        // When: Move focus to search
        focusManager.moveFocus(to: .search)

        // Then: Current focus should be search
        XCTAssertEqual(focusManager.currentFocus, .search)
    }

    func testSetFocusArea_settings() {
        // When: Move focus to settings
        focusManager.moveFocus(to: .settings)

        // Then: Current focus should be settings
        XCTAssertEqual(focusManager.currentFocus, .settings)
    }

    func testSetFocusArea_coachingPrompt() {
        // When: Move focus to coaching prompt
        focusManager.moveFocus(to: .coachingPrompt)

        // Then: Current focus should be coaching prompt
        XCTAssertEqual(focusManager.currentFocus, .coachingPrompt)
    }

    func testSetFocusArea_updatesPreviousFocus() {
        // Given: Initial focus is controls
        XCTAssertEqual(focusManager.currentFocus, .controls)

        // When: Move focus to transcript
        focusManager.moveFocus(to: .transcript)

        // Then: Previous focus should be controls
        XCTAssertEqual(focusManager.previousFocus, .controls)
    }

    func testSetFocusArea_chainedMoves() {
        // When: Chain multiple focus moves
        focusManager.moveFocus(to: .transcript)
        focusManager.moveFocus(to: .topics)
        focusManager.moveFocus(to: .insights)

        // Then: Current should be insights, previous should be topics
        XCTAssertEqual(focusManager.currentFocus, .insights)
        XCTAssertEqual(focusManager.previousFocus, .topics)
    }

    // MARK: - Test: Focus Next

    func testFocusNext() {
        // Given: Focus is on controls (index 3)
        XCTAssertEqual(focusManager.currentFocus, .controls)

        // When: Focus next
        focusManager.focusNext()

        // Then: Focus should move to the next area
        XCTAssertEqual(focusManager.currentFocus, .search)
    }

    func testFocusNext_fromFirstArea() {
        // Given: Focus is on transcript (first area)
        focusManager.moveFocus(to: .transcript)

        // When: Focus next
        focusManager.focusNext()

        // Then: Focus should move to topics
        XCTAssertEqual(focusManager.currentFocus, .topics)
    }

    func testFocusNext_multipleTimes() {
        // Given: Focus starts at controls
        focusManager.moveFocus(to: .transcript)

        // When: Navigate forward multiple times
        focusManager.focusNext() // topics
        focusManager.focusNext() // insights
        focusManager.focusNext() // controls

        // Then: Should be at controls
        XCTAssertEqual(focusManager.currentFocus, .controls)
    }

    func testFocusNext_whenCyclingDisabled() {
        // Given: Focus cycling is disabled
        focusManager.enableFocusCycling = false
        let initialFocus = focusManager.currentFocus

        // When: Focus next
        focusManager.focusNext()

        // Then: Focus should not change
        XCTAssertEqual(focusManager.currentFocus, initialFocus)
    }

    // MARK: - Test: Focus Previous

    func testFocusPrevious() {
        // Given: Focus is on controls
        XCTAssertEqual(focusManager.currentFocus, .controls)

        // When: Focus previous
        focusManager.focusPrevious()

        // Then: Focus should move to insights
        XCTAssertEqual(focusManager.currentFocus, .insights)
    }

    func testFocusPrevious_fromFirstArea() {
        // Given: Focus is on transcript (first area)
        focusManager.moveFocus(to: .transcript)

        // When: Focus previous
        focusManager.focusPrevious()

        // Then: Focus should wrap to the last area (coaching prompt)
        XCTAssertEqual(focusManager.currentFocus, .coachingPrompt)
    }

    func testFocusPrevious_multipleTimes() {
        // Given: Focus starts at controls
        focusManager.moveFocus(to: .controls)

        // When: Navigate backward multiple times
        focusManager.focusPrevious() // insights
        focusManager.focusPrevious() // topics
        focusManager.focusPrevious() // transcript

        // Then: Should be at transcript
        XCTAssertEqual(focusManager.currentFocus, .transcript)
    }

    func testFocusPrevious_whenCyclingDisabled() {
        // Given: Focus cycling is disabled
        focusManager.enableFocusCycling = false
        let initialFocus = focusManager.currentFocus

        // When: Focus previous
        focusManager.focusPrevious()

        // Then: Focus should not change
        XCTAssertEqual(focusManager.currentFocus, initialFocus)
    }

    // MARK: - Test: Focus Cycling

    func testFocusCycling_wrapsAtEnd() {
        // Given: Focus is on the last area
        focusManager.moveFocus(to: .coachingPrompt)

        // When: Focus next
        focusManager.focusNext()

        // Then: Should wrap to transcript (first area)
        XCTAssertEqual(focusManager.currentFocus, .transcript)
    }

    func testFocusCycling_wrapsAtBeginning() {
        // Given: Focus is on the first area
        focusManager.moveFocus(to: .transcript)

        // When: Focus previous
        focusManager.focusPrevious()

        // Then: Should wrap to coaching prompt (last area)
        XCTAssertEqual(focusManager.currentFocus, .coachingPrompt)
    }

    func testFocusCycling_fullCycleForward() {
        // Given: Starting at transcript
        focusManager.moveFocus(to: .transcript)
        let startArea = focusManager.currentFocus

        // When: Cycle through all areas
        let areaCount = FocusManager.FocusArea.allCases.count
        for _ in 0..<areaCount {
            focusManager.focusNext()
        }

        // Then: Should be back at transcript
        XCTAssertEqual(focusManager.currentFocus, startArea)
    }

    func testFocusCycling_fullCycleBackward() {
        // Given: Starting at transcript
        focusManager.moveFocus(to: .transcript)
        let startArea = focusManager.currentFocus

        // When: Cycle through all areas backward
        let areaCount = FocusManager.FocusArea.allCases.count
        for _ in 0..<areaCount {
            focusManager.focusPrevious()
        }

        // Then: Should be back at transcript
        XCTAssertEqual(focusManager.currentFocus, startArea)
    }

    func testFocusCycling_toggleEnabled() {
        // Given: Focus cycling is enabled
        XCTAssertTrue(focusManager.enableFocusCycling)

        // When: Disable cycling
        focusManager.enableFocusCycling = false

        // Then: Cycling should be disabled
        XCTAssertFalse(focusManager.enableFocusCycling)
    }

    // MARK: - Test: Restore Previous Focus

    func testRestorePreviousFocus() {
        // Given: Focus moved from controls to transcript
        focusManager.moveFocus(to: .transcript)
        XCTAssertEqual(focusManager.previousFocus, .controls)

        // When: Restore previous focus
        focusManager.restorePreviousFocus()

        // Then: Current focus should be controls, previous should be nil
        XCTAssertEqual(focusManager.currentFocus, .controls)
        XCTAssertNil(focusManager.previousFocus)
    }

    func testRestorePreviousFocus_whenNoPrevious() {
        // Given: No previous focus (newly created manager)
        focusManager.previousFocus = nil
        let currentBefore = focusManager.currentFocus

        // When: Try to restore previous focus
        focusManager.restorePreviousFocus()

        // Then: Current focus should remain unchanged
        XCTAssertEqual(focusManager.currentFocus, currentBefore)
    }

    func testRestorePreviousFocus_afterMultipleMoves() {
        // Given: Multiple focus moves
        focusManager.moveFocus(to: .transcript)
        focusManager.moveFocus(to: .topics)
        focusManager.moveFocus(to: .insights)

        // When: Restore previous focus
        focusManager.restorePreviousFocus()

        // Then: Should restore to topics
        XCTAssertEqual(focusManager.currentFocus, .topics)
    }

    // MARK: - Test: Clear Focus

    func testClearFocus() {
        // Given: Focus is on transcript
        focusManager.moveFocus(to: .transcript)

        // When: Clear focus
        focusManager.clearFocus()

        // Then: Current focus should be nil, previous should be transcript
        XCTAssertNil(focusManager.currentFocus)
        XCTAssertEqual(focusManager.previousFocus, .transcript)
    }

    func testClearFocus_thenRestore() {
        // Given: Focus is cleared
        focusManager.moveFocus(to: .topics)
        focusManager.clearFocus()
        XCTAssertNil(focusManager.currentFocus)

        // When: Restore previous focus
        focusManager.restorePreviousFocus()

        // Then: Should restore to topics
        XCTAssertEqual(focusManager.currentFocus, .topics)
    }

    // MARK: - Test: Focus Area Accessibility Labels

    func testFocusAreaAccessibilityLabel_transcript() {
        XCTAssertEqual(FocusManager.FocusArea.transcript.accessibilityLabel, "Transcript panel")
    }

    func testFocusAreaAccessibilityLabel_topics() {
        XCTAssertEqual(FocusManager.FocusArea.topics.accessibilityLabel, "Topics panel")
    }

    func testFocusAreaAccessibilityLabel_insights() {
        XCTAssertEqual(FocusManager.FocusArea.insights.accessibilityLabel, "Insights panel")
    }

    func testFocusAreaAccessibilityLabel_controls() {
        XCTAssertEqual(FocusManager.FocusArea.controls.accessibilityLabel, "Session controls")
    }

    func testFocusAreaAccessibilityLabel_search() {
        XCTAssertEqual(FocusManager.FocusArea.search.accessibilityLabel, "Search field")
    }

    func testFocusAreaAccessibilityLabel_settings() {
        XCTAssertEqual(FocusManager.FocusArea.settings.accessibilityLabel, "Settings")
    }

    func testFocusAreaAccessibilityLabel_coachingPrompt() {
        XCTAssertEqual(FocusManager.FocusArea.coachingPrompt.accessibilityLabel, "Coaching prompt")
    }

    // MARK: - Test: Focus Area Accessibility Hints

    func testFocusAreaAccessibilityHint_transcript() {
        XCTAssertEqual(FocusManager.FocusArea.transcript.accessibilityHint, "View and edit conversation transcript")
    }

    func testFocusAreaAccessibilityHint_topics() {
        XCTAssertEqual(FocusManager.FocusArea.topics.accessibilityHint, "View topic coverage status")
    }

    func testFocusAreaAccessibilityHint_insights() {
        XCTAssertEqual(FocusManager.FocusArea.insights.accessibilityHint, "Review flagged insights")
    }

    func testFocusAreaAccessibilityHint_controls() {
        XCTAssertEqual(FocusManager.FocusArea.controls.accessibilityHint, "Control session recording")
    }

    func testFocusAreaAccessibilityHint_search() {
        XCTAssertEqual(FocusManager.FocusArea.search.accessibilityHint, "Search transcript content")
    }

    func testFocusAreaAccessibilityHint_settings() {
        XCTAssertEqual(FocusManager.FocusArea.settings.accessibilityHint, "Adjust application settings")
    }

    func testFocusAreaAccessibilityHint_coachingPrompt() {
        XCTAssertEqual(FocusManager.FocusArea.coachingPrompt.accessibilityHint, "View coaching suggestion")
    }

    // MARK: - Test: All Focus Areas Have Labels and Hints

    func testAllFocusAreas_haveAccessibilityLabels() {
        for area in FocusManager.FocusArea.allCases {
            XCTAssertFalse(area.accessibilityLabel.isEmpty, "\(area) should have an accessibility label")
        }
    }

    func testAllFocusAreas_haveAccessibilityHints() {
        for area in FocusManager.FocusArea.allCases {
            XCTAssertFalse(area.accessibilityHint.isEmpty, "\(area) should have an accessibility hint")
        }
    }

    // MARK: - Test: Focus Areas Are Hashable

    func testFocusAreas_areHashable() {
        let set = Set<FocusManager.FocusArea>([.transcript, .topics, .insights])
        XCTAssertEqual(set.count, 3)
    }

    func testFocusAreas_equalityWorks() {
        XCTAssertEqual(FocusManager.FocusArea.transcript, FocusManager.FocusArea.transcript)
        XCTAssertNotEqual(FocusManager.FocusArea.transcript, FocusManager.FocusArea.topics)
    }
}

// MARK: - FocusField Tests

final class FocusFieldTests: XCTestCase {

    // MARK: - Test: Accessibility Identifiers

    func testFocusFieldStates_participantName() {
        let field = FocusField.participantName
        XCTAssertEqual(field.accessibilityIdentifier, "participantNameField")
    }

    func testFocusFieldStates_projectName() {
        let field = FocusField.projectName
        XCTAssertEqual(field.accessibilityIdentifier, "projectNameField")
    }

    func testFocusFieldStates_templateSelector() {
        let field = FocusField.templateSelector
        XCTAssertEqual(field.accessibilityIdentifier, "templateSelector")
    }

    func testFocusFieldStates_topicEditor() {
        let testId = UUID()
        let field = FocusField.topicEditor(id: testId)
        XCTAssertEqual(field.accessibilityIdentifier, "topicEditor-\(testId.uuidString)")
    }

    func testFocusFieldStates_insightNote() {
        let testId = UUID()
        let field = FocusField.insightNote(id: testId)
        XCTAssertEqual(field.accessibilityIdentifier, "insightNote-\(testId.uuidString)")
    }

    func testFocusFieldStates_searchQuery() {
        let field = FocusField.searchQuery
        XCTAssertEqual(field.accessibilityIdentifier, "searchQueryField")
    }

    func testFocusFieldStates_apiKey() {
        let field = FocusField.apiKey
        XCTAssertEqual(field.accessibilityIdentifier, "apiKeyField")
    }

    // MARK: - Test: FocusField Hashability

    func testFocusField_hashability() {
        let id1 = UUID()
        let id2 = UUID()

        let set = Set<FocusField>([
            .participantName,
            .projectName,
            .topicEditor(id: id1),
            .topicEditor(id: id2)
        ])

        XCTAssertEqual(set.count, 4)
    }

    func testFocusField_equalityWithSameId() {
        let testId = UUID()
        let field1 = FocusField.topicEditor(id: testId)
        let field2 = FocusField.topicEditor(id: testId)

        XCTAssertEqual(field1, field2)
    }

    func testFocusField_inequalityWithDifferentId() {
        let field1 = FocusField.topicEditor(id: UUID())
        let field2 = FocusField.topicEditor(id: UUID())

        XCTAssertNotEqual(field1, field2)
    }

    func testFocusField_inequalityAcrossTypes() {
        let field1 = FocusField.participantName
        let field2 = FocusField.projectName

        XCTAssertNotEqual(field1, field2)
    }

    // MARK: - Test: Unique Identifiers

    func testFocusField_uniqueIdentifiers() {
        let identifiers = [
            FocusField.participantName.accessibilityIdentifier,
            FocusField.projectName.accessibilityIdentifier,
            FocusField.templateSelector.accessibilityIdentifier,
            FocusField.searchQuery.accessibilityIdentifier,
            FocusField.apiKey.accessibilityIdentifier
        ]

        let uniqueIdentifiers = Set(identifiers)
        XCTAssertEqual(identifiers.count, uniqueIdentifiers.count, "All field identifiers should be unique")
    }

    func testFocusField_identifiersAreNotEmpty() {
        let fields: [FocusField] = [
            .participantName,
            .projectName,
            .templateSelector,
            .topicEditor(id: UUID()),
            .insightNote(id: UUID()),
            .searchQuery,
            .apiKey
        ]

        for field in fields {
            XCTAssertFalse(field.accessibilityIdentifier.isEmpty, "Accessibility identifier should not be empty")
        }
    }
}
