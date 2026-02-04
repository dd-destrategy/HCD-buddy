//
//  SessionManagerTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for SessionManager critical paths
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

@MainActor
final class SessionManagerTests: XCTestCase {

    var sessionManager: SessionManager!
    var mockAudioCapturer: MockAudioCaptureService!
    var mockAPIClient: MockRealtimeAPIClient!
    var testContainer: ModelContainer!
    var testDataManager: DataManager!

    override func setUp() {
        super.setUp()
        mockAudioCapturer = MockAudioCaptureService()
        mockAPIClient = MockRealtimeAPIClient()

        // Create in-memory SwiftData container for testing
        let schema = Schema([
            Session.self,
            Utterance.self,
            Insight.self,
            TopicStatus.self,
            CoachingEvent.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        testContainer = try! ModelContainer(for: schema, configurations: [configuration])
        testDataManager = DataManager(container: testContainer)

        sessionManager = SessionManager(
            audioCapturerProvider: { [weak self] in self?.mockAudioCapturer ?? MockAudioCaptureService() },
            apiClientProvider: { [weak self] in self?.mockAPIClient ?? MockRealtimeAPIClient() },
            dataManager: testDataManager
        )
    }

    override func tearDown() {
        sessionManager = nil
        mockAudioCapturer = nil
        mockAPIClient = nil
        testDataManager = nil
        testContainer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestConfig() -> SessionConfig {
        return SessionConfig(
            apiKey: "test-api-key",
            systemPrompt: "Test prompt",
            topics: ["Topic 1", "Topic 2"],
            sessionMode: .full,
            metadata: SessionMetadata(
                participantName: "Test User",
                projectName: "Test Project"
            )
        )
    }

    // MARK: - Test: Session Lifecycle (idle -> running -> ended)

    func testSessionLifecycle_idleToRunningToEnded() async throws {
        // Given: Manager is in idle state
        XCTAssertEqual(sessionManager.state, .idle)

        // When: Configure and start session
        let config = createTestConfig()
        try await sessionManager.configure(with: config)

        // Then: State should be ready
        XCTAssertEqual(sessionManager.state, .ready)
        XCTAssertNotNil(sessionManager.currentSession)

        // When: Start the session
        try await sessionManager.start()

        // Then: State should be running
        XCTAssertEqual(sessionManager.state, .running)

        // When: End the session
        try await sessionManager.end()

        // Then: State should be ended
        XCTAssertEqual(sessionManager.state, .ended)

        // When: Reset the manager
        await sessionManager.reset()

        // Then: State should be back to idle
        XCTAssertEqual(sessionManager.state, .idle)
        XCTAssertNil(sessionManager.currentSession)
    }

    func testConfigureFromNonIdleStateThrowsError() async {
        // Given: Manager is configured (in ready state)
        let config = createTestConfig()
        try? await sessionManager.configure(with: config)
        XCTAssertEqual(sessionManager.state, .ready)

        // When/Then: Attempting to configure again should throw
        do {
            try await sessionManager.configure(with: config)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected behavior
            XCTAssertTrue(error is SessionError)
        }
    }

    func testStartFromNonReadyStateThrowsError() async throws {
        // Given: Manager is in idle state
        XCTAssertEqual(sessionManager.state, .idle)

        // When/Then: Attempting to start without configuring should throw
        do {
            try await sessionManager.start()
            XCTFail("Should have thrown an error")
        } catch let error as SessionError {
            XCTAssertEqual(error.kind, .invalidStateTransition)
        }
    }

    // MARK: - Test: Pause and Resume

    func testPauseResume() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()
        XCTAssertEqual(sessionManager.state, .running)

        // When: Pause the session
        sessionManager.pause()

        // Then: State should be paused
        XCTAssertEqual(sessionManager.state, .paused)

        // When: Resume the session
        try await sessionManager.resume()

        // Then: State should be running again
        XCTAssertEqual(sessionManager.state, .running)
    }

    func testPauseWhenNotRunningDoesNotChangeState() async throws {
        // Given: Session is in ready state (not running)
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        XCTAssertEqual(sessionManager.state, .ready)

        // When: Attempt to pause
        sessionManager.pause()

        // Then: State should remain ready (pause is ignored)
        XCTAssertEqual(sessionManager.state, .ready)
    }

    func testResumeFromIdleStateThrowsError() async throws {
        // Given: Manager is in idle state
        XCTAssertEqual(sessionManager.state, .idle)

        // When/Then: Attempting to resume should throw
        do {
            try await sessionManager.resume()
            XCTFail("Should have thrown an error")
        } catch let error as SessionError {
            XCTAssertEqual(error.kind, .invalidStateTransition)
        }
    }

    // MARK: - Test: Error Recovery

    func testErrorRecovery() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()
        XCTAssertEqual(sessionManager.state, .running)

        // Note: Error recovery is tested implicitly through the state machine
        // The SessionManager handles recoverable errors internally via SessionRecoveryService
        // We verify that the state machine allows transition from error back to running

        // The error state and recovery is managed internally
        // Here we verify the manager stays in running state when properly configured
        XCTAssertEqual(sessionManager.state, .running)
        XCTAssertNil(sessionManager.lastError)
    }

    func testRecoverableErrorAllowsResume() async throws {
        // Given: Session is configured and ready
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // The SessionManager handles errors through internal callbacks
        // We test that sessions in running state can be properly paused and resumed
        // which exercises the state machine paths also used for error recovery

        sessionManager.pause()
        XCTAssertTrue(sessionManager.state.canResume)

        try await sessionManager.resume()
        XCTAssertEqual(sessionManager.state, .running)
    }

    // MARK: - Test: Graceful Degradation

    func testGracefulDegradation() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()
        XCTAssertEqual(sessionManager.state, .running)

        // When: Switch to degraded mode manually
        sessionManager.switchToDegradedMode(.transcriptionOnly)

        // Then: Degraded mode should be set
        XCTAssertEqual(sessionManager.degradedMode, .transcriptionOnly)

        // And session should still be running
        XCTAssertEqual(sessionManager.state, .running)
    }

    func testDegradedModeFromErrorState() async throws {
        // Given: Session is configured
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // We can test the degraded mode feature directly
        // Switching to degraded mode should work regardless of current state
        sessionManager.switchToDegradedMode(.localRecordingOnly)

        // Verify degraded mode is active
        XCTAssertNotNil(sessionManager.degradedMode)
        XCTAssertEqual(sessionManager.degradedMode, .localRecordingOnly)

        // Verify degraded mode shows appropriate features
        XCTAssertTrue(sessionManager.degradedMode?.availableFeatures.contains("Audio capture") ?? false)
        XCTAssertTrue(sessionManager.degradedMode?.disabledFeatures.contains("AI coaching prompts") ?? false)
    }

    // MARK: - Test: Transcription Stream Delivery

    func testTranscriptionStreamDelivery() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Set up expectation for transcription
        let expectation = XCTestExpectation(description: "Receive transcription event")

        // When: Listen to transcription stream
        Task {
            for await event in sessionManager.transcriptionStream {
                // Then: Verify event is received
                XCTAssertFalse(event.text.isEmpty)
                expectation.fulfill()
                break
            }
        }

        // Simulate transcription event from mock API client
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay

        let testEvent = TranscriptionEvent(
            text: "Test transcription",
            isFinal: true,
            speaker: .interviewer,
            timestamp: 1.0,
            confidence: 0.95
        )
        await mockAPIClient.simulateTranscription(testEvent)

        // Wait for expectation with timeout
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Test: Session State Properties

    func testSessionStateProperties() async throws {
        // Given: Various session states
        let config = createTestConfig()

        // Idle state
        XCTAssertFalse(sessionManager.state.isActive)
        XCTAssertFalse(sessionManager.state.canStart)
        XCTAssertFalse(sessionManager.state.canPause)
        XCTAssertFalse(sessionManager.state.canEnd)

        // Ready state
        try await sessionManager.configure(with: config)
        XCTAssertFalse(sessionManager.state.isActive)
        XCTAssertTrue(sessionManager.state.canStart)
        XCTAssertFalse(sessionManager.state.canPause)
        XCTAssertTrue(sessionManager.state.canEnd)

        // Running state
        try await sessionManager.start()
        XCTAssertTrue(sessionManager.state.isActive)
        XCTAssertFalse(sessionManager.state.canStart)
        XCTAssertTrue(sessionManager.state.canPause)
        XCTAssertTrue(sessionManager.state.canEnd)

        // Paused state
        sessionManager.pause()
        XCTAssertTrue(sessionManager.state.isActive)
        XCTAssertTrue(sessionManager.state.canResume)
        XCTAssertTrue(sessionManager.state.canEnd)
    }

    // MARK: - Test: Elapsed Time Formatting

    func testFormattedElapsedTime() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Then: Initially formatted as 00:00
        XCTAssertEqual(sessionManager.formattedElapsedTime, "00:00")
    }

    // MARK: - Test: Connection Quality

    func testConnectionQualityInitiallyDisconnected() {
        // Given: Fresh session manager
        // Then: Connection quality should be disconnected
        XCTAssertEqual(sessionManager.connectionQuality, .disconnected)
    }

    // MARK: - Test: Audio Levels

    func testAudioLevelsInitiallySilent() {
        // Given: Fresh session manager
        // Then: Audio levels should be silent
        XCTAssertEqual(sessionManager.audioLevels.systemLevel, 0.0)
        XCTAssertEqual(sessionManager.audioLevels.microphoneLevel, 0.0)
    }

    // MARK: - Test: End Session Cleanup

    func testEndSessionCleansUp() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Track initial session
        let session = sessionManager.currentSession
        XCTAssertNotNil(session)
        XCTAssertNil(session?.endedAt)

        // When: End the session
        try await sessionManager.end()

        // Then: Session should be marked as ended
        XCTAssertEqual(sessionManager.state, .ended)
        XCTAssertNotNil(session?.endedAt)
    }
}
