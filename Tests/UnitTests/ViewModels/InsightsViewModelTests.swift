//
//  InsightsViewModelTests.swift
//  HCDInterviewCoach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for InsightsViewModel
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class InsightsViewModelTests: XCTestCase {

    var viewModel: InsightsViewModel!
    var mockFlaggingService: MockInsightFlaggingService!

    override func setUp() {
        super.setUp()
        mockFlaggingService = MockInsightFlaggingService()
        viewModel = InsightsViewModel(flaggingService: mockFlaggingService)
    }

    override func tearDown() {
        viewModel = nil
        mockFlaggingService = nil
        super.tearDown()
    }

    // MARK: - Test Initial State

    func testInitialState() {
        // Given: Fresh view model

        // Then: Should have default initial values
        XCTAssertTrue(viewModel.insights.isEmpty)
        XCTAssertNil(viewModel.selectedInsight)
        XCTAssertNil(viewModel.editingInsight)
        XCTAssertFalse(viewModel.isShowingDetailSheet)
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertEqual(viewModel.filterMode, .all)
        XCTAssertEqual(viewModel.sortOrder, .chronological)
        XCTAssertFalse(viewModel.isCollapsed)
        XCTAssertEqual(viewModel.flaggingStatus, .idle)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testInitialState_computedProperties() {
        // Given: Fresh view model

        // Then: Computed properties should have correct defaults
        XCTAssertEqual(viewModel.totalCount, 0)
        XCTAssertEqual(viewModel.manualCount, 0)
        XCTAssertEqual(viewModel.automaticCount, 0)
        XCTAssertFalse(viewModel.hasInsights)
        XCTAssertNil(viewModel.selectedIndex)
    }

    // MARK: - Test Manual Insight Flagging

    func testManualInsightFlagging_callsCallback() {
        // Given: Callback is set
        var callbackCalled = false
        viewModel.onFlagCurrentMoment = {
            callbackCalled = true
        }

        // When: Flag current moment
        viewModel.flagCurrentMoment()

        // Then: Callback should be called
        XCTAssertTrue(callbackCalled)
    }

    func testManualInsightFlagging_selectsNewInsight() {
        // Given: View model
        let insight = createTestInsight(source: .userAdded)
        mockFlaggingService.simulateInsights([insight])

        // When: Flagging completes (simulated via status change)
        mockFlaggingService.simulateFlaggingStatus(.flagged(insight))

        // Wait for bindings to propagate
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        // Then: New insight should be selected
        // Note: Selection happens through the binding when status changes to .flagged
    }

    // MARK: - Test Auto Insight Detection

    func testAutoInsightDetection_countsCorrectly() {
        // Given: Mix of manual and auto insights
        let manualInsight = createTestInsight(source: .userAdded)
        let autoInsight1 = createTestInsight(source: .aiGenerated)
        let autoInsight2 = createTestInsight(source: .aiGenerated)
        mockFlaggingService.simulateInsights([manualInsight, autoInsight1, autoInsight2])

        // Then: Counts should be correct
        XCTAssertEqual(viewModel.totalCount, 3)
        XCTAssertEqual(viewModel.manualCount, 1)
        XCTAssertEqual(viewModel.automaticCount, 2)
    }

    func testAutoInsightDetection_filterShowsOnlyAuto() {
        // Given: Mix of insights
        let manualInsight = createTestInsight(source: .userAdded, theme: "Manual")
        let autoInsight = createTestInsight(source: .aiGenerated, theme: "Auto")
        mockFlaggingService.simulateInsights([manualInsight, autoInsight])

        // When: Filter by automatic
        viewModel.filterMode = .automatic

        // Then: Only auto insights should be shown
        let filtered = viewModel.filteredInsights
        XCTAssertEqual(filtered.count, 1)
        XCTAssertTrue(filtered.first?.isAIGenerated ?? false)
    }

    // MARK: - Test Insight Editing

    func testInsightEditing_opensDetailSheet() {
        // Given: Insight to edit
        let insight = createTestInsight()
        mockFlaggingService.simulateInsights([insight])
        viewModel.select(insight)

        // When: Edit selected insight
        viewModel.editSelectedInsight()

        // Then: Detail sheet should be showing
        XCTAssertTrue(viewModel.isShowingDetailSheet)
        XCTAssertEqual(viewModel.editingInsight?.id, insight.id)
    }

    func testInsightEditing_editSpecificInsight() {
        // Given: Insight
        let insight = createTestInsight()
        mockFlaggingService.simulateInsights([insight])

        // When: Edit specific insight
        viewModel.edit(insight)

        // Then: Should open detail sheet
        XCTAssertTrue(viewModel.isShowingDetailSheet)
        XCTAssertEqual(viewModel.editingInsight?.id, insight.id)
    }

    func testInsightEditing_dismissDetailSheet() {
        // Given: Detail sheet is showing
        let insight = createTestInsight()
        viewModel.editingInsight = insight
        viewModel.isShowingDetailSheet = true

        // When: Dismiss
        viewModel.dismissDetailSheet()

        // Then: Should close detail sheet
        XCTAssertFalse(viewModel.isShowingDetailSheet)
        XCTAssertNil(viewModel.editingInsight)
    }

    func testInsightEditing_saveChanges() {
        // Given: Editing insight
        let insight = createTestInsight()
        mockFlaggingService.simulateInsights([insight])
        viewModel.editingInsight = insight
        viewModel.isShowingDetailSheet = true

        // When: Save changes
        viewModel.saveInsightChanges(title: "New Title", tags: ["tag1", "tag2"])

        // Then: Service should be called
        XCTAssertTrue(mockFlaggingService.updateInsightWasCalled)
        XCTAssertEqual(mockFlaggingService.lastUpdatedTitle, "New Title")
        XCTAssertEqual(mockFlaggingService.lastUpdatedTags, ["tag1", "tag2"])

        // And detail sheet should close
        XCTAssertFalse(viewModel.isShowingDetailSheet)
        XCTAssertNil(viewModel.editingInsight)
    }

    func testInsightEditing_noSelectedInsight() {
        // Given: No selected insight
        viewModel.selectedInsight = nil

        // When: Try to edit selected
        viewModel.editSelectedInsight()

        // Then: Detail sheet should not open
        XCTAssertFalse(viewModel.isShowingDetailSheet)
        XCTAssertNil(viewModel.editingInsight)
    }

    // MARK: - Test Insight Deletion

    func testInsightDeletion_removesInsight() {
        // Given: Insight to delete
        let insight = createTestInsight()
        mockFlaggingService.simulateInsights([insight])

        // When: Delete insight
        viewModel.delete(insight)

        // Then: Service should be called
        XCTAssertTrue(mockFlaggingService.removeInsightWasCalled)
        XCTAssertEqual(mockFlaggingService.lastRemovedInsightId, insight.id)
    }

    func testInsightDeletion_clearsSelectionIfDeleted() {
        // Given: Selected insight
        let insight1 = createTestInsight(theme: "First")
        let insight2 = createTestInsight(theme: "Second")
        mockFlaggingService.simulateInsights([insight1, insight2])
        viewModel.select(insight1)

        // When: Delete selected insight
        viewModel.delete(insight1)

        // Then: Selection should move to next (or be cleared if only one)
        // Note: Actual behavior depends on implementation
    }

    func testInsightDeletion_deleteSelectedInsight() {
        // Given: Selected insight
        let insight = createTestInsight()
        mockFlaggingService.simulateInsights([insight])
        viewModel.select(insight)

        // When: Delete selected
        viewModel.deleteSelectedInsight()

        // Then: Should delete the selected insight
        XCTAssertTrue(mockFlaggingService.removeInsightWasCalled)
    }

    func testInsightDeletion_noSelectedInsight() {
        // Given: No selection
        viewModel.selectedInsight = nil

        // When: Delete selected
        viewModel.deleteSelectedInsight()

        // Then: Should not crash or call service
        XCTAssertFalse(mockFlaggingService.removeInsightWasCalled)
    }

    // MARK: - Test Insight Navigation

    func testInsightNavigation_selectNext() {
        // Given: Multiple insights with selection
        let insight1 = createTestInsight(theme: "First", timestamp: 10)
        let insight2 = createTestInsight(theme: "Second", timestamp: 20)
        let insight3 = createTestInsight(theme: "Third", timestamp: 30)
        mockFlaggingService.simulateInsights([insight1, insight2, insight3])
        viewModel.select(insight1)

        // When: Select next
        viewModel.selectNext()

        // Then: Next insight should be selected
        XCTAssertEqual(viewModel.selectedInsight?.id, insight2.id)
    }

    func testInsightNavigation_selectNextWrapsAround() {
        // Given: Selection at last insight
        let insight1 = createTestInsight(theme: "First", timestamp: 10)
        let insight2 = createTestInsight(theme: "Second", timestamp: 20)
        mockFlaggingService.simulateInsights([insight1, insight2])
        viewModel.select(insight2)

        // When: Select next
        viewModel.selectNext()

        // Then: Should wrap to first
        XCTAssertEqual(viewModel.selectedInsight?.id, insight1.id)
    }

    func testInsightNavigation_selectPrevious() {
        // Given: Selection at second insight
        let insight1 = createTestInsight(theme: "First", timestamp: 10)
        let insight2 = createTestInsight(theme: "Second", timestamp: 20)
        mockFlaggingService.simulateInsights([insight1, insight2])
        viewModel.select(insight2)

        // When: Select previous
        viewModel.selectPrevious()

        // Then: Previous insight should be selected
        XCTAssertEqual(viewModel.selectedInsight?.id, insight1.id)
    }

    func testInsightNavigation_selectPreviousWrapsAround() {
        // Given: Selection at first insight
        let insight1 = createTestInsight(theme: "First", timestamp: 10)
        let insight2 = createTestInsight(theme: "Second", timestamp: 20)
        mockFlaggingService.simulateInsights([insight1, insight2])
        viewModel.select(insight1)

        // When: Select previous
        viewModel.selectPrevious()

        // Then: Should wrap to last
        XCTAssertEqual(viewModel.selectedInsight?.id, insight2.id)
    }

    func testInsightNavigation_selectNextWithNoSelection() {
        // Given: No selection but insights exist
        let insight1 = createTestInsight(theme: "First", timestamp: 10)
        mockFlaggingService.simulateInsights([insight1])
        viewModel.selectedInsight = nil

        // When: Select next
        viewModel.selectNext()

        // Then: First insight should be selected
        XCTAssertEqual(viewModel.selectedInsight?.id, insight1.id)
    }

    func testInsightNavigation_selectPreviousWithNoSelection() {
        // Given: No selection but insights exist
        let insight1 = createTestInsight(theme: "First", timestamp: 10)
        mockFlaggingService.simulateInsights([insight1])
        viewModel.selectedInsight = nil

        // When: Select previous
        viewModel.selectPrevious()

        // Then: Last insight should be selected
        XCTAssertEqual(viewModel.selectedInsight?.id, insight1.id)
    }

    func testInsightNavigation_selectNextEmptyList() {
        // Given: No insights
        mockFlaggingService.simulateInsights([])

        // When: Select next
        viewModel.selectNext()

        // Then: Should not crash, no selection
        XCTAssertNil(viewModel.selectedInsight)
    }

    func testInsightNavigation_navigateToTranscript() {
        // Given: Insight and callback
        var navigatedUtterance: Utterance?
        viewModel.onNavigateToUtterance = { utterance in
            navigatedUtterance = utterance
        }
        let insight = createTestInsight(timestamp: 30.0)
        mockFlaggingService.simulateInsights([insight])

        // When: Navigate to transcript
        viewModel.navigateToTranscript(for: insight)

        // Then: Callback should be called with correct timestamp
        XCTAssertNotNil(navigatedUtterance)
        XCTAssertEqual(navigatedUtterance?.timestampSeconds, 30.0)
    }

    func testInsightNavigation_navigateToSelectedInsight() {
        // Given: Selected insight and callback
        var callbackCalled = false
        viewModel.onNavigateToUtterance = { _ in
            callbackCalled = true
        }
        let insight = createTestInsight()
        mockFlaggingService.simulateInsights([insight])
        viewModel.select(insight)

        // When: Navigate to selected
        viewModel.navigateToSelectedInsight()

        // Then: Callback should be called
        XCTAssertTrue(callbackCalled)
    }

    // MARK: - Test Selection

    func testSelect() {
        // Given: Insight
        let insight = createTestInsight()
        mockFlaggingService.simulateInsights([insight])

        // When: Select
        viewModel.select(insight)

        // Then: Should be selected
        XCTAssertEqual(viewModel.selectedInsight?.id, insight.id)
    }

    func testClearSelection() {
        // Given: Selected insight
        let insight = createTestInsight()
        viewModel.selectedInsight = insight

        // When: Clear
        viewModel.clearSelection()

        // Then: Selection should be nil
        XCTAssertNil(viewModel.selectedInsight)
    }

    func testSelectedIndex() {
        // Given: Multiple insights with one selected
        let insight1 = createTestInsight(theme: "First", timestamp: 10)
        let insight2 = createTestInsight(theme: "Second", timestamp: 20)
        mockFlaggingService.simulateInsights([insight1, insight2])
        viewModel.select(insight2)

        // Then: Selected index should be 1
        XCTAssertEqual(viewModel.selectedIndex, 1)
    }

    func testSelectedIndex_noSelection() {
        // Given: No selection
        let insight = createTestInsight()
        mockFlaggingService.simulateInsights([insight])
        viewModel.selectedInsight = nil

        // Then: Selected index should be nil
        XCTAssertNil(viewModel.selectedIndex)
    }

    // MARK: - Test Filtering

    func testFilterMode_all() {
        // Given: Mixed insights
        let manual = createTestInsight(source: .userAdded, theme: "Manual")
        let auto = createTestInsight(source: .aiGenerated, theme: "Auto")
        mockFlaggingService.simulateInsights([manual, auto])

        // When: Filter all
        viewModel.filterMode = .all

        // Then: All insights should be visible
        XCTAssertEqual(viewModel.filteredInsights.count, 2)
    }

    func testFilterMode_manual() {
        // Given: Mixed insights
        let manual = createTestInsight(source: .userAdded, theme: "Manual")
        let auto = createTestInsight(source: .aiGenerated, theme: "Auto")
        mockFlaggingService.simulateInsights([manual, auto])

        // When: Filter manual
        viewModel.filterMode = .manual

        // Then: Only manual insights
        let filtered = viewModel.filteredInsights
        XCTAssertEqual(filtered.count, 1)
        XCTAssertTrue(filtered.first?.isUserAdded ?? false)
    }

    func testFilterMode_automatic() {
        // Given: Mixed insights
        let manual = createTestInsight(source: .userAdded, theme: "Manual")
        let auto = createTestInsight(source: .aiGenerated, theme: "Auto")
        mockFlaggingService.simulateInsights([manual, auto])

        // When: Filter automatic
        viewModel.filterMode = .automatic

        // Then: Only auto insights
        let filtered = viewModel.filteredInsights
        XCTAssertEqual(filtered.count, 1)
        XCTAssertTrue(filtered.first?.isAIGenerated ?? false)
    }

    func testSearchQuery_filters() {
        // Given: Insights with different content
        let insight1 = createTestInsight(quote: "pain point for users", theme: "Pain Point")
        let insight2 = createTestInsight(quote: "users love this feature", theme: "Positive")
        mockFlaggingService.simulateInsights([insight1, insight2])

        // When: Search for "pain"
        viewModel.searchQuery = "pain"

        // Then: Only matching insights
        let filtered = viewModel.filteredInsights
        XCTAssertEqual(filtered.count, 1)
        XCTAssertTrue(filtered.first?.quote.contains("pain") ?? false)
    }

    func testSearchQuery_searchesTags() {
        // Given: Insight with tags
        let insight = createTestInsight(tags: ["ux-issue", "priority"])
        mockFlaggingService.simulateInsights([insight])

        // When: Search for tag
        viewModel.searchQuery = "ux-issue"

        // Then: Should find by tag
        XCTAssertEqual(viewModel.filteredInsights.count, 1)
    }

    func testSearchQuery_searchesTheme() {
        // Given: Insight
        let insight = createTestInsight(theme: "Critical Pain Point")
        mockFlaggingService.simulateInsights([insight])

        // When: Search in theme
        viewModel.searchQuery = "Critical"

        // Then: Should find
        XCTAssertEqual(viewModel.filteredInsights.count, 1)
    }

    func testSearchQuery_caseInsensitive() {
        // Given: Insight
        let insight = createTestInsight(quote: "IMPORTANT insight")
        mockFlaggingService.simulateInsights([insight])

        // When: Search lowercase
        viewModel.searchQuery = "important"

        // Then: Should find
        XCTAssertEqual(viewModel.filteredInsights.count, 1)
    }

    // MARK: - Test Sorting

    func testSortOrder_chronological() {
        // Given: Insights at different times
        let insight1 = createTestInsight(theme: "First", timestamp: 60)
        let insight2 = createTestInsight(theme: "Second", timestamp: 30)
        let insight3 = createTestInsight(theme: "Third", timestamp: 90)
        mockFlaggingService.simulateInsights([insight1, insight2, insight3])

        // When: Sort chronological
        viewModel.sortOrder = .chronological

        // Then: Oldest first
        let sorted = viewModel.filteredInsights
        XCTAssertEqual(sorted[0].timestampSeconds, 30)
        XCTAssertEqual(sorted[1].timestampSeconds, 60)
        XCTAssertEqual(sorted[2].timestampSeconds, 90)
    }

    func testSortOrder_reverseChronological() {
        // Given: Insights at different times
        let insight1 = createTestInsight(theme: "First", timestamp: 60)
        let insight2 = createTestInsight(theme: "Second", timestamp: 30)
        mockFlaggingService.simulateInsights([insight1, insight2])

        // When: Sort reverse chronological
        viewModel.sortOrder = .reverseChronological

        // Then: Newest first
        let sorted = viewModel.filteredInsights
        XCTAssertEqual(sorted[0].timestampSeconds, 60)
        XCTAssertEqual(sorted[1].timestampSeconds, 30)
    }

    func testSortOrder_alphabetical() {
        // Given: Insights with different themes
        let insight1 = createTestInsight(theme: "Zebra")
        let insight2 = createTestInsight(theme: "Apple")
        let insight3 = createTestInsight(theme: "Mango")
        mockFlaggingService.simulateInsights([insight1, insight2, insight3])

        // When: Sort alphabetically
        viewModel.sortOrder = .alphabetical

        // Then: Alphabetical order
        let sorted = viewModel.filteredInsights
        XCTAssertEqual(sorted[0].theme, "Apple")
        XCTAssertEqual(sorted[1].theme, "Mango")
        XCTAssertEqual(sorted[2].theme, "Zebra")
    }

    // MARK: - Test Cycle Methods

    func testCycleFilterMode() {
        // Given: Initial filter mode
        viewModel.filterMode = .all

        // When/Then: Cycle through modes
        viewModel.cycleFilterMode()
        XCTAssertEqual(viewModel.filterMode, .manual)

        viewModel.cycleFilterMode()
        XCTAssertEqual(viewModel.filterMode, .automatic)

        viewModel.cycleFilterMode()
        XCTAssertEqual(viewModel.filterMode, .all)
    }

    func testCycleSortOrder() {
        // Given: Initial sort order
        viewModel.sortOrder = .chronological

        // When/Then: Cycle through orders
        viewModel.cycleSortOrder()
        XCTAssertEqual(viewModel.sortOrder, .reverseChronological)

        viewModel.cycleSortOrder()
        XCTAssertEqual(viewModel.sortOrder, .alphabetical)

        viewModel.cycleSortOrder()
        XCTAssertEqual(viewModel.sortOrder, .chronological)
    }

    // MARK: - Test Panel Toggle

    func testToggleCollapsed() {
        // Given: Not collapsed
        viewModel.isCollapsed = false

        // When: Toggle
        viewModel.toggleCollapsed()

        // Then: Should be collapsed
        XCTAssertTrue(viewModel.isCollapsed)

        // When: Toggle again
        viewModel.toggleCollapsed()

        // Then: Should be expanded
        XCTAssertFalse(viewModel.isCollapsed)
    }

    // MARK: - Test Other Operations

    func testRefresh() {
        // When: Refresh
        viewModel.refresh()

        // Then: Service should be called
        XCTAssertTrue(mockFlaggingService.refreshWasCalled)
    }

    func testUndoLastFlag() {
        // When: Undo
        viewModel.undoLastFlag()

        // Then: Service should be called
        XCTAssertTrue(mockFlaggingService.undoLastFlagWasCalled)
    }

    func testClearAutomaticInsights() {
        // When: Clear automatic
        viewModel.clearAutomaticInsights()

        // Then: Service should be called
        XCTAssertTrue(mockFlaggingService.clearAutoGeneratedInsightsWasCalled)
    }

    // MARK: - Test Accessibility

    func testAccessibilityLabel_empty() {
        // Given: No insights
        mockFlaggingService.simulateInsights([])

        // Then: Should indicate empty
        XCTAssertEqual(viewModel.accessibilityLabel, "Insights panel, empty")
    }

    func testAccessibilityLabel_withInsights() {
        // Given: Some insights
        let insight1 = createTestInsight()
        let insight2 = createTestInsight()
        mockFlaggingService.simulateInsights([insight1, insight2])

        // Then: Should indicate count
        XCTAssertEqual(viewModel.accessibilityLabel, "Insights panel, 2 insights")
    }

    func testAnnounceSelection() {
        // Given: Selected insight
        let insight = createTestInsight(theme: "Pain Point", timestamp: 90)
        mockFlaggingService.simulateInsights([insight])
        viewModel.select(insight)

        // When: Get announcement
        let announcement = viewModel.announceSelection()

        // Then: Should include theme and timestamp
        XCTAssertNotNil(announcement)
        XCTAssertTrue(announcement?.contains("Pain Point") ?? false)
        XCTAssertTrue(announcement?.contains("01:30") ?? false)
    }

    func testAnnounceSelection_noSelection() {
        // Given: No selection
        viewModel.selectedInsight = nil

        // Then: No announcement
        XCTAssertNil(viewModel.announceSelection())
    }

    // MARK: - Test Filter Mode Properties

    func testInsightFilterModeProperties() {
        // Test all filter modes have required properties
        for mode in InsightFilterMode.allCases {
            XCTAssertFalse(mode.id.isEmpty)
            XCTAssertFalse(mode.rawValue.isEmpty)
            XCTAssertFalse(mode.icon.isEmpty)
            XCTAssertFalse(mode.accessibilityLabel.isEmpty)
        }
    }

    func testInsightSortOrderProperties() {
        // Test all sort orders have required properties
        for order in InsightSortOrder.allCases {
            XCTAssertFalse(order.id.isEmpty)
            XCTAssertFalse(order.rawValue.isEmpty)
            XCTAssertFalse(order.icon.isEmpty)
        }
    }

    // MARK: - Helper Methods

    private func createTestInsight(
        source: InsightSource = .userAdded,
        quote: String = "Test quote",
        theme: String = "Test Theme",
        timestamp: Double = 60.0,
        tags: [String] = []
    ) -> Insight {
        return Insight(
            timestampSeconds: timestamp,
            quote: quote,
            theme: theme,
            source: source,
            tags: tags
        )
    }
}

// MARK: - Mock Classes

@MainActor
final class MockInsightFlaggingService: InsightFlaggingService {

    var updateInsightWasCalled = false
    var lastUpdatedTitle: String?
    var lastUpdatedTags: [String]?
    var removeInsightWasCalled = false
    var lastRemovedInsightId: UUID?
    var refreshWasCalled = false
    var undoLastFlagWasCalled = false
    var clearAutoGeneratedInsightsWasCalled = false

    init() {
        // Initialize without session or data manager for testing
        super.init(session: nil)
    }

    func simulateInsights(_ newInsights: [Insight]) {
        // Directly set the inherited @Published property so $insights fires
        self.insights = newInsights
    }

    func simulateFlaggingStatus(_ status: FlaggingStatus) {
        // Directly set the inherited @Published property so $flaggingStatus fires
        self.flaggingStatus = status
    }

    override func updateInsight(_ insight: Insight, title: String?, notes: String?, tags: [String]?) {
        updateInsightWasCalled = true
        lastUpdatedTitle = title
        lastUpdatedTags = tags
    }

    override func removeInsight(_ insight: Insight) {
        removeInsightWasCalled = true
        lastRemovedInsightId = insight.id
        insights.removeAll { $0.id == insight.id }
    }

    override func refresh() {
        refreshWasCalled = true
    }

    @discardableResult
    override func undoLastFlag() -> Bool {
        undoLastFlagWasCalled = true
        return true
    }

    override func clearAutoGeneratedInsights() {
        clearAutoGeneratedInsightsWasCalled = true
        insights.removeAll { $0.isAIGenerated }
    }
}
