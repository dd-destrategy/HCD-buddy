//
//  ExportViewModelTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E9: Export System
//  Unit tests for ExportViewModel
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class ExportViewModelTests: XCTestCase {

    var viewModel: ExportViewModel!
    var testSession: Session!

    override func setUp() {
        super.setUp()
        testSession = createTestSession()
        viewModel = ExportViewModel(session: testSession)
    }

    override func tearDown() {
        viewModel = nil
        testSession = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestSession() -> Session {
        let session = Session(
            participantName: "Test User",
            projectName: "ViewModel Test Project",
            sessionMode: .full,
            startedAt: Date().addingTimeInterval(-1800),
            endedAt: Date(),
            totalDurationSeconds: 1800
        )

        // Add test utterances
        session.utterances = [
            Utterance(speaker: .interviewer, text: "Test question one", timestampSeconds: 0),
            Utterance(speaker: .participant, text: "Test answer one", timestampSeconds: 5),
            Utterance(speaker: .interviewer, text: "Test question two", timestampSeconds: 10)
        ]

        // Add test insights
        session.insights = [
            Insight(timestampSeconds: 60, quote: "Test insight", theme: "Test Theme", source: .aiGenerated)
        ]

        // Add test topics
        session.topicStatuses = [
            TopicStatus(topicId: "t1", topicName: "Topic 1", status: .fullyCovered),
            TopicStatus(topicId: "t2", topicName: "Topic 2", status: .partialCoverage)
        ]

        return session
    }

    private func createEmptySession() -> Session {
        return Session(
            participantName: "Empty User",
            projectName: "Empty Project",
            sessionMode: .full
        )
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        // Then
        XCTAssertEqual(viewModel.selectedFormat, .markdown)
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertFalse(viewModel.showPreview)
        XCTAssertTrue(viewModel.previewContent.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
        XCTAssertFalse(viewModel.showCopiedFeedback)
        XCTAssertNil(viewModel.lastExportResult)
    }

    // MARK: - Session Statistics Tests

    func testSessionStatistics() {
        // When
        let stats = viewModel.sessionStatistics

        // Then
        XCTAssertEqual(stats.participantName, "Test User")
        XCTAssertEqual(stats.projectName, "ViewModel Test Project")
        XCTAssertEqual(stats.duration, 1800)
        XCTAssertEqual(stats.utteranceCount, 3)
        XCTAssertEqual(stats.insightCount, 1)
        XCTAssertEqual(stats.topicCount, 2)
    }

    func testFormattedDuration() {
        // When
        let stats = viewModel.sessionStatistics

        // Then
        XCTAssertEqual(stats.formattedDuration, "30:00")
    }

    func testTotalItemCount() {
        // When
        let stats = viewModel.sessionStatistics

        // Then
        XCTAssertEqual(stats.totalItemCount, 6) // 3 utterances + 1 insight + 2 topics
    }

    // MARK: - Exportable Content Tests

    func testHasExportableContent() {
        // Then
        XCTAssertTrue(viewModel.hasExportableContent)
    }

    func testHasNoExportableContent() {
        // Given
        let emptySession = createEmptySession()
        let emptyViewModel = ExportViewModel(session: emptySession)

        // Then
        XCTAssertFalse(emptyViewModel.hasExportableContent)
    }

    // MARK: - Suggested Filename Tests

    func testSuggestedFilename() {
        // When
        let filename = viewModel.suggestedFilename

        // Then
        XCTAssertTrue(filename.contains("viewmodel-test-project"))
        XCTAssertTrue(filename.contains("test-user"))
        XCTAssertFalse(filename.contains(" "))
    }

    func testSuggestedFilenameChangesWithFormat() {
        // Given
        viewModel.selectedFormat = .markdown
        let markdownFilename = viewModel.suggestedFilename

        viewModel.selectedFormat = .json
        let jsonFilename = viewModel.suggestedFilename

        // Then - filenames should be the same base name (format is added by save dialog)
        XCTAssertEqual(markdownFilename, jsonFilename)
    }

    // MARK: - Preview Tests

    func testUpdatePreviewWhenNotShowing() {
        // Given
        viewModel.showPreview = false

        // When
        viewModel.updatePreview()

        // Then
        XCTAssertTrue(viewModel.previewContent.isEmpty)
    }

    func testUpdatePreviewMarkdown() {
        // Given
        viewModel.showPreview = true
        viewModel.selectedFormat = .markdown

        // When
        viewModel.updatePreview()

        // Then
        XCTAssertFalse(viewModel.previewContent.isEmpty)
        XCTAssertTrue(viewModel.previewContent.contains("#"))
    }

    func testUpdatePreviewJSON() {
        // Given
        viewModel.showPreview = true
        viewModel.selectedFormat = .json

        // When
        viewModel.updatePreview()

        // Then
        XCTAssertFalse(viewModel.previewContent.isEmpty)
        XCTAssertTrue(viewModel.previewContent.contains("{"))
    }

    // MARK: - Estimated Word Count Tests

    func testEstimatedWordCount() {
        // When
        let wordCount = viewModel.estimatedWordCount

        // Then
        XCTAssertGreaterThan(wordCount, 0)
    }

    // MARK: - Copy to Clipboard Tests

    func testCopyToClipboardSuccess() async {
        // When
        await viewModel.copyToClipboard()

        // Then
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertFalse(viewModel.showError)

        // Check clipboard has content
        let pasteboard = NSPasteboard.general
        let content = pasteboard.string(forType: .string)
        XCTAssertNotNil(content)
        XCTAssertFalse(content!.isEmpty)
    }

    func testCopyToClipboardUpdatesState() async {
        // Given
        XCTAssertFalse(viewModel.isExporting)

        // When - start the copy operation
        let copyTask = Task {
            await viewModel.copyToClipboard()
        }

        // Brief delay to let the task start
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Wait for completion
        await copyTask.value

        // Then
        XCTAssertFalse(viewModel.isExporting)
    }

    // MARK: - Generate Export Content Tests

    func testGenerateExportContentMarkdown() async throws {
        // Given
        viewModel.selectedFormat = .markdown

        // When
        let content = try await viewModel.generateExportContent()

        // Then
        XCTAssertFalse(content.isEmpty)
        XCTAssertTrue(content.contains("# Interview Session:"))
    }

    func testGenerateExportContentJSON() async throws {
        // Given
        viewModel.selectedFormat = .json

        // When
        let content = try await viewModel.generateExportContent()

        // Then
        XCTAssertFalse(content.isEmpty)
        XCTAssertTrue(content.hasPrefix("{"))
    }

    // MARK: - Reset Tests

    func testReset() {
        // Given
        viewModel.selectedFormat = .json
        viewModel.showPreview = true
        viewModel.showError = true
        viewModel.errorMessage = "Test error"

        // When
        viewModel.reset()

        // Then
        XCTAssertEqual(viewModel.selectedFormat, .markdown)
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertFalse(viewModel.showPreview)
        XCTAssertTrue(viewModel.previewContent.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
        XCTAssertFalse(viewModel.showCopiedFeedback)
        XCTAssertNil(viewModel.lastExportResult)
    }

    // MARK: - Format Selection Tests

    func testFormatSelectionUpdatesSelectedFormat() {
        // When
        viewModel.selectedFormat = .json

        // Then
        XCTAssertEqual(viewModel.selectedFormat, .json)

        // When
        viewModel.selectedFormat = .markdown

        // Then
        XCTAssertEqual(viewModel.selectedFormat, .markdown)
    }

    // MARK: - Export Preferences Tests

    func testDefaultExportPreferences() {
        // Given
        let preferences = ExportPreferences.default

        // Then
        XCTAssertEqual(preferences.defaultFormat, .markdown)
        XCTAssertTrue(preferences.includeTimestamps)
        XCTAssertTrue(preferences.includeTopicCoverage)
        XCTAssertTrue(preferences.prettyPrintJSON)
        XCTAssertFalse(preferences.autoOpenAfterExport)
    }

    func testExportPreferencesEncodable() throws {
        // Given
        var preferences = ExportPreferences.default
        preferences.defaultFormat = .json
        preferences.autoOpenAfterExport = true

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(preferences)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ExportPreferences.self, from: data)

        // Then
        XCTAssertEqual(decoded.defaultFormat, .json)
        XCTAssertEqual(decoded.autoOpenAfterExport, true)
    }

    // MARK: - Session Export Info Tests

    func testSessionExportInfoFormattedDurationUnderHour() {
        // Given
        let info = SessionExportInfo(
            participantName: "Test",
            projectName: "Test",
            duration: 1845, // 30:45
            utteranceCount: 0,
            insightCount: 0,
            topicCount: 0
        )

        // Then
        XCTAssertEqual(info.formattedDuration, "30:45")
    }

    func testSessionExportInfoFormattedDurationOverHour() {
        // Given
        let info = SessionExportInfo(
            participantName: "Test",
            projectName: "Test",
            duration: 5432, // 1:30:32
            utteranceCount: 0,
            insightCount: 0,
            topicCount: 0
        )

        // Then
        XCTAssertEqual(info.formattedDuration, "1:30:32")
    }

    // MARK: - Export History Item Tests

    func testExportHistoryItemCreation() {
        // Given
        let statistics = ExportStatistics(
            utteranceCount: 10,
            insightCount: 5,
            topicCount: 3,
            wordCount: 1000,
            characterCount: 5000
        )
        let result = ExportResult(
            format: .markdown,
            fileURL: nil,
            content: "Test content",
            duration: 0.5,
            statistics: statistics
        )

        // When
        let historyItem = ExportHistoryItem(result: result, sessionId: UUID())

        // Then
        XCTAssertNotNil(historyItem.id)
        XCTAssertNotNil(historyItem.sessionId)
        XCTAssertEqual(historyItem.format, .markdown)
        XCTAssertNil(historyItem.fileURL)
        XCTAssertEqual(historyItem.statistics.utteranceCount, 10)
    }
}
