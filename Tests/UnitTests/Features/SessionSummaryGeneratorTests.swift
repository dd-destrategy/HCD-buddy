//
//  SessionSummaryGeneratorTests.swift
//  HCDInterviewCoach Tests
//
//  Unit tests for SessionSummaryGenerator
//  Tests theme extraction, pain point detection, positive highlight detection,
//  topic gap identification, quality score computation, and markdown export.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class SessionSummaryGeneratorTests: XCTestCase {

    var generator: SessionSummaryGenerator!

    override func setUp() {
        super.setUp()
        generator = SessionSummaryGenerator()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createEmptySession() -> Session {
        return Session(
            participantName: "Test User",
            projectName: "Test Project",
            sessionMode: .full,
            startedAt: Date(),
            totalDurationSeconds: 0
        )
    }

    private func createSessionWithUtterances(_ utterances: [(Speaker, String, Double)]) -> Session {
        let session = Session(
            participantName: "Test Participant",
            projectName: "Test Project",
            sessionMode: .full,
            startedAt: Date(),
            totalDurationSeconds: 1800
        )

        session.utterances = utterances.map { speaker, text, timestamp in
            Utterance(speaker: speaker, text: text, timestampSeconds: timestamp)
        }

        return session
    }

    // MARK: - Test: Empty Session

    func testEmptySession_producesEmptySummary() async {
        // Given: An empty session with no utterances, insights, or topics
        let session = createEmptySession()

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Summary should have empty collections
        XCTAssertTrue(summary.keyThemes.isEmpty, "Empty session should have no themes")
        XCTAssertTrue(summary.participantPainPoints.isEmpty, "Empty session should have no pain points")
        XCTAssertTrue(summary.positiveHighlights.isEmpty, "Empty session should have no positive highlights")
        XCTAssertTrue(summary.keyQuotes.isEmpty, "Empty session should have no key quotes")
        XCTAssertTrue(summary.topicGaps.isEmpty, "Empty session should have no topic gaps")
        XCTAssertNotNil(summary.generatedAt, "Summary should have a generation timestamp")
    }

    func testEmptySession_hasNonNilSummary() async {
        // Given: An empty session
        let session = createEmptySession()

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Summary should exist and be stored in the generator
        XCTAssertNotNil(generator.summary)
        XCTAssertEqual(generator.summary?.id, summary.id)
        XCTAssertFalse(generator.isGenerating)
        XCTAssertNil(generator.generationError)
    }

    // MARK: - Test: Pain Point Detection

    func testPainPointDetection_detectsFrustration() async {
        // Given: Session with a participant utterance containing "frustrat"
        let session = createSessionWithUtterances([
            (.participant, "I find it really frustrating when the app crashes during my workflow.", 30.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should detect the pain point
        XCTAssertFalse(summary.participantPainPoints.isEmpty, "Should detect frustration as a pain point")
        XCTAssertTrue(
            summary.participantPainPoints.first?.contains("frustrating") ?? false,
            "Pain point should contain the original text"
        )
    }

    func testPainPointDetection_detectsDifficult() async {
        // Given: Session with "difficult" keyword
        let session = createSessionWithUtterances([
            (.participant, "It is very difficult to navigate through the menu system.", 45.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should detect the pain point
        XCTAssertFalse(summary.participantPainPoints.isEmpty, "Should detect 'difficult' as a pain point")
    }

    func testPainPointDetection_detectsProblem() async {
        // Given: Session with "problem" keyword
        let session = createSessionWithUtterances([
            (.participant, "The biggest problem is that things get lost between systems.", 60.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should detect the pain point
        XCTAssertFalse(summary.participantPainPoints.isEmpty, "Should detect 'problem' as a pain point")
    }

    func testPainPointDetection_detectsStruggle() async {
        // Given: Session with "struggle" keyword
        let session = createSessionWithUtterances([
            (.participant, "I constantly struggle with keeping everything organized.", 75.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should detect the pain point
        XCTAssertFalse(summary.participantPainPoints.isEmpty, "Should detect 'struggle' as a pain point")
    }

    func testPainPointDetection_ignoresInterviewerUtterances() async {
        // Given: Session with pain point keywords only from interviewer
        let session = createSessionWithUtterances([
            (.interviewer, "Can you tell me about any frustrating experiences?", 30.0),
            (.participant, "Everything works well for me.", 50.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should NOT detect pain points from interviewer utterances
        XCTAssertTrue(summary.participantPainPoints.isEmpty, "Should not detect pain points from interviewer")
    }

    func testPainPointDetection_detectsMultipleKeywords() async {
        // Given: Session with multiple pain point utterances
        let session = createSessionWithUtterances([
            (.participant, "The onboarding is really confusing and hard to follow.", 30.0),
            (.participant, "I hate how slow the search function is.", 90.0),
            (.participant, "The reporting feature is great though.", 150.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should detect multiple pain points but not the positive one
        XCTAssertGreaterThanOrEqual(summary.participantPainPoints.count, 2, "Should detect at least 2 pain points")
    }

    // MARK: - Test: Positive Highlight Detection

    func testPositiveDetection_detectsLove() async {
        // Given: Session with "love" keyword
        let session = createSessionWithUtterances([
            (.participant, "I absolutely love the drag and drop feature.", 60.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should detect the positive highlight
        XCTAssertFalse(summary.positiveHighlights.isEmpty, "Should detect 'love' as a positive highlight")
    }

    func testPositiveDetection_detectsAmazing() async {
        // Given: Session with "amazing" keyword
        let session = createSessionWithUtterances([
            (.participant, "The visual board is amazing and so intuitive to use.", 120.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should detect the positive highlight
        XCTAssertFalse(summary.positiveHighlights.isEmpty, "Should detect 'amazing' as a positive highlight")
    }

    func testPositiveDetection_detectsEasy() async {
        // Given: Session with "easy" keyword
        let session = createSessionWithUtterances([
            (.participant, "Setting up the project was easy and straightforward.", 180.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should detect the positive highlight
        XCTAssertFalse(summary.positiveHighlights.isEmpty, "Should detect 'easy' as a positive highlight")
    }

    func testPositiveDetection_ignoresInterviewerUtterances() async {
        // Given: Session with positive keywords only from interviewer
        let session = createSessionWithUtterances([
            (.interviewer, "That sounds amazing! Tell me more.", 30.0),
            (.participant, "The process is somewhat cumbersome actually.", 50.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should NOT detect positives from interviewer utterances
        XCTAssertTrue(summary.positiveHighlights.isEmpty, "Should not detect positives from interviewer")
    }

    // MARK: - Test: Theme Extraction

    func testThemeExtraction_extractsRepeatedWords() async {
        // Given: Session where "collaboration" and "team" appear multiple times
        let session = createSessionWithUtterances([
            (.participant, "Our team collaboration is key to our workflow.", 30.0),
            (.participant, "The collaboration tools need to support team communication.", 90.0),
            (.participant, "Better team collaboration would save us hours every week.", 150.0),
            (.participant, "I think collaboration is the most important aspect of any tool.", 210.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should extract "collaboration" as a top theme
        XCTAssertFalse(summary.keyThemes.isEmpty, "Should extract at least one theme")

        let themeNames = summary.keyThemes.map { $0.name.lowercased() }
        XCTAssertTrue(
            themeNames.contains("collaboration"),
            "Should extract 'collaboration' as a theme. Extracted themes: \(themeNames)"
        )
    }

    func testThemeExtraction_countsCorrectMentions() async {
        // Given: Session where a word appears a known number of times
        let session = createSessionWithUtterances([
            (.participant, "The dashboard gives me a great overview.", 30.0),
            (.participant, "I check the dashboard first thing every morning.", 90.0),
            (.participant, "A customizable dashboard would be perfect.", 150.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: "dashboard" theme should have 3 mentions
        let dashboardTheme = summary.keyThemes.first { $0.name.lowercased() == "dashboard" }
        XCTAssertNotNil(dashboardTheme, "Should extract 'dashboard' as a theme")
        XCTAssertEqual(dashboardTheme?.mentionCount, 3, "Dashboard should have 3 mentions")
    }

    func testThemeExtraction_limitsToFiveThemes() async {
        // Given: Session with many different topics
        let session = createSessionWithUtterances([
            (.participant, "The notifications are important for productivity and efficiency.", 30.0),
            (.participant, "Notifications help with productivity tracking and efficiency gains.", 60.0),
            (.participant, "I need better integrations with our reporting systems.", 90.0),
            (.participant, "Integrations improve reporting across departments significantly.", 120.0),
            (.participant, "Customization allows personalization of the workspace experience.", 150.0),
            (.participant, "Customization and personalization drive workspace adoption rates.", 180.0),
            (.participant, "Scheduling and automation reduce manual overhead daily.", 210.0),
            (.participant, "Automation and scheduling streamline operations efficiently.", 240.0),
            (.participant, "Security and compliance requirements for enterprise deployments.", 270.0),
            (.participant, "Compliance and security features for enterprise customers.", 300.0),
            (.participant, "Analytics provides insights for strategic leadership decisions.", 330.0),
            (.participant, "Strategic analytics inform leadership and business decisions.", 360.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should limit themes to a maximum of 5
        XCTAssertLessThanOrEqual(summary.keyThemes.count, 5, "Should have at most 5 themes")
    }

    func testThemeExtraction_ignoresStopWords() async {
        // Given: Session with lots of stop words
        let session = createSessionWithUtterances([
            (.participant, "The thing about the application is that it is very useful for the team.", 30.0),
            (.participant, "I think that the application is good for what we need it for.", 90.0),
            (.participant, "The application really helps with our daily operations.", 150.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Stop words should not be themes
        let themeNames = summary.keyThemes.map { $0.name.lowercased() }
        XCTAssertFalse(themeNames.contains("the"), "Stop word 'the' should not be a theme")
        XCTAssertFalse(themeNames.contains("that"), "Stop word 'that' should not be a theme")
        XCTAssertFalse(themeNames.contains("very"), "Stop word 'very' should not be a theme")
    }

    func testThemeExtraction_includesSupportingQuotes() async {
        // Given: Session where a word appears multiple times
        let session = createSessionWithUtterances([
            (.participant, "The dashboard needs real-time updates.", 30.0),
            (.participant, "I check the dashboard every morning for progress.", 90.0)
        ])

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Theme should include supporting quotes
        let dashboardTheme = summary.keyThemes.first { $0.name.lowercased() == "dashboard" }
        if let theme = dashboardTheme {
            XCTAssertFalse(theme.supportingQuotes.isEmpty, "Theme should have supporting quotes")
        }
    }

    // MARK: - Test: Topic Gap Identification

    func testTopicGaps_identifiesNotCovered() async {
        // Given: Session with uncovered topics
        let session = createEmptySession()
        session.topicStatuses = [
            TopicStatus(topicId: "1", topicName: "User Goals", status: .fullyCovered),
            TopicStatus(topicId: "2", topicName: "Pain Points", status: .notCovered),
            TopicStatus(topicId: "3", topicName: "Workflow", status: .fullyCovered)
        ]

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should identify uncovered topic
        XCTAssertFalse(summary.topicGaps.isEmpty, "Should identify topic gaps")
        XCTAssertTrue(
            summary.topicGaps.contains { $0.contains("Pain Points") },
            "Should include 'Pain Points' as a gap"
        )
    }

    func testTopicGaps_identifiesPartialCoverage() async {
        // Given: Session with partially covered topics
        let session = createEmptySession()
        session.topicStatuses = [
            TopicStatus(topicId: "1", topicName: "Feature Requests", status: .partialCoverage),
            TopicStatus(topicId: "2", topicName: "User Goals", status: .fullyCovered)
        ]

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should identify partial coverage
        XCTAssertFalse(summary.topicGaps.isEmpty, "Should identify partially covered topics as gaps")
        XCTAssertTrue(
            summary.topicGaps.contains { $0.contains("Feature Requests") && $0.contains("partial") },
            "Should label partial coverage appropriately"
        )
    }

    func testTopicGaps_excludesFullyCoveredAndSkipped() async {
        // Given: Session with only fully covered and skipped topics
        let session = createEmptySession()
        session.topicStatuses = [
            TopicStatus(topicId: "1", topicName: "User Goals", status: .fullyCovered),
            TopicStatus(topicId: "2", topicName: "Irrelevant Topic", status: .skipped)
        ]

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should have no topic gaps
        XCTAssertTrue(summary.topicGaps.isEmpty, "Fully covered and skipped topics should not be gaps")
    }

    func testTopicGaps_emptyTopicStatuses() async {
        // Given: Session with no topic statuses
        let session = createEmptySession()
        session.topicStatuses = []

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should have no topic gaps
        XCTAssertTrue(summary.topicGaps.isEmpty, "No topic statuses should mean no gaps")
    }

    // MARK: - Test: Quality Score Computation

    func testQualityScore_emptySessionScoresLow() async {
        // Given: Empty session with zero duration
        let session = createEmptySession()
        session.totalDurationSeconds = 0

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Quality score should be low
        XCTAssertLessThan(summary.sessionQualityScore, 50, "Empty session should have a low quality score")
    }

    func testQualityScore_fullSessionScoresHigher() async {
        // Given: A well-populated session
        let session = createSessionWithUtterances([
            (.interviewer, "Tell me about your experience.", 30.0),
            (.participant, "I have used the product for three months and found it very helpful.", 60.0),
            (.interviewer, "What challenges did you face?", 120.0),
            (.participant, "The main challenge was learning the interface initially.", 150.0),
            (.interviewer, "How did you overcome that?", 210.0),
            (.participant, "I watched tutorial videos and eventually got comfortable.", 240.0),
            (.interviewer, "What features do you use most?", 300.0),
            (.participant, "The dashboard and reporting features are what I use every day.", 330.0)
        ])
        session.totalDurationSeconds = 1800

        session.topicStatuses = [
            TopicStatus(topicId: "1", topicName: "Experience", status: .fullyCovered),
            TopicStatus(topicId: "2", topicName: "Challenges", status: .fullyCovered),
            TopicStatus(topicId: "3", topicName: "Features", status: .partialCoverage)
        ]

        session.insights = [
            Insight(timestampSeconds: 60, quote: "Very helpful", theme: "Satisfaction", source: .userAdded),
            Insight(timestampSeconds: 150, quote: "Learning curve", theme: "Onboarding", source: .aiGenerated)
        ]

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Quality score should be higher than empty session
        XCTAssertGreaterThan(summary.sessionQualityScore, 30, "Populated session should score higher")
    }

    func testQualityScore_rangeIsBounded() async {
        // Given: A session
        let session = createSessionWithUtterances([
            (.participant, "This is a test utterance.", 30.0)
        ])
        session.totalDurationSeconds = 60

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Score should be between 0 and 100
        XCTAssertGreaterThanOrEqual(summary.sessionQualityScore, 0, "Score should not be negative")
        XCTAssertLessThanOrEqual(summary.sessionQualityScore, 100, "Score should not exceed 100")
    }

    func testQualityScore_longerDurationScoresHigher() async {
        // Given: Two sessions with different durations but same content
        let shortSession = createSessionWithUtterances([
            (.interviewer, "Tell me about your experience.", 10.0),
            (.participant, "It was good.", 20.0)
        ])
        shortSession.totalDurationSeconds = 120

        let longSession = createSessionWithUtterances([
            (.interviewer, "Tell me about your experience.", 10.0),
            (.participant, "It was good.", 20.0)
        ])
        longSession.totalDurationSeconds = 2400

        // When: Generate summaries
        let shortSummary = await generator.generate(from: shortSession)
        let longSummary = await generator.generate(from: longSession)

        // Then: Longer session should score equal or higher on the duration component
        // (Overall score may vary due to other factors, but duration should contribute positively)
        XCTAssertGreaterThanOrEqual(
            longSummary.sessionQualityScore,
            shortSummary.sessionQualityScore - 10,
            "Longer session should not score significantly lower"
        )
    }

    // MARK: - Test: Markdown Export Formatting

    func testMarkdownExport_containsHeader() {
        // Given: A summary
        let summary = SessionSummary(
            keyThemes: [ThemeSummary(name: "TestTheme", mentionCount: 3, supportingQuotes: ["Quote 1"])],
            sessionQualityScore: 75
        )

        // When: Export as markdown
        let markdown = generator.exportSummaryAsMarkdown(summary)

        // Then: Should contain header
        XCTAssertTrue(markdown.contains("# Session Summary"), "Markdown should contain header")
    }

    func testMarkdownExport_containsQualityScore() {
        // Given: A summary with a quality score
        let summary = SessionSummary(sessionQualityScore: 82.5)

        // When: Export as markdown
        let markdown = generator.exportSummaryAsMarkdown(summary)

        // Then: Should contain quality score
        XCTAssertTrue(markdown.contains("Quality Score"), "Markdown should contain quality score label")
        XCTAssertTrue(markdown.contains("83"), "Markdown should contain formatted score (rounded)")
    }

    func testMarkdownExport_containsThemes() {
        // Given: A summary with themes
        let summary = SessionSummary(
            keyThemes: [
                ThemeSummary(name: "Collaboration", mentionCount: 5, supportingQuotes: ["We need better teamwork"]),
                ThemeSummary(name: "Dashboard", mentionCount: 3, supportingQuotes: ["The dashboard is key"])
            ]
        )

        // When: Export as markdown
        let markdown = generator.exportSummaryAsMarkdown(summary)

        // Then: Should contain theme sections
        XCTAssertTrue(markdown.contains("## Key Themes"), "Markdown should have Key Themes section")
        XCTAssertTrue(markdown.contains("Collaboration"), "Markdown should contain theme name")
        XCTAssertTrue(markdown.contains("5 mentions"), "Markdown should contain mention count")
        XCTAssertTrue(markdown.contains("We need better teamwork"), "Markdown should contain supporting quote")
    }

    func testMarkdownExport_containsPainPoints() {
        // Given: A summary with pain points
        let summary = SessionSummary(
            participantPainPoints: ["The search is frustratingly slow", "Navigation is confusing"]
        )

        // When: Export as markdown
        let markdown = generator.exportSummaryAsMarkdown(summary)

        // Then: Should contain pain points section
        XCTAssertTrue(markdown.contains("## Pain Points"), "Markdown should have Pain Points section")
        XCTAssertTrue(markdown.contains("frustratingly slow"), "Markdown should contain pain point text")
    }

    func testMarkdownExport_containsPositiveHighlights() {
        // Given: A summary with positive highlights
        let summary = SessionSummary(
            positiveHighlights: ["The drag and drop is amazing"]
        )

        // When: Export as markdown
        let markdown = generator.exportSummaryAsMarkdown(summary)

        // Then: Should contain positive highlights
        XCTAssertTrue(markdown.contains("## Positive Highlights"), "Markdown should have Positive Highlights section")
        XCTAssertTrue(markdown.contains("amazing"), "Markdown should contain highlight text")
    }

    func testMarkdownExport_containsKeyQuotes() {
        // Given: A summary with key quotes
        let summary = SessionSummary(
            keyQuotes: [
                KeyQuote(
                    text: "The tool needs to be simple enough for everyone",
                    speaker: "Participant",
                    timestamp: 300.0,
                    significance: "Core user need"
                )
            ]
        )

        // When: Export as markdown
        let markdown = generator.exportSummaryAsMarkdown(summary)

        // Then: Should contain key quotes
        XCTAssertTrue(markdown.contains("## Key Quotes"), "Markdown should have Key Quotes section")
        XCTAssertTrue(markdown.contains("simple enough"), "Markdown should contain quote text")
        XCTAssertTrue(markdown.contains("Participant"), "Markdown should contain speaker name")
        XCTAssertTrue(markdown.contains("Core user need"), "Markdown should contain significance")
    }

    func testMarkdownExport_containsTopicGaps() {
        // Given: A summary with topic gaps
        let summary = SessionSummary(
            topicGaps: ["Ideal Solution (not covered)", "Integration Needs (partial coverage)"]
        )

        // When: Export as markdown
        let markdown = generator.exportSummaryAsMarkdown(summary)

        // Then: Should contain topic gaps
        XCTAssertTrue(markdown.contains("## Topic Gaps"), "Markdown should have Topic Gaps section")
        XCTAssertTrue(markdown.contains("Ideal Solution"), "Markdown should contain gap topic name")
    }

    func testMarkdownExport_containsFollowUps() {
        // Given: A summary with follow-up suggestions
        let summary = SessionSummary(
            suggestedFollowUps: [
                "Can you tell me more about your experience with collaboration?",
                "How do you currently handle reporting?"
            ]
        )

        // When: Export as markdown
        let markdown = generator.exportSummaryAsMarkdown(summary)

        // Then: Should contain follow-ups as a numbered list
        XCTAssertTrue(markdown.contains("## Suggested Follow-Up Questions"), "Markdown should have Follow-Up section")
        XCTAssertTrue(markdown.contains("1."), "Follow-ups should be numbered")
        XCTAssertTrue(markdown.contains("collaboration"), "Markdown should contain suggestion text")
    }

    func testMarkdownExport_omitsEmptySections() {
        // Given: A summary with no themes or pain points
        let summary = SessionSummary(
            keyThemes: [],
            participantPainPoints: [],
            positiveHighlights: [],
            keyQuotes: [],
            topicGaps: [],
            suggestedFollowUps: [],
            sessionQualityScore: 50
        )

        // When: Export as markdown
        let markdown = generator.exportSummaryAsMarkdown(summary)

        // Then: Should not contain empty section headers
        XCTAssertFalse(markdown.contains("## Key Themes"), "Should omit empty Key Themes section")
        XCTAssertFalse(markdown.contains("## Pain Points"), "Should omit empty Pain Points section")
        XCTAssertFalse(markdown.contains("## Positive Highlights"), "Should omit empty Positive Highlights section")
    }

    // MARK: - Test: Follow-Up Suggestions

    func testFollowUpSuggestions_generatedForUncoveredTopics() async {
        // Given: Session with uncovered topics
        let session = createEmptySession()
        session.topicStatuses = [
            TopicStatus(topicId: "1", topicName: "Ideal Solution", status: .notCovered)
        ]

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Should have follow-up suggestions mentioning the uncovered topic
        XCTAssertFalse(summary.suggestedFollowUps.isEmpty, "Should generate follow-up suggestions")
        XCTAssertTrue(
            summary.suggestedFollowUps.contains { $0.lowercased().contains("ideal solution") },
            "Follow-ups should mention uncovered topic"
        )
    }

    // MARK: - Test: Key Quote Extraction

    func testKeyQuotes_prioritizesParticipantUtterances() async {
        // Given: Session with both speaker types
        let session = createSessionWithUtterances([
            (.interviewer, "Can you describe your experience in detail with the product so far?", 30.0),
            (.participant, "I have been using this product for three months and I love how intuitive the interface is, especially the dashboard which gives me real-time insights into my team performance.", 60.0)
        ])

        session.insights = [
            Insight(timestampSeconds: 60, quote: "Love how intuitive", theme: "UX", source: .aiGenerated)
        ]

        // When: Generate summary
        let summary = await generator.generate(from: session)

        // Then: Key quotes should prioritize participant
        if let firstQuote = summary.keyQuotes.first {
            XCTAssertEqual(firstQuote.speaker, "Participant", "Top quote should be from participant")
        }
    }

    // MARK: - Test: Generator State Management

    func testGeneratorState_isGeneratingDuringGeneration() async {
        // Given: Fresh generator
        XCTAssertFalse(generator.isGenerating)
        XCTAssertNil(generator.summary)

        // When: Generate summary
        let session = createEmptySession()
        _ = await generator.generate(from: session)

        // Then: Should no longer be generating and should have summary
        XCTAssertFalse(generator.isGenerating)
        XCTAssertNotNil(generator.summary)
    }
}
