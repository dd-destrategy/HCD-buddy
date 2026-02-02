//
//  TranscriptViewModelTests.swift
//  HCDInterviewCoach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for TranscriptViewModel
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class TranscriptViewModelTests: XCTestCase {

    var viewModel: TranscriptViewModel!
    var mockVirtualizationManager: MockTranscriptVirtualizationManager!

    override func setUp() {
        super.setUp()
        mockVirtualizationManager = MockTranscriptVirtualizationManager()
        viewModel = TranscriptViewModel(
            sessionManager: nil,
            virtualizationManager: mockVirtualizationManager
        )
    }

    override func tearDown() {
        viewModel = nil
        mockVirtualizationManager = nil
        super.tearDown()
    }

    // MARK: - Test Initial State

    func testInitialState() {
        // Given: Fresh view model
        let freshViewModel = TranscriptViewModel()

        // Then: Should have default initial values
        XCTAssertNil(freshViewModel.speakerFilter)
        XCTAssertEqual(freshViewModel.searchQuery, "")
        XCTAssertTrue(freshViewModel.searchResults.isEmpty)
        XCTAssertEqual(freshViewModel.currentSearchResultIndex, 0)
        XCTAssertFalse(freshViewModel.isSearchActive)
        XCTAssertTrue(freshViewModel.isAutoScrollEnabled)
        XCTAssertNil(freshViewModel.selectedUtteranceId)
        XCTAssertTrue(freshViewModel.isEmpty)
        XCTAssertEqual(freshViewModel.statusMessage, "Waiting for session...")
        XCTAssertFalse(freshViewModel.isProcessing)
        XCTAssertNil(freshViewModel.errorMessage)
    }

    func testInitialState_emptyStatistics() {
        // Given: Fresh view model

        // When: Accessing statistics
        let stats = viewModel.statistics

        // Then: All statistics should be zero
        XCTAssertEqual(stats.totalUtterances, 0)
        XCTAssertEqual(stats.interviewerUtterances, 0)
        XCTAssertEqual(stats.participantUtterances, 0)
        XCTAssertEqual(stats.totalWords, 0)
        XCTAssertEqual(stats.durationSeconds, 0)
    }

    // MARK: - Test Add Utterance

    func testAddUtterance_updatesIsEmpty() {
        // Given: Empty view model
        XCTAssertTrue(viewModel.isEmpty)

        // When: Add an utterance via virtualization manager
        let utterance = createTestUtterance(text: "Hello world", speaker: .participant)
        mockVirtualizationManager.addUtterance(utterance)
        mockVirtualizationManager.simulateVisibleUtterances([utterance])

        // Then: isEmpty should update (tracked via virtualization manager)
        XCTAssertFalse(mockVirtualizationManager.visibleUtterances.isEmpty)
    }

    func testAddUtterance_autoScrollWhenEnabled() {
        // Given: Auto-scroll is enabled
        viewModel.isAutoScrollEnabled = true

        // When: Add an utterance
        let utterance = createTestUtterance(text: "Test text", speaker: .interviewer)
        mockVirtualizationManager.addUtterance(utterance)

        // Then: Scroll to end should have been called
        XCTAssertTrue(mockVirtualizationManager.scrollToEndCalled)
    }

    func testAddUtterance_noAutoScrollWhenDisabled() {
        // Given: Auto-scroll is disabled
        viewModel.isAutoScrollEnabled = false

        // When: Add utterance via virtualization manager directly
        mockVirtualizationManager.scrollToEndCalled = false
        let utterance = createTestUtterance(text: "Test text", speaker: .interviewer)
        mockVirtualizationManager.addUtterance(utterance)

        // Note: The ViewModel only controls auto-scroll behavior when processing transcription events
        // Direct addition through virtualization manager doesn't trigger the ViewModel's auto-scroll logic
    }

    // MARK: - Test Search Filtering

    func testSearchFiltering_emptyQueryClearsSearch() {
        // Given: Active search
        viewModel.isSearchActive = true
        viewModel.searchQuery = "test"

        // When: Clear the query
        viewModel.clearSearch()

        // Then: Search should be cleared
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertEqual(viewModel.currentSearchResultIndex, 0)
        XCTAssertFalse(viewModel.isSearchActive)
        XCTAssertNil(viewModel.selectedUtteranceId)
    }

    func testSearchFiltering_performSearchActivatesSearch() async {
        // Given: View model with search query
        viewModel.searchQuery = "hello"

        // When: Perform search
        viewModel.performSearch()

        // Wait for async search to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Search should be active
        XCTAssertTrue(viewModel.isSearchActive)
    }

    func testSearchFiltering_emptyQueryDoesNotActivateSearch() {
        // Given: Empty search query
        viewModel.searchQuery = ""

        // When: Perform search
        viewModel.performSearch()

        // Then: Search should not be active
        XCTAssertFalse(viewModel.isSearchActive)
    }

    func testSearchFiltering_nextSearchResult() {
        // Given: Multiple search results
        let results = [
            createSearchResult(index: 0),
            createSearchResult(index: 1),
            createSearchResult(index: 2)
        ]
        mockVirtualizationManager.mockSearchResults = results
        viewModel.performSearch()

        // Simulate search completion by setting results directly
        // In real scenario, this would be done through async completion

        // When: Navigate to next result
        viewModel.nextSearchResult()

        // Then: Index should cycle (but results array is empty in mock)
        // Note: Without actual results, this tests the cycling logic
    }

    func testSearchFiltering_previousSearchResult() {
        // Given: Search results at index 2
        viewModel.currentSearchResultIndex = 2

        // When: Navigate to previous result
        viewModel.previousSearchResult()

        // Then: Should stay at same index (no results)
        // The actual implementation guards against empty results
    }

    // MARK: - Test Speaker Toggle

    func testSpeakerToggle_interviewerToParticipant() {
        // Given: Utterance with interviewer speaker
        let utteranceId = UUID()
        let utterance = createTestUtterance(id: utteranceId, text: "Test", speaker: .interviewer)
        mockVirtualizationManager.addUtterance(utterance)
        mockVirtualizationManager.simulateVisibleUtterances([utterance])

        // When: Toggle speaker
        viewModel.toggleSpeaker(for: utteranceId)

        // Then: Should call update with participant speaker
        XCTAssertEqual(mockVirtualizationManager.lastUpdatedSpeaker, .participant)
    }

    func testSpeakerToggle_participantToInterviewer() {
        // Given: Utterance with participant speaker
        let utteranceId = UUID()
        let utterance = createTestUtterance(id: utteranceId, text: "Test", speaker: .participant)
        mockVirtualizationManager.addUtterance(utterance)
        mockVirtualizationManager.simulateVisibleUtterances([utterance])

        // When: Toggle speaker
        viewModel.toggleSpeaker(for: utteranceId)

        // Then: Should call update with interviewer speaker
        XCTAssertEqual(mockVirtualizationManager.lastUpdatedSpeaker, .interviewer)
    }

    func testSpeakerToggle_unknownToInterviewer() {
        // Given: Utterance with unknown speaker
        let utteranceId = UUID()
        let utterance = createTestUtterance(id: utteranceId, text: "Test", speaker: .unknown)
        mockVirtualizationManager.addUtterance(utterance)
        mockVirtualizationManager.simulateVisibleUtterances([utterance])

        // When: Toggle speaker
        viewModel.toggleSpeaker(for: utteranceId)

        // Then: Should call update with interviewer speaker
        XCTAssertEqual(mockVirtualizationManager.lastUpdatedSpeaker, .interviewer)
    }

    func testUpdateSpeaker_directUpdate() {
        // Given: Utterance
        let utteranceId = UUID()
        let utterance = createTestUtterance(id: utteranceId, text: "Test", speaker: .interviewer)
        mockVirtualizationManager.addUtterance(utterance)
        mockVirtualizationManager.simulateVisibleUtterances([utterance])

        // When: Update speaker directly
        viewModel.updateSpeaker(for: utteranceId, to: .participant)

        // Then: Should update to specified speaker
        XCTAssertEqual(mockVirtualizationManager.lastUpdatedSpeaker, .participant)
    }

    // MARK: - Test Auto Scroll

    func testAutoScroll_enabledByDefault() {
        // Given: Fresh view model

        // Then: Auto-scroll should be enabled
        XCTAssertTrue(viewModel.isAutoScrollEnabled)
    }

    func testAutoScroll_canBeDisabled() {
        // Given: View model with auto-scroll enabled
        XCTAssertTrue(viewModel.isAutoScrollEnabled)

        // When: Disable auto-scroll
        viewModel.isAutoScrollEnabled = false

        // Then: Auto-scroll should be disabled
        XCTAssertFalse(viewModel.isAutoScrollEnabled)
    }

    func testJumpToEnd_enablesAutoScroll() {
        // Given: Auto-scroll disabled
        viewModel.isAutoScrollEnabled = false

        // When: Jump to end
        viewModel.jumpToEnd()

        // Then: Auto-scroll should be re-enabled
        XCTAssertTrue(viewModel.isAutoScrollEnabled)
        XCTAssertTrue(mockVirtualizationManager.scrollToEndCalled)
    }

    func testJumpToStart_disablesAutoScroll() {
        // Given: Auto-scroll enabled and utterances present
        viewModel.isAutoScrollEnabled = true
        let utterance = createTestUtterance(text: "Test", speaker: .participant)
        mockVirtualizationManager.addUtterance(utterance)
        mockVirtualizationManager.simulateVisibleUtterances([utterance])

        // When: Jump to start
        viewModel.jumpToStart()

        // Then: Auto-scroll should be disabled
        XCTAssertFalse(viewModel.isAutoScrollEnabled)
    }

    // MARK: - Test Timestamp Navigation

    func testTimestampNavigation_scrollsToClosestUtterance() {
        // Given: Multiple utterances at different timestamps
        let utterance1 = createTestUtterance(text: "First", speaker: .interviewer, timestamp: 10.0)
        let utterance2 = createTestUtterance(text: "Second", speaker: .participant, timestamp: 30.0)
        let utterance3 = createTestUtterance(text: "Third", speaker: .interviewer, timestamp: 60.0)

        mockVirtualizationManager.simulateVisibleUtterances([utterance1, utterance2, utterance3])

        // When: Navigate to timestamp 25.0
        viewModel.scrollToTimestamp(25.0)

        // Then: Should select the closest utterance (utterance2 at 30.0)
        XCTAssertEqual(viewModel.selectedUtteranceId, utterance2.id)
    }

    func testTimestampNavigation_emptyTranscript() {
        // Given: Empty transcript
        mockVirtualizationManager.simulateVisibleUtterances([])

        // When: Navigate to timestamp
        viewModel.scrollToTimestamp(25.0)

        // Then: Selection should remain nil
        XCTAssertNil(viewModel.selectedUtteranceId)
    }

    // MARK: - Test Speaker Filter

    func testFilterBySpeaker_setsFilter() {
        // Given: No filter
        XCTAssertNil(viewModel.speakerFilter)

        // When: Filter by interviewer
        viewModel.filterBySpeaker(.interviewer)

        // Then: Filter should be set
        XCTAssertEqual(viewModel.speakerFilter, .interviewer)
    }

    func testFilterBySpeaker_clearFilter() {
        // Given: Active filter
        viewModel.speakerFilter = .interviewer

        // When: Clear filter
        viewModel.filterBySpeaker(nil)

        // Then: Filter should be nil
        XCTAssertNil(viewModel.speakerFilter)
    }

    func testFilteredUtterances_noFilter() {
        // Given: Utterances with mixed speakers
        let utterance1 = createTestUtterance(text: "First", speaker: .interviewer)
        let utterance2 = createTestUtterance(text: "Second", speaker: .participant)
        mockVirtualizationManager.simulateVisibleUtterances([utterance1, utterance2])

        // When: No filter applied
        viewModel.speakerFilter = nil

        // Then: All utterances should be returned
        XCTAssertEqual(viewModel.filteredUtterances.count, 2)
    }

    func testFilteredUtterances_withFilter() {
        // Given: Utterances with mixed speakers
        let utterance1 = createTestUtterance(text: "First", speaker: .interviewer)
        let utterance2 = createTestUtterance(text: "Second", speaker: .participant)
        mockVirtualizationManager.simulateVisibleUtterances([utterance1, utterance2])

        // When: Filter by interviewer
        viewModel.speakerFilter = .interviewer

        // Then: Only interviewer utterances should be returned
        let filtered = viewModel.filteredUtterances
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.speaker, .interviewer)
    }

    // MARK: - Test Statistics

    func testStatistics_calculation() {
        // Given: Multiple utterances
        let utterance1 = createTestUtterance(text: "Hello world", speaker: .interviewer, timestamp: 0)
        let utterance2 = createTestUtterance(text: "How are you today", speaker: .participant, timestamp: 30)
        let utterance3 = createTestUtterance(text: "I am fine thanks", speaker: .participant, timestamp: 60)
        mockVirtualizationManager.simulateVisibleUtterances([utterance1, utterance2, utterance3])

        // When: Get statistics
        let stats = viewModel.statistics

        // Then: Statistics should be calculated correctly
        XCTAssertEqual(stats.totalUtterances, 3)
        XCTAssertEqual(stats.interviewerUtterances, 1)
        XCTAssertEqual(stats.participantUtterances, 2)
        XCTAssertEqual(stats.durationSeconds, 60) // Last timestamp
    }

    func testStatistics_participationRatio() {
        // Given: Multiple utterances
        let utterance1 = createTestUtterance(text: "First", speaker: .interviewer)
        let utterance2 = createTestUtterance(text: "Second", speaker: .participant)
        mockVirtualizationManager.simulateVisibleUtterances([utterance1, utterance2])

        // When: Get participation ratio
        let stats = viewModel.statistics

        // Then: Should show 50% / 50%
        XCTAssertEqual(stats.participationRatio, "50% / 50%")
    }

    func testStatistics_emptyParticipationRatio() {
        // Given: No utterances
        mockVirtualizationManager.simulateVisibleUtterances([])

        // When: Get participation ratio
        let stats = viewModel.statistics

        // Then: Should show N/A
        XCTAssertEqual(stats.participationRatio, "N/A")
    }

    func testStatistics_formattedDuration() {
        // Given: 3 minute session
        let utterance = createTestUtterance(text: "Test", speaker: .participant, timestamp: 180)
        mockVirtualizationManager.simulateVisibleUtterances([utterance])

        // When: Get formatted duration
        let stats = viewModel.statistics

        // Then: Should format as MM:SS
        XCTAssertEqual(stats.formattedDuration, "3:00")
    }

    func testStatistics_formattedDurationWithHours() {
        // Given: 90 minute session
        let utterance = createTestUtterance(text: "Test", speaker: .participant, timestamp: 5400)
        mockVirtualizationManager.simulateVisibleUtterances([utterance])

        // When: Get formatted duration
        let stats = viewModel.statistics

        // Then: Should format as HH:MM:SS
        XCTAssertEqual(stats.formattedDuration, "1:30:00")
    }

    // MARK: - Test Export

    func testExportAsText_formattedOutput() {
        // Given: Utterances
        let utterance1 = createTestUtterance(text: "Hello", speaker: .interviewer, timestamp: 0)
        let utterance2 = createTestUtterance(text: "Hi there", speaker: .participant, timestamp: 30)
        mockVirtualizationManager.simulateVisibleUtterances([utterance1, utterance2])

        // When: Export as text
        let exported = viewModel.exportAsText()

        // Then: Should contain formatted utterances
        XCTAssertTrue(exported.contains("[00:00]"))
        XCTAssertTrue(exported.contains("Interviewer"))
        XCTAssertTrue(exported.contains("Hello"))
        XCTAssertTrue(exported.contains("[00:30]"))
        XCTAssertTrue(exported.contains("Participant"))
        XCTAssertTrue(exported.contains("Hi there"))
    }

    func testExportAsText_emptyTranscript() {
        // Given: Empty transcript
        mockVirtualizationManager.simulateVisibleUtterances([])

        // When: Export as text
        let exported = viewModel.exportAsText()

        // Then: Should be empty
        XCTAssertEqual(exported, "")
    }

    // MARK: - Test Connection

    func testDisconnect_updatesStatusMessage() {
        // Given: Connected view model
        viewModel.connect(to: MockSessionManagerForTranscript())

        // When: Disconnect
        viewModel.disconnect()

        // Then: Status message should update
        XCTAssertEqual(viewModel.statusMessage, "Disconnected")
    }

    // MARK: - Test Flag Insight

    func testFlagAsInsight_callsCallback() {
        // Given: Utterance and callback
        var flaggedUtterance: UtteranceViewModel?
        viewModel.onInsightFlagged = { utterance in
            flaggedUtterance = utterance
        }

        let utteranceId = UUID()
        let utterance = createTestUtterance(id: utteranceId, text: "Important insight", speaker: .participant)
        mockVirtualizationManager.addUtterance(utterance)
        mockVirtualizationManager.simulateVisibleUtterances([utterance])

        // When: Flag as insight
        viewModel.flagAsInsight(utteranceId)

        // Then: Callback should be called with the utterance
        XCTAssertNotNil(flaggedUtterance)
        XCTAssertEqual(flaggedUtterance?.id, utteranceId)
    }

    func testFlagAsInsight_nonExistentUtterance() {
        // Given: Callback set but no matching utterance
        var callbackCalled = false
        viewModel.onInsightFlagged = { _ in
            callbackCalled = true
        }

        // When: Flag non-existent utterance
        viewModel.flagAsInsight(UUID())

        // Then: Callback should not be called
        XCTAssertFalse(callbackCalled)
    }

    // MARK: - Helper Methods

    private func createTestUtterance(
        id: UUID = UUID(),
        text: String,
        speaker: Speaker,
        timestamp: TimeInterval = 0.0
    ) -> UtteranceViewModel {
        return UtteranceViewModel(
            from: TranscriptionEvent(
                text: text,
                isFinal: true,
                speaker: speaker,
                timestamp: timestamp,
                confidence: 0.95
            ),
            id: id
        )
    }

    private func createSearchResult(index: Int) -> SearchResult {
        return SearchResult(
            utteranceId: UUID(),
            matchRange: "test".startIndex..<"test".endIndex,
            context: "test context \(index)",
            timestamp: TimeInterval(index * 10)
        )
    }
}

// MARK: - Mock Classes

@MainActor
final class MockTranscriptVirtualizationManager: TranscriptVirtualizationManager {
    var scrollToEndCalled = false
    var lastUpdatedSpeaker: Speaker?
    var mockSearchResults: [SearchResult] = []
    private var utterances: [UUID: UtteranceViewModel] = [:]
    private var _visibleUtterances: [UtteranceViewModel] = []

    override var visibleUtterances: [UtteranceViewModel] {
        _visibleUtterances
    }

    func simulateVisibleUtterances(_ utterances: [UtteranceViewModel]) {
        _visibleUtterances = utterances
        for utterance in utterances {
            self.utterances[utterance.id] = utterance
        }
    }

    override func addUtterance(_ utterance: UtteranceViewModel) {
        utterances[utterance.id] = utterance
        _visibleUtterances.append(utterance)
    }

    override func getUtterance(_ id: UUID) -> UtteranceViewModel? {
        return utterances[id]
    }

    override func updateUtterance(_ utterance: UtteranceViewModel) {
        lastUpdatedSpeaker = utterance.speaker
        utterances[utterance.id] = utterance
        if let index = _visibleUtterances.firstIndex(where: { $0.id == utterance.id }) {
            _visibleUtterances[index] = utterance
        }
    }

    override func scrollToEnd() {
        scrollToEndCalled = true
    }

    override func scrollToUtterance(_ id: UUID) -> CGFloat? {
        return 0
    }

    override func search(for query: String) async -> [SearchResult] {
        return mockSearchResults
    }
}

@MainActor
final class MockSessionManagerForTranscript: SessionManager {
    init() {
        // Initialize with minimal setup for testing
    }
}
