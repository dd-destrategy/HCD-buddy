//
//  ExportServiceTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E9: Export System
//  Unit tests for ExportService
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class ExportServiceTests: XCTestCase {

    var exportService: ExportService!
    var testSession: Session!

    override func setUp() {
        super.setUp()
        exportService = ExportService()
        testSession = createTestSession()
    }

    override func tearDown() {
        exportService = nil
        testSession = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestSession() -> Session {
        let session = Session(
            participantName: "John Doe",
            projectName: "User Research Study",
            sessionMode: .full,
            startedAt: Date().addingTimeInterval(-3600),
            endedAt: Date(),
            totalDurationSeconds: 3600,
            notes: "Test session notes"
        )

        // Add test utterances
        let utterance1 = Utterance(
            speaker: .interviewer,
            text: "Hello, thank you for joining us today.",
            timestampSeconds: 0,
            confidence: 0.95
        )
        let utterance2 = Utterance(
            speaker: .participant,
            text: "Thank you for having me.",
            timestampSeconds: 5,
            confidence: 0.92
        )
        let utterance3 = Utterance(
            speaker: .interviewer,
            text: "Can you tell us about your experience with the product?",
            timestampSeconds: 10,
            confidence: 0.88
        )

        session.utterances = [utterance1, utterance2, utterance3]

        // Add test insights
        let insight1 = Insight(
            timestampSeconds: 120,
            quote: "The onboarding was really confusing",
            theme: "Onboarding Issues",
            source: .aiGenerated,
            tags: ["onboarding", "ux"]
        )
        let insight2 = Insight(
            timestampSeconds: 300,
            quote: "I love the dark mode feature",
            theme: "Feature Appreciation",
            source: .userAdded,
            tags: ["dark-mode", "positive"]
        )

        session.insights = [insight1, insight2]

        // Add test topic statuses
        let topic1 = TopicStatus(
            topicId: "topic-1",
            topicName: "User Background",
            status: .fullyCovered
        )
        let topic2 = TopicStatus(
            topicId: "topic-2",
            topicName: "Pain Points",
            status: .partialCoverage
        )
        let topic3 = TopicStatus(
            topicId: "topic-3",
            topicName: "Feature Requests",
            status: .notCovered
        )

        session.topicStatuses = [topic1, topic2, topic3]

        return session
    }

    private func createEmptySession() -> Session {
        return Session(
            participantName: "Empty User",
            projectName: "Empty Project",
            sessionMode: .full
        )
    }

    // MARK: - Markdown Export Tests

    func testExportToMarkdown() throws {
        // When
        let markdown = try exportService.exportToMarkdown(testSession)

        // Then
        XCTAssertFalse(markdown.isEmpty)
        XCTAssertTrue(markdown.contains("# Interview Session:"))
        XCTAssertTrue(markdown.contains("User Research Study"))
        XCTAssertTrue(markdown.contains("John Doe"))
    }

    func testMarkdownContainsTranscript() throws {
        // When
        let markdown = try exportService.exportToMarkdown(testSession)

        // Then
        XCTAssertTrue(markdown.contains("## Transcript"))
        XCTAssertTrue(markdown.contains("**Interviewer:**"))
        XCTAssertTrue(markdown.contains("**Participant:**"))
        XCTAssertTrue(markdown.contains("Hello, thank you for joining us today."))
    }

    func testMarkdownContainsInsights() throws {
        // When
        let markdown = try exportService.exportToMarkdown(testSession)

        // Then
        XCTAssertTrue(markdown.contains("## Key Insights"))
        XCTAssertTrue(markdown.contains("Onboarding Issues"))
        XCTAssertTrue(markdown.contains("Feature Appreciation"))
    }

    func testMarkdownContainsTopicCoverage() throws {
        // When
        let markdown = try exportService.exportToMarkdown(testSession)

        // Then
        XCTAssertTrue(markdown.contains("## Topic Coverage"))
        XCTAssertTrue(markdown.contains("User Background"))
        XCTAssertTrue(markdown.contains("Pain Points"))
    }

    func testMarkdownContainsTimestamps() throws {
        // When
        let markdown = try exportService.exportToMarkdown(testSession)

        // Then
        XCTAssertTrue(markdown.contains("[00:00]"))
        XCTAssertTrue(markdown.contains("[00:05]"))
        XCTAssertTrue(markdown.contains("[00:10]"))
    }

    func testEmptySessionThrowsError() {
        // Given
        let emptySession = createEmptySession()

        // When/Then
        XCTAssertThrowsError(try exportService.exportToMarkdown(emptySession)) { error in
            XCTAssertEqual(error as? ExportError, .emptySession)
        }
    }

    // MARK: - JSON Export Tests

    func testExportToJSON() throws {
        // When
        let jsonData = try exportService.exportToJSON(testSession)

        // Then
        XCTAssertFalse(jsonData.isEmpty)

        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(json)
    }

    func testJSONContainsSchemaVersion() throws {
        // When
        let jsonData = try exportService.exportToJSON(testSession)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Then
        XCTAssertNotNil(json?["schemaVersion"] as? String)
    }

    func testJSONContainsSessionData() throws {
        // When
        let jsonData = try exportService.exportToJSON(testSession)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Then
        let session = json?["session"] as? [String: Any]
        XCTAssertNotNil(session)
        XCTAssertEqual(session?["projectName"] as? String, "User Research Study")
        XCTAssertEqual(session?["participantName"] as? String, "John Doe")
    }

    func testJSONContainsTranscript() throws {
        // When
        let jsonData = try exportService.exportToJSON(testSession)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Then
        let transcript = json?["transcript"] as? [[String: Any]]
        XCTAssertNotNil(transcript)
        XCTAssertEqual(transcript?.count, 3)
    }

    func testJSONContainsInsights() throws {
        // When
        let jsonData = try exportService.exportToJSON(testSession)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Then
        let insights = json?["insights"] as? [[String: Any]]
        XCTAssertNotNil(insights)
        XCTAssertEqual(insights?.count, 2)
    }

    func testJSONContainsTopicCoverage() throws {
        // When
        let jsonData = try exportService.exportToJSON(testSession)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Then
        let topicCoverage = json?["topicCoverage"] as? [[String: Any]]
        XCTAssertNotNil(topicCoverage)
        XCTAssertEqual(topicCoverage?.count, 3)
    }

    func testJSONContainsMetadata() throws {
        // When
        let jsonData = try exportService.exportToJSON(testSession)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Then
        let metadata = json?["metadata"] as? [String: Any]
        XCTAssertNotNil(metadata)
        XCTAssertEqual(metadata?["appName"] as? String, "HCD Interview Coach")
        XCTAssertEqual(metadata?["exportFormat"] as? String, "JSON")
    }

    func testEmptySessionJSONThrowsError() {
        // Given
        let emptySession = createEmptySession()

        // When/Then
        XCTAssertThrowsError(try exportService.exportToJSON(emptySession)) { error in
            XCTAssertEqual(error as? ExportError, .emptySession)
        }
    }

    // MARK: - Suggested Filename Tests

    func testSuggestedFilenameFormat() {
        // When
        let filename = exportService.suggestedFilename(for: testSession, format: .markdown)

        // Then
        XCTAssertTrue(filename.contains("user-research-study"))
        XCTAssertTrue(filename.contains("john-doe"))
        XCTAssertFalse(filename.contains(" "))
        XCTAssertFalse(filename.hasSuffix(".md")) // Extension should not be included
    }

    func testSuggestedFilenameForJSON() {
        // When
        let filename = exportService.suggestedFilename(for: testSession, format: .json)

        // Then
        XCTAssertTrue(filename.contains("user-research-study"))
        XCTAssertFalse(filename.hasSuffix(".json")) // Extension should not be included
    }

    // MARK: - Clipboard Tests

    func testCopyToClipboard() {
        // Given
        let testContent = "Test content for clipboard"

        // When
        exportService.copyToClipboard(testContent)

        // Then
        let pasteboard = NSPasteboard.general
        let clipboardContent = pasteboard.string(forType: .string)
        XCTAssertEqual(clipboardContent, testContent)
    }

    // MARK: - Export Format Tests

    func testExportFormatFileExtensions() {
        XCTAssertEqual(ExportFormat.markdown.fileExtension, "md")
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
    }

    func testExportFormatDescriptions() {
        XCTAssertFalse(ExportFormat.markdown.description.isEmpty)
        XCTAssertFalse(ExportFormat.json.description.isEmpty)
    }

    func testExportFormatIcons() {
        XCTAssertEqual(ExportFormat.markdown.icon, "doc.richtext")
        XCTAssertEqual(ExportFormat.json.icon, "curlybraces")
    }
}
