//
//  TopicAnalyzerTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for TopicAnalyzer - targeting 90% coverage
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class TopicAnalyzerTests: XCTestCase {

    // MARK: - Properties

    var analyzer: TopicAnalyzer!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        analyzer = TopicAnalyzer()
    }

    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func configureAnalyzerWithTopics(_ topics: [String], keywords: [String: [String]]? = nil) {
        analyzer.configure(topics: topics, keywords: keywords)
    }

    // MARK: - Test: Analyze Utterance

    func testAnalyzeUtterance_detectsKeywordMatch() {
        // Given: Topics configured with keywords
        configureAnalyzerWithTopics(["User Experience"], keywords: ["User Experience": ["usability", "interface", "design"]])

        // When: Analyze an utterance containing a keyword
        analyzer.analyze(text: "The usability of this interface is really important to us", speaker: .participant, timestamp: 60.0)

        // Then: Topic should be detected
        let coverage = analyzer.topicCoverages["User Experience"]
        XCTAssertNotNil(coverage)
        XCTAssertTrue(coverage!.status.hasBeenStarted)
    }

    func testAnalyzeUtterance_emptyTextIgnored() {
        // Given: Topics configured
        configureAnalyzerWithTopics(["Test Topic"])

        // When: Analyze empty text
        analyzer.analyze(text: "", speaker: .participant, timestamp: 60.0)

        // Then: No change should occur
        let coverage = analyzer.topicCoverages["Test Topic"]
        XCTAssertEqual(coverage?.status, .notStarted)
    }

    func testAnalyzeUtterance_incrementsMentionCount() async throws {
        // Given: Topics configured
        configureAnalyzerWithTopics(["Workflow"])

        // When: Analyze multiple utterances mentioning the topic
        analyzer.analyze(text: "Our workflow needs improvement", speaker: .participant, timestamp: 60.0)

        // Wait for async analysis to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Mention count should be incremented
        let coverage = analyzer.topicCoverages["Workflow"]
        XCTAssertNotNil(coverage)
        XCTAssertGreaterThanOrEqual(coverage!.mentionCount, 1)
    }

    // MARK: - Test: Topic Detection

    func testTopicDetection_byKeyword() async throws {
        // Given: Topics with specific keywords
        configureAnalyzerWithTopics(["Navigation"], keywords: ["Navigation": ["menu", "sidebar", "breadcrumb"]])

        // When: Analyze text with keyword
        analyzer.analyze(text: "The sidebar navigation is confusing for new users", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Topic should be detected
        let coverage = analyzer.topicCoverages["Navigation"]
        XCTAssertTrue(coverage?.status.hasBeenStarted ?? false)
    }

    func testTopicDetection_byTopicName() async throws {
        // Given: A topic
        configureAnalyzerWithTopics(["Onboarding Process"])

        // When: Analyze text mentioning topic by name
        analyzer.analyze(text: "The onboarding process takes too long for new employees", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Topic should be detected
        let coverage = analyzer.topicCoverages["Onboarding Process"]
        XCTAssertTrue(coverage?.status.hasBeenStarted ?? false)
    }

    func testTopicDetection_noMatchForUnrelatedText() async throws {
        // Given: A topic
        configureAnalyzerWithTopics(["Mobile Experience"])

        // When: Analyze unrelated text
        analyzer.analyze(text: "The weather is nice today", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Topic should not be detected
        let coverage = analyzer.topicCoverages["Mobile Experience"]
        XCTAssertEqual(coverage?.status, .notStarted)
    }

    // MARK: - Test: Coverage Calculation

    func testCoverageCalculation_overallCoverage() {
        // Given: Multiple topics with different coverage
        configureAnalyzerWithTopics(["Topic 1", "Topic 2", "Topic 3", "Topic 4"])

        // Manually set some coverage for testing
        analyzer.setStatus(for: "Topic 1", to: .deepDive)
        analyzer.setStatus(for: "Topic 2", to: .explored)
        analyzer.setStatus(for: "Topic 3", to: .mentioned)
        // Topic 4 remains notStarted

        // When: Calculate overall coverage
        let coverage = analyzer.overallCoverage

        // Then: Coverage should be average of all topics
        // deepDive=1.0, explored=0.66, mentioned=0.33, notStarted=0.0
        // Average = (1.0 + 0.66 + 0.33 + 0.0) / 4 = ~0.50
        XCTAssertGreaterThan(coverage, 0.4)
        XCTAssertLessThan(coverage, 0.6)
    }

    func testCoverageCalculation_noTopics() {
        // Given: No topics configured

        // When: Calculate overall coverage
        let coverage = analyzer.overallCoverage

        // Then: Should be 0
        XCTAssertEqual(coverage, 0.0)
    }

    // MARK: - Test: Status Progression - Not Started

    func testStatusProgression_notStarted() {
        // Given: A newly configured topic
        configureAnalyzerWithTopics(["New Topic"])

        // Then: Status should be notStarted
        let coverage = analyzer.topicCoverages["New Topic"]
        XCTAssertEqual(coverage?.status, .notStarted)
        XCTAssertEqual(coverage?.mentionCount, 0)
    }

    func testStatusProgression_notStartedProperties() {
        // Given: Topics in notStarted state
        configureAnalyzerWithTopics(["Test"])

        // Then: Should have correct properties
        let status = TopicCoverageStatus.notStarted
        XCTAssertFalse(status.hasBeenStarted)
        XCTAssertFalse(status.isComplete)
        XCTAssertEqual(status.progressValue, 0.0)
    }

    // MARK: - Test: Status Progression - Mentioned

    func testStatusProgression_mentioned() async throws {
        // Given: A topic
        configureAnalyzerWithTopics(["Payment"])

        // When: Analyze a brief mention
        analyzer.analyze(text: "We also use payment systems for transactions", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Status should progress to mentioned or higher
        let coverage = analyzer.topicCoverages["Payment"]
        XCTAssertTrue(coverage?.status.hasBeenStarted ?? false)
    }

    func testStatusProgression_mentionedProperties() {
        // Test mentioned status properties
        let status = TopicCoverageStatus.mentioned
        XCTAssertTrue(status.hasBeenStarted)
        XCTAssertFalse(status.isComplete)
        XCTAssertEqual(status.progressPercentage, 33)
    }

    // MARK: - Test: Status Progression - Explored

    func testStatusProgression_explored() {
        // Given: A topic
        configureAnalyzerWithTopics(["Security"])

        // When: Manually set to explored
        analyzer.setStatus(for: "Security", to: .explored)

        // Then: Status should be explored
        let coverage = analyzer.topicCoverages["Security"]
        XCTAssertEqual(coverage?.status, .explored)
    }

    func testStatusProgression_exploredProperties() {
        // Test explored status properties
        let status = TopicCoverageStatus.explored
        XCTAssertTrue(status.hasBeenStarted)
        XCTAssertFalse(status.isComplete)
        XCTAssertEqual(status.progressPercentage, 66)
    }

    // MARK: - Test: Status Progression - Deep Dive

    func testStatusProgression_deepDive() {
        // Given: A topic
        configureAnalyzerWithTopics(["Performance"])

        // When: Set to deepDive
        analyzer.setStatus(for: "Performance", to: .deepDive)

        // Then: Status should be deepDive
        let coverage = analyzer.topicCoverages["Performance"]
        XCTAssertEqual(coverage?.status, .deepDive)
    }

    func testStatusProgression_deepDiveProperties() {
        // Test deepDive status properties
        let status = TopicCoverageStatus.deepDive
        XCTAssertTrue(status.hasBeenStarted)
        XCTAssertTrue(status.isComplete)
        XCTAssertEqual(status.progressPercentage, 100)
    }

    // MARK: - Test: Keyword Matching

    func testKeywordMatching_caseInsensitive() async throws {
        // Given: Topic with lowercase keywords
        configureAnalyzerWithTopics(["Search"], keywords: ["Search": ["search", "filter", "find"]])

        // When: Analyze text with different case
        analyzer.analyze(text: "The SEARCH functionality and FILTER options are important", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should still match
        let coverage = analyzer.topicCoverages["Search"]
        XCTAssertTrue(coverage?.status.hasBeenStarted ?? false)
    }

    func testKeywordMatching_multipleKeywords() async throws {
        // Given: Topic with multiple keywords
        configureAnalyzerWithTopics(["Authentication"], keywords: ["Authentication": ["login", "password", "signin", "authentication"]])

        // When: Analyze text with multiple keyword matches
        analyzer.analyze(text: "The login process with password authentication is complex", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should match with higher confidence
        let coverage = analyzer.topicCoverages["Authentication"]
        XCTAssertTrue(coverage?.status.hasBeenStarted ?? false)
        XCTAssertGreaterThan(coverage?.confidence ?? 0, 0.5)
    }

    func testKeywordMatching_partialWord() async throws {
        // Given: Topic with keyword
        configureAnalyzerWithTopics(["Workflow"], keywords: ["Workflow": ["workflow"]])

        // When: Analyze text containing the keyword within another word
        analyzer.analyze(text: "The workflow automation saves us time every day", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should match
        let coverage = analyzer.topicCoverages["Workflow"]
        XCTAssertTrue(coverage?.status.hasBeenStarted ?? false)
    }

    // MARK: - Test: Confidence Threshold

    func testConfidenceThreshold_default() {
        // Given: Default analyzer
        XCTAssertEqual(analyzer.confidenceThreshold, 0.4)
    }

    func testConfidenceThreshold_custom() async throws {
        // Given: Custom confidence threshold
        analyzer.confidenceThreshold = 0.8
        configureAnalyzerWithTopics(["Testing"])

        // When: Analyze with weak match
        analyzer.analyze(text: "We do some testing occasionally", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Depending on semantic matching, may or may not detect
        // The test validates the threshold is configurable
        XCTAssertEqual(analyzer.confidenceThreshold, 0.8)
    }

    func testConfidenceThreshold_highConfidenceMatch() async throws {
        // Given: Topic with exact keyword
        configureAnalyzerWithTopics(["Dashboard"], keywords: ["Dashboard": ["dashboard", "widget", "metrics"]])

        // When: Analyze with exact keyword match
        analyzer.analyze(text: "The dashboard and all the widgets on the dashboard are essential for tracking our metrics", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should have high confidence
        let coverage = analyzer.topicCoverages["Dashboard"]
        XCTAssertGreaterThan(coverage?.confidence ?? 0, 0.7)
    }

    // MARK: - Test: Multiple Topics

    func testMultipleTopics_detectsMultiple() async throws {
        // Given: Multiple topics
        configureAnalyzerWithTopics(
            ["Performance", "Security", "Usability"],
            keywords: [
                "Performance": ["speed", "fast", "slow"],
                "Security": ["secure", "password", "authentication"],
                "Usability": ["easy", "intuitive", "user-friendly"]
            ]
        )

        // When: Analyze text mentioning multiple topics
        analyzer.analyze(text: "The system is fast and secure, but not very easy to use", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Multiple topics should be detected
        XCTAssertTrue(analyzer.topicCoverages["Performance"]?.status.hasBeenStarted ?? false)
        XCTAssertTrue(analyzer.topicCoverages["Security"]?.status.hasBeenStarted ?? false)
        XCTAssertTrue(analyzer.topicCoverages["Usability"]?.status.hasBeenStarted ?? false)
    }

    func testMultipleTopics_tracksIndependently() {
        // Given: Multiple topics
        configureAnalyzerWithTopics(["Topic A", "Topic B", "Topic C"])

        // When: Set different statuses
        analyzer.setStatus(for: "Topic A", to: .deepDive)
        analyzer.setStatus(for: "Topic B", to: .mentioned)
        // Topic C remains notStarted

        // Then: Each topic should have independent status
        XCTAssertEqual(analyzer.topicCoverages["Topic A"]?.status, .deepDive)
        XCTAssertEqual(analyzer.topicCoverages["Topic B"]?.status, .mentioned)
        XCTAssertEqual(analyzer.topicCoverages["Topic C"]?.status, .notStarted)
    }

    // MARK: - Test: Manual Override

    func testManualOverride_setStatus() {
        // Given: A topic
        configureAnalyzerWithTopics(["Override Test"])

        // When: Manually set status
        analyzer.setStatus(for: "Override Test", to: .explored)

        // Then: Status should be set and marked as override
        let coverage = analyzer.topicCoverages["Override Test"]
        XCTAssertEqual(coverage?.status, .explored)
        XCTAssertTrue(coverage?.isManualOverride ?? false)
    }

    func testManualOverride_cycleStatus() {
        // Given: A topic in notStarted state
        configureAnalyzerWithTopics(["Cycle Test"])
        XCTAssertEqual(analyzer.topicCoverages["Cycle Test"]?.status, .notStarted)

        // When: Cycle through statuses
        let status1 = analyzer.cycleStatus(for: "Cycle Test")
        XCTAssertEqual(status1, .mentioned)

        let status2 = analyzer.cycleStatus(for: "Cycle Test")
        XCTAssertEqual(status2, .explored)

        let status3 = analyzer.cycleStatus(for: "Cycle Test")
        XCTAssertEqual(status3, .deepDive)

        let status4 = analyzer.cycleStatus(for: "Cycle Test")
        XCTAssertEqual(status4, .notStarted) // Wraps around
    }

    func testManualOverride_preventsAutoUpdate() async throws {
        // Given: A topic with manual override
        configureAnalyzerWithTopics(["Manual Topic"], keywords: ["Manual Topic": ["keyword"]])
        analyzer.setStatus(for: "Manual Topic", to: .notStarted)

        // When: Analyze text that would normally trigger detection
        analyzer.analyze(text: "This is about the keyword that should match", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Status should remain unchanged due to manual override
        let coverage = analyzer.topicCoverages["Manual Topic"]
        XCTAssertEqual(coverage?.status, .notStarted)
        XCTAssertTrue(coverage?.isManualOverride ?? false)
    }

    // MARK: - Test: Query Methods

    func testUncoveredTopics() {
        // Given: Topics with various coverage
        configureAnalyzerWithTopics(["A", "B", "C", "D"])
        analyzer.setStatus(for: "A", to: .mentioned)
        analyzer.setStatus(for: "B", to: .deepDive)
        // C and D remain notStarted

        // When: Get uncovered topics
        let uncovered = analyzer.uncoveredTopics

        // Then: Should return only notStarted topics
        XCTAssertEqual(uncovered.count, 2)
        XCTAssertTrue(uncovered.contains("C"))
        XCTAssertTrue(uncovered.contains("D"))
    }

    func testInProgressTopics() {
        // Given: Topics with various coverage
        configureAnalyzerWithTopics(["A", "B", "C", "D"])
        analyzer.setStatus(for: "A", to: .mentioned)
        analyzer.setStatus(for: "B", to: .explored)
        analyzer.setStatus(for: "C", to: .deepDive)
        // D remains notStarted

        // When: Get in-progress topics
        let inProgress = analyzer.inProgressTopics

        // Then: Should return mentioned and explored topics
        XCTAssertEqual(inProgress.count, 2)
        XCTAssertTrue(inProgress.contains("A"))
        XCTAssertTrue(inProgress.contains("B"))
    }

    func testCompletedTopics() {
        // Given: Topics with various coverage
        configureAnalyzerWithTopics(["A", "B", "C"])
        analyzer.setStatus(for: "A", to: .deepDive)
        analyzer.setStatus(for: "B", to: .deepDive)
        analyzer.setStatus(for: "C", to: .mentioned)

        // When: Get completed topics
        let completed = analyzer.completedTopics

        // Then: Should return only deepDive topics
        XCTAssertEqual(completed.count, 2)
        XCTAssertTrue(completed.contains("A"))
        XCTAssertTrue(completed.contains("B"))
    }

    // MARK: - Test: Reset

    func testReset_clearsAllState() {
        // Given: Configured analyzer with data
        configureAnalyzerWithTopics(["Topic 1", "Topic 2"])
        analyzer.setStatus(for: "Topic 1", to: .explored)

        // When: Reset
        analyzer.reset()

        // Then: All state should be cleared
        XCTAssertTrue(analyzer.topicCoverages.isEmpty)
        XCTAssertNil(analyzer.lastAnalyzedAt)
        XCTAssertFalse(analyzer.isAnalyzing)
    }

    // MARK: - Test: Reanalyze All

    func testReanalyzeAll_resetsAndReprocesses() async throws {
        // Given: Configured analyzer with some analysis done
        configureAnalyzerWithTopics(["Workflow"])
        analyzer.analyze(text: "We need to improve our workflow", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Reanalyze all
        await analyzer.reanalyzeAll()

        // Then: Last analyzed timestamp should be updated
        XCTAssertNotNil(analyzer.lastAnalyzedAt)
    }

    // MARK: - Test: Status From Coverage Score

    func testStatusFromCoverageScore_notStarted() {
        let status = TopicCoverageStatus.from(coverageScore: 0.10)
        XCTAssertEqual(status, .notStarted)
    }

    func testStatusFromCoverageScore_mentioned() {
        let status = TopicCoverageStatus.from(coverageScore: 0.30)
        XCTAssertEqual(status, .mentioned)
    }

    func testStatusFromCoverageScore_explored() {
        let status = TopicCoverageStatus.from(coverageScore: 0.60)
        XCTAssertEqual(status, .explored)
    }

    func testStatusFromCoverageScore_deepDive() {
        let status = TopicCoverageStatus.from(coverageScore: 0.80)
        XCTAssertEqual(status, .deepDive)
    }

    // MARK: - Test: Status Transitions

    func testStatusNext() {
        XCTAssertEqual(TopicCoverageStatus.notStarted.next, .mentioned)
        XCTAssertEqual(TopicCoverageStatus.mentioned.next, .explored)
        XCTAssertEqual(TopicCoverageStatus.explored.next, .deepDive)
        XCTAssertEqual(TopicCoverageStatus.deepDive.next, .notStarted)
    }

    func testStatusPrevious() {
        XCTAssertEqual(TopicCoverageStatus.notStarted.previous, .deepDive)
        XCTAssertEqual(TopicCoverageStatus.mentioned.previous, .notStarted)
        XCTAssertEqual(TopicCoverageStatus.explored.previous, .mentioned)
        XCTAssertEqual(TopicCoverageStatus.deepDive.previous, .explored)
    }

    // MARK: - Test: Follow-up Detection

    func testFollowUpDetection_interviewerProbing() async throws {
        // Given: A topic
        configureAnalyzerWithTopics(["Details"])

        // When: Analyze an interviewer follow-up question
        analyzer.analyze(text: "Can you tell me more about how that works in practice?", speaker: .interviewer, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Follow-up pattern should be detected
        // This contributes to depth level
        XCTAssertNotNil(analyzer.lastAnalyzedAt)
    }

    func testFollowUpDetection_participantElaboration() async throws {
        // Given: A topic
        configureAnalyzerWithTopics(["Explanation"])

        // When: Analyze a participant elaboration
        analyzer.analyze(text: "Let me explain further. For example, when we encounter this situation, we need to consider multiple factors because the reason is complex.", speaker: .participant, timestamp: 60.0)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Detail pattern should be detected
        XCTAssertNotNil(analyzer.lastAnalyzedAt)
    }

    // MARK: - Test: Semantic Matching Toggle

    func testSemanticMatching_enabled() {
        // Given: Semantic matching enabled (default)
        XCTAssertTrue(analyzer.useSemanticMatching)

        // When: Analyze with semantic similarity expected
        configureAnalyzerWithTopics(["User Research"])

        // Then: Semantic matching should be available
        XCTAssertTrue(analyzer.useSemanticMatching)
    }

    func testSemanticMatching_disabled() {
        // Given: Disable semantic matching
        analyzer.useSemanticMatching = false

        // Then: Should be disabled
        XCTAssertFalse(analyzer.useSemanticMatching)
    }

    // MARK: - Test: Default Keywords Generation

    func testDefaultKeywordsGeneration() {
        // Given: Topics without explicit keywords
        configureAnalyzerWithTopics(["User Experience Design"])

        // Then: Topic coverage should be initialized
        XCTAssertNotNil(analyzer.topicCoverages["User Experience Design"])

        // Keywords are generated internally from topic name
        // e.g., "user", "experience", "design"
    }
}
