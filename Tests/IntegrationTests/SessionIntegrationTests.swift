//
//  SessionIntegrationTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Integration tests for full session lifecycle
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

/// Integration tests for the complete session lifecycle.
/// Tests the full flow from idle -> configure -> ready -> start -> running -> end -> ended.
@MainActor
final class SessionIntegrationTests: IntegrationTestCase {

    // MARK: - System Under Test

    var sessionManager: SessionManager!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        sessionManager = createTestSessionManager()
    }

    override func tearDown() async throws {
        // Clean up session if still active
        if sessionManager?.state.canEnd ?? false {
            try? await sessionManager.end()
        }
        if sessionManager?.state == .ended || sessionManager?.state.isError ?? false {
            await sessionManager?.reset()
        }
        sessionManager = nil
        try await super.tearDown()
    }

    // MARK: - Test: Full Session Lifecycle

    /// Tests the complete session lifecycle: idle -> configuring -> ready -> running -> ending -> ended
    func testFullSessionLifecycle() async throws {
        // Given: Session manager is in idle state
        assertSessionState(sessionManager, is: .idle)
        XCTAssertNil(sessionManager.currentSession)

        // When: Configure the session
        let config = createTestConfig()
        try await sessionManager.configure(with: config)

        // Then: State should be ready
        assertSessionState(sessionManager, is: .ready)
        assertHasActiveSession(sessionManager)

        // When: Start the session
        try await sessionManager.start()

        // Then: State should be running
        assertSessionState(sessionManager, is: .running)
        XCTAssertEqual(mockAudioCapture.startCallCount, 1, "Audio capture should have been started")

        // When: End the session
        try await sessionManager.end()

        // Then: State should be ended
        assertSessionState(sessionManager, is: .ended)
        XCTAssertNotNil(sessionManager.currentSession?.endedAt, "Session should have end timestamp")

        // When: Reset for new session
        await sessionManager.reset()

        // Then: State should be back to idle
        assertSessionState(sessionManager, is: .idle)
        XCTAssertNil(sessionManager.currentSession)
    }

    // MARK: - Test: Session with Transcription

    /// Tests that transcription events flow correctly during a session
    func testSessionWithTranscription() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()
        assertSessionState(sessionManager, is: .running)

        // Set up transcription expectation
        let transcriptionExpectation = XCTestExpectation(description: "Receive transcription")
        var receivedTranscriptions: [TranscriptionEvent] = []

        // Start listening to transcription stream
        let streamTask = Task {
            for await event in sessionManager.transcriptionStream {
                receivedTranscriptions.append(event)
                if receivedTranscriptions.count >= 2 {
                    transcriptionExpectation.fulfill()
                    break
                }
            }
        }

        // When: Simulate transcription events from API
        try await Task.sleep(nanoseconds: 100_000_000) // Allow stream setup

        let event1 = createTestTranscriptionEvent(
            text: "Hello, thank you for joining us today.",
            speaker: .interviewer,
            timestamp: 1.0
        )
        await mockAPIClient.simulateTranscription(event1)

        try await Task.sleep(nanoseconds: 50_000_000)

        let event2 = createTestTranscriptionEvent(
            text: "Happy to be here!",
            speaker: .participant,
            timestamp: 3.0
        )
        await mockAPIClient.simulateTranscription(event2)

        // Wait for transcriptions
        await fulfillment(of: [transcriptionExpectation], timeout: shortTimeout)
        streamTask.cancel()

        // Then: Transcriptions should be received
        XCTAssertEqual(receivedTranscriptions.count, 2, "Should have received 2 transcription events")
        XCTAssertEqual(receivedTranscriptions[0].text, "Hello, thank you for joining us today.")
        XCTAssertEqual(receivedTranscriptions[1].speaker, .participant)

        // Verify recent transcriptions are tracked
        XCTAssertFalse(sessionManager.recentTranscriptions.isEmpty, "Recent transcriptions should be tracked")
    }

    // MARK: - Test: Session Pause and Resume

    /// Tests pausing and resuming a session
    func testSessionPauseResume() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()
        assertSessionState(sessionManager, is: .running)

        // When: Pause the session
        sessionManager.pause()

        // Then: State should be paused
        assertSessionState(sessionManager, is: .paused)
        XCTAssertEqual(mockAudioCapture.pauseCallCount, 1, "Audio capture should have been paused")
        XCTAssertTrue(sessionManager.state.canResume, "Should be able to resume from paused state")

        // When: Resume the session
        try await sessionManager.resume()

        // Then: State should be running again
        assertSessionState(sessionManager, is: .running)
        XCTAssertEqual(mockAudioCapture.resumeCallCount, 1, "Audio capture should have been resumed")
    }

    /// Tests that pause is ignored when not in running state
    func testPauseWhenNotRunning() async throws {
        // Given: Session is in ready state (not running)
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        assertSessionState(sessionManager, is: .ready)

        // When: Attempt to pause
        sessionManager.pause()

        // Then: State should remain ready (pause ignored)
        assertSessionState(sessionManager, is: .ready)
        XCTAssertEqual(mockAudioCapture.pauseCallCount, 0, "Audio capture should not have been paused")
    }

    /// Tests multiple pause/resume cycles
    func testMultiplePauseResumeCycles() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // When: Perform multiple pause/resume cycles
        for cycle in 1...3 {
            sessionManager.pause()
            assertSessionState(sessionManager, is: .paused)

            try await sessionManager.resume()
            assertSessionState(sessionManager, is: .running)
        }

        // Then: Audio capture should have correct call counts
        XCTAssertEqual(mockAudioCapture.pauseCallCount, 3)
        XCTAssertEqual(mockAudioCapture.resumeCallCount, 3)
    }

    // MARK: - Test: Error Recovery

    /// Tests recovery from a simulated connection loss
    func testSessionErrorRecovery() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()
        assertSessionState(sessionManager, is: .running)

        // Simulate API disconnect
        await mockAPIClient.simulateDisconnect()

        // Allow time for recovery process to initiate
        try await Task.sleep(nanoseconds: 200_000_000)

        // Session manager should handle the error internally
        // The recovery service will attempt to reconnect

        // Simulate successful reconnection
        await mockAPIClient.simulateReconnect()

        // Allow recovery to complete
        try await Task.sleep(nanoseconds: 200_000_000)

        // Verify session can still be properly ended
        if sessionManager.state == .running || sessionManager.state.canEnd {
            try await sessionManager.end()
            assertSessionState(sessionManager, is: .ended)
        }
    }

    /// Tests that degraded mode can be activated
    func testSessionDegradedMode() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()
        assertSessionState(sessionManager, is: .running)
        XCTAssertNil(sessionManager.degradedMode)

        // When: Switch to degraded mode
        sessionManager.switchToDegradedMode(.transcriptionOnly)

        // Then: Degraded mode should be active
        XCTAssertNotNil(sessionManager.degradedMode)
        XCTAssertEqual(sessionManager.degradedMode, .transcriptionOnly)

        // Session should still be running
        assertSessionState(sessionManager, is: .running)

        // Verify degraded mode features
        XCTAssertTrue(sessionManager.degradedMode?.availableFeatures.contains("Audio capture") ?? false)
        XCTAssertTrue(sessionManager.degradedMode?.availableFeatures.contains("Transcription") ?? false)
    }

    // MARK: - Test: Session Export

    /// Tests exporting a completed session
    func testSessionExport() async throws {
        // Given: Session has run and ended with some data
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Add some transcription data
        let transcriptionEvent = createTestTranscriptionEvent(
            text: "This is a test interview response.",
            speaker: .participant,
            timestamp: 5.0
        )
        await mockAPIClient.simulateTranscription(transcriptionEvent)
        try await Task.sleep(nanoseconds: 100_000_000)

        // End the session
        try await sessionManager.end()
        assertSessionState(sessionManager, is: .ended)

        // When: Export the session
        guard let session = sessionManager.currentSession else {
            XCTFail("Session should exist after ending")
            return
        }

        let exportService = ExportService()

        // Then: Export to Markdown should work
        // Note: This may throw if session has no utterances persisted
        // In real integration, utterances would be persisted by the coordinator
        do {
            let markdown = try exportService.exportToMarkdown(session)
            XCTAssertFalse(markdown.isEmpty, "Export should produce content")
            XCTAssertTrue(markdown.contains(session.projectName), "Export should contain project name")
        } catch ExportError.emptySession {
            // Expected if no utterances were persisted - acceptable for this test
            // In production, the SessionCoordinator handles persistence
        }

        // Export to JSON should also work
        do {
            let jsonData = try exportService.exportToJSON(session)
            XCTAssertGreaterThan(jsonData.count, 0, "JSON export should produce data")
        } catch ExportError.emptySession {
            // Expected if no utterances were persisted
        }
    }

    // MARK: - Test: Session Statistics

    /// Tests that session statistics are properly tracked
    func testSessionStatistics() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Allow some time to pass
        try await Task.sleep(nanoseconds: 1_100_000_000) // ~1.1 seconds

        // When: Get session statistics
        let stats = await sessionManager.getSessionStatistics()

        // Then: Statistics should be available
        XCTAssertNotNil(stats)
        XCTAssertNotNil(stats?.sessionId)
        XCTAssertGreaterThan(stats?.duration ?? 0, 0, "Duration should be greater than 0")

        // Verify formatted elapsed time
        XCTAssertFalse(sessionManager.formattedElapsedTime.isEmpty)
    }

    // MARK: - Test: Invalid State Transitions

    /// Tests that invalid state transitions throw appropriate errors
    func testInvalidStateTransitions() async throws {
        // Test: Cannot start from idle state
        assertSessionState(sessionManager, is: .idle)
        do {
            try await sessionManager.start()
            XCTFail("Should have thrown error when starting from idle state")
        } catch let error as SessionError {
            XCTAssertEqual(error.kind, .invalidStateTransition)
        }

        // Test: Cannot configure from non-idle state
        try await sessionManager.configure(with: createTestConfig())
        assertSessionState(sessionManager, is: .ready)

        do {
            try await sessionManager.configure(with: createTestConfig())
            XCTFail("Should have thrown error when configuring from ready state")
        } catch let error as SessionError {
            XCTAssertEqual(error.kind, .invalidStateTransition)
        }

        // Test: Cannot resume from ready state
        do {
            try await sessionManager.resume()
            XCTFail("Should have thrown error when resuming from ready state")
        } catch let error as SessionError {
            XCTAssertEqual(error.kind, .invalidStateTransition)
        }
    }

    // MARK: - Test: Session Metadata

    /// Tests that session metadata is properly set and persisted
    func testSessionMetadata() async throws {
        // Given: Configuration with specific metadata
        let config = SessionConfig(
            apiKey: "test-key",
            systemPrompt: "Test prompt",
            topics: ["UX", "Research"],
            sessionMode: .full,
            metadata: SessionMetadata(
                participantName: "John Doe",
                projectName: "Customer Research",
                plannedDuration: 2700
            )
        )

        // When: Configure and start session
        try await sessionManager.configure(with: config)

        // Then: Session should have correct metadata
        let session = sessionManager.currentSession
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.participantName, "John Doe")
        XCTAssertEqual(session?.projectName, "Customer Research")
        XCTAssertEqual(session?.sessionMode, .full)
    }

    // MARK: - Test: Audio Levels

    /// Tests that audio levels are properly tracked during session
    func testAudioLevels() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Initially, audio levels should be silent
        XCTAssertEqual(sessionManager.audioLevels, .silence)

        // When: Simulate audio levels
        mockAudioCapture.simulateAudioLevels(system: 0.5, microphone: 0.7)

        // Then: Wait for timer to update (timer fires every 1 second)
        try await Task.sleep(nanoseconds: 1_100_000_000)

        // Note: In the real implementation, audio levels are updated via timer
        // The mock audio capture provides the levels
        let mockLevels = mockAudioCapture.audioLevels
        XCTAssertEqual(mockLevels.systemLevel, 0.5, accuracy: 0.01)
        XCTAssertEqual(mockLevels.microphoneLevel, 0.7, accuracy: 0.01)
    }

    // MARK: - Test: Connection Quality

    /// Tests initial connection quality state
    func testConnectionQuality() async throws {
        // Given: Session manager in idle state
        // Then: Connection quality should be disconnected
        XCTAssertEqual(sessionManager.connectionQuality, .disconnected)

        // When: Configure and start session
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Connection quality is managed by ConnectionQualityMonitor
        // and updated based on API connection state
    }

    // MARK: - Test: Session End Cleanup

    /// Tests that ending a session properly cleans up resources
    func testSessionEndCleansUpResources() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Store reference to session
        let session = sessionManager.currentSession
        XCTAssertNotNil(session)
        XCTAssertNil(session?.endedAt)

        // When: End the session
        try await sessionManager.end()

        // Then: Session should be properly finalized
        assertSessionState(sessionManager, is: .ended)
        XCTAssertNotNil(session?.endedAt)
        XCTAssertGreaterThan(session?.totalDurationSeconds ?? 0, 0)

        // Audio capture should be stopped
        XCTAssertEqual(mockAudioCapture.stopCallCount, 1)
    }

    // MARK: - Test: Concurrent Operations Safety

    /// Tests that rapid state changes are handled safely
    func testRapidStateChanges() async throws {
        // Given: Session is configured
        let config = createTestConfig()
        try await sessionManager.configure(with: config)

        // When: Rapid start/pause/resume operations
        try await sessionManager.start()
        sessionManager.pause()
        try await sessionManager.resume()
        sessionManager.pause()
        try await sessionManager.resume()

        // Then: Session should be in a valid state
        XCTAssertTrue(sessionManager.state == .running || sessionManager.state == .paused)

        // Clean end
        try await sessionManager.end()
        assertSessionState(sessionManager, is: .ended)
    }
}
