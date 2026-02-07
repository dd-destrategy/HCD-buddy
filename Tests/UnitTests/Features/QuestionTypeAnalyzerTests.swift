//
//  QuestionTypeAnalyzerTests.swift
//  HCD Interview Coach Tests
//
//  Unit tests for QuestionTypeAnalyzer rules-based classification
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class QuestionTypeAnalyzerTests: XCTestCase {

    var analyzer: QuestionTypeAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = QuestionTypeAnalyzer()
    }

    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeInterviewerUtterance(
        text: String,
        timestamp: Double = 0.0,
        id: UUID = UUID()
    ) -> Utterance {
        return Utterance(
            id: id,
            speaker: .interviewer,
            text: text,
            timestampSeconds: timestamp
        )
    }

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

    // MARK: - Open-Ended Detection

    func testClassify_openEnded_howDoYou() {
        // Given
        let utterance = makeInterviewerUtterance(text: "How do you typically handle this situation?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .openEnded)
        XCTAssertGreaterThanOrEqual(result?.confidence ?? 0, 0.80)
    }

    func testClassify_openEnded_tellMeAbout() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Tell me about your experience with the onboarding flow.")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .openEnded)
        XCTAssertGreaterThanOrEqual(result?.confidence ?? 0, 0.90)
    }

    func testClassify_openEnded_walkMeThrough() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Walk me through how you use this feature on a typical day?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .openEnded)
        XCTAssertGreaterThanOrEqual(result?.confidence ?? 0, 0.90)
    }

    func testClassify_openEnded_describe() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Describe your ideal workflow for this task?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .openEnded)
    }

    func testClassify_openEnded_whatWasYourExperience() {
        // Given
        let utterance = makeInterviewerUtterance(text: "What was your experience like when you first used this product?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .openEnded)
    }

    // MARK: - Closed Detection

    func testClassify_closed_doYou() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Do you use this feature regularly?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .closed)
        XCTAssertGreaterThanOrEqual(result?.confidence ?? 0, 0.80)
    }

    func testClassify_closed_didYou() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Did you complete the setup process?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .closed)
    }

    func testClassify_closed_isIt() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Is it easy to find that option?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .closed)
    }

    func testClassify_closed_haveYou() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Have you tried the new version?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .closed)
    }

    // MARK: - Leading Detection

    func testClassify_leading_dontYouThink() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Don't you think this design is better?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .leading)
        XCTAssertTrue(result?.antiPatterns.contains(.leadingQuestion) ?? false)
    }

    func testClassify_leading_wouldntYouAgree() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Wouldn't you agree that this is easier to use?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .leading)
        XCTAssertTrue(result?.antiPatterns.contains(.leadingQuestion) ?? false)
    }

    func testClassify_leading_isntItTrue() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Isn't it true that the old design was confusing?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .leading)
        XCTAssertTrue(result?.antiPatterns.contains(.leadingQuestion) ?? false)
    }

    func testClassify_leading_surelyObviously() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Surely you found this feature helpful?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .leading)
    }

    // MARK: - Double-Barreled Detection

    func testClassify_doubleBarreled_andConjunction() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Do you like the color and do you find the size appropriate?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .doubleBarreled)
        XCTAssertTrue(result?.antiPatterns.contains(.doubleBarreledQuestion) ?? false)
    }

    func testClassify_doubleBarreled_multipleQuestionMarks() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Was it fast? Was it easy?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .doubleBarreled)
        XCTAssertTrue(result?.antiPatterns.contains(.doubleBarreledQuestion) ?? false)
    }

    func testClassify_doubleBarreled_andHowConjunction() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Do you use this daily and how does it compare to your old tool?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .doubleBarreled)
    }

    // MARK: - Probing Detection

    func testClassify_probing_whyIsThat() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Why is that important to you?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .probing)
        XCTAssertGreaterThanOrEqual(result?.confidence ?? 0, 0.80)
    }

    func testClassify_probing_tellMeMore() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Tell me more about that experience.")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .probing)
    }

    func testClassify_probing_canYouElaborate() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Can you elaborate on what happened next?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .probing)
    }

    // MARK: - Clarifying Detection

    func testClassify_clarifying_whatDoYouMean() {
        // Given
        let utterance = makeInterviewerUtterance(text: "What do you mean by 'intuitive'?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .clarifying)
    }

    func testClassify_clarifying_couldYouExplain() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Could you explain what you meant by that?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .clarifying)
    }

    // MARK: - Hypothetical Detection

    func testClassify_hypothetical_whatIf() {
        // Given
        let utterance = makeInterviewerUtterance(text: "What if you could redesign this from scratch?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .hypothetical)
    }

    func testClassify_hypothetical_imagine() {
        // Given
        let utterance = makeInterviewerUtterance(text: "Imagine you had unlimited time. How would you approach this?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .hypothetical)
    }

    // MARK: - Non-Question / Participant Ignored

    func testClassify_ignoresParticipantUtterance() {
        // Given
        let utterance = makeParticipantUtterance(text: "I really enjoyed using the new feature.")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNil(result, "Participant utterances should not be classified")
    }

    func testClassify_ignoresStatements() {
        // Given
        let utterance = makeInterviewerUtterance(text: "That's a great point, thank you for sharing.")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNil(result, "Non-question statements should not be classified")
    }

    func testClassify_ignoresEmptyText() {
        // Given
        let utterance = makeInterviewerUtterance(text: "")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNil(result)
    }

    func testClassify_ignoresUnknownSpeaker() {
        // Given
        let utterance = Utterance(
            speaker: .unknown,
            text: "How do you feel about that?",
            timestampSeconds: 0
        )

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNil(result, "Unknown speaker utterances should not be classified")
    }

    // MARK: - Quality Score Calculation

    func testQualityScore_allOpenEnded() {
        // Given: All open-ended questions
        let questions = [
            "How do you approach this task?",
            "What was your experience with the feature?",
            "Tell me about your workflow.",
            "Describe your ideal solution."
        ]

        // When
        for text in questions {
            let utterance = makeInterviewerUtterance(text: text)
            _ = analyzer.classify(utterance)
        }

        // Then: Quality score should be high
        XCTAssertGreaterThan(analyzer.sessionStats.qualityScore, 70.0)
        XCTAssertEqual(analyzer.sessionStats.totalQuestions, 4)
        XCTAssertEqual(analyzer.sessionStats.openEndedCount, 4)
    }

    func testQualityScore_allClosed() {
        // Given: All closed questions
        let questions = [
            "Do you use this feature?",
            "Did you complete the task?",
            "Is it helpful?",
            "Have you seen this before?"
        ]

        // When
        for text in questions {
            let utterance = makeInterviewerUtterance(text: text)
            _ = analyzer.classify(utterance)
        }

        // Then: Quality score should be low (closed questions are not desirable)
        XCTAssertLessThan(analyzer.sessionStats.qualityScore, 30.0)
        XCTAssertEqual(analyzer.sessionStats.closedCount, 4)
    }

    func testQualityScore_mixedWithLeading() {
        // Given: Mix of questions with some leading
        let questions = [
            "How do you approach this task?",
            "Don't you think this is better?",
            "Tell me about your experience.",
            "Wouldn't you agree it's improved?"
        ]

        // When
        for text in questions {
            let utterance = makeInterviewerUtterance(text: text)
            _ = analyzer.classify(utterance)
        }

        // Then: Quality score should be penalized for leading questions
        let stats = analyzer.sessionStats
        XCTAssertEqual(stats.totalQuestions, 4)
        XCTAssertGreaterThan(stats.leadingCount, 0)
        // Leading questions add penalty, so score should be moderate at best
        XCTAssertLessThan(stats.qualityScore, 80.0)
    }

    func testQualityScore_openEndedPercentage() {
        // Given: 2 open-ended out of 4 total
        let questions = [
            "How do you approach this task?",
            "Do you use this regularly?",
            "What was your experience?",
            "Is it helpful?"
        ]

        // When
        for text in questions {
            let utterance = makeInterviewerUtterance(text: text)
            _ = analyzer.classify(utterance)
        }

        // Then
        let stats = analyzer.sessionStats
        XCTAssertEqual(stats.totalQuestions, 4)
        XCTAssertEqual(stats.openEndedCount, 2)
        XCTAssertEqual(stats.openEndedPercentage, 50.0, accuracy: 0.1)
    }

    // MARK: - Anti-Pattern: Closed Question Run

    func testAntiPattern_closedQuestionRun() {
        // Given: 3+ consecutive closed questions
        let closedQuestions = [
            "Do you use this feature?",
            "Did you complete the setup?",
            "Is it easy to use?"
        ]

        // When
        var lastResult: QuestionClassification?
        for text in closedQuestions {
            let utterance = makeInterviewerUtterance(text: text)
            lastResult = analyzer.classify(utterance)
        }

        // Then: The third closed question should trigger a closed run anti-pattern
        XCTAssertNotNil(lastResult)
        XCTAssertTrue(
            lastResult?.antiPatterns.contains(.closedQuestionRun) ?? false,
            "Third consecutive closed question should trigger closedQuestionRun anti-pattern"
        )
    }

    func testAntiPattern_closedRunResetsOnOpenEnded() {
        // Given: 2 closed questions followed by an open-ended, then 2 more closed
        let questions: [(String, QuestionType)] = [
            ("Do you use this?", .closed),
            ("Is it easy?", .closed),
            ("How do you feel about the overall experience?", .openEnded),
            ("Do you like it?", .closed),
            ("Have you tried it?", .closed)
        ]

        // When
        var lastResult: QuestionClassification?
        for (text, _) in questions {
            let utterance = makeInterviewerUtterance(text: text)
            lastResult = analyzer.classify(utterance)
        }

        // Then: Should NOT have closedQuestionRun since run was broken by open-ended
        XCTAssertNotNil(lastResult)
        XCTAssertFalse(
            lastResult?.antiPatterns.contains(.closedQuestionRun) ?? true,
            "Closed run should be reset after an open-ended question"
        )
    }

    // MARK: - Anti-Pattern: Assumptive Language

    func testAntiPattern_assumptiveLanguage() {
        // Given
        let utterance = makeInterviewerUtterance(text: "I'm sure you found this confusing, right?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.antiPatterns.contains(.assumptiveLanguage) ?? false)
    }

    // MARK: - Classification Tracking

    func testClassifications_appendsResults() {
        // Given
        XCTAssertEqual(analyzer.classifications.count, 0)

        // When
        let u1 = makeInterviewerUtterance(text: "How do you feel about this?", timestamp: 10.0)
        let u2 = makeInterviewerUtterance(text: "Do you use this daily?", timestamp: 20.0)
        _ = analyzer.classify(u1)
        _ = analyzer.classify(u2)

        // Then
        XCTAssertEqual(analyzer.classifications.count, 2)
        XCTAssertEqual(analyzer.classifications[0].type, .openEnded)
        XCTAssertEqual(analyzer.classifications[1].type, .closed)
    }

    func testClassifications_storesUtteranceId() {
        // Given
        let utteranceId = UUID()
        let utterance = makeInterviewerUtterance(
            text: "How do you approach this?",
            id: utteranceId
        )

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertEqual(result?.utteranceId, utteranceId)
    }

    func testClassifications_storesTimestamp() {
        // Given
        let utterance = makeInterviewerUtterance(
            text: "How do you approach this?",
            timestamp: 125.5
        )

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertEqual(result?.timestamp, 125.5)
    }

    // MARK: - Reset

    func testReset_clearsAllState() {
        // Given: Analyzer with some data
        let utterance = makeInterviewerUtterance(text: "How do you feel about this?")
        _ = analyzer.classify(utterance)
        XCTAssertEqual(analyzer.classifications.count, 1)

        // When
        analyzer.reset()

        // Then
        XCTAssertEqual(analyzer.classifications.count, 0)
        XCTAssertEqual(analyzer.sessionStats.totalQuestions, 0)
        XCTAssertEqual(analyzer.sessionStats.qualityScore, 0)
        XCTAssertTrue(analyzer.currentAntiPatterns.isEmpty)
    }

    // MARK: - Stats Update

    func testSessionStats_updatesAfterEachClassification() {
        // Given
        XCTAssertEqual(analyzer.sessionStats.totalQuestions, 0)

        // When
        let u1 = makeInterviewerUtterance(text: "How do you use this?")
        _ = analyzer.classify(u1)

        // Then
        XCTAssertEqual(analyzer.sessionStats.totalQuestions, 1)
        XCTAssertEqual(analyzer.sessionStats.openEndedCount, 1)

        // When
        let u2 = makeInterviewerUtterance(text: "Do you like it?")
        _ = analyzer.classify(u2)

        // Then
        XCTAssertEqual(analyzer.sessionStats.totalQuestions, 2)
        XCTAssertEqual(analyzer.sessionStats.closedCount, 1)
    }

    func testSessionStats_emptyByDefault() {
        // Then
        XCTAssertEqual(analyzer.sessionStats.totalQuestions, 0)
        XCTAssertEqual(analyzer.sessionStats.openEndedCount, 0)
        XCTAssertEqual(analyzer.sessionStats.closedCount, 0)
        XCTAssertEqual(analyzer.sessionStats.leadingCount, 0)
        XCTAssertEqual(analyzer.sessionStats.doubleBarreledCount, 0)
        XCTAssertEqual(analyzer.sessionStats.probingCount, 0)
        XCTAssertEqual(analyzer.sessionStats.openEndedPercentage, 0)
        XCTAssertEqual(analyzer.sessionStats.qualityScore, 0)
    }

    // MARK: - Edge Cases

    func testClassify_questionMarkOnlyMakesClosed() {
        // Given: A statement with a question mark at the end
        let utterance = makeInterviewerUtterance(text: "You enjoyed that?")

        // When
        let result = analyzer.classify(utterance)

        // Then: Should be classified (has question mark) as closed
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .closed)
    }

    func testClassify_caseInsensitive() {
        // Given: Mixed case
        let utterance = makeInterviewerUtterance(text: "HOW DO YOU typically handle this?")

        // When
        let result = analyzer.classify(utterance)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .openEnded)
    }
}
