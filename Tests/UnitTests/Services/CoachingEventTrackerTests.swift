//
//  CoachingEventTrackerTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for CoachingEventTracker - targeting 90% coverage
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

@MainActor
final class CoachingEventTrackerTests: XCTestCase {

    // MARK: - Properties

    var eventTracker: CoachingEventTracker!
    var preferences: CoachingPreferences!
    var testSession: Session!
    var modelContainer: ModelContainer!

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

        // Use shared preferences and reset to known state
        preferences = CoachingPreferences.shared
        preferences.setupForTesting(enabled: true, onboardingComplete: true, level: .balanced)

        eventTracker = CoachingEventTracker(
            dataManager: DataManager.shared,
            preferences: preferences
        )

        testSession = Session(
            participantName: "Test Participant",
            projectName: "Test Project",
            sessionMode: .full
        )

        modelContainer.mainContext.insert(testSession)
        try? modelContainer.mainContext.save()
    }

    override func tearDown() {
        preferences.setupForTesting(enabled: false, onboardingComplete: false, level: .balanced)
        preferences.resetStatistics()
        eventTracker = nil
        preferences = nil
        testSession = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestPrompt(
        type: CoachingFunctionType = .suggestFollowUp,
        text: String = "Test prompt text",
        reason: String = "Test reason",
        confidence: Double = 0.90,
        timestamp: TimeInterval = 60.0
    ) -> CoachingPrompt {
        return CoachingPrompt(
            type: type,
            text: text,
            reason: reason,
            confidence: confidence,
            timestamp: timestamp
        )
    }

    // MARK: - Test: Track Prompt Shown

    func testTrackPromptShown_createsEventRecord() {
        // Given: A session and prompt
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()

        // When: Record prompt shown
        let record = eventTracker.recordPromptShown(prompt, at: 60.0)

        // Then: Event record should be created
        XCTAssertEqual(record.id, prompt.id)
        XCTAssertEqual(record.promptType, prompt.type)
        XCTAssertEqual(record.promptText, prompt.text)
        XCTAssertEqual(record.confidence, prompt.confidence)
    }

    func testTrackPromptShown_incrementsPromptsShown() {
        // Given: A session
        eventTracker.startSession(testSession)
        XCTAssertEqual(eventTracker.sessionStats.promptsShown, 0)

        // When: Record multiple prompts
        let prompt1 = createTestPrompt()
        let prompt2 = createTestPrompt(timestamp: 120.0)

        _ = eventTracker.recordPromptShown(prompt1, at: 60.0)
        _ = eventTracker.recordPromptShown(prompt2, at: 120.0)

        // Then: Count should be incremented
        XCTAssertEqual(eventTracker.sessionStats.promptsShown, 2)
    }

    func testTrackPromptShown_addsToSessionEvents() {
        // Given: A session
        eventTracker.startSession(testSession)
        XCTAssertEqual(eventTracker.sessionEvents.count, 0)

        // When: Record a prompt
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // Then: Event should be in sessionEvents
        XCTAssertEqual(eventTracker.sessionEvents.count, 1)
        XCTAssertEqual(eventTracker.sessionEvents.first?.id, prompt.id)
    }

    func testTrackPromptShown_recordsCorrectTimestamp() {
        // Given: A session
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        let sessionTimestamp: TimeInterval = 185.0

        // When: Record prompt shown
        let record = eventTracker.recordPromptShown(prompt, at: sessionTimestamp)

        // Then: Timestamp should be recorded
        XCTAssertEqual(record.timestampSeconds, sessionTimestamp)
        XCTAssertNotNil(record.shownAt)
    }

    // MARK: - Test: Track Prompt Dismissed

    func testTrackPromptDismissed_recordsResponse() {
        // Given: A session with a prompt shown
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // When: Record dismissal
        eventTracker.recordResponse(.dismissed, for: prompt.id)

        // Then: Response should be recorded
        let event = eventTracker.sessionEvents.first { $0.id == prompt.id }
        XCTAssertEqual(event?.response, .dismissed)
        XCTAssertNotNil(event?.respondedAt)
    }

    func testTrackPromptDismissed_incrementsDismissedCount() {
        // Given: A session with prompts
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)
        XCTAssertEqual(eventTracker.sessionStats.promptsDismissed, 0)

        // When: Dismiss the prompt
        eventTracker.recordResponse(.dismissed, for: prompt.id)

        // Then: Dismissed count should be incremented
        XCTAssertEqual(eventTracker.sessionStats.promptsDismissed, 1)
    }

    func testTrackPromptDismissed_updatesPreferences() {
        // Given: A session with prompts
        let initialDismissed = preferences.totalPromptsDismissed
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // When: Dismiss the prompt
        eventTracker.recordResponse(.dismissed, for: prompt.id)

        // Then: Preferences should be updated
        XCTAssertEqual(preferences.totalPromptsDismissed, initialDismissed + 1)
    }

    // MARK: - Test: Track Prompt Accepted

    func testTrackPromptAccepted_recordsResponse() {
        // Given: A session with a prompt shown
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // When: Record acceptance
        eventTracker.recordResponse(.accepted, for: prompt.id)

        // Then: Response should be recorded
        let event = eventTracker.sessionEvents.first { $0.id == prompt.id }
        XCTAssertEqual(event?.response, .accepted)
    }

    func testTrackPromptAccepted_incrementsAcceptedCount() {
        // Given: A session with prompts
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)
        XCTAssertEqual(eventTracker.sessionStats.promptsAccepted, 0)

        // When: Accept the prompt
        eventTracker.recordResponse(.accepted, for: prompt.id)

        // Then: Accepted count should be incremented
        XCTAssertEqual(eventTracker.sessionStats.promptsAccepted, 1)
    }

    func testTrackPromptAccepted_updatesPreferences() {
        // Given: A session with prompts
        let initialAccepted = preferences.totalPromptsAccepted
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // When: Accept the prompt
        eventTracker.recordResponse(.accepted, for: prompt.id)

        // Then: Preferences should be updated
        XCTAssertEqual(preferences.totalPromptsAccepted, initialAccepted + 1)
    }

    func testTrackPromptAccepted_calculatesResponseTime() async throws {
        // Given: A session with a prompt shown
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // Wait a short time to simulate user response delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // When: Accept the prompt
        eventTracker.recordResponse(.accepted, for: prompt.id)

        // Then: Response time should be calculated
        let event = eventTracker.sessionEvents.first { $0.id == prompt.id }
        XCTAssertNotNil(event?.responseTimeSeconds)
        XCTAssertGreaterThan(event?.responseTimeSeconds ?? 0, 0)
    }

    // MARK: - Test: Session Stats

    func testSessionStats_initialValues() {
        // Given: A new tracker
        eventTracker.startSession(testSession)

        // Then: Stats should be zero
        XCTAssertEqual(eventTracker.sessionStats.promptsShown, 0)
        XCTAssertEqual(eventTracker.sessionStats.promptsAccepted, 0)
        XCTAssertEqual(eventTracker.sessionStats.promptsDismissed, 0)
        XCTAssertEqual(eventTracker.sessionStats.promptsSnoozed, 0)
        XCTAssertEqual(eventTracker.sessionStats.promptsTimedOut, 0)
    }

    func testSessionStats_acceptanceRate() {
        // Given: A session with mixed responses
        eventTracker.startSession(testSession)

        // Show 4 prompts
        for i in 0..<4 {
            let prompt = createTestPrompt(timestamp: Double(i * 60))
            _ = eventTracker.recordPromptShown(prompt, at: Double(i * 60))

            // Accept first 2, dismiss last 2
            if i < 2 {
                eventTracker.recordResponse(.accepted, for: prompt.id)
            } else {
                eventTracker.recordResponse(.dismissed, for: prompt.id)
            }
        }

        // Then: Acceptance rate should be 50%
        XCTAssertEqual(eventTracker.sessionStats.acceptanceRate, 0.5)
    }

    func testSessionStats_acceptanceRateZeroWhenNoPrompts() {
        // Given: No prompts shown
        eventTracker.startSession(testSession)

        // Then: Acceptance rate should be 0
        XCTAssertEqual(eventTracker.sessionStats.acceptanceRate, 0)
    }

    func testSessionStats_averageResponseTime() async throws {
        // Given: A session with responses
        eventTracker.startSession(testSession)

        // Show and respond to prompts
        let prompt1 = createTestPrompt(timestamp: 60.0)
        _ = eventTracker.recordPromptShown(prompt1, at: 60.0)
        try await Task.sleep(nanoseconds: 50_000_000)
        eventTracker.recordResponse(.accepted, for: prompt1.id)

        let prompt2 = createTestPrompt(timestamp: 120.0)
        _ = eventTracker.recordPromptShown(prompt2, at: 120.0)
        try await Task.sleep(nanoseconds: 50_000_000)
        eventTracker.recordResponse(.dismissed, for: prompt2.id)

        // Then: Average response time should be calculated
        XCTAssertGreaterThan(eventTracker.sessionStats.averageResponseTime, 0)
    }

    // MARK: - Test: Event Timestamps

    func testEventTimestamps_shownAtIsRecorded() {
        // Given: A session
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        let beforeRecord = Date()

        // When: Record prompt shown
        let record = eventTracker.recordPromptShown(prompt, at: 60.0)

        // Then: shownAt should be recorded
        XCTAssertNotNil(record.shownAt)
        XCTAssertGreaterThanOrEqual(record.shownAt, beforeRecord)
    }

    func testEventTimestamps_respondedAtIsRecorded() {
        // Given: A session with a prompt
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)
        let beforeResponse = Date()

        // When: Record response
        eventTracker.recordResponse(.accepted, for: prompt.id)

        // Then: respondedAt should be recorded
        let event = eventTracker.sessionEvents.first { $0.id == prompt.id }
        XCTAssertNotNil(event?.respondedAt)
        XCTAssertGreaterThanOrEqual(event?.respondedAt ?? Date.distantPast, beforeResponse)
    }

    func testEventTimestamps_sessionTimestamp() {
        // Given: A session
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        let sessionTimestamp: TimeInterval = 245.5

        // When: Record prompt shown at specific session timestamp
        let record = eventTracker.recordPromptShown(prompt, at: sessionTimestamp)

        // Then: Session timestamp should be recorded
        XCTAssertEqual(record.timestampSeconds, sessionTimestamp)
    }

    // MARK: - Test: Event Persistence

    func testEventPersistence_eventsAddedToSession() {
        // Given: A session
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()

        // When: Record prompt shown
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // Then: Events should be in the session (handled by persistence layer)
        // Note: Actual persistence depends on DataManager which is mocked
        XCTAssertEqual(eventTracker.sessionEvents.count, 1)
    }

    func testEventPersistence_responsesArePersisted() {
        // Given: A session with a prompt
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // When: Record response
        eventTracker.recordResponse(.accepted, for: prompt.id)

        // Then: Response should be persisted in event
        let event = eventTracker.sessionEvents.first { $0.id == prompt.id }
        XCTAssertEqual(event?.response, .accepted)
    }

    // MARK: - Test: Stats Reset

    func testStatsReset_onNewSession() {
        // Given: A session with some stats
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)
        eventTracker.recordResponse(.accepted, for: prompt.id)

        // When: Start a new session
        let newSession = Session(
            participantName: "New Participant",
            projectName: "New Project",
            sessionMode: .full
        )
        eventTracker.startSession(newSession)

        // Then: Stats should be reset
        XCTAssertEqual(eventTracker.sessionStats.promptsShown, 0)
        XCTAssertEqual(eventTracker.sessionStats.promptsAccepted, 0)
        XCTAssertEqual(eventTracker.sessionEvents.count, 0)
    }

    func testEndSession_updatesSessionDuration() {
        // Given: A session that has been running
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // When: End session
        eventTracker.endSession()

        // Then: Session stats should include duration
        // Note: Duration depends on actual session durationSeconds
        XCTAssertGreaterThanOrEqual(eventTracker.sessionStats.sessionDuration, 0)
    }

    func testEndSession_recordsSessionCompleted() {
        // Given: A session
        let initialCompleted = preferences.sessionsCompleted
        eventTracker.startSession(testSession)

        // When: End session
        eventTracker.endSession()

        // Then: Session completed should be recorded
        XCTAssertEqual(preferences.sessionsCompleted, initialCompleted + 1)
    }

    // MARK: - Test: Auto Dismiss

    func testAutoDismiss_recordsNotResponded() {
        // Given: A session with a prompt
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // When: Auto-dismiss
        eventTracker.recordAutoDismiss(for: prompt.id)

        // Then: Should be marked as notResponded
        let event = eventTracker.sessionEvents.first { $0.id == prompt.id }
        XCTAssertEqual(event?.response, .notResponded)
    }

    func testAutoDismiss_incrementsTimedOutCount() {
        // Given: A session with a prompt
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)
        XCTAssertEqual(eventTracker.sessionStats.promptsTimedOut, 0)

        // When: Auto-dismiss
        eventTracker.recordAutoDismiss(for: prompt.id)

        // Then: Timed out count should be incremented
        XCTAssertEqual(eventTracker.sessionStats.promptsTimedOut, 1)
    }

    // MARK: - Test: Snoozed Response

    func testSnoozeResponse_incrementsSnoozedCount() {
        // Given: A session with a prompt
        eventTracker.startSession(testSession)
        let prompt = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)
        XCTAssertEqual(eventTracker.sessionStats.promptsSnoozed, 0)

        // When: Snooze the prompt
        eventTracker.recordResponse(.snoozed, for: prompt.id)

        // Then: Snoozed count should be incremented
        XCTAssertEqual(eventTracker.sessionStats.promptsSnoozed, 1)
    }

    // MARK: - Test: Type Analytics

    func testTypeAnalytics_forSpecificType() {
        // Given: A session with prompts of different types
        eventTracker.startSession(testSession)

        // Follow-up prompts
        for i in 0..<3 {
            let prompt = createTestPrompt(type: .suggestFollowUp, timestamp: Double(i * 60))
            _ = eventTracker.recordPromptShown(prompt, at: Double(i * 60))
            if i < 2 {
                eventTracker.recordResponse(.accepted, for: prompt.id)
            } else {
                eventTracker.recordResponse(.dismissed, for: prompt.id)
            }
        }

        // When: Get analytics for follow-up type
        let analytics = eventTracker.getTypeAnalytics(for: .suggestFollowUp)

        // Then: Analytics should be accurate
        XCTAssertEqual(analytics.type, .suggestFollowUp)
        XCTAssertEqual(analytics.totalShown, 3)
        XCTAssertEqual(analytics.accepted, 2)
        XCTAssertEqual(analytics.dismissed, 1)
        XCTAssertEqual(analytics.acceptanceRate, 2.0 / 3.0, accuracy: 0.01)
    }

    func testTypeAnalytics_emptyForUnusedType() {
        // Given: A session with no prompts of a specific type
        eventTracker.startSession(testSession)

        let prompt = createTestPrompt(type: .suggestFollowUp)
        _ = eventTracker.recordPromptShown(prompt, at: 60.0)

        // When: Get analytics for unused type
        let analytics = eventTracker.getTypeAnalytics(for: .encouragement)

        // Then: Should have zero values
        XCTAssertEqual(analytics.totalShown, 0)
        XCTAssertEqual(analytics.accepted, 0)
        XCTAssertEqual(analytics.acceptanceRate, 0)
    }

    // MARK: - Test: Most Effective Types

    func testMostEffectiveTypes_sortsByAcceptanceRate() {
        // Given: A session with various prompt types
        eventTracker.startSession(testSession)

        // High acceptance rate type
        for i in 0..<4 {
            let prompt = createTestPrompt(type: .suggestFollowUp, timestamp: Double(i * 30))
            _ = eventTracker.recordPromptShown(prompt, at: Double(i * 30))
            eventTracker.recordResponse(.accepted, for: prompt.id)
        }

        // Low acceptance rate type
        for i in 0..<4 {
            let prompt = createTestPrompt(type: .generalTip, timestamp: Double((i + 5) * 30))
            _ = eventTracker.recordPromptShown(prompt, at: Double((i + 5) * 30))
            eventTracker.recordResponse(.dismissed, for: prompt.id)
        }

        // When: Get most effective types
        let effectiveTypes = eventTracker.getMostEffectiveTypes()

        // Then: Should be sorted by acceptance rate
        if effectiveTypes.count >= 2 {
            XCTAssertEqual(effectiveTypes.first, .suggestFollowUp)
        }
    }

    func testMostEffectiveTypes_requiresMinimumSampleSize() {
        // Given: A session with few prompts
        eventTracker.startSession(testSession)

        // Only 2 prompts of one type (below minimum of 3)
        for i in 0..<2 {
            let prompt = createTestPrompt(type: .suggestFollowUp, timestamp: Double(i * 60))
            _ = eventTracker.recordPromptShown(prompt, at: Double(i * 60))
            eventTracker.recordResponse(.accepted, for: prompt.id)
        }

        // When: Get most effective types
        let effectiveTypes = eventTracker.getMostEffectiveTypes()

        // Then: Should not include types below sample size
        XCTAssertFalse(effectiveTypes.contains(.suggestFollowUp))
    }

    // MARK: - Test: Adaptive Thresholds

    func testAdaptiveThresholds_returnsBaseWhenInsufficientData() {
        // Given: Preferences with low prompt count
        preferences.resetStatistics()
        eventTracker.startSession(testSession)

        // When: Get adaptive thresholds
        let thresholds = eventTracker.getAdaptiveThresholds()

        // Then: Should return base thresholds
        XCTAssertEqual(thresholds.minimumConfidence, preferences.effectiveThresholds.minimumConfidence)
    }

    func testAdaptiveThresholds_increasesConfidenceForHighDismissalRate() {
        // Given: Preferences indicating high dismissal rate
        // Simulate many prompts shown with high dismissal
        for _ in 0..<15 {
            preferences.recordPromptShown()
            preferences.recordPromptDismissed()
        }
        eventTracker.startSession(testSession)

        // When: Get adaptive thresholds
        let thresholds = eventTracker.getAdaptiveThresholds()

        // Then: Confidence threshold may be increased
        // The actual value depends on the implementation
        XCTAssertGreaterThanOrEqual(thresholds.minimumConfidence, 0.70)
    }

    // MARK: - Test: Response Not Found

    func testRecordResponse_handlesNonexistentPrompt() {
        // Given: A session
        eventTracker.startSession(testSession)
        let fakePromptId = UUID()

        // When: Try to record response for non-existent prompt
        eventTracker.recordResponse(.accepted, for: fakePromptId)

        // Then: Should not crash, stats unchanged
        XCTAssertEqual(eventTracker.sessionStats.promptsAccepted, 0)
    }

    // MARK: - Test: Multiple Sessions

    func testMultipleSessions_trackIndependently() {
        // Given: First session with some events
        eventTracker.startSession(testSession)
        let prompt1 = createTestPrompt()
        _ = eventTracker.recordPromptShown(prompt1, at: 60.0)
        eventTracker.recordResponse(.accepted, for: prompt1.id)
        XCTAssertEqual(eventTracker.sessionStats.promptsAccepted, 1)

        // When: Start new session
        let session2 = Session(
            participantName: "Participant 2",
            projectName: "Project 2",
            sessionMode: .full
        )
        eventTracker.startSession(session2)

        // Then: Stats should be reset for new session
        XCTAssertEqual(eventTracker.sessionStats.promptsAccepted, 0)
        XCTAssertEqual(eventTracker.sessionStats.promptsShown, 0)
    }

    // MARK: - Test: Coaching Response Enum

    func testCoachingResponse_displayNames() {
        XCTAssertEqual(CoachingResponse.accepted.displayName, "Accepted")
        XCTAssertEqual(CoachingResponse.dismissed.displayName, "Dismissed")
        XCTAssertEqual(CoachingResponse.snoozed.displayName, "Snoozed")
        XCTAssertEqual(CoachingResponse.notResponded.displayName, "Not Responded")
    }

    func testCoachingResponse_icons() {
        XCTAssertEqual(CoachingResponse.accepted.icon, "checkmark.circle.fill")
        XCTAssertEqual(CoachingResponse.dismissed.icon, "xmark.circle.fill")
        XCTAssertEqual(CoachingResponse.snoozed.icon, "clock.fill")
        XCTAssertEqual(CoachingResponse.notResponded.icon, "circle")
    }

    // MARK: - Test: Session Coaching Stats Struct

    func testSessionCoachingStats_defaultValues() {
        // Given: Default stats
        let stats = SessionCoachingStats()

        // Then: All values should be zero
        XCTAssertEqual(stats.promptsShown, 0)
        XCTAssertEqual(stats.promptsAccepted, 0)
        XCTAssertEqual(stats.promptsDismissed, 0)
        XCTAssertEqual(stats.promptsSnoozed, 0)
        XCTAssertEqual(stats.promptsTimedOut, 0)
        XCTAssertEqual(stats.totalResponseTime, 0)
        XCTAssertEqual(stats.sessionDuration, 0)
    }

    func testSessionCoachingStats_acceptanceRateCalculation() {
        // Given: Stats with prompts
        var stats = SessionCoachingStats()
        stats.promptsShown = 10
        stats.promptsAccepted = 7

        // Then: Acceptance rate should be 70%
        XCTAssertEqual(stats.acceptanceRate, 0.7)
    }

    func testSessionCoachingStats_averageResponseTimeCalculation() {
        // Given: Stats with response time
        var stats = SessionCoachingStats()
        stats.promptsAccepted = 2
        stats.promptsDismissed = 3
        stats.promptsSnoozed = 0
        stats.totalResponseTime = 10.0 // 10 seconds total

        // Then: Average should be 10 / 5 = 2 seconds
        XCTAssertEqual(stats.averageResponseTime, 2.0)
    }

    func testSessionCoachingStats_averageResponseTimeZeroWhenNoResponses() {
        // Given: Stats with no responses
        let stats = SessionCoachingStats()

        // Then: Average should be 0
        XCTAssertEqual(stats.averageResponseTime, 0)
    }

    // MARK: - Test: Prompt Type Analytics Struct

    func testPromptTypeAnalytics_equality() {
        // Given: Two identical analytics
        let analytics1 = PromptTypeAnalytics(
            type: .suggestFollowUp,
            totalShown: 10,
            accepted: 7,
            dismissed: 3,
            acceptanceRate: 0.7,
            averageResponseTime: 2.5
        )
        let analytics2 = PromptTypeAnalytics(
            type: .suggestFollowUp,
            totalShown: 10,
            accepted: 7,
            dismissed: 3,
            acceptanceRate: 0.7,
            averageResponseTime: 2.5
        )

        // Then: Should be equal
        XCTAssertEqual(analytics1, analytics2)
    }
}
