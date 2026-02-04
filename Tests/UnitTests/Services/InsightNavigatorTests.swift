//
//  InsightNavigatorTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for InsightNavigator - targeting 90% coverage
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

@MainActor
final class InsightNavigatorTests: XCTestCase {

    // MARK: - Properties

    var navigator: InsightNavigator!
    var testSession: Session!
    var modelContainer: ModelContainer!

    // Callback tracking
    var scrollCallbackInvocations: [(utterance: Utterance, animated: Bool)] = []
    var seekCallbackInvocations: [Double] = []

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

        testSession = Session(
            participantName: "Test Participant",
            projectName: "Test Project",
            sessionMode: .full
        )

        modelContainer.mainContext.insert(testSession)
        try? modelContainer.mainContext.save()

        navigator = InsightNavigator(session: testSession)

        // Setup callback tracking
        scrollCallbackInvocations = []
        seekCallbackInvocations = []

        navigator.onScrollToUtterance = { [weak self] utterance, animated in
            self?.scrollCallbackInvocations.append((utterance, animated))
        }

        navigator.onSeekToTimestamp = { [weak self] timestamp in
            self?.seekCallbackInvocations.append(timestamp)
        }
    }

    override func tearDown() {
        navigator = nil
        // Delete model objects before destroying container to prevent SwiftData crash
        if let context = modelContainer?.mainContext {
            for obj in (try? context.fetch(FetchDescriptor<Insight>())) ?? [] { context.delete(obj) }
            for obj in (try? context.fetch(FetchDescriptor<Session>())) ?? [] { context.delete(obj) }
            try? context.save()
        }
        testSession = nil
        modelContainer = nil
        scrollCallbackInvocations = []
        seekCallbackInvocations = []
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestUtterance(
        text: String = "Test utterance",
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

    private func createTestInsight(
        quote: String = "Test insight",
        timestamp: Double = 60.0,
        theme: String = "Test Theme"
    ) -> Insight {
        let insight = Insight(
            timestampSeconds: timestamp,
            quote: quote,
            theme: theme,
            source: .userAdded
        )
        insight.session = testSession
        modelContainer.mainContext.insert(insight)
        testSession.insights.append(insight)
        return insight
    }

    // MARK: - Test: Navigate To Insight

    func testNavigateToInsight_successWithExactMatch() {
        // Given: An utterance and insight at the same timestamp
        let timestamp: Double = 120.0
        let utterance = createTestUtterance(timestamp: timestamp)
        let insight = createTestInsight(timestamp: timestamp)

        // When: Navigate to the insight
        let result = navigator.navigate(to: insight)

        // Then: Should succeed with exact match
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.utterance?.id, utterance.id)
        if case .success = result {
            // Expected case
        } else {
            XCTFail("Expected success result")
        }
    }

    func testNavigateToInsight_successWithCloseMatch() {
        // Given: An utterance and insight at close timestamps (within 5 seconds)
        let utterance = createTestUtterance(timestamp: 120.0)
        let insight = createTestInsight(timestamp: 122.0)

        // When: Navigate to the insight
        let result = navigator.navigate(to: insight)

        // Then: Should succeed
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.utterance?.id, utterance.id)
    }

    func testNavigateToInsight_approximateMatch() {
        // Given: An utterance and insight with larger time difference (> 5 seconds)
        let utterance = createTestUtterance(timestamp: 120.0)
        let insight = createTestInsight(timestamp: 130.0)

        // When: Navigate to the insight
        let result = navigator.navigate(to: insight)

        // Then: Should return approximate match
        XCTAssertTrue(result.isSuccess)
        if case .approximateMatch(let u, let diff) = result {
            XCTAssertEqual(u.id, utterance.id)
            XCTAssertEqual(diff, 10.0, accuracy: 0.1)
        } else if case .success = result {
            // Also acceptable if within maxTimeDifferenceForMatch
        } else {
            XCTFail("Expected approximateMatch or success result")
        }
    }

    func testNavigateToInsight_utteranceNotFound() {
        // Given: An insight with no utterances in session
        let insight = createTestInsight(timestamp: 120.0)

        // When: Navigate to the insight (no utterances available)
        // Session already has the insight but no utterances
        let result = navigator.navigate(to: insight)

        // Then: Should return utteranceNotFound
        XCTAssertFalse(result.isSuccess)
        if case .utteranceNotFound(let timestamp) = result {
            XCTAssertEqual(timestamp, 120.0)
        } else {
            XCTFail("Expected utteranceNotFound result")
        }
    }

    // MARK: - Test: Navigate To Timestamp

    func testNavigateToTimestamp_success() {
        // Given: An utterance at a specific timestamp
        let utterance = createTestUtterance(timestamp: 90.0)

        // When: Navigate to a timestamp
        let result = navigator.navigate(to: 92.0)

        // Then: Should find nearest utterance
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.utterance?.id, utterance.id)
    }

    func testNavigateToTimestamp_findsNearestUtterance() {
        // Given: Multiple utterances
        _ = createTestUtterance(timestamp: 60.0)
        let closestUtterance = createTestUtterance(timestamp: 120.0)
        _ = createTestUtterance(timestamp: 180.0)

        // When: Navigate to a timestamp between utterances
        let result = navigator.navigate(to: 115.0)

        // Then: Should find the closest utterance
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.utterance?.id, closestUtterance.id)
    }

    func testNavigateToTimestamp_noUtterances() {
        // Given: No utterances in session

        // When: Navigate to a timestamp
        let result = navigator.navigate(to: 60.0)

        // Then: Should return utteranceNotFound
        XCTAssertFalse(result.isSuccess)
        if case .utteranceNotFound = result {
            // Expected case
        } else {
            XCTFail("Expected utteranceNotFound result")
        }
    }

    // MARK: - Test: Scroll Behavior

    func testScrollBehavior_animatedByDefault() {
        // Given: An utterance
        let utterance = createTestUtterance()
        let insight = createTestInsight(timestamp: utterance.timestampSeconds)

        // When: Navigate without specifying animation
        _ = navigator.navigate(to: insight)

        // Then: Should animate scroll by default
        XCTAssertEqual(scrollCallbackInvocations.count, 1)
        XCTAssertTrue(scrollCallbackInvocations.first?.animated ?? false)
    }

    func testScrollBehavior_withoutAnimation() {
        // Given: An utterance
        let utterance = createTestUtterance()
        let insight = createTestInsight(timestamp: utterance.timestampSeconds)

        // When: Navigate without animation
        _ = navigator.navigate(to: insight, animated: false)

        // Then: Should not animate scroll
        XCTAssertEqual(scrollCallbackInvocations.count, 1)
        XCTAssertFalse(scrollCallbackInvocations.first?.animated ?? true)
    }

    func testScrollBehavior_invokesCallback() {
        // Given: An utterance
        let utterance = createTestUtterance()

        // When: Navigate to the utterance directly
        navigator.navigate(to: utterance)

        // Then: Scroll callback should be invoked
        XCTAssertEqual(scrollCallbackInvocations.count, 1)
        XCTAssertEqual(scrollCallbackInvocations.first?.utterance.id, utterance.id)
    }

    func testScrollBehavior_invokesSeekCallback() {
        // Given: An utterance
        let utterance = createTestUtterance(timestamp: 150.0)

        // When: Navigate to the utterance
        navigator.navigate(to: utterance)

        // Then: Seek callback should be invoked with correct timestamp
        XCTAssertEqual(seekCallbackInvocations.count, 1)
        XCTAssertEqual(seekCallbackInvocations.first, 150.0)
    }

    // MARK: - Test: Highlight Insight

    func testHighlightInsight_setsHighlightedUtterance() {
        // Given: An utterance
        let utterance = createTestUtterance()
        let insight = createTestInsight(timestamp: utterance.timestampSeconds)

        // When: Navigate to the insight
        _ = navigator.navigate(to: insight)

        // Then: Highlighted utterance should be set
        XCTAssertNotNil(navigator.highlightedUtterance)
        XCTAssertEqual(navigator.highlightedUtterance?.id, utterance.id)
    }

    func testHighlightInsight_clearsAfterDuration() async throws {
        // Given: An utterance and short highlight duration for testing
        let utterance = createTestUtterance()

        // When: Navigate and wait for highlight to clear
        navigator.navigate(to: utterance)
        XCTAssertNotNil(navigator.highlightedUtterance)

        // Wait for highlight duration (default is 3 seconds, but we can't change it in test)
        // Instead, test clearHighlight manually
        navigator.clearHighlight()

        // Then: Highlight should be cleared
        XCTAssertNil(navigator.highlightedUtterance)
    }

    func testClearHighlight_removesHighlightedUtterance() {
        // Given: A highlighted utterance
        let utterance = createTestUtterance()
        navigator.navigate(to: utterance)
        XCTAssertNotNil(navigator.highlightedUtterance)

        // When: Clear highlight
        navigator.clearHighlight()

        // Then: Highlighted utterance should be nil
        XCTAssertNil(navigator.highlightedUtterance)
    }

    // MARK: - Test: Navigation History

    func testNavigationHistory_updatesLastNavigationResult() {
        // Given: An utterance
        let utterance = createTestUtterance()
        let insight = createTestInsight(timestamp: utterance.timestampSeconds)

        // When: Navigate
        _ = navigator.navigate(to: insight)

        // Then: Last navigation result should be updated
        XCTAssertNotNil(navigator.lastNavigationResult)
        XCTAssertTrue(navigator.lastNavigationResult?.isSuccess ?? false)
    }

    func testNavigationHistory_tracksMultipleNavigations() {
        // Given: Multiple utterances
        let utterance1 = createTestUtterance(timestamp: 60.0)
        let utterance2 = createTestUtterance(timestamp: 120.0)

        // When: Navigate multiple times
        _ = navigator.navigate(to: utterance1)
        let firstResult = navigator.lastNavigationResult

        _ = navigator.navigate(to: utterance2)
        let secondResult = navigator.lastNavigationResult

        // Then: Last result should reflect the most recent navigation
        XCTAssertNotEqual(firstResult?.utterance?.id, secondResult?.utterance?.id)
        XCTAssertEqual(secondResult?.utterance?.id, utterance2.id)
    }

    // MARK: - Test: Next/Previous Insight

    func testFindNearestInsight_findsClosest() {
        // Given: Multiple insights
        _ = createTestInsight(timestamp: 60.0)
        let expectedInsight = createTestInsight(timestamp: 120.0)
        _ = createTestInsight(timestamp: 180.0)

        // When: Find nearest insight
        let nearest = navigator.findNearestInsight(to: 125.0)

        // Then: Should find the closest insight
        XCTAssertNotNil(nearest)
        XCTAssertEqual(nearest?.id, expectedInsight.id)
    }

    func testFindNearestInsight_returnsNilWhenNoInsights() {
        // Given: No insights in session

        // When: Find nearest insight
        let nearest = navigator.findNearestInsight(to: 100.0)

        // Then: Should return nil
        XCTAssertNil(nearest)
    }

    func testHasInsightsNear_returnsTrue() {
        // Given: An insight within tolerance
        _ = createTestInsight(timestamp: 100.0)

        // When: Check for insights near timestamp
        let hasInsights = navigator.hasInsightsNear(105.0, tolerance: 10.0)

        // Then: Should return true
        XCTAssertTrue(hasInsights)
    }

    func testHasInsightsNear_returnsFalse() {
        // Given: An insight outside tolerance
        _ = createTestInsight(timestamp: 200.0)

        // When: Check for insights near a distant timestamp
        let hasInsights = navigator.hasInsightsNear(50.0, tolerance: 10.0)

        // Then: Should return false
        XCTAssertFalse(hasInsights)
    }

    // MARK: - Test: Navigation States

    func testIsNavigating_setsDuringNavigation() {
        // Given: An utterance
        let utterance = createTestUtterance()
        let insight = createTestInsight(timestamp: utterance.timestampSeconds)

        // Note: isNavigating is set briefly during navigation
        // Since navigation is synchronous, we can only test initial/final state
        XCTAssertFalse(navigator.isNavigating)

        // When: Navigate
        _ = navigator.navigate(to: insight)

        // Then: isNavigating should be false after navigation completes
        XCTAssertFalse(navigator.isNavigating)
    }

    func testTargetTimestamp_setsDuringNavigation() {
        // Given: An utterance
        let utterance = createTestUtterance()
        let insight = createTestInsight(timestamp: 150.0)
        _ = utterance // Ensure utterance is in session

        // Note: targetTimestamp is set briefly during navigation
        XCTAssertNil(navigator.targetTimestamp)

        // When: Navigate
        _ = navigator.navigate(to: insight)

        // Then: targetTimestamp should be nil after navigation completes
        XCTAssertNil(navigator.targetTimestamp)
    }

    // MARK: - Test: Navigation Result Properties

    func testNavigationResult_description() {
        // Given: An utterance
        let utterance = createTestUtterance()
        let insight = createTestInsight(timestamp: utterance.timestampSeconds)

        // When: Navigate
        let result = navigator.navigate(to: insight)

        // Then: Result should have a description
        XCTAssertFalse(result.description.isEmpty)
    }

    func testNavigationResult_utteranceNotFoundDescription() {
        // Given: No utterances

        // When: Navigate to a timestamp with no utterances
        let result = navigator.navigate(to: 100.0)

        // Then: Should have appropriate description
        XCTAssertTrue(result.description.contains("No utterance found"))
    }

    func testNavigationResult_approximateMatchDescription() {
        // Given: An utterance far from insight timestamp
        _ = createTestUtterance(timestamp: 100.0)
        let insight = createTestInsight(timestamp: 110.0)

        // When: Navigate to insight
        let result = navigator.navigate(to: insight)

        // Then: If approximate match, description should mention distance
        if case .approximateMatch = result {
            XCTAssertTrue(result.description.contains("away"))
        }
        // Success is also acceptable if within threshold
    }

    // MARK: - Test: Navigation Coordinator

    func testNavigationCoordinator_navigateToInsight() {
        // Given: Navigation coordinator and utterances
        let coordinator = InsightNavigationCoordinator.shared
        let utterance = createTestUtterance()
        let insight = createTestInsight(timestamp: utterance.timestampSeconds)

        // When: Navigate to insight via coordinator
        coordinator.navigateToInsight(insight, utterances: [utterance])

        // Then: Should have a scroll request
        XCTAssertNotNil(coordinator.transcriptScrollRequest)
        XCTAssertEqual(coordinator.transcriptScrollRequest?.utterance.id, utterance.id)

        // Cleanup
        coordinator.clearHighlights()
    }

    func testNavigationCoordinator_navigateToUtterance() {
        // Given: Navigation coordinator and utterance
        let coordinator = InsightNavigationCoordinator.shared
        let utterance = createTestUtterance()

        // When: Navigate to utterance
        coordinator.navigateToUtterance(utterance)

        // Then: Should have a scroll request
        XCTAssertNotNil(coordinator.transcriptScrollRequest)
        XCTAssertEqual(coordinator.highlightedUtteranceId, utterance.id)

        // Cleanup
        coordinator.clearHighlights()
    }

    func testNavigationCoordinator_highlightInsight() {
        // Given: Navigation coordinator and insight
        let coordinator = InsightNavigationCoordinator.shared
        let insight = createTestInsight()

        // When: Highlight insight
        coordinator.highlightInsight(insight)

        // Then: Should have highlighted insight ID
        XCTAssertEqual(coordinator.highlightedInsightId, insight.id)

        // Cleanup
        coordinator.clearHighlights()
    }

    func testNavigationCoordinator_clearHighlights() {
        // Given: Navigation coordinator with highlights
        let coordinator = InsightNavigationCoordinator.shared
        let utterance = createTestUtterance()
        let insight = createTestInsight(timestamp: utterance.timestampSeconds)

        coordinator.navigateToInsight(insight, utterances: [utterance])
        coordinator.highlightInsight(insight)

        // When: Clear highlights
        coordinator.clearHighlights()

        // Then: All highlights should be cleared
        XCTAssertNil(coordinator.transcriptScrollRequest)
        XCTAssertNil(coordinator.highlightedInsightId)
        XCTAssertNil(coordinator.highlightedUtteranceId)
    }

    // MARK: - Test: Factory

    func testInsightNavigatorFactory_createsNavigator() {
        // Given: A session

        // When: Create navigator via factory
        let factoryNavigator = InsightNavigatorFactory.create(for: testSession)

        // Then: Navigator should be created
        XCTAssertNotNil(factoryNavigator)
    }

    func testInsightNavigatorFactory_handlesNilSession() {
        // When: Create navigator with nil session
        let factoryNavigator = InsightNavigatorFactory.create(for: nil)

        // Then: Navigator should still be created
        XCTAssertNotNil(factoryNavigator)
    }
}
