//
//  FollowUpSuggesterTests.swift
//  HCD Interview Coach Tests
//
//  Unit tests for FollowUpSuggester rules-based suggestion generation
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class FollowUpSuggesterTests: XCTestCase {

    var suggester: FollowUpSuggester!

    override func setUp() {
        super.setUp()
        suggester = FollowUpSuggester()
    }

    override func tearDown() {
        suggester = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeParticipantUtterance(
        text: String,
        timestamp: Double = 0.0
    ) -> Utterance {
        return Utterance(
            speaker: .participant,
            text: text,
            timestampSeconds: timestamp
        )
    }

    private func makeInterviewerUtterance(
        text: String,
        timestamp: Double = 0.0
    ) -> Utterance {
        return Utterance(
            speaker: .interviewer,
            text: text,
            timestampSeconds: timestamp
        )
    }

    // MARK: - Emotion Trigger Tests

    func testGenerateSuggestions_emotionTrigger_frustrated() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I was really frustrated when the app crashed during my presentation."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        XCTAssertFalse(suggester.suggestions.isEmpty)
        let emotionSuggestion = suggester.suggestions.first { $0.category == .emotionExplore }
        XCTAssertNotNil(emotionSuggestion, "Should generate an emotion exploration suggestion")
        XCTAssertTrue(
            emotionSuggestion?.text.lowercased().contains("frustrat") ?? false,
            "Suggestion should reference the detected emotion"
        )
    }

    func testGenerateSuggestions_emotionTrigger_excited() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I was so excited when I discovered that shortcut feature."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        let emotionSuggestion = suggester.suggestions.first { $0.category == .emotionExplore }
        XCTAssertNotNil(emotionSuggestion, "Should generate emotion suggestion for 'excited'")
    }

    func testGenerateSuggestions_emotionTrigger_confused() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "The whole setup process was really confusing to me."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        let emotionSuggestion = suggester.suggestions.first { $0.category == .emotionExplore }
        XCTAssertNotNil(emotionSuggestion, "Should generate emotion suggestion for 'confusing'")
    }

    func testGenerateSuggestions_emotionTrigger_hasRelevantTriggerQuote() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I felt really overwhelmed by all the options on the dashboard."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        let emotionSuggestion = suggester.suggestions.first { $0.category == .emotionExplore }
        XCTAssertNotNil(emotionSuggestion)
        XCTAssertFalse(
            emotionSuggestion?.triggerQuote.isEmpty ?? true,
            "Trigger quote should not be empty"
        )
    }

    // MARK: - Short Answer / Elaboration Tests

    func testGenerateSuggestions_shortAnswer_generatesElaboration() {
        // Given: A very short participant answer
        let utterance = makeParticipantUtterance(text: "It was fine.")

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        XCTAssertFalse(suggester.suggestions.isEmpty)
        let elaboration = suggester.suggestions.first { $0.category == .probeDeeper }
        XCTAssertNotNil(elaboration, "Short answers should generate an elaboration suggestion")
    }

    func testGenerateSuggestions_shortAnswer_highRelevance() {
        // Given: Very short answer (3 words or fewer)
        let utterance = makeParticipantUtterance(text: "Yes.")

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        let elaboration = suggester.suggestions.first { $0.category == .probeDeeper }
        XCTAssertNotNil(elaboration)
        XCTAssertGreaterThanOrEqual(
            elaboration?.relevance ?? 0,
            0.90,
            "Very short answers should have high relevance for elaboration"
        )
    }

    func testGenerateSuggestions_longAnswer_noElaborationAlone() {
        // Given: A long, detailed answer with no other triggers
        let utterance = makeParticipantUtterance(
            text: "I usually go to the main screen and then click on the projects tab and scroll down to find my active project and then open it up to see the details page where I can review everything."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then: Should not generate a probeDeeper suggestion for a long answer
        // (unless other patterns triggered it first and it was added as a fallback)
        let hasOnlyElaboration = suggester.suggestions.allSatisfy { $0.category == .probeDeeper }
        if !suggester.suggestions.isEmpty {
            XCTAssertFalse(
                hasOnlyElaboration,
                "Long answers should trigger other types of suggestions, not just elaboration"
            )
        }
    }

    // MARK: - Process / Timeline Tests

    func testGenerateSuggestions_processDescription_generatesTimeline() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "First I opened the app, then I navigated to settings, and eventually I found the option I was looking for."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        let timelineSuggestion = suggester.suggestions.first { $0.category == .timelineExplore }
        XCTAssertNotNil(timelineSuggestion, "Process descriptions should generate timeline suggestions")
    }

    func testGenerateSuggestions_triedTo_generatesTimeline() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I tried to export the file but it kept failing with an error."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        let timelineSuggestion = suggester.suggestions.first { $0.category == .timelineExplore }
        XCTAssertNotNil(timelineSuggestion, "Process-related words should trigger timeline suggestions")
    }

    // MARK: - Comparison / Contrast Tests

    func testGenerateSuggestions_comparison_generatesContrast() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "This is much better than the previous version we were using."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        let contrastSuggestion = suggester.suggestions.first { $0.category == .contrastExplore }
        XCTAssertNotNil(contrastSuggestion, "Comparisons should generate contrast exploration suggestions")
    }

    func testGenerateSuggestions_preference_generatesContrast() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I prefer using the keyboard shortcuts instead of clicking through menus."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        let contrastSuggestion = suggester.suggestions.first { $0.category == .contrastExplore }
        XCTAssertNotNil(contrastSuggestion, "Preferences should trigger contrast suggestions")
    }

    // MARK: - Clarification Tests

    func testGenerateSuggestions_jargon_generatesClarification() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "It's basically just that thing where you kind of drag and drop the stuff."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        let clarifySuggestion = suggester.suggestions.first { $0.category == .clarify }
        XCTAssertNotNil(clarifySuggestion, "Vague language should generate clarification suggestions")
    }

    // MARK: - Topic Redirect Tests

    func testGenerateSuggestions_withTopics_generatesRedirect() {
        // Given: An utterance that doesn't cover the provided topics
        let utterance = makeParticipantUtterance(
            text: "I mostly use the search feature to find things quickly."
        )
        let uncoveredTopics = ["onboarding", "notifications", "settings"]

        // When
        suggester.generateSuggestions(from: utterance, topics: uncoveredTopics)

        // Then
        let redirectSuggestion = suggester.suggestions.first { $0.category == .redirectToTopic }
        XCTAssertNotNil(redirectSuggestion, "Uncovered topics should generate redirect suggestions")
    }

    func testGenerateSuggestions_withTopics_doesNotRedirectToMentionedTopic() {
        // Given: An utterance that mentions one of the topics
        let utterance = makeParticipantUtterance(
            text: "The onboarding process was straightforward."
        )
        let topics = ["onboarding"]

        // When
        suggester.generateSuggestions(from: utterance, topics: topics)

        // Then: Should not redirect to a topic that's already being discussed
        let redirectSuggestion = suggester.suggestions.first { $0.category == .redirectToTopic }
        XCTAssertNil(redirectSuggestion, "Should not redirect to a topic already mentioned in the utterance")
    }

    // MARK: - Max Suggestions Tests

    func testMaxSuggestions_respected() {
        // Given: An utterance with many trigger patterns
        suggester.maxSuggestions = 2
        let utterance = makeParticipantUtterance(
            text: "I was frustrated because it's basically sort of like compared to the old one, I first tried to use it but eventually gave up."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        XCTAssertLessThanOrEqual(
            suggester.suggestions.count,
            2,
            "Should not exceed maxSuggestions"
        )
    }

    func testMaxSuggestions_defaultIsThree() {
        // Then
        XCTAssertEqual(suggester.maxSuggestions, 3)
    }

    // MARK: - Dismiss Tests

    func testDismissSuggestion_removesFromList() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I was really frustrated with the whole experience."
        )
        suggester.generateSuggestions(from: utterance)
        let initialCount = suggester.suggestions.count
        XCTAssertGreaterThan(initialCount, 0)

        // When
        if let firstSuggestion = suggester.suggestions.first {
            suggester.dismissSuggestion(firstSuggestion.id)
        }

        // Then
        XCTAssertEqual(suggester.suggestions.count, initialCount - 1)
    }

    func testDismissAll_clearsAllSuggestions() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I was really frustrated because I tried to export but it kept crashing."
        )
        suggester.generateSuggestions(from: utterance)
        XCTAssertFalse(suggester.suggestions.isEmpty)

        // When
        suggester.dismissAll()

        // Then
        XCTAssertTrue(suggester.suggestions.isEmpty)
    }

    func testDismissAll_tracksDismissedCount() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I was frustrated with the confusing process."
        )
        suggester.generateSuggestions(from: utterance)
        let count = suggester.suggestions.count

        // When
        suggester.dismissAll()

        // Then
        XCTAssertEqual(suggester.totalDismissed, count)
    }

    // MARK: - Accept Tests

    func testAcceptSuggestion_removesFromList() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I was frustrated with the whole thing."
        )
        suggester.generateSuggestions(from: utterance)
        let initialCount = suggester.suggestions.count
        XCTAssertGreaterThan(initialCount, 0)

        // When
        if let firstSuggestion = suggester.suggestions.first {
            suggester.acceptSuggestion(firstSuggestion.id)
        }

        // Then
        XCTAssertEqual(suggester.suggestions.count, initialCount - 1)
    }

    func testAcceptSuggestion_tracksAcceptedCount() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I was frustrated with the experience."
        )
        suggester.generateSuggestions(from: utterance)
        XCTAssertEqual(suggester.totalAccepted, 0)

        // When
        if let firstSuggestion = suggester.suggestions.first {
            suggester.acceptSuggestion(firstSuggestion.id)
        }

        // Then
        XCTAssertEqual(suggester.totalAccepted, 1)
    }

    // MARK: - Reset Tests

    func testReset_clearsAllState() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I was frustrated with the slow process."
        )
        suggester.generateSuggestions(from: utterance)
        if let first = suggester.suggestions.first {
            suggester.acceptSuggestion(first.id)
        }
        XCTAssertGreaterThan(suggester.totalAccepted, 0)

        // When
        suggester.reset()

        // Then
        XCTAssertTrue(suggester.suggestions.isEmpty)
        XCTAssertEqual(suggester.totalAccepted, 0)
        XCTAssertEqual(suggester.totalDismissed, 0)
        XCTAssertFalse(suggester.isGenerating)
    }

    // MARK: - Enable / Disable Tests

    func testDisabled_doesNotGenerate() {
        // Given
        suggester.isEnabled = false
        let utterance = makeParticipantUtterance(
            text: "I was so frustrated with this experience."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        XCTAssertTrue(suggester.suggestions.isEmpty, "Disabled suggester should not generate suggestions")
    }

    func testEnabled_generates() {
        // Given
        suggester.isEnabled = true
        let utterance = makeParticipantUtterance(
            text: "I was really frustrated when the app crashed."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        XCTAssertFalse(suggester.suggestions.isEmpty, "Enabled suggester should generate suggestions")
    }

    // MARK: - Speaker Filtering

    func testIgnoresInterviewerUtterances() {
        // Given
        let utterance = makeInterviewerUtterance(
            text: "I was frustrated too, that must have been difficult."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        XCTAssertTrue(
            suggester.suggestions.isEmpty,
            "Should not generate suggestions for interviewer utterances"
        )
    }

    // MARK: - Generating State

    func testIsGenerating_falseAfterCompletion() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "The experience was frustrating."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        XCTAssertFalse(suggester.isGenerating, "isGenerating should be false after completion")
    }

    // MARK: - Empty / Whitespace Input

    func testEmptyUtterance_noSuggestions() {
        // Given
        let utterance = makeParticipantUtterance(text: "")

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        XCTAssertTrue(suggester.suggestions.isEmpty)
    }

    func testWhitespaceOnlyUtterance_noSuggestions() {
        // Given
        let utterance = makeParticipantUtterance(text: "   ")

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        XCTAssertTrue(suggester.suggestions.isEmpty)
    }

    // MARK: - Suggestion Properties

    func testSuggestion_hasValidProperties() {
        // Given
        let utterance = makeParticipantUtterance(
            text: "I was frustrated when the export failed."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then
        for suggestion in suggester.suggestions {
            XCTAssertFalse(suggestion.text.isEmpty, "Suggestion text should not be empty")
            XCTAssertGreaterThan(suggestion.relevance, 0, "Relevance should be positive")
            XCTAssertLessThanOrEqual(suggestion.relevance, 1.0, "Relevance should be at most 1.0")
            XCTAssertFalse(suggestion.triggerQuote.isEmpty, "Trigger quote should not be empty")
        }
    }

    func testSuggestions_sortedByRelevance() {
        // Given: An utterance with multiple trigger types
        let utterance = makeParticipantUtterance(
            text: "I was frustrated because I first tried to use it and it was basically impossible compared to the old version."
        )

        // When
        suggester.generateSuggestions(from: utterance)

        // Then: Should be sorted by relevance descending
        if suggester.suggestions.count >= 2 {
            for i in 0..<(suggester.suggestions.count - 1) {
                XCTAssertGreaterThanOrEqual(
                    suggester.suggestions[i].relevance,
                    suggester.suggestions[i + 1].relevance,
                    "Suggestions should be sorted by relevance (highest first)"
                )
            }
        }
    }
}
