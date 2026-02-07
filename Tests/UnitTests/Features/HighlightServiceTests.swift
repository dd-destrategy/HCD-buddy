//
//  HighlightServiceTests.swift
//  HCD Interview Coach Tests
//
//  FEATURE E: Highlight Reel & Quote Library
//  Unit tests for HighlightService CRUD operations, queries, filtering,
//  star management, export, statistics, and persistence.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class HighlightServiceTests: XCTestCase {

    // MARK: - Properties

    var highlightService: HighlightService!
    var tempDirectory: URL!
    var storageURL: URL!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HighlightServiceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storageURL = tempDirectory.appendingPathComponent("highlights.json")
        highlightService = HighlightService(storageURL: storageURL)
    }

    override func tearDown() {
        highlightService = nil
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        storageURL = nil
        super.tearDown()
    }

    // MARK: - Test: Create Highlight

    func testCreateHighlight_addsToHighlightsArray() {
        // Given: Empty highlights
        XCTAssertEqual(highlightService.highlights.count, 0)

        // When: Creating a highlight
        let highlight = highlightService.createHighlight(
            title: "Test Highlight",
            quoteText: "This is a test quote",
            speaker: "Participant",
            category: .painPoint,
            notes: "Test notes",
            utteranceId: UUID(),
            sessionId: UUID(),
            timestampSeconds: 60
        )

        // Then: Highlight should be in the array
        XCTAssertEqual(highlightService.highlights.count, 1)
        XCTAssertEqual(highlight.title, "Test Highlight")
        XCTAssertEqual(highlight.quoteText, "This is a test quote")
        XCTAssertEqual(highlight.speaker, "Participant")
        XCTAssertEqual(highlight.category, .painPoint)
        XCTAssertEqual(highlight.notes, "Test notes")
    }

    func testCreateHighlight_generatesUniqueId() {
        // When: Creating two highlights
        let h1 = highlightService.createHighlight(
            title: "First", quoteText: "Quote 1", speaker: "Participant",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        let h2 = highlightService.createHighlight(
            title: "Second", quoteText: "Quote 2", speaker: "Interviewer",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // Then: IDs should differ
        XCTAssertNotEqual(h1.id, h2.id)
    }

    func testCreateHighlight_setsDefaultValues() {
        // When: Creating with minimal parameters
        let highlight = highlightService.createHighlight(
            title: "Minimal",
            quoteText: "Some text",
            speaker: "Participant",
            utteranceId: UUID(),
            sessionId: UUID(),
            timestampSeconds: 0
        )

        // Then: Defaults should be set
        XCTAssertEqual(highlight.category, .uncategorized)
        XCTAssertEqual(highlight.notes, "")
        XCTAssertFalse(highlight.isStarred)
    }

    func testCreateHighlight_setsTimestamps() {
        // When: Creating a highlight
        let before = Date()
        let highlight = highlightService.createHighlight(
            title: "Timed", quoteText: "Quote", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )
        let after = Date()

        // Then: Timestamps should be approximately now
        XCTAssertGreaterThanOrEqual(highlight.createdAt, before)
        XCTAssertLessThanOrEqual(highlight.createdAt, after)
        XCTAssertGreaterThanOrEqual(highlight.updatedAt, before)
        XCTAssertLessThanOrEqual(highlight.updatedAt, after)
    }

    func testCreateHighlight_storesUtteranceAndSessionIds() {
        // Given: Specific IDs
        let utteranceId = UUID()
        let sessionId = UUID()

        // When: Creating
        let highlight = highlightService.createHighlight(
            title: "IDs", quoteText: "Quote", speaker: "P",
            utteranceId: utteranceId, sessionId: sessionId, timestampSeconds: 100
        )

        // Then: IDs should match
        XCTAssertEqual(highlight.utteranceId, utteranceId)
        XCTAssertEqual(highlight.sessionId, sessionId)
        XCTAssertEqual(highlight.timestampSeconds, 100)
    }

    // MARK: - Test: Update Highlight

    func testUpdateHighlight_updatesTitle() {
        // Given: A highlight
        let highlight = highlightService.createHighlight(
            title: "Original", quoteText: "Quote", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )

        // When: Updating the title
        highlightService.updateHighlight(highlight.id, title: "Updated Title")

        // Then: Title should be updated, other fields unchanged
        let updated = highlightService.highlights.first { $0.id == highlight.id }
        XCTAssertEqual(updated?.title, "Updated Title")
        XCTAssertEqual(updated?.category, .uncategorized)
        XCTAssertEqual(updated?.notes, "")
    }

    func testUpdateHighlight_updatesCategory() {
        // Given: A highlight
        let highlight = highlightService.createHighlight(
            title: "Cat", quoteText: "Quote", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )

        // When: Updating the category
        highlightService.updateHighlight(highlight.id, category: .delight)

        // Then: Category should be updated
        let updated = highlightService.highlights.first { $0.id == highlight.id }
        XCTAssertEqual(updated?.category, .delight)
        XCTAssertEqual(updated?.title, "Cat")
    }

    func testUpdateHighlight_updatesNotes() {
        // Given: A highlight
        let highlight = highlightService.createHighlight(
            title: "Notes", quoteText: "Quote", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )

        // When: Updating the notes
        highlightService.updateHighlight(highlight.id, notes: "New notes here")

        // Then: Notes should be updated
        let updated = highlightService.highlights.first { $0.id == highlight.id }
        XCTAssertEqual(updated?.notes, "New notes here")
    }

    func testUpdateHighlight_updatesStar() {
        // Given: A highlight
        let highlight = highlightService.createHighlight(
            title: "Star", quoteText: "Quote", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )
        XCTAssertFalse(highlight.isStarred)

        // When: Updating the star
        highlightService.updateHighlight(highlight.id, isStarred: true)

        // Then: Star should be updated
        let updated = highlightService.highlights.first { $0.id == highlight.id }
        XCTAssertEqual(updated?.isStarred, true)
    }

    func testUpdateHighlight_updatesMultipleFields() {
        // Given: A highlight
        let highlight = highlightService.createHighlight(
            title: "Multi", quoteText: "Quote", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )

        // When: Updating multiple fields
        highlightService.updateHighlight(
            highlight.id,
            title: "New Title",
            category: .featureRequest,
            notes: "New notes",
            isStarred: true
        )

        // Then: All fields should be updated
        let updated = highlightService.highlights.first { $0.id == highlight.id }
        XCTAssertEqual(updated?.title, "New Title")
        XCTAssertEqual(updated?.category, .featureRequest)
        XCTAssertEqual(updated?.notes, "New notes")
        XCTAssertEqual(updated?.isStarred, true)
    }

    func testUpdateHighlight_updatesUpdatedAt() {
        // Given: A highlight
        let highlight = highlightService.createHighlight(
            title: "Time", quoteText: "Quote", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )
        let originalUpdatedAt = highlight.updatedAt

        // Small delay to ensure different timestamp
        Thread.sleep(forTimeInterval: 0.01)

        // When: Updating
        highlightService.updateHighlight(highlight.id, title: "New")

        // Then: updatedAt should be newer
        let updated = highlightService.highlights.first { $0.id == highlight.id }
        XCTAssertNotNil(updated)
        XCTAssertGreaterThan(updated!.updatedAt, originalUpdatedAt)
    }

    func testUpdateHighlight_nonExistentId_doesNothing() {
        // Given: A highlight
        highlightService.createHighlight(
            title: "Existing", quoteText: "Quote", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )

        // When: Updating a non-existent ID
        highlightService.updateHighlight(UUID(), title: "Ghost")

        // Then: Existing highlight should be unchanged
        XCTAssertEqual(highlightService.highlights.count, 1)
        XCTAssertEqual(highlightService.highlights.first?.title, "Existing")
    }

    // MARK: - Test: Delete Highlight

    func testDeleteHighlight_removesFromArray() {
        // Given: A highlight
        let highlight = highlightService.createHighlight(
            title: "To Delete", quoteText: "Quote", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )
        XCTAssertEqual(highlightService.highlights.count, 1)

        // When: Deleting
        highlightService.deleteHighlight(highlight.id)

        // Then: Should be empty
        XCTAssertEqual(highlightService.highlights.count, 0)
    }

    func testDeleteHighlight_removesOnlyTarget() {
        // Given: Multiple highlights
        let h1 = highlightService.createHighlight(
            title: "Keep", quoteText: "Quote 1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        let h2 = highlightService.createHighlight(
            title: "Delete Me", quoteText: "Quote 2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )
        XCTAssertEqual(highlightService.highlights.count, 2)

        // When: Deleting one
        highlightService.deleteHighlight(h2.id)

        // Then: Only the target should be removed
        XCTAssertEqual(highlightService.highlights.count, 1)
        XCTAssertEqual(highlightService.highlights.first?.id, h1.id)
    }

    func testDeleteHighlight_nonExistentId_doesNothing() {
        // Given: A highlight
        highlightService.createHighlight(
            title: "Safe", quoteText: "Quote", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )

        // When: Deleting a non-existent ID
        highlightService.deleteHighlight(UUID())

        // Then: No change
        XCTAssertEqual(highlightService.highlights.count, 1)
    }

    // MARK: - Test: Highlights for Session

    func testHighlightsForSession_filtersCorrectly() {
        // Given: Highlights in different sessions
        let session1 = UUID()
        let session2 = UUID()

        highlightService.createHighlight(
            title: "Session 1 H1", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: session1, timestampSeconds: 30
        )
        highlightService.createHighlight(
            title: "Session 1 H2", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: session1, timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "Session 2 H1", quoteText: "Q3", speaker: "P",
            utteranceId: UUID(), sessionId: session2, timestampSeconds: 20
        )

        // When: Getting highlights for session 1
        let result = highlightService.highlights(for: session1)

        // Then: Should return only session 1 highlights, sorted by timestamp
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.sessionId == session1 })
        XCTAssertEqual(result[0].timestampSeconds, 10) // Sorted by timestamp ascending
        XCTAssertEqual(result[1].timestampSeconds, 30)
    }

    func testHighlightsForSession_emptyResult() {
        // Given: No highlights for a session
        let emptySessionId = UUID()

        // When: Querying
        let result = highlightService.highlights(for: emptySessionId)

        // Then: Should be empty
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Test: Starred Highlights

    func testStarredHighlights_returnsOnlyStarred() {
        // Given: Mix of starred and unstarred
        let h1 = highlightService.createHighlight(
            title: "Starred 1", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "Not Starred", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )
        let h3 = highlightService.createHighlight(
            title: "Starred 2", quoteText: "Q3", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 30
        )

        highlightService.toggleStar(h1.id)
        highlightService.toggleStar(h3.id)

        // When: Getting starred highlights
        let result = highlightService.starredHighlights()

        // Then: Should return only starred ones
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.isStarred })
    }

    // MARK: - Test: Highlights in Category

    func testHighlightsInCategory_filtersCorrectly() {
        // Given: Highlights in different categories
        highlightService.createHighlight(
            title: "Pain 1", quoteText: "Q1", speaker: "P", category: .painPoint,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "Delight", quoteText: "Q2", speaker: "P", category: .delight,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )
        highlightService.createHighlight(
            title: "Pain 2", quoteText: "Q3", speaker: "P", category: .painPoint,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 30
        )

        // When: Getting pain point highlights
        let result = highlightService.highlights(in: .painPoint)

        // Then: Should return only pain points
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.category == .painPoint })
    }

    // MARK: - Test: Search Highlights

    func testSearchHighlights_matchesTitle() {
        // Given: Highlights with different titles
        highlightService.createHighlight(
            title: "Navigation Problem", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "Good Experience", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // When: Searching by title
        let result = highlightService.searchHighlights(query: "navigation")

        // Then: Should match
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Navigation Problem")
    }

    func testSearchHighlights_matchesQuoteText() {
        // Given: Highlights
        highlightService.createHighlight(
            title: "H1", quoteText: "I love the dashboard feature", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "The settings page is confusing", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // When: Searching by quote text
        let result = highlightService.searchHighlights(query: "dashboard")

        // Then: Should match
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "H1")
    }

    func testSearchHighlights_matchesNotes() {
        // Given: Highlights with notes
        highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "P",
            category: .painPoint, notes: "Related to onboarding flow",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "Q2", speaker: "P",
            category: .delight, notes: "Liked the color scheme",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // When: Searching notes
        let result = highlightService.searchHighlights(query: "onboarding")

        // Then: Should match
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "H1")
    }

    func testSearchHighlights_matchesSpeaker() {
        // Given: Highlights with different speakers
        highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "Participant",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "Q2", speaker: "Interviewer",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // When: Searching by speaker
        let result = highlightService.searchHighlights(query: "interviewer")

        // Then: Should match
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "H2")
    }

    func testSearchHighlights_caseInsensitive() {
        // Given: A highlight
        highlightService.createHighlight(
            title: "Important Finding", quoteText: "Q", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )

        // When: Searching with different cases
        let upper = highlightService.searchHighlights(query: "IMPORTANT")
        let lower = highlightService.searchHighlights(query: "important")
        let mixed = highlightService.searchHighlights(query: "ImPoRtAnT")

        // Then: All should match
        XCTAssertEqual(upper.count, 1)
        XCTAssertEqual(lower.count, 1)
        XCTAssertEqual(mixed.count, 1)
    }

    func testSearchHighlights_partialMatch() {
        // Given: A highlight
        highlightService.createHighlight(
            title: "Navigation Problem", quoteText: "Q", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )

        // When: Searching with partial text
        let result = highlightService.searchHighlights(query: "nav")

        // Then: Should match
        XCTAssertEqual(result.count, 1)
    }

    func testSearchHighlights_emptyQuery_returnsAll() {
        // Given: Multiple highlights
        highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // When: Searching with empty query
        let result = highlightService.searchHighlights(query: "")

        // Then: Should return all
        XCTAssertEqual(result.count, 2)
    }

    func testSearchHighlights_whitespaceOnlyQuery_returnsAll() {
        // Given: A highlight
        highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )

        // When: Searching with whitespace
        let result = highlightService.searchHighlights(query: "   ")

        // Then: Should return all
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - Test: Filtered Highlights (Combined Filters)

    func testFilteredHighlights_searchOnly() {
        // Given: Highlights
        highlightService.createHighlight(
            title: "Alpha", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "Beta", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // When: Setting search query
        highlightService.searchQuery = "alpha"

        // Then: Should filter
        XCTAssertEqual(highlightService.filteredHighlights.count, 1)
        XCTAssertEqual(highlightService.filteredHighlights.first?.title, "Alpha")
    }

    func testFilteredHighlights_categoryOnly() {
        // Given: Highlights in different categories
        highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "P", category: .painPoint,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "Q2", speaker: "P", category: .delight,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // When: Filtering by category
        highlightService.selectedCategory = .delight

        // Then: Should filter
        XCTAssertEqual(highlightService.filteredHighlights.count, 1)
        XCTAssertEqual(highlightService.filteredHighlights.first?.category, .delight)
    }

    func testFilteredHighlights_starredOnly() {
        // Given: Mix of starred and unstarred
        let h1 = highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )
        highlightService.toggleStar(h1.id)

        // When: Showing starred only
        highlightService.showStarredOnly = true

        // Then: Should filter
        XCTAssertEqual(highlightService.filteredHighlights.count, 1)
        XCTAssertTrue(highlightService.filteredHighlights.first!.isStarred)
    }

    func testFilteredHighlights_combinedFilters() {
        // Given: Various highlights
        let sessionId = UUID()
        let h1 = highlightService.createHighlight(
            title: "Nav Pain", quoteText: "Q1", speaker: "P", category: .painPoint,
            utteranceId: UUID(), sessionId: sessionId, timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "Nav Delight", quoteText: "Q2", speaker: "P", category: .delight,
            utteranceId: UUID(), sessionId: sessionId, timestampSeconds: 20
        )
        let h3 = highlightService.createHighlight(
            title: "Nav Pain Starred", quoteText: "Q3", speaker: "P", category: .painPoint,
            utteranceId: UUID(), sessionId: sessionId, timestampSeconds: 30
        )

        highlightService.toggleStar(h1.id)
        highlightService.toggleStar(h3.id)

        // When: Combining search + category + star
        highlightService.searchQuery = "Nav"
        highlightService.selectedCategory = .painPoint
        highlightService.showStarredOnly = true

        // Then: Should match only the starred pain point with "Nav" in title
        XCTAssertEqual(highlightService.filteredHighlights.count, 2)
        XCTAssertTrue(highlightService.filteredHighlights.allSatisfy { $0.isStarred })
        XCTAssertTrue(highlightService.filteredHighlights.allSatisfy { $0.category == .painPoint })
    }

    // MARK: - Test: Toggle Star

    func testToggleStar_starsUnstarred() {
        // Given: An unstarred highlight
        let highlight = highlightService.createHighlight(
            title: "Unstarred", quoteText: "Q", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )
        XCTAssertFalse(highlight.isStarred)

        // When: Toggling
        highlightService.toggleStar(highlight.id)

        // Then: Should be starred
        let updated = highlightService.highlights.first { $0.id == highlight.id }
        XCTAssertTrue(updated!.isStarred)
    }

    func testToggleStar_unstarsStarred() {
        // Given: A starred highlight
        let highlight = highlightService.createHighlight(
            title: "Starred", quoteText: "Q", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )
        highlightService.toggleStar(highlight.id)
        XCTAssertTrue(highlightService.highlights.first { $0.id == highlight.id }!.isStarred)

        // When: Toggling again
        highlightService.toggleStar(highlight.id)

        // Then: Should be unstarred
        let updated = highlightService.highlights.first { $0.id == highlight.id }
        XCTAssertFalse(updated!.isStarred)
    }

    func testToggleStar_nonExistentId_doesNothing() {
        // Given: A highlight
        highlightService.createHighlight(
            title: "Safe", quoteText: "Q", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )

        // When: Toggling a non-existent ID
        highlightService.toggleStar(UUID())

        // Then: Existing highlight unchanged
        XCTAssertFalse(highlightService.highlights.first!.isStarred)
    }

    // MARK: - Test: Export as Markdown

    func testExportAsMarkdown_emptyHighlights() {
        // Given: No highlights

        // When: Exporting
        let markdown = highlightService.exportAsMarkdown()

        // Then: Should have header and empty message
        XCTAssertTrue(markdown.contains("# Highlight Reel"))
        XCTAssertTrue(markdown.contains("No highlights found"))
    }

    func testExportAsMarkdown_includesHighlightContent() {
        // Given: A highlight
        let highlight = highlightService.createHighlight(
            title: "Key Finding",
            quoteText: "The menu is really confusing",
            speaker: "Participant",
            category: .painPoint,
            notes: "Observed frustration",
            utteranceId: UUID(),
            sessionId: UUID(),
            timestampSeconds: 125
        )
        highlightService.toggleStar(highlight.id)

        // When: Exporting
        let markdown = highlightService.exportAsMarkdown()

        // Then: Should contain all relevant information
        XCTAssertTrue(markdown.contains("# Highlight Reel"))
        XCTAssertTrue(markdown.contains("## Pain Point"))
        XCTAssertTrue(markdown.contains("### Key Finding"))
        XCTAssertTrue(markdown.contains("The menu is really confusing"))
        XCTAssertTrue(markdown.contains("Participant"))
        XCTAssertTrue(markdown.contains("02:05"))
        XCTAssertTrue(markdown.contains("Observed frustration"))
        XCTAssertTrue(markdown.contains("\u{2B50}")) // Star emoji
    }

    func testExportAsMarkdown_groupsByCategory() {
        // Given: Highlights in different categories
        highlightService.createHighlight(
            title: "Pain", quoteText: "Q1", speaker: "P", category: .painPoint,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "Joy", quoteText: "Q2", speaker: "P", category: .delight,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // When: Exporting
        let markdown = highlightService.exportAsMarkdown()

        // Then: Should have both category headers
        XCTAssertTrue(markdown.contains("## Pain Point"))
        XCTAssertTrue(markdown.contains("## Delight"))
    }

    func testExportAsMarkdown_filtersBySession() {
        // Given: Highlights in different sessions
        let session1 = UUID()
        let session2 = UUID()
        highlightService.createHighlight(
            title: "In Session 1", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: session1, timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "In Session 2", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: session2, timestampSeconds: 20
        )

        // When: Exporting for session 1 only
        let markdown = highlightService.exportAsMarkdown(sessionId: session1)

        // Then: Should only include session 1
        XCTAssertTrue(markdown.contains("In Session 1"))
        XCTAssertFalse(markdown.contains("In Session 2"))
        XCTAssertTrue(markdown.contains("Total: 1 highlight(s)"))
    }

    func testExportAsMarkdown_unstarredNoStarMarker() {
        // Given: An unstarred highlight
        highlightService.createHighlight(
            title: "No Star", quoteText: "Q", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )

        // When: Exporting
        let markdown = highlightService.exportAsMarkdown()

        // Then: Should NOT contain star emoji
        XCTAssertFalse(markdown.contains("\u{2B50}"))
    }

    // MARK: - Test: Export Starred as Markdown

    func testExportStarredAsMarkdown_empty() {
        // Given: No starred highlights

        // When: Exporting starred
        let markdown = highlightService.exportStarredAsMarkdown()

        // Then: Should show empty message
        XCTAssertTrue(markdown.contains("# Starred Highlights"))
        XCTAssertTrue(markdown.contains("No starred highlights found"))
    }

    func testExportStarredAsMarkdown_includesOnlyStarred() {
        // Given: Mix of starred and unstarred
        let h1 = highlightService.createHighlight(
            title: "Starred One", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "Not Starred", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )
        highlightService.toggleStar(h1.id)

        // When: Exporting starred
        let markdown = highlightService.exportStarredAsMarkdown()

        // Then: Should include only starred
        XCTAssertTrue(markdown.contains("Starred One"))
        XCTAssertFalse(markdown.contains("Not Starred"))
    }

    // MARK: - Test: Count by Category

    func testCountByCategory_returnsCorrectCounts() {
        // Given: Highlights in various categories
        highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "P", category: .painPoint,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "Q2", speaker: "P", category: .painPoint,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )
        highlightService.createHighlight(
            title: "H3", quoteText: "Q3", speaker: "P", category: .delight,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 30
        )
        highlightService.createHighlight(
            title: "H4", quoteText: "Q4", speaker: "P", category: .workaround,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 40
        )

        // When: Getting counts
        let counts = highlightService.countByCategory()

        // Then: Should have correct counts
        XCTAssertEqual(counts[.painPoint], 2)
        XCTAssertEqual(counts[.delight], 1)
        XCTAssertEqual(counts[.workaround], 1)
        XCTAssertNil(counts[.featureRequest])
        XCTAssertNil(counts[.keyQuote])
    }

    // MARK: - Test: Statistics

    func testTotalCount() {
        // Given: Empty service
        XCTAssertEqual(highlightService.totalCount, 0)

        // When: Adding highlights
        highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // Then: Count should match
        XCTAssertEqual(highlightService.totalCount, 2)
    }

    func testStarredCount() {
        // Given: Highlights
        let h1 = highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        XCTAssertEqual(highlightService.starredCount, 0)

        // When: Starring one
        highlightService.toggleStar(h1.id)

        // Then: Starred count should be 1
        XCTAssertEqual(highlightService.starredCount, 1)
    }

    // MARK: - Test: Persistence Round-Trip

    func testPersistence_saveAndReload() {
        // Given: Highlights
        let utteranceId = UUID()
        let sessionId = UUID()
        let highlight = highlightService.createHighlight(
            title: "Persisted",
            quoteText: "This should persist",
            speaker: "Participant",
            category: .userNeed,
            notes: "Important finding",
            utteranceId: utteranceId,
            sessionId: sessionId,
            timestampSeconds: 90
        )
        highlightService.toggleStar(highlight.id)

        // When: Creating a new service from the same file
        let reloaded = HighlightService(storageURL: storageURL)

        // Then: Data should persist
        XCTAssertEqual(reloaded.highlights.count, 1)
        let found = reloaded.highlights.first { $0.id == highlight.id }
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.title, "Persisted")
        XCTAssertEqual(found?.quoteText, "This should persist")
        XCTAssertEqual(found?.speaker, "Participant")
        XCTAssertEqual(found?.category, .userNeed)
        XCTAssertEqual(found?.notes, "Important finding")
        XCTAssertEqual(found?.isStarred, true)
        XCTAssertEqual(found?.utteranceId, utteranceId)
        XCTAssertEqual(found?.sessionId, sessionId)
        XCTAssertEqual(found?.timestampSeconds, 90)
    }

    func testPersistence_multipleHighlights() {
        // Given: Multiple highlights
        highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "P", category: .painPoint,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "Q2", speaker: "I", category: .delight,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )
        highlightService.createHighlight(
            title: "H3", quoteText: "Q3", speaker: "P", category: .workaround,
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 30
        )

        // When: Reloading
        let reloaded = HighlightService(storageURL: storageURL)

        // Then: All should be present
        XCTAssertEqual(reloaded.highlights.count, 3)
    }

    func testPersistence_corruptedFile_loadsEmpty() throws {
        // Given: A corrupted file
        let corruptData = "not json at all".data(using: .utf8)!
        try corruptData.write(to: storageURL)

        // When: Loading
        let service = HighlightService(storageURL: storageURL)

        // Then: Should be empty (graceful degradation)
        XCTAssertEqual(service.highlights.count, 0)
    }

    func testPersistence_noFile_loadsEmpty() {
        // Given: A new storage URL with no existing file
        let newURL = tempDirectory.appendingPathComponent("nonexistent.json")

        // When: Loading
        let service = HighlightService(storageURL: newURL)

        // Then: Should be empty
        XCTAssertEqual(service.highlights.count, 0)
    }

    func testPersistence_deleteAndReload() {
        // Given: Highlights that are then deleted
        let h1 = highlightService.createHighlight(
            title: "H1", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        highlightService.createHighlight(
            title: "H2", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )
        highlightService.deleteHighlight(h1.id)

        // When: Reloading
        let reloaded = HighlightService(storageURL: storageURL)

        // Then: Deleted highlight should not be present
        XCTAssertEqual(reloaded.highlights.count, 1)
        XCTAssertEqual(reloaded.highlights.first?.title, "H2")
    }

    // MARK: - Test: Highlight Model

    func testHighlight_formattedTimestamp() {
        // Given: Various timestamps
        let h1 = Highlight(
            title: "T", quoteText: "Q", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 0
        )
        let h2 = Highlight(
            title: "T", quoteText: "Q", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 65
        )
        let h3 = Highlight(
            title: "T", quoteText: "Q", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 3661
        )

        // Then: Should format correctly
        XCTAssertEqual(h1.formattedTimestamp, "00:00")
        XCTAssertEqual(h2.formattedTimestamp, "01:05")
        XCTAssertEqual(h3.formattedTimestamp, "61:01")
    }

    func testHighlight_equalityBasedOnId() {
        // Given: Two highlights with different data but same ID
        let sharedId = UUID()
        let h1 = Highlight(
            id: sharedId, title: "Title A", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        let h2 = Highlight(
            id: sharedId, title: "Title B", quoteText: "Q2", speaker: "I",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )

        // Then: Should be equal (based on ID)
        XCTAssertEqual(h1, h2)
    }

    func testHighlight_inequalityBasedOnId() {
        // Given: Two highlights with same data but different IDs
        let h1 = Highlight(
            title: "Same", quoteText: "Same", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        let h2 = Highlight(
            title: "Same", quoteText: "Same", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )

        // Then: Should not be equal (different IDs)
        XCTAssertNotEqual(h1, h2)
    }

    func testHighlight_codable_roundTrip() throws {
        // Given: A highlight with all fields populated
        let highlight = Highlight(
            title: "Codable Test",
            quoteText: "This is a test quote",
            speaker: "Participant",
            category: .featureRequest,
            notes: "Some notes",
            isStarred: true,
            utteranceId: UUID(),
            sessionId: UUID(),
            timestampSeconds: 145
        )

        // When: Encoding and decoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(highlight)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Highlight.self, from: data)

        // Then: All fields should match
        XCTAssertEqual(decoded.id, highlight.id)
        XCTAssertEqual(decoded.title, highlight.title)
        XCTAssertEqual(decoded.quoteText, highlight.quoteText)
        XCTAssertEqual(decoded.speaker, highlight.speaker)
        XCTAssertEqual(decoded.category, highlight.category)
        XCTAssertEqual(decoded.notes, highlight.notes)
        XCTAssertEqual(decoded.isStarred, highlight.isStarred)
        XCTAssertEqual(decoded.utteranceId, highlight.utteranceId)
        XCTAssertEqual(decoded.sessionId, highlight.sessionId)
        XCTAssertEqual(decoded.timestampSeconds, highlight.timestampSeconds)
    }

    func testHighlight_hashable() {
        // Given: Two highlights
        let h1 = Highlight(
            title: "A", quoteText: "Q1", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 10
        )
        let h2 = Highlight(
            title: "B", quoteText: "Q2", speaker: "P",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 20
        )
        let h1Duplicate = Highlight(
            id: h1.id, title: "A Copy", quoteText: "Q3", speaker: "I",
            utteranceId: UUID(), sessionId: UUID(), timestampSeconds: 30
        )

        // Then: Same ID should hash equally
        var set = Set<Highlight>()
        set.insert(h1)
        set.insert(h2)
        set.insert(h1Duplicate) // Same ID as h1
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Test: HighlightCategory

    func testHighlightCategory_allCasesPresent() {
        // Then: All cases should be available
        XCTAssertEqual(HighlightCategory.allCases.count, 7)
    }

    func testHighlightCategory_displayNames() {
        XCTAssertEqual(HighlightCategory.painPoint.displayName, "Pain Point")
        XCTAssertEqual(HighlightCategory.userNeed.displayName, "User Need")
        XCTAssertEqual(HighlightCategory.delight.displayName, "Delight")
        XCTAssertEqual(HighlightCategory.workaround.displayName, "Workaround")
        XCTAssertEqual(HighlightCategory.featureRequest.displayName, "Feature Request")
        XCTAssertEqual(HighlightCategory.keyQuote.displayName, "Key Quote")
        XCTAssertEqual(HighlightCategory.uncategorized.displayName, "Uncategorized")
    }

    func testHighlightCategory_icons() {
        // Then: All categories should have non-empty icons
        for category in HighlightCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) should have an icon")
        }
    }

    func testHighlightCategory_colorHexValues() {
        // Then: All categories should have hex color strings starting with #
        for category in HighlightCategory.allCases {
            XCTAssertTrue(category.colorHex.hasPrefix("#"), "\(category) colorHex should start with #")
            XCTAssertEqual(category.colorHex.count, 7, "\(category) colorHex should be 7 characters (#RRGGBB)")
        }
    }
}
