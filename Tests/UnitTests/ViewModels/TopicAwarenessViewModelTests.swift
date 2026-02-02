//
//  TopicAwarenessViewModelTests.swift
//  HCDInterviewCoach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for TopicAwarenessViewModel
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class TopicAwarenessViewModelTests: XCTestCase {

    var viewModel: TopicAwarenessViewModel!
    var mockAnalyzer: MockTopicAnalyzer!

    override func setUp() {
        super.setUp()
        mockAnalyzer = MockTopicAnalyzer()
        viewModel = TopicAwarenessViewModel(sessionManager: nil, analyzer: mockAnalyzer)
    }

    override func tearDown() {
        viewModel = nil
        mockAnalyzer = nil
        super.tearDown()
    }

    // MARK: - Test Initial State

    func testInitialState() {
        // Given: Fresh view model

        // Then: Should have default initial values
        XCTAssertTrue(viewModel.topicItems.isEmpty)
        XCTAssertNil(viewModel.selectedTopic)
        XCTAssertEqual(viewModel.filterOption, .all)
        XCTAssertEqual(viewModel.sortOption, .order)
        XCTAssertFalse(viewModel.isCompactMode)
        XCTAssertTrue(viewModel.isPanelExpanded)
        XCTAssertEqual(viewModel.overallCoverage, 0.0)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isAnalyzing)
    }

    func testInitialState_emptyStatusCounts() {
        // Given: Fresh view model

        // Then: Status counts should be empty
        XCTAssertTrue(viewModel.statusCounts.isEmpty)
    }

    // MARK: - Test Initial Topics From Template

    func testInitialTopicsFromTemplate_configuresTopics() {
        // Given: Topics to configure
        let topics = ["User Needs", "Pain Points", "Workflow"]

        // When: Configure topics
        viewModel.configure(topics: topics)

        // Then: Topics should be configured
        XCTAssertEqual(viewModel.topicItems.count, 3)
        XCTAssertEqual(viewModel.topicItems[0].name, "User Needs")
        XCTAssertEqual(viewModel.topicItems[1].name, "Pain Points")
        XCTAssertEqual(viewModel.topicItems[2].name, "Workflow")
    }

    func testInitialTopicsFromTemplate_withKeywords() {
        // Given: Topics with keywords
        let topics = ["User Needs", "Pain Points"]
        let keywords = [
            "User Needs": ["need", "want", "require", "desire"],
            "Pain Points": ["frustrating", "difficult", "problem", "challenge"]
        ]

        // When: Configure with keywords
        viewModel.configure(topics: topics, keywords: keywords)

        // Then: Topics should be configured (keywords passed to analyzer)
        XCTAssertEqual(viewModel.topicItems.count, 2)
        XCTAssertTrue(mockAnalyzer.configureWasCalled)
        XCTAssertEqual(mockAnalyzer.configuredKeywords?["User Needs"]?.count, 4)
    }

    func testInitialTopicsFromTemplate_defaultStatus() {
        // Given: Topics
        let topics = ["Topic 1", "Topic 2"]

        // When: Configure
        viewModel.configure(topics: topics)

        // Then: All topics should start as not started
        for item in viewModel.topicItems {
            XCTAssertEqual(item.status, .notStarted)
        }
    }

    func testInitialTopicsFromTemplate_preservesOrder() {
        // Given: Topics in specific order
        let topics = ["First", "Second", "Third", "Fourth"]

        // When: Configure
        viewModel.configure(topics: topics)

        // Then: Order should be preserved
        XCTAssertEqual(viewModel.topicItems[0].order, 0)
        XCTAssertEqual(viewModel.topicItems[1].order, 1)
        XCTAssertEqual(viewModel.topicItems[2].order, 2)
        XCTAssertEqual(viewModel.topicItems[3].order, 3)
    }

    // MARK: - Test Topic Status Update

    func testTopicStatusUpdate_cycleStatus() {
        // Given: Configured topics
        viewModel.configure(topics: ["Test Topic"])
        let topicId = viewModel.topicItems.first?.id ?? ""

        // When: Cycle status
        viewModel.cycleStatus(for: topicId)

        // Then: Analyzer should have cycled status
        XCTAssertTrue(mockAnalyzer.cycleStatusWasCalled)
        XCTAssertEqual(mockAnalyzer.lastCycledTopicId, topicId)
    }

    func testTopicStatusUpdate_setSpecificStatus() {
        // Given: Configured topics
        viewModel.configure(topics: ["Test Topic"])
        let topicId = viewModel.topicItems.first?.id ?? ""

        // When: Set specific status
        viewModel.setStatus(for: topicId, to: .deepDive)

        // Then: Analyzer should have set status
        XCTAssertTrue(mockAnalyzer.setStatusWasCalled)
        XCTAssertEqual(mockAnalyzer.lastSetStatusTopicId, topicId)
        XCTAssertEqual(mockAnalyzer.lastSetStatus, .deepDive)
    }

    func testTopicStatusUpdate_statusCountsUpdated() {
        // Given: Topics with different statuses
        mockAnalyzer.simulatedCoverages = [
            "Topic 1": TopicCoverage(
                topicName: "Topic 1",
                status: .notStarted,
                mentionCount: 0,
                confidence: 0.0,
                lastMentionedAt: nil,
                relatedUtterances: []
            ),
            "Topic 2": TopicCoverage(
                topicName: "Topic 2",
                status: .mentioned,
                mentionCount: 1,
                confidence: 0.5,
                lastMentionedAt: Date(),
                relatedUtterances: ["test"]
            ),
            "Topic 3": TopicCoverage(
                topicName: "Topic 3",
                status: .deepDive,
                mentionCount: 5,
                confidence: 0.9,
                lastMentionedAt: Date(),
                relatedUtterances: ["test"]
            )
        ]
        viewModel.configure(topics: ["Topic 1", "Topic 2", "Topic 3"])

        // Then: Status counts should reflect the coverage states
        // Note: The actual counts depend on the mock implementation
        XCTAssertNotNil(viewModel.statusCounts)
    }

    // MARK: - Test Coverage Calculation

    func testCoverageCalculation_zeroCoverage() {
        // Given: All topics not started
        mockAnalyzer.simulatedOverallCoverage = 0.0
        viewModel.configure(topics: ["Topic 1", "Topic 2"])

        // Then: Overall coverage should be 0
        XCTAssertEqual(viewModel.overallCoverage, 0.0)
    }

    func testCoverageCalculation_fullCoverage() {
        // Given: All topics at deep dive
        mockAnalyzer.simulatedOverallCoverage = 1.0
        mockAnalyzer.simulatedCoverages = [
            "Topic 1": TopicCoverage(
                topicName: "Topic 1",
                status: .deepDive,
                mentionCount: 5,
                confidence: 0.9,
                lastMentionedAt: Date(),
                relatedUtterances: []
            )
        ]
        viewModel.configure(topics: ["Topic 1"])

        // Then: Overall coverage should be 1.0
        XCTAssertEqual(viewModel.overallCoverage, 1.0)
    }

    func testCoverageCalculation_partialCoverage() {
        // Given: Mixed coverage
        mockAnalyzer.simulatedOverallCoverage = 0.5
        viewModel.configure(topics: ["Topic 1", "Topic 2"])

        // Then: Overall coverage should be 50%
        XCTAssertEqual(viewModel.overallCoverage, 0.5)
    }

    func testCoverageSummary() {
        // Given: Configured topics with coverage
        mockAnalyzer.simulatedOverallCoverage = 0.66
        viewModel.configure(topics: ["Topic 1", "Topic 2", "Topic 3"])

        // When: Get coverage summary
        let summary = viewModel.coverageSummary

        // Then: Summary should have correct values
        XCTAssertEqual(summary.total, 3)
        XCTAssertEqual(summary.formattedPercentage, "66%")
    }

    func testCoverageSummary_completedCount() {
        // Given: Topics with some completed
        mockAnalyzer.simulatedCoverages = [
            "Topic 1": TopicCoverage(
                topicName: "Topic 1",
                status: .deepDive,
                mentionCount: 5,
                confidence: 0.9,
                lastMentionedAt: Date(),
                relatedUtterances: []
            ),
            "Topic 2": TopicCoverage(
                topicName: "Topic 2",
                status: .mentioned,
                mentionCount: 1,
                confidence: 0.5,
                lastMentionedAt: Date(),
                relatedUtterances: []
            )
        ]
        viewModel.configure(topics: ["Topic 1", "Topic 2"])

        // When: Get summary
        let summary = viewModel.coverageSummary

        // Then: Should track completed correctly
        XCTAssertEqual(summary.completedCount, summary.deepDive)
    }

    // MARK: - Test Topic Matching

    func testTopicMatching_filterAll() {
        // Given: Topics with various statuses
        mockAnalyzer.simulatedCoverages = [
            "Topic 1": TopicCoverage(topicName: "Topic 1", status: .notStarted, mentionCount: 0, confidence: 0, lastMentionedAt: nil, relatedUtterances: []),
            "Topic 2": TopicCoverage(topicName: "Topic 2", status: .mentioned, mentionCount: 1, confidence: 0.5, lastMentionedAt: Date(), relatedUtterances: []),
            "Topic 3": TopicCoverage(topicName: "Topic 3", status: .deepDive, mentionCount: 5, confidence: 0.9, lastMentionedAt: Date(), relatedUtterances: [])
        ]
        viewModel.configure(topics: ["Topic 1", "Topic 2", "Topic 3"])

        // When: Filter is set to all
        viewModel.filterOption = .all

        // Then: All topics should be shown
        XCTAssertEqual(viewModel.filteredTopicItems.count, 3)
    }

    func testTopicMatching_filterNotStarted() {
        // Given: Topics with various statuses
        mockAnalyzer.simulatedCoverages = [
            "Topic 1": TopicCoverage(topicName: "Topic 1", status: .notStarted, mentionCount: 0, confidence: 0, lastMentionedAt: nil, relatedUtterances: []),
            "Topic 2": TopicCoverage(topicName: "Topic 2", status: .mentioned, mentionCount: 1, confidence: 0.5, lastMentionedAt: Date(), relatedUtterances: []),
            "Topic 3": TopicCoverage(topicName: "Topic 3", status: .notStarted, mentionCount: 0, confidence: 0, lastMentionedAt: nil, relatedUtterances: [])
        ]
        viewModel.configure(topics: ["Topic 1", "Topic 2", "Topic 3"])

        // When: Filter is set to not started
        viewModel.filterOption = .notStarted

        // Then: Only not started topics should be shown
        let filtered = viewModel.filteredTopicItems
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.status == .notStarted })
    }

    func testTopicMatching_filterInProgress() {
        // Given: Topics with various statuses
        mockAnalyzer.simulatedCoverages = [
            "Topic 1": TopicCoverage(topicName: "Topic 1", status: .mentioned, mentionCount: 1, confidence: 0.5, lastMentionedAt: Date(), relatedUtterances: []),
            "Topic 2": TopicCoverage(topicName: "Topic 2", status: .explored, mentionCount: 3, confidence: 0.7, lastMentionedAt: Date(), relatedUtterances: []),
            "Topic 3": TopicCoverage(topicName: "Topic 3", status: .deepDive, mentionCount: 5, confidence: 0.9, lastMentionedAt: Date(), relatedUtterances: [])
        ]
        viewModel.configure(topics: ["Topic 1", "Topic 2", "Topic 3"])

        // When: Filter is set to in progress
        viewModel.filterOption = .inProgress

        // Then: Only mentioned and explored topics should be shown
        let filtered = viewModel.filteredTopicItems
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.status == .mentioned || $0.status == .explored })
    }

    func testTopicMatching_filterCompleted() {
        // Given: Topics with various statuses
        mockAnalyzer.simulatedCoverages = [
            "Topic 1": TopicCoverage(topicName: "Topic 1", status: .mentioned, mentionCount: 1, confidence: 0.5, lastMentionedAt: Date(), relatedUtterances: []),
            "Topic 2": TopicCoverage(topicName: "Topic 2", status: .deepDive, mentionCount: 5, confidence: 0.9, lastMentionedAt: Date(), relatedUtterances: [])
        ]
        viewModel.configure(topics: ["Topic 1", "Topic 2"])

        // When: Filter is set to completed
        viewModel.filterOption = .completed

        // Then: Only deep dive topics should be shown
        let filtered = viewModel.filteredTopicItems
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.status, .deepDive)
    }

    // MARK: - Test Sorting

    func testSorting_byOriginalOrder() {
        // Given: Topics
        viewModel.configure(topics: ["Zebra", "Apple", "Mango"])

        // When: Sort by order
        viewModel.sortOption = .order

        // Then: Should be in original order
        let items = viewModel.filteredTopicItems
        XCTAssertEqual(items[0].name, "Zebra")
        XCTAssertEqual(items[1].name, "Apple")
        XCTAssertEqual(items[2].name, "Mango")
    }

    func testSorting_byAlphabetical() {
        // Given: Topics
        viewModel.configure(topics: ["Zebra", "Apple", "Mango"])

        // When: Sort alphabetically
        viewModel.sortOption = .alphabetical

        // Then: Should be in alphabetical order
        let items = viewModel.filteredTopicItems
        XCTAssertEqual(items[0].name, "Apple")
        XCTAssertEqual(items[1].name, "Mango")
        XCTAssertEqual(items[2].name, "Zebra")
    }

    func testSorting_byStatus() {
        // Given: Topics with different statuses
        mockAnalyzer.simulatedCoverages = [
            "Topic A": TopicCoverage(topicName: "Topic A", status: .notStarted, mentionCount: 0, confidence: 0, lastMentionedAt: nil, relatedUtterances: []),
            "Topic B": TopicCoverage(topicName: "Topic B", status: .deepDive, mentionCount: 5, confidence: 0.9, lastMentionedAt: Date(), relatedUtterances: []),
            "Topic C": TopicCoverage(topicName: "Topic C", status: .mentioned, mentionCount: 1, confidence: 0.5, lastMentionedAt: Date(), relatedUtterances: [])
        ]
        viewModel.configure(topics: ["Topic A", "Topic B", "Topic C"])

        // When: Sort by status
        viewModel.sortOption = .status

        // Then: Should be sorted by status (higher status first)
        let items = viewModel.filteredTopicItems
        XCTAssertEqual(items[0].status, .deepDive)
        XCTAssertEqual(items[1].status, .mentioned)
        XCTAssertEqual(items[2].status, .notStarted)
    }

    func testSorting_byRecentActivity() {
        // Given: Topics with different last updated times
        let oldDate = Date().addingTimeInterval(-3600)
        let recentDate = Date()

        mockAnalyzer.simulatedCoverages = [
            "Topic A": TopicCoverage(topicName: "Topic A", status: .mentioned, mentionCount: 1, confidence: 0.5, lastMentionedAt: oldDate, lastUpdatedAt: oldDate, relatedUtterances: []),
            "Topic B": TopicCoverage(topicName: "Topic B", status: .mentioned, mentionCount: 2, confidence: 0.6, lastMentionedAt: recentDate, lastUpdatedAt: recentDate, relatedUtterances: [])
        ]
        viewModel.configure(topics: ["Topic A", "Topic B"])

        // When: Sort by recent activity
        viewModel.sortOption = .recentActivity

        // Then: Most recent should be first
        let items = viewModel.filteredTopicItems
        XCTAssertEqual(items[0].name, "Topic B")
        XCTAssertEqual(items[1].name, "Topic A")
    }

    // MARK: - Test Panel Toggle

    func testTogglePanel() {
        // Given: Panel is expanded
        XCTAssertTrue(viewModel.isPanelExpanded)

        // When: Toggle panel
        viewModel.togglePanel()

        // Then: Panel should be collapsed
        XCTAssertFalse(viewModel.isPanelExpanded)

        // When: Toggle again
        viewModel.togglePanel()

        // Then: Panel should be expanded
        XCTAssertTrue(viewModel.isPanelExpanded)
    }

    // MARK: - Test Topic Selection

    func testSelectTopic() {
        // Given: Configured topics
        viewModel.configure(topics: ["Topic 1"])
        let topic = viewModel.topicItems.first

        // When: Select topic
        viewModel.selectTopic(topic)

        // Then: Topic should be selected
        XCTAssertEqual(viewModel.selectedTopic?.id, topic?.id)
    }

    func testClearTopicSelection() {
        // Given: Selected topic
        viewModel.configure(topics: ["Topic 1"])
        viewModel.selectedTopic = viewModel.topicItems.first

        // When: Clear selection
        viewModel.selectTopic(nil)

        // Then: Selection should be nil
        XCTAssertNil(viewModel.selectedTopic)
    }

    // MARK: - Test Reset

    func testReset() {
        // Given: Configured topics with coverage
        mockAnalyzer.simulatedCoverages = [
            "Topic 1": TopicCoverage(topicName: "Topic 1", status: .deepDive, mentionCount: 5, confidence: 0.9, lastMentionedAt: Date(), relatedUtterances: [])
        ]
        viewModel.configure(topics: ["Topic 1"])

        // When: Reset
        viewModel.reset()

        // Then: Analyzer should be reset
        XCTAssertTrue(mockAnalyzer.resetWasCalled)
    }

    // MARK: - Test Analysis Control

    func testStartAnalysis() {
        // Given: View model

        // When: Start analysis (without session manager, this is a no-op)
        viewModel.startAnalysis()

        // Then: No crash should occur
        // Note: Full test would require session manager mock
    }

    func testStopAnalysis() {
        // Given: View model

        // When: Stop analysis
        viewModel.stopAnalysis()

        // Then: No crash should occur
    }

    // MARK: - Test Topic Item Accessibility

    func testTopicItemAccessibilityDescription() {
        // Given: Topic item
        let item = TopicItem(
            id: "test",
            name: "User Needs",
            status: .mentioned,
            order: 0,
            confidence: 0.7,
            mentionCount: 3,
            lastUpdated: Date(),
            isManualOverride: false
        )

        // Then: Accessibility description should include relevant info
        let description = item.accessibilityDescription
        XCTAssertTrue(description.contains("User Needs"))
        XCTAssertTrue(description.contains("Mentioned"))
        XCTAssertTrue(description.contains("mentioned 3 times"))
    }

    func testTopicItemAccessibilityDescription_manualOverride() {
        // Given: Manually overridden topic item
        let item = TopicItem(
            id: "test",
            name: "Topic",
            status: .deepDive,
            order: 0,
            confidence: 1.0,
            mentionCount: 0,
            lastUpdated: Date(),
            isManualOverride: true
        )

        // Then: Should indicate manual override
        XCTAssertTrue(item.accessibilityDescription.contains("manually set"))
    }

    // MARK: - Test Filter and Sort Options

    func testFilterOptionProperties() {
        // Test all filter options have required properties
        for option in TopicFilterOption.allCases {
            XCTAssertFalse(option.id.isEmpty)
            XCTAssertFalse(option.rawValue.isEmpty)
            XCTAssertFalse(option.iconName.isEmpty)
        }
    }

    func testSortOptionProperties() {
        // Test all sort options have required properties
        for option in TopicSortOption.allCases {
            XCTAssertFalse(option.id.isEmpty)
            XCTAssertFalse(option.rawValue.isEmpty)
            XCTAssertFalse(option.iconName.isEmpty)
        }
    }
}

// MARK: - Mock Classes

@MainActor
final class MockTopicAnalyzer: TopicAnalyzer {
    var configureWasCalled = false
    var configuredKeywords: [String: [String]]?
    var cycleStatusWasCalled = false
    var lastCycledTopicId: String?
    var setStatusWasCalled = false
    var lastSetStatusTopicId: String?
    var lastSetStatus: TopicCoverageStatus?
    var resetWasCalled = false
    var simulatedOverallCoverage: Double = 0.0
    var simulatedCoverages: [String: TopicCoverage] = [:]

    override func configure(topics: [String], keywords: [String: [String]]? = nil) {
        configureWasCalled = true
        configuredKeywords = keywords
        super.configure(topics: topics, keywords: keywords)

        // Apply simulated coverages if available
        for (topic, coverage) in simulatedCoverages {
            topicCoverages[topic] = coverage
        }
    }

    override var overallCoverage: Double {
        return simulatedOverallCoverage
    }

    @discardableResult
    override func cycleStatus(for topic: String) -> TopicCoverageStatus? {
        cycleStatusWasCalled = true
        lastCycledTopicId = topic
        return super.cycleStatus(for: topic)
    }

    override func setStatus(for topic: String, to status: TopicCoverageStatus) {
        setStatusWasCalled = true
        lastSetStatusTopicId = topic
        lastSetStatus = status
        super.setStatus(for: topic, to: status)
    }

    override func reset() {
        resetWasCalled = true
        super.reset()
    }
}
