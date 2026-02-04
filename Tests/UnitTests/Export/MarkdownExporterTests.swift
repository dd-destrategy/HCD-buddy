//
//  MarkdownExporterTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E9: Export System
//  Unit tests for MarkdownExporter
//

import XCTest
@testable import HCDInterviewCoach

final class MarkdownExporterTests: XCTestCase {

    var exporter: MarkdownExporter!
    var testSession: Session!

    override func setUp() {
        super.setUp()
        exporter = MarkdownExporter()
        testSession = createTestSession()
    }

    override func tearDown() {
        exporter = nil
        testSession = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestSession() -> Session {
        let session = Session(
            participantName: "Jane Smith",
            projectName: "Mobile App Research",
            sessionMode: .full,
            startedAt: Date().addingTimeInterval(-7200),
            endedAt: Date(),
            totalDurationSeconds: 7200,
            notes: "Conducted user interview about mobile app experience"
        )

        // Add utterances
        let utterances = [
            Utterance(speaker: .interviewer, text: "Welcome to our session.", timestampSeconds: 0, confidence: 0.95),
            Utterance(speaker: .participant, text: "Thank you for inviting me.", timestampSeconds: 3, confidence: 0.92),
            Utterance(speaker: .interviewer, text: "How long have you been using our app?", timestampSeconds: 8, confidence: 0.90),
            Utterance(speaker: .participant, text: "About six months now.", timestampSeconds: 12, confidence: 0.88),
        ]
        session.utterances = utterances

        // Add insights
        let insights = [
            Insight(
                timestampSeconds: 60,
                quote: "The navigation could be more intuitive",
                theme: "Navigation UX",
                source: .aiGenerated,
                tags: ["navigation", "ux", "improvement"]
            ),
            Insight(
                timestampSeconds: 180,
                quote: "I really appreciate the quick load times",
                theme: "Performance Praise",
                source: .userAdded,
                tags: ["performance", "positive"]
            )
        ]
        session.insights = insights

        // Add topic statuses
        let topics = [
            TopicStatus(topicId: "t1", topicName: "First Impressions", status: .fullyCovered),
            TopicStatus(topicId: "t2", topicName: "Daily Usage", status: .partialCoverage),
            TopicStatus(topicId: "t3", topicName: "Pain Points", status: .notCovered),
            TopicStatus(topicId: "t4", topicName: "Competitor Comparison", status: .skipped)
        ]
        session.topicStatuses = topics

        return session
    }

    // MARK: - Basic Export Tests

    func testExportProducesValidMarkdown() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertFalse(markdown.isEmpty)
        XCTAssertTrue(markdown.hasPrefix("# Interview Session:"))
    }

    func testExportContainsSessionTitle() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("# Interview Session: Mobile App Research"))
    }

    // MARK: - Metadata Section Tests

    func testMetadataSectionContainsParticipant() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("| **Participant** | Jane Smith |"))
    }

    func testMetadataSectionContainsDuration() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("| **Duration** | 2:00:00 |"))
    }

    func testMetadataSectionContainsMode() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("| **Mode** | Full |"))
    }

    func testMetadataSectionContainsUtteranceCount() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("| **Utterances** | 4 |"))
    }

    func testMetadataSectionContainsInsightCount() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("| **Insights** | 2 |"))
    }

    // MARK: - Transcript Section Tests

    func testTranscriptSectionExists() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("## Transcript"))
    }

    func testTranscriptContainsSpeakerLabels() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("**Interviewer:**"))
        XCTAssertTrue(markdown.contains("**Participant:**"))
    }

    func testTranscriptContainsTimestamps() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("[00:00]"))
        XCTAssertTrue(markdown.contains("[00:03]"))
        XCTAssertTrue(markdown.contains("[00:08]"))
        XCTAssertTrue(markdown.contains("[00:12]"))
    }

    func testTranscriptContainsAllUtterances() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("Welcome to our session."))
        XCTAssertTrue(markdown.contains("Thank you for inviting me."))
        XCTAssertTrue(markdown.contains("How long have you been using our app?"))
        XCTAssertTrue(markdown.contains("About six months now."))
    }

    func testTranscriptOrdersByTimestamp() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        let welcomeIndex = markdown.range(of: "Welcome to our session")!.lowerBound
        let thankYouIndex = markdown.range(of: "Thank you for inviting")!.lowerBound
        let howLongIndex = markdown.range(of: "How long have you been")!.lowerBound

        XCTAssertTrue(welcomeIndex < thankYouIndex)
        XCTAssertTrue(thankYouIndex < howLongIndex)
    }

    // MARK: - Insights Section Tests

    func testInsightsSectionExists() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("## Key Insights"))
    }

    func testInsightsContainThemes() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("**Navigation UX**"))
        XCTAssertTrue(markdown.contains("**Performance Praise**"))
    }

    func testInsightsContainQuotes() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("> The navigation could be more intuitive"))
        XCTAssertTrue(markdown.contains("> I really appreciate the quick load times"))
    }

    func testInsightsContainTags() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("`navigation`"))
        XCTAssertTrue(markdown.contains("`performance`"))
    }

    func testInsightsContainTimestamps() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("(at 01:00)"))
        XCTAssertTrue(markdown.contains("(at 03:00)"))
    }

    func testInsightsIndicateSource() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("*Source: AI*"))
        XCTAssertTrue(markdown.contains("*Source: Manual*"))
    }

    // MARK: - Topic Coverage Section Tests

    func testTopicCoverageSectionExists() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("## Topic Coverage"))
    }

    func testTopicCoverageContainsAllTopics() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("First Impressions"))
        XCTAssertTrue(markdown.contains("Daily Usage"))
        XCTAssertTrue(markdown.contains("Pain Points"))
        XCTAssertTrue(markdown.contains("Competitor Comparison"))
    }

    func testTopicCoverageContainsStatusNames() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("*Fully Covered*"))
        XCTAssertTrue(markdown.contains("*Partial Coverage*"))
        XCTAssertTrue(markdown.contains("*Not Covered*"))
        XCTAssertTrue(markdown.contains("*Skipped*"))
    }

    // MARK: - Notes Section Tests

    func testNotesSectionExists() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("## Session Notes"))
        XCTAssertTrue(markdown.contains("Conducted user interview about mobile app experience"))
    }

    func testNotesSectionOmittedWhenEmpty() throws {
        // Given
        testSession.notes = nil

        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertFalse(markdown.contains("## Session Notes"))
    }

    // MARK: - Footer Tests

    func testFooterContainsExportInfo() throws {
        // When
        let markdown = try exporter.export(testSession)

        // Then
        XCTAssertTrue(markdown.contains("*Exported from HCD Interview Coach*"))
        XCTAssertTrue(markdown.contains("*Session ID:"))
        XCTAssertTrue(markdown.contains("*Export Date:"))
    }

    // MARK: - Configuration Tests

    func testExportWithoutMetadata() throws {
        // Given
        var config = MarkdownExporter.Configuration.default
        config.includeMetadata = false
        let customExporter = MarkdownExporter(configuration: config)

        // When
        let markdown = try customExporter.export(testSession)

        // Then
        XCTAssertFalse(markdown.contains("| Property | Value |"))
    }

    func testExportWithoutTimestamps() throws {
        // Given
        var config = MarkdownExporter.Configuration.default
        config.includeTimestamps = false
        let customExporter = MarkdownExporter(configuration: config)

        // When
        let markdown = try customExporter.export(testSession)

        // Then
        XCTAssertFalse(markdown.contains("[00:00]"))
        XCTAssertTrue(markdown.contains("**Interviewer:** Welcome to our session."))
    }

    func testExportWithoutTranscript() throws {
        // Given
        var config = MarkdownExporter.Configuration.default
        config.includeTranscript = false
        let customExporter = MarkdownExporter(configuration: config)

        // When
        let markdown = try customExporter.export(testSession)

        // Then
        XCTAssertFalse(markdown.contains("## Transcript"))
        XCTAssertFalse(markdown.contains("Welcome to our session."))
    }

    func testExportWithoutInsights() throws {
        // Given
        var config = MarkdownExporter.Configuration.default
        config.includeInsights = false
        let customExporter = MarkdownExporter(configuration: config)

        // When
        let markdown = try customExporter.export(testSession)

        // Then
        XCTAssertFalse(markdown.contains("## Key Insights"))
    }

    func testExportWithoutTopicCoverage() throws {
        // Given
        var config = MarkdownExporter.Configuration.default
        config.includeTopicCoverage = false
        let customExporter = MarkdownExporter(configuration: config)

        // When
        let markdown = try customExporter.export(testSession)

        // Then
        XCTAssertFalse(markdown.contains("## Topic Coverage"))
    }

    // MARK: - Preview Tests

    func testPreviewIsTruncated() {
        // Given
        // Add many utterances to exceed preview length
        for i in 0..<50 {
            let utterance = Utterance(
                speaker: .interviewer,
                text: "This is utterance number \(i) with some additional text to make it longer.",
                timestampSeconds: Double(i * 10),
                confidence: 0.9
            )
            testSession.utterances.append(utterance)
        }

        // When
        let preview = exporter.preview(testSession)

        // Then
        XCTAssertTrue(preview.count <= 550) // 500 + truncation message
        XCTAssertTrue(preview.contains("[Preview truncated...]"))
    }

    func testShortPreviewNotTruncated() {
        // Given
        testSession.utterances = [
            Utterance(speaker: .interviewer, text: "Short", timestampSeconds: 0)
        ]
        testSession.insights = []
        testSession.topicStatuses = []

        // When
        let preview = exporter.preview(testSession)

        // Then
        XCTAssertFalse(preview.contains("[Preview truncated...]"))
    }

    // MARK: - Word Count Tests

    func testEstimatedWordCount() {
        // When
        let wordCount = exporter.estimatedWordCount(testSession)

        // Then
        XCTAssertGreaterThan(wordCount, 0)
        // Should at least count words from utterances and insights
        XCTAssertGreaterThan(wordCount, 20)
    }
}
