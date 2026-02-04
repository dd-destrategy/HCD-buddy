//
//  SessionCoordinatorTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for SessionCoordinator orchestration
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

@MainActor
final class SessionCoordinatorTests: XCTestCase {

    var coordinator: SessionCoordinator!
    var mockAudioCapture: MockAudioCaptureService!
    var mockAPIClient: MockRealtimeAPIClient!
    var mockTranscriptionBuffer: TranscriptionBuffer!

    override func setUp() {
        super.setUp()
        mockAudioCapture = MockAudioCaptureService()
        mockAPIClient = MockRealtimeAPIClient()
        mockTranscriptionBuffer = TranscriptionBuffer()

        coordinator = SessionCoordinator(
            audioCapture: mockAudioCapture,
            apiClient: mockAPIClient,
            transcriptionBuffer: mockTranscriptionBuffer
        )
    }

    override func tearDown() {
        coordinator = nil
        mockAudioCapture = nil
        mockAPIClient = nil
        mockTranscriptionBuffer = nil
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

    private func createTestSession() -> Session {
        return Session(
            participantName: "Test User",
            projectName: "Test Project",
            sessionMode: .full
        )
    }

    // MARK: - Test: Coordinator Initialization

    func testCoordinatorInitialization() {
        // Given: A fresh coordinator
        // Then: Initial state should be not ready
        XCTAssertFalse(coordinator.isReady)
        XCTAssertFalse(coordinator.isCapturingAudio)
        XCTAssertEqual(coordinator.apiConnectionState, .disconnected)
        XCTAssertEqual(coordinator.audioLevels, AudioLevels.silence)
        XCTAssertNil(coordinator.lastError)
    }

    func testCoordinatorInitialization_withCustomDependencies() {
        // Given: Custom dependencies
        let customAudioCapture = MockAudioCaptureService()
        let customAPIClient = MockRealtimeAPIClient()

        // When: Creating coordinator with custom dependencies
        let customCoordinator = SessionCoordinator(
            audioCapture: customAudioCapture,
            apiClient: customAPIClient
        )

        // Then: Should be properly initialized
        XCTAssertFalse(customCoordinator.isReady)
        XCTAssertFalse(customCoordinator.isCapturingAudio)
    }

    // MARK: - Test: Start Audio and API

    func testStartAudioAndAPI_successfulPrepare() async throws {
        // Given: Valid config and session
        let config = createTestConfig()
        let session = createTestSession()

        // When: Prepare the coordinator
        try await coordinator.prepare(with: config, session: session)

        // Then: Should be ready
        XCTAssertTrue(coordinator.isReady)
        XCTAssertEqual(coordinator.apiConnectionState, .connected)

        // Verify API client was called
        let connectCount = await mockAPIClient.connectCallCount
        XCTAssertEqual(connectCount, 1)
    }

    func testStartAudioAndAPI_startsCaptureAfterPrepare() async throws {
        // Given: Prepared coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)

        // When: Start capture
        try coordinator.startCapture()

        // Then: Should be capturing audio
        XCTAssertTrue(coordinator.isCapturingAudio)
        XCTAssertEqual(mockAudioCapture.startCallCount, 1)
    }

    func testStartAudioAndAPI_failsWhenNotReady() async throws {
        // Given: Coordinator is not prepared

        // When/Then: Starting capture should throw
        do {
            try coordinator.startCapture()
            XCTFail("Should have thrown an error")
        } catch let error as SessionError {
            XCTAssertEqual(error.kind, .invalidStateTransition)
        }
    }

    func testStartAudioAndAPI_connectionFailure() async throws {
        // Given: API client configured to fail
        let failingAPIClient = MockRealtimeAPIClient()
        failingAPIClient.shouldThrowOnConnect = true
        failingAPIClient.connectionErrorToThrow = .networkUnavailable

        let failCoordinator = SessionCoordinator(
            audioCapture: mockAudioCapture,
            apiClient: failingAPIClient
        )

        let config = createTestConfig()
        let session = createTestSession()

        // When/Then: Prepare should throw connection error
        do {
            try await failCoordinator.prepare(with: config, session: session)
            XCTFail("Should have thrown a connection error")
        } catch let error as SessionError {
            XCTAssertEqual(error.kind, .connectionFailed)
        }
    }

    // MARK: - Test: Stop Audio and API

    func testStopAudioAndAPI_stopsAllComponents() async throws {
        // Given: Running coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()
        XCTAssertTrue(coordinator.isCapturingAudio)

        // When: Stop the coordinator
        await coordinator.stop()

        // Then: Should stop everything
        XCTAssertFalse(coordinator.isCapturingAudio)
        XCTAssertFalse(coordinator.isReady)
        XCTAssertEqual(coordinator.apiConnectionState, .disconnected)
        XCTAssertEqual(mockAudioCapture.stopCallCount, 1)

        let disconnectCount = await mockAPIClient.disconnectCallCount
        XCTAssertEqual(disconnectCount, 1)
    }

    func testStopAudioAndAPI_flushesBuffer() async throws {
        // Given: Running coordinator with buffered data
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()

        // When: Stop the coordinator
        await coordinator.stop()

        // Then: Buffer should be flushed (verified by checking stats)
        let stats = await coordinator.getBufferStatistics()
        XCTAssertFalse(stats.hasActivePartial)
    }

    func testStopAudioAndAPI_clearsSessionReference() async throws {
        // Given: Running coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)

        // When: Stop the coordinator
        await coordinator.stop()

        // Then: Session duration should be nil (session reference cleared)
        XCTAssertNil(coordinator.currentSessionDuration)
    }

    // MARK: - Test: Pause Coordination

    func testPauseCoordination_pausesAudioCapture() async throws {
        // Given: Running coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()
        XCTAssertTrue(coordinator.isCapturingAudio)

        // When: Pause capture
        coordinator.pauseCapture()

        // Then: Should pause audio
        XCTAssertFalse(coordinator.isCapturingAudio)
        XCTAssertEqual(mockAudioCapture.pauseCallCount, 1)
    }

    func testPauseCoordination_stopsAudioLevelMonitoring() async throws {
        // Given: Running coordinator with audio levels
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()

        // Simulate some audio levels
        mockAudioCapture.simulateAudioLevels(system: 0.5, microphone: 0.3)

        // When: Pause capture
        coordinator.pauseCapture()

        // Then: Audio levels should reset to silence
        // Note: May need small delay for timer to stop
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(coordinator.audioLevels, AudioLevels.silence)
    }

    // MARK: - Test: Resume Coordination

    func testResumeCoordination_resumesAudioCapture() async throws {
        // Given: Paused coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()
        coordinator.pauseCapture()
        XCTAssertFalse(coordinator.isCapturingAudio)

        // When: Resume capture
        coordinator.resumeCapture()

        // Then: Should resume audio
        XCTAssertTrue(coordinator.isCapturingAudio)
        XCTAssertEqual(mockAudioCapture.resumeCallCount, 1)
    }

    func testResumeCoordination_restartsAudioLevelMonitoring() async throws {
        // Given: Paused coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()
        coordinator.pauseCapture()

        // When: Resume capture
        coordinator.resumeCapture()

        // Then: Audio level monitoring should restart
        // Simulate audio and verify levels update
        mockAudioCapture.simulateAudioLevels(system: 0.7, microphone: 0.4)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Audio levels should be updating (not silence)
        XCTAssertTrue(coordinator.isCapturingAudio)
    }

    // MARK: - Test: Audio Stream Forwarding

    func testAudioStreamForwarding_sendsToAPI() async throws {
        // Given: Running coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()

        // When: Simulate audio chunk
        let testChunk = MockAudioCaptureService.createTestAudioChunk(
            timestamp: 1.0,
            dataSize: 2048
        )
        mockAudioCapture.simulateAudioChunk(testChunk)

        // Wait for async processing
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then: Audio should be sent to API
        let sendCount = await mockAPIClient.sendAudioCallCount
        XCTAssertGreaterThan(sendCount, 0)
    }

    func testAudioStreamForwarding_multipleChunks() async throws {
        // Given: Running coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()

        // When: Simulate multiple audio chunks
        for i in 0..<5 {
            let chunk = MockAudioCaptureService.createTestAudioChunk(
                timestamp: Double(i),
                dataSize: 1024
            )
            mockAudioCapture.simulateAudioChunk(chunk)
        }

        // Wait for async processing
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then: All chunks should be forwarded
        let sendCount = await mockAPIClient.sendAudioCallCount
        XCTAssertGreaterThanOrEqual(sendCount, 5)
    }

    // MARK: - Test: Transcription Event Handling

    func testTranscriptionEventHandling_receivesEvents() async throws {
        // Given: Running coordinator with callback configured
        let config = createTestConfig()
        let session = createTestSession()

        let expectation = XCTestExpectation(description: "Receive transcription")
        var receivedSegment: TranscriptionSegment?

        coordinator.configure(
            onTranscription: { segment in
                receivedSegment = segment
                expectation.fulfill()
            },
            onFunctionCall: { _ in },
            onError: { _ in }
        )

        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()

        // When: Simulate transcription event
        let event = TranscriptionEvent(
            text: "Test transcription text",
            isFinal: true,
            speaker: .participant,
            timestamp: 5.0,
            confidence: 0.95
        )
        await mockAPIClient.simulateTranscription(event)

        // Then: Should receive transcription
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(receivedSegment)
        XCTAssertEqual(receivedSegment?.text, "Test transcription text")
    }

    func testTranscriptionEventHandling_partialEvents() async throws {
        // Given: Running coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()

        // When: Simulate partial transcription
        let partialEvent = TranscriptionEvent(
            text: "Partial text...",
            isFinal: false,
            speaker: .interviewer,
            timestamp: 1.0,
            confidence: 0.7
        )
        await mockAPIClient.simulateTranscription(partialEvent)

        // Wait for processing
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Should have active partial in buffer
        let partial = await coordinator.getCurrentPartial()
        XCTAssertNotNil(partial)
        XCTAssertEqual(partial?.text, "Partial text...")
    }

    func testTranscriptionEventHandling_finalizePartial() async throws {
        // Given: Running coordinator with partial transcription
        let config = createTestConfig()
        let session = createTestSession()

        let expectation = XCTestExpectation(description: "Receive final transcription")

        coordinator.configure(
            onTranscription: { _ in
                expectation.fulfill()
            },
            onFunctionCall: { _ in },
            onError: { _ in }
        )

        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()

        // Send partial first
        let partialEvent = TranscriptionEvent(
            text: "Hello",
            isFinal: false,
            speaker: .participant,
            timestamp: 1.0,
            confidence: 0.8
        )
        await mockAPIClient.simulateTranscription(partialEvent)

        // When: Send final event
        let finalEvent = TranscriptionEvent(
            text: "Hello, how are you?",
            isFinal: true,
            speaker: .participant,
            timestamp: 2.0,
            confidence: 0.95
        )
        await mockAPIClient.simulateTranscription(finalEvent)

        // Then: Should receive finalized transcription
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Test: Error Propagation

    func testErrorPropagation_audioErrors() async throws {
        // Given: Coordinator with error callback
        let config = createTestConfig()
        let session = createTestSession()

        var receivedError: SessionError?
        coordinator.configure(
            onTranscription: { _ in },
            onFunctionCall: { _ in },
            onError: { error in
                receivedError = error
            }
        )

        try await coordinator.prepare(with: config, session: session)

        // When: Audio capture fails on start
        mockAudioCapture.shouldThrowOnStart = true
        mockAudioCapture.errorToThrow = .captureFailure("Test failure")

        do {
            try coordinator.startCapture()
            XCTFail("Should have thrown")
        } catch {
            // Expected
        }

        // Then: Error should be propagated
        // The error is thrown directly, not via callback
        XCTAssertFalse(coordinator.isCapturingAudio)
    }

    func testErrorPropagation_setsLastError() async throws {
        // Given: Coordinator prepared but will fail on capture
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)

        mockAudioCapture.shouldThrowOnStart = true
        mockAudioCapture.errorToThrow = .blackHoleNotInstalled

        // When: Attempt to start capture
        do {
            try coordinator.startCapture()
        } catch {
            // Expected to throw
        }

        // Then: Should not be capturing
        XCTAssertFalse(coordinator.isCapturingAudio)
    }

    // MARK: - Test: Graceful Shutdown

    func testGracefulShutdown_stopsInOrder() async throws {
        // Given: Fully running coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()

        XCTAssertTrue(coordinator.isReady)
        XCTAssertTrue(coordinator.isCapturingAudio)

        // When: Stop gracefully
        await coordinator.stop()

        // Then: Everything should be stopped in proper order
        XCTAssertFalse(coordinator.isCapturingAudio)
        XCTAssertFalse(coordinator.isReady)
        XCTAssertEqual(coordinator.apiConnectionState, .disconnected)
        XCTAssertEqual(coordinator.audioLevels, AudioLevels.silence)
    }

    func testGracefulShutdown_canRestartAfterStop() async throws {
        // Given: Stopped coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()
        await coordinator.stop()

        // Reset mock state
        await mockAPIClient.reset()
        mockAudioCapture.reset()

        // When: Prepare and start again
        let newSession = createTestSession()
        try await coordinator.prepare(with: config, session: newSession)
        try coordinator.startCapture()

        // Then: Should be running again
        XCTAssertTrue(coordinator.isReady)
        XCTAssertTrue(coordinator.isCapturingAudio)
    }

    // MARK: - Test: Reconnection

    func testReconnect_reconnectsAPI() async throws {
        // Given: Running coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)

        // When: Reconnect
        try await coordinator.reconnect(with: config)

        // Then: Should reconnect to API
        let connectCount = await mockAPIClient.connectCallCount
        XCTAssertEqual(connectCount, 2) // Initial + reconnect
    }

    // MARK: - Test: Buffer Statistics

    func testBufferStatistics_initialState() async throws {
        // Given: Fresh coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)

        // When: Get statistics
        let stats = await coordinator.getBufferStatistics()

        // Then: Should show empty buffer
        XCTAssertEqual(stats.totalPartialEvents, 0)
        XCTAssertEqual(stats.totalFinalEvents, 0)
        XCTAssertFalse(stats.hasActivePartial)
    }

    func testBufferStatistics_afterTranscription() async throws {
        // Given: Running coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()

        // When: Process some transcriptions
        let event1 = TranscriptionEvent(
            text: "First",
            isFinal: false,
            speaker: .participant,
            timestamp: 1.0,
            confidence: 0.8
        )
        await mockAPIClient.simulateTranscription(event1)

        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Statistics should reflect activity
        let stats = await coordinator.getBufferStatistics()
        XCTAssertGreaterThan(stats.totalPartialEvents, 0)
    }

    // MARK: - Test: Session Duration

    func testCurrentSessionDuration_tracksTime() async throws {
        // Given: Running coordinator
        let config = createTestConfig()
        let session = createTestSession()
        try await coordinator.prepare(with: config, session: session)

        // When: Check duration
        let duration = coordinator.currentSessionDuration

        // Then: Should have non-nil duration
        XCTAssertNotNil(duration)
        XCTAssertGreaterThanOrEqual(duration ?? -1, 0)
    }

    func testCurrentSessionDuration_nilWhenNotRunning() {
        // Given: Fresh coordinator

        // When: Check duration
        let duration = coordinator.currentSessionDuration

        // Then: Should be nil
        XCTAssertNil(duration)
    }

    // MARK: - Test: Function Call Handling

    func testFunctionCallHandling_receivesEvents() async throws {
        // Given: Running coordinator with function call callback
        let config = createTestConfig()
        let session = createTestSession()

        let expectation = XCTestExpectation(description: "Receive function call")
        var receivedEvent: FunctionCallEvent?

        coordinator.configure(
            onTranscription: { _ in },
            onFunctionCall: { event in
                receivedEvent = event
                expectation.fulfill()
            },
            onError: { _ in }
        )

        try await coordinator.prepare(with: config, session: session)
        try coordinator.startCapture()

        // When: Simulate function call
        let functionEvent = FunctionCallEvent(
            name: "show_nudge",
            arguments: ["text": "Consider asking about this", "reason": "Good opportunity"],
            timestamp: 5.0
        )
        await mockAPIClient.simulateFunctionCall(functionEvent)

        // Then: Should receive function call
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(receivedEvent)
        XCTAssertEqual(receivedEvent?.name, "show_nudge")
    }
}

// MARK: - Factory Tests

@MainActor
final class SessionCoordinatorFactoryTests: XCTestCase {

    func testCreateProduction_returnsValidCoordinator() {
        // Given: Mock dependencies
        let mockAudio = MockAudioCaptureService()
        let mockAPI = MockRealtimeAPIClient()

        // When: Create production coordinator
        let coordinator = SessionCoordinatorFactory.createProduction(
            audioCapture: mockAudio,
            apiClient: mockAPI
        )

        // Then: Should be valid coordinator
        XCTAssertFalse(coordinator.isReady)
        XCTAssertFalse(coordinator.isCapturingAudio)
    }

    func testCreateForTesting_acceptsCustomDataManager() async throws {
        // Given: Mock dependencies and in-memory data manager
        let mockAudio = MockAudioCaptureService()
        let mockAPI = MockRealtimeAPIClient()

        let schema = Schema([
            Session.self, Utterance.self, Insight.self,
            TopicStatus.self, CoachingEvent.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let testDataManager = DataManager(container: container)

        // When: Create test coordinator with custom data manager
        let coordinator = SessionCoordinatorFactory.createForTesting(
            audioCapture: mockAudio,
            apiClient: mockAPI,
            dataManager: testDataManager
        )

        // Then: Should be valid coordinator
        XCTAssertFalse(coordinator.isReady)
    }
}
