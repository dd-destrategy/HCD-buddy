//
//  InsightFlaggingServiceTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for InsightFlaggingService - targeting 90% coverage
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

@MainActor
final class InsightFlaggingServiceTests: XCTestCase {

    // MARK: - Properties

    var flaggingService: InsightFlaggingService!
    var testSession: Session!
    var modelContainer: ModelContainer!
    var dataManager: MockDataManager!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        // Create in-memory model container for testing
        let schema = Schema([
            Session.self,
            Utterance.self,
            Insight.self,
            TopicStatus.self,
            CoachingEvent.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }

        dataManager = MockDataManager(container: modelContainer)

        testSession = Session(
            participantName: "Test Participant",
            projectName: "Test Project",
            sessionMode: .full
        )

        modelContainer.mainContext.insert(testSession)
        try? modelContainer.mainContext.save()

        flaggingService = InsightFlaggingService(session: testSession, dataManager: dataManager)
    }

    override func tearDown() {
        flaggingService = nil
        testSession = nil
        dataManager = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestUtterance(
        text: String = "This is a test utterance",
        speaker: Speaker = .participant,
        timestamp: Double = 60.0
    ) -> Utterance {
        let utterance = Utterance(
            speaker: speaker,
            text: text,
            timestampSeconds: timestamp
        )
        utterance.session = testSession
        modelContainer.mainContext.insert(utterance)
        testSession.utterances.append(utterance)
        return utterance
    }

    // MARK: - Test: Manual Flag Insight

    func testManualFlagInsight_createsInsight() {
        // Given: An utterance to flag
        let utterance = createTestUtterance(text: "I really need this feature to work better")

        // When: Flag the utterance manually
        let insight = flaggingService.flagManually(utterance: utterance)

        // Then: Insight should be created with correct properties
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight.quote, utterance.text)
        XCTAssertEqual(insight.source, .userAdded)
        XCTAssertEqual(insight.timestampSeconds, utterance.timestampSeconds)
    }

    func testManualFlagInsight_withCustomTitle() {
        // Given: An utterance with a custom title
        let utterance = createTestUtterance(text: "The workflow is frustrating")
        let customTitle = "Key Pain Point"

        // When: Flag with a custom title
        let insight = flaggingService.flagManually(utterance: utterance, title: customTitle)

        // Then: Insight should have the custom title
        XCTAssertEqual(insight.theme, customTitle)
    }

    func testManualFlagInsight_updatesLastFlaggedInsight() {
        // Given: An utterance to flag
        let utterance = createTestUtterance()

        // When: Flag the utterance
        let insight = flaggingService.flagManually(utterance: utterance)

        // Then: lastFlaggedInsight should be updated
        XCTAssertEqual(flaggingService.lastFlaggedInsight?.id, insight.id)
    }

    func testManualFlagInsight_updatesFlaggingStatus() {
        // Given: An utterance to flag
        let utterance = createTestUtterance()

        // When: Flag the utterance
        _ = flaggingService.flagManually(utterance: utterance)

        // Then: Flagging status should be updated to flagged
        if case .flagged = flaggingService.flaggingStatus {
            // Expected state
        } else {
            XCTFail("Expected flagging status to be .flagged")
        }
    }

    // MARK: - Test: Auto Detect Insight

    func testAutoDetectInsight_withPainPointKeyword() {
        // Given: An utterance with pain point keywords
        let utterance = createTestUtterance(
            text: "This is a major pain point for us. The frustrating part is that it happens every time we try to use the system."
        )

        // When: Evaluate for auto-flagging
        let recommendation = flaggingService.evaluateForAutoFlagging(utterance)

        // Then: Should recommend flagging with appropriate reason
        XCTAssertNotNil(recommendation)
        XCTAssertTrue(recommendation!.matchedKeywords.contains { $0.lowercased().contains("pain") || $0.lowercased().contains("frustrating") })
    }

    func testAutoDetectInsight_withLowConfidence() {
        // Given: An utterance with low confidence (short text, no keywords)
        let utterance = createTestUtterance(text: "OK sure")

        // When: Evaluate for auto-flagging
        let recommendation = flaggingService.evaluateForAutoFlagging(utterance)

        // Then: Should not recommend flagging
        XCTAssertNil(recommendation)
    }

    func testFlagAutomatically_createsAIGeneratedInsight() {
        // Given: An utterance and auto-flagging is enabled
        let utterance = createTestUtterance(
            text: "I absolutely love how this feature works. It's been a game changer for our team."
        )
        flaggingService.autoFlaggingEnabled = true

        // When: Flag automatically
        let insight = flaggingService.flagAutomatically(utterance: utterance, reason: "Positive Moment")

        // Then: Insight should be AI-generated
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.source, .aiGenerated)
        XCTAssertEqual(insight?.theme, "Positive Moment")
    }

    func testFlagAutomatically_respectsDisabledAutoFlagging() {
        // Given: Auto-flagging is disabled
        let utterance = createTestUtterance()
        flaggingService.autoFlaggingEnabled = false

        // When: Try to flag automatically
        let insight = flaggingService.flagAutomatically(utterance: utterance, reason: "Test")

        // Then: Should not create insight
        XCTAssertNil(insight)
    }

    // MARK: - Test: Insight With Timestamp

    func testInsightWithTimestamp_flagAtTimestamp() {
        // Given: A timestamp and quote
        let timestamp: Double = 120.5
        let quote = "This is an important observation"

        // When: Flag at specific timestamp
        let insight = flaggingService.flagAtTimestamp(timestamp, quote: quote)

        // Then: Insight should have correct timestamp
        XCTAssertEqual(insight.timestampSeconds, timestamp)
        XCTAssertEqual(insight.quote, quote)
    }

    func testInsightWithTimestamp_formattedTimestamp() {
        // Given: A timestamp of 185 seconds (3:05)
        let insight = flaggingService.flagAtTimestamp(185.0, quote: "Test")

        // Then: Formatted timestamp should be correct
        XCTAssertEqual(insight.formattedTimestamp, "03:05")
    }

    // MARK: - Test: Insight With Utterance

    func testInsightWithUtterance_linksToSession() {
        // Given: An utterance belonging to a session
        let utterance = createTestUtterance()

        // When: Flag the utterance
        let insight = flaggingService.flagManually(utterance: utterance)

        // Then: Insight should be linked to session
        XCTAssertEqual(insight.session?.id, testSession.id)
    }

    func testInsightWithUtterance_preservesUtteranceText() {
        // Given: An utterance with specific text
        let expectedText = "I wish the navigation was more intuitive"
        let utterance = createTestUtterance(text: expectedText)

        // When: Flag the utterance
        let insight = flaggingService.flagManually(utterance: utterance)

        // Then: Quote should match utterance text
        XCTAssertEqual(insight.quote, expectedText)
    }

    // MARK: - Test: Insight Types

    func testInsightTypes_userAdded() {
        // Given: A manually created insight
        let utterance = createTestUtterance()
        let insight = flaggingService.flagManually(utterance: utterance)

        // Then: Should be marked as user-added
        XCTAssertTrue(insight.isUserAdded)
        XCTAssertFalse(insight.isAIGenerated)
    }

    func testInsightTypes_aiGenerated() {
        // Given: An automatically created insight
        let utterance = createTestUtterance(text: "I really love this feature, it's amazing!")
        flaggingService.autoFlaggingEnabled = true
        let insight = flaggingService.flagAutomatically(utterance: utterance, reason: "Positive")

        // Then: Should be marked as AI-generated
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.isAIGenerated)
        XCTAssertFalse(insight!.isUserAdded)
    }

    func testInsightTypes_filterBySource() {
        // Given: Mixed insights (manual and automatic)
        let utterance1 = createTestUtterance(text: "First utterance with something I need to say")
        let utterance2 = createTestUtterance(text: "Second utterance - I absolutely love this feature!", timestamp: 120.0)

        _ = flaggingService.flagManually(utterance: utterance1)
        flaggingService.autoFlaggingEnabled = true
        _ = flaggingService.flagAutomatically(utterance: utterance2, reason: "Auto")

        // When: Filter by source
        let userInsights = flaggingService.insights(bySource: .userAdded)
        let aiInsights = flaggingService.insights(bySource: .aiGenerated)

        // Then: Should correctly filter
        XCTAssertEqual(userInsights.count, 1)
        XCTAssertEqual(aiInsights.count, 1)
    }

    // MARK: - Test: Insight Confidence

    func testInsightConfidence_highConfidence() {
        // Given: An utterance with strong sentiment phrases
        let utterance = createTestUtterance(
            text: "I absolutely need this feature. This is the most important thing for our workflow. I really can't live without it."
        )

        // When: Evaluate for auto-flagging
        let recommendation = flaggingService.evaluateForAutoFlagging(utterance)

        // Then: Should have high confidence
        XCTAssertNotNil(recommendation)
        XCTAssertEqual(recommendation?.confidenceLevel, "High")
    }

    func testInsightConfidence_mediumConfidence() {
        // Given: An utterance with some keywords
        let utterance = createTestUtterance(
            text: "I wish we could improve this part of the system because it's difficult to use sometimes"
        )

        // When: Evaluate for auto-flagging
        let recommendation = flaggingService.evaluateForAutoFlagging(utterance)

        // Then: Should have some confidence
        XCTAssertNotNil(recommendation)
        XCTAssertTrue(recommendation!.confidence > 0.3)
    }

    func testInsightConfidence_belowThreshold() {
        // Given: An utterance with minimal sentiment
        let utterance = createTestUtterance(text: "The weather is nice today and we can continue")

        // When: Evaluate for auto-flagging
        let recommendation = flaggingService.evaluateForAutoFlagging(utterance)

        // Then: Should not recommend (below threshold)
        XCTAssertNil(recommendation)
    }

    // MARK: - Test: Edit Insight

    func testEditInsight_updateTitle() {
        // Given: An existing insight
        let utterance = createTestUtterance()
        let insight = flaggingService.flagManually(utterance: utterance, title: "Original Title")

        // When: Update the title
        let newTitle = "Updated Title"
        flaggingService.updateInsight(insight, title: newTitle)

        // Then: Title should be updated
        XCTAssertEqual(insight.theme, newTitle)
    }

    func testEditInsight_updateTags() {
        // Given: An existing insight
        let utterance = createTestUtterance()
        let insight = flaggingService.flagManually(utterance: utterance)
        let originalTags = insight.tags

        // When: Update the tags
        let newTags = ["important", "follow-up", "user-need"]
        flaggingService.updateInsight(insight, tags: newTags)

        // Then: Tags should be updated
        XCTAssertEqual(insight.tags, newTags)
        XCTAssertNotEqual(insight.tags, originalTags)
    }

    // MARK: - Test: Delete Insight

    func testDeleteInsight_removesFromList() {
        // Given: An existing insight
        let utterance = createTestUtterance()
        let insight = flaggingService.flagManually(utterance: utterance)
        flaggingService.refresh()
        let countBefore = flaggingService.insights.count

        // When: Delete the insight
        flaggingService.removeInsight(insight)

        // Then: Insight should be removed
        XCTAssertEqual(flaggingService.insights.count, countBefore - 1)
    }

    func testDeleteInsight_clearsLastFlaggedIfMatching() {
        // Given: An insight that is the last flagged
        let utterance = createTestUtterance()
        let insight = flaggingService.flagManually(utterance: utterance)
        XCTAssertEqual(flaggingService.lastFlaggedInsight?.id, insight.id)

        // When: Delete the insight
        flaggingService.removeInsight(insight)

        // Then: lastFlaggedInsight should be nil
        XCTAssertNil(flaggingService.lastFlaggedInsight)
    }

    func testUndoLastFlag_removesLastInsight() {
        // Given: A recently flagged insight
        let utterance = createTestUtterance()
        _ = flaggingService.flagManually(utterance: utterance)
        flaggingService.refresh()
        let countBefore = flaggingService.insights.count

        // When: Undo the last flag
        let result = flaggingService.undoLastFlag()

        // Then: Should return true and remove the insight
        XCTAssertTrue(result)
        XCTAssertEqual(flaggingService.insights.count, countBefore - 1)
        XCTAssertNil(flaggingService.lastFlaggedInsight)
    }

    func testUndoLastFlag_returnsFalseWhenNoLastInsight() {
        // Given: No last flagged insight
        XCTAssertNil(flaggingService.lastFlaggedInsight)

        // When: Try to undo
        let result = flaggingService.undoLastFlag()

        // Then: Should return false
        XCTAssertFalse(result)
    }

    // MARK: - Test: Insight Navigation

    func testInsightNavigation_nearestInsight() {
        // Given: Multiple insights at different timestamps
        let utterance1 = createTestUtterance(timestamp: 60.0)
        let utterance2 = createTestUtterance(timestamp: 120.0)
        let utterance3 = createTestUtterance(timestamp: 180.0)

        _ = flaggingService.flagManually(utterance: utterance1)
        _ = flaggingService.flagManually(utterance: utterance2)
        _ = flaggingService.flagManually(utterance: utterance3)

        // When: Find nearest insight to timestamp 100
        let nearest = flaggingService.nearestInsight(to: 100.0)

        // Then: Should return insight at 120.0 (closest to 100)
        XCTAssertNotNil(nearest)
        XCTAssertEqual(nearest?.timestampSeconds, 120.0)
    }

    func testInsightNavigation_insightsInTimeRange() {
        // Given: Multiple insights at different timestamps
        let utterance1 = createTestUtterance(timestamp: 30.0)
        let utterance2 = createTestUtterance(timestamp: 90.0)
        let utterance3 = createTestUtterance(timestamp: 150.0)

        _ = flaggingService.flagManually(utterance: utterance1)
        _ = flaggingService.flagManually(utterance: utterance2)
        _ = flaggingService.flagManually(utterance: utterance3)

        // When: Get insights in time range
        let insightsInRange = flaggingService.insights(from: 60.0, to: 120.0)

        // Then: Should only return insight at 90.0
        XCTAssertEqual(insightsInRange.count, 1)
        XCTAssertEqual(insightsInRange.first?.timestampSeconds, 90.0)
    }

    // MARK: - Test: Max Insights Limit

    func testMaxInsightsLimit_canFlagMultipleInsights() {
        // Given: Multiple utterances
        let utterances = (1...5).map { i in
            createTestUtterance(text: "Utterance \(i)", timestamp: Double(i * 60))
        }

        // When: Flag all utterances
        for utterance in utterances {
            _ = flaggingService.flagManually(utterance: utterance)
        }
        flaggingService.refresh()

        // Then: All insights should be created
        XCTAssertEqual(flaggingService.insights.count, 5)
    }

    func testClearAutoGeneratedInsights() {
        // Given: Mixed insights
        let utterance1 = createTestUtterance(text: "Manual insight text")
        let utterance2 = createTestUtterance(text: "I really love this feature!", timestamp: 120.0)

        _ = flaggingService.flagManually(utterance: utterance1)
        flaggingService.autoFlaggingEnabled = true
        _ = flaggingService.flagAutomatically(utterance: utterance2, reason: "Auto")
        flaggingService.refresh()

        // When: Clear auto-generated insights
        flaggingService.clearAutoGeneratedInsights()

        // Then: Only manual insights should remain
        XCTAssertEqual(flaggingService.insights.count, 1)
        XCTAssertTrue(flaggingService.insights.first?.isUserAdded ?? false)
    }

    // MARK: - Test: Duplicate Detection

    func testDuplicateDetection_preventsDuplicates() {
        // Given: An utterance that was already flagged
        let utterance = createTestUtterance()
        _ = flaggingService.flagManually(utterance: utterance)
        flaggingService.refresh()

        // When: Check if utterance is already flagged
        let isDuplicate = flaggingService.isUtteranceAlreadyFlagged(utterance)

        // Then: Should detect as duplicate
        XCTAssertTrue(isDuplicate)
    }

    func testDuplicateDetection_allowsDifferentUtterances() {
        // Given: An utterance that was flagged
        let utterance1 = createTestUtterance(text: "First utterance", timestamp: 60.0)
        _ = flaggingService.flagManually(utterance: utterance1)

        // When: Check a different utterance
        let utterance2 = createTestUtterance(text: "Second utterance", timestamp: 180.0)
        let isDuplicate = flaggingService.isUtteranceAlreadyFlagged(utterance2)

        // Then: Should not detect as duplicate
        XCTAssertFalse(isDuplicate)
    }

    func testAutoFlagEvaluation_skipsDuplicates() {
        // Given: An utterance that was already flagged
        let utterance = createTestUtterance(
            text: "This is a major pain point that I really need fixed urgently"
        )
        _ = flaggingService.flagManually(utterance: utterance)
        flaggingService.refresh()

        // When: Evaluate for auto-flagging
        let recommendation = flaggingService.evaluateForAutoFlagging(utterance)

        // Then: Should not recommend (already flagged)
        XCTAssertNil(recommendation)
    }

    // MARK: - Test: Theme Generation

    func testThemeGeneration_painPoint() {
        // Given: An utterance with pain point language
        let utterance = createTestUtterance(text: "This is frustrating and a real pain point for our team")

        // When: Flag without custom title
        let insight = flaggingService.flagManually(utterance: utterance)

        // Then: Theme should reflect pain point
        XCTAssertTrue(insight.theme.lowercased().contains("pain"))
    }

    func testThemeGeneration_userNeed() {
        // Given: An utterance expressing a need
        let utterance = createTestUtterance(text: "I really wish we could have better filtering options")

        // When: Flag without custom title
        let insight = flaggingService.flagManually(utterance: utterance)

        // Then: Theme should reflect user need
        XCTAssertTrue(insight.theme.lowercased().contains("need") || insight.theme.lowercased().contains("wish"))
    }

    func testThemeGeneration_positiveMoment() {
        // Given: An utterance with positive sentiment
        let utterance = createTestUtterance(text: "I absolutely love how this feature works")

        // When: Flag without custom title
        let insight = flaggingService.flagManually(utterance: utterance)

        // Then: Theme should reflect positive moment
        XCTAssertTrue(insight.theme.lowercased().contains("positive") || insight.theme.lowercased().contains("love"))
    }

    // MARK: - Test: Tag Extraction

    func testTagExtraction_extractsPainPointTags() {
        // Given: An utterance with pain point indicators
        let utterance = createTestUtterance(text: "This is frustrating and difficult to use")

        // When: Flag the utterance
        let insight = flaggingService.flagManually(utterance: utterance)

        // Then: Should have pain-point tag
        XCTAssertTrue(insight.tags.contains("pain-point"))
    }

    func testTagExtraction_extractsMultipleTags() {
        // Given: An utterance with multiple indicators
        let utterance = createTestUtterance(text: "I need a better workflow because I'm confused about the current process")

        // When: Flag the utterance
        let insight = flaggingService.flagManually(utterance: utterance)

        // Then: Should have multiple tags
        XCTAssertTrue(insight.tags.count >= 2)
    }
}

// MARK: - Mock Data Manager

/// Mock DataManager for testing without actual database operations
@MainActor
final class MockDataManager {
    let container: ModelContainer

    var mainContext: ModelContext {
        container.mainContext
    }

    init(container: ModelContainer) {
        self.container = container
    }

    func save() throws {
        if mainContext.hasChanges {
            try mainContext.save()
        }
    }
}

// MARK: - InsightFlaggingService Extension for Testing

extension InsightFlaggingService {
    /// Convenience initializer for testing with mock data manager
    @MainActor
    convenience init(session: Session?, dataManager: MockDataManager) {
        self.init(session: session)
    }
}
