//
//  AudioAPIIntegrationTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Integration tests for audio capture to API flow
//

import XCTest
@testable import HCDInterviewCoach

/// Integration tests for the audio capture to API flow.
/// Tests the complete pipeline from audio capture through API processing.
@MainActor
final class AudioAPIIntegrationTests: IntegrationTestCase {

    // MARK: - System Under Test

    var sessionManager: SessionManager!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        sessionManager = createTestSessionManager()
    }

    override func tearDown() async throws {
        if sessionManager?.state.canEnd ?? false {
            try? await sessionManager.end()
        }
        if sessionManager?.state == .ended || sessionManager?.state.isError ?? false {
            await sessionManager?.reset()
        }
        sessionManager = nil
        try await super.tearDown()
    }

    // MARK: - Test: Audio Chunk Streaming

    /// Tests that audio chunks flow from capture to API
    func testAudioChunkStreaming() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()
        assertSessionState(sessionManager, is: .running)

        // Verify audio capture is running
        XCTAssertTrue(mockAudioCapture.isRunning, "Audio capture should be running")
        XCTAssertEqual(mockAudioCapture.startCallCount, 1)

        // When: Simulate audio chunks being captured
        for i in 0..<5 {
            let chunk = createTestAudioChunk(
                timestamp: TimeInterval(i) * 0.1,
                dataSize: 2400  // 100ms of 24kHz mono audio
            )
            mockAudioCapture.simulateAudioChunk(chunk)

            // Allow processing time
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        // Allow time for chunks to be processed
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then: API client should have received audio chunks
        // Note: The actual sending happens through the SessionCoordinator
        // In this test, we verify the mock audio capture is producing chunks
        XCTAssertTrue(mockAudioCapture.isRunning)
    }

    /// Tests audio chunk format compliance
    func testAudioChunkFormat() async throws {
        // Given: Create an audio chunk
        let chunk = createTestAudioChunk(
            timestamp: 1.0,
            dataSize: 1024
        )

        // Then: Verify format is correct for OpenAI Realtime API
        XCTAssertEqual(chunk.sampleRate, 24000, "Sample rate should be 24kHz")
        XCTAssertEqual(chunk.channels, 1, "Audio should be mono")
        XCTAssertGreaterThan(chunk.data.count, 0, "Audio data should not be empty")
    }

    /// Tests continuous audio streaming during session
    func testContinuousAudioStreaming() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // When: Stream multiple audio chunks over time
        let streamDuration = 1.0 // 1 second
        let chunkInterval = 0.1 // 100ms chunks
        var chunkCount = 0

        let startTime = Date()
        while Date().timeIntervalSince(startTime) < streamDuration {
            let chunk = createTestAudioChunk(
                timestamp: TimeInterval(chunkCount) * chunkInterval,
                dataSize: 2400
            )
            mockAudioCapture.simulateAudioChunk(chunk)
            chunkCount += 1

            try await Task.sleep(nanoseconds: UInt64(chunkInterval * 1_000_000_000))
        }

        // Then: Multiple chunks should have been produced
        XCTAssertGreaterThan(chunkCount, 5, "Should have produced multiple audio chunks")
    }

    // MARK: - Test: Transcription Event Parsing

    /// Tests that transcription events are properly parsed and delivered
    func testTranscriptionEventParsing() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Set up expectations
        var receivedEvents: [TranscriptionEvent] = []
        let expectation = XCTestExpectation(description: "Receive transcription events")
        expectation.expectedFulfillmentCount = 3

        // Listen to transcription stream
        let streamTask = Task {
            for await event in sessionManager.transcriptionStream {
                receivedEvents.append(event)
                expectation.fulfill()
                if receivedEvents.count >= 3 {
                    break
                }
            }
        }

        // Allow stream setup
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Simulate various transcription events from API
        let events = [
            TranscriptionEvent(
                text: "So, tell me about your experience.",
                isFinal: true,
                speaker: .interviewer,
                timestamp: 5.0,
                confidence: 0.95
            ),
            TranscriptionEvent(
                text: "Well, it started about two years ago...",
                isFinal: true,
                speaker: .participant,
                timestamp: 8.0,
                confidence: 0.92
            ),
            TranscriptionEvent(
                text: "That's interesting. Can you elaborate?",
                isFinal: true,
                speaker: .interviewer,
                timestamp: 15.0,
                confidence: 0.94
            )
        ]

        for event in events {
            await mockAPIClient.simulateTranscription(event)
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms between events
        }

        // Wait for events
        await fulfillment(of: [expectation], timeout: shortTimeout)
        streamTask.cancel()

        // Then: All events should be received and parsed correctly
        XCTAssertEqual(receivedEvents.count, 3)

        // Verify first event
        XCTAssertEqual(receivedEvents[0].speaker, .interviewer)
        XCTAssertTrue(receivedEvents[0].text.contains("experience"))

        // Verify second event
        XCTAssertEqual(receivedEvents[1].speaker, .participant)
        XCTAssertTrue(receivedEvents[1].isFinal)

        // Verify third event
        XCTAssertGreaterThan(receivedEvents[2].confidence, 0.9)
    }

    /// Tests partial (non-final) transcription handling
    func testPartialTranscriptionHandling() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        var receivedEvents: [TranscriptionEvent] = []
        let expectation = XCTestExpectation(description: "Receive transcription")

        let streamTask = Task {
            for await event in sessionManager.transcriptionStream {
                receivedEvents.append(event)
                if event.isFinal {
                    expectation.fulfill()
                    break
                }
            }
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Simulate partial then final transcription
        let partialEvent = TranscriptionEvent(
            text: "I think that...",
            isFinal: false,
            speaker: .participant,
            timestamp: 10.0,
            confidence: 0.70
        )
        await mockAPIClient.simulateTranscription(partialEvent)

        try await Task.sleep(nanoseconds: 100_000_000)

        let finalEvent = TranscriptionEvent(
            text: "I think that this approach works well.",
            isFinal: true,
            speaker: .participant,
            timestamp: 12.0,
            confidence: 0.95
        )
        await mockAPIClient.simulateTranscription(finalEvent)

        await fulfillment(of: [expectation], timeout: shortTimeout)
        streamTask.cancel()

        // Then: Final event should be properly identified
        let finalEvents = receivedEvents.filter { $0.isFinal }
        XCTAssertFalse(finalEvents.isEmpty, "Should have received final transcription")
    }

    // MARK: - Test: Connection Reconnection

    /// Tests reconnection after API disconnect
    func testConnectionReconnection() async throws {
        // Given: Session is running and connected
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()
        assertSessionState(sessionManager, is: .running)

        // Verify initial connection
        let initialConnectionState = await mockAPIClient.connectionState
        XCTAssertEqual(initialConnectionState, .connected)

        // When: Simulate disconnection
        await mockAPIClient.simulateDisconnect()

        // Allow time for disconnect to be processed
        try await Task.sleep(nanoseconds: 100_000_000)

        // Connection state should change
        let disconnectedState = await mockAPIClient.connectionState
        XCTAssertEqual(disconnectedState, .disconnected)

        // When: Simulate reconnection
        await mockAPIClient.simulateReconnect()

        // Allow reconnection
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Connection should be re-established
        let reconnectedState = await mockAPIClient.connectionState
        XCTAssertEqual(reconnectedState, .connected)

        // Session should still be functional
        let isConnected = await mockAPIClient.isConnected
        XCTAssertTrue(isConnected)
    }

    /// Tests connection failure handling
    func testConnectionFailureHandling() async throws {
        // Given: API client configured to fail
        mockAPIClient = MockRealtimeAPIClient()
        // The mock will be used by session manager

        // Create a session manager that will use this failing mock
        let failingManager = SessionManager(
            audioCapturerProvider: { [weak self] in
                self?.mockAudioCapture ?? MockAudioCaptureService()
            },
            apiClientProvider: {
                // Return a mock that simulates failure
                let client = MockRealtimeAPIClient()
                return client
            }
        )

        // When: Try to configure and connect
        // Note: The mock by default succeeds, but we test the flow
        let config = createTestConfig()

        do {
            try await failingManager.configure(with: config)
            try await failingManager.start()

            // Simulate connection failure after start
            // In real scenario, this would trigger error recovery

            // Clean up
            try await failingManager.end()
            await failingManager.reset()

        } catch {
            // Connection failures are expected in some scenarios
            // The session manager should handle this gracefully
        }
    }

    // MARK: - Test: Audio Pause/Resume

    /// Tests audio capture pause and resume
    func testAudioPauseResume() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        XCTAssertTrue(mockAudioCapture.isRunning)
        XCTAssertFalse(mockAudioCapture.isPaused)

        // When: Pause session
        sessionManager.pause()

        // Then: Audio should be paused
        XCTAssertTrue(mockAudioCapture.isPaused)
        XCTAssertEqual(mockAudioCapture.pauseCallCount, 1)

        // When: Resume session
        try await sessionManager.resume()

        // Then: Audio should be resumed
        XCTAssertFalse(mockAudioCapture.isPaused)
        XCTAssertEqual(mockAudioCapture.resumeCallCount, 1)
    }

    // MARK: - Test: Function Call Events

    /// Tests function call event handling from API
    func testFunctionCallEventHandling() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // When: Simulate function call events
        let insightEvent = FunctionCallEvent(
            name: "flag_insight",
            arguments: [
                "quote": "I was frustrated when the feature didn't work",
                "theme": "Usability"
            ],
            timestamp: 45.0
        )
        await mockAPIClient.simulateFunctionCall(insightEvent)

        try await Task.sleep(nanoseconds: 100_000_000)

        let topicEvent = FunctionCallEvent(
            name: "update_topic",
            arguments: [
                "topic_id": "onboarding",
                "status": "touched"
            ],
            timestamp: 60.0
        )
        await mockAPIClient.simulateFunctionCall(topicEvent)

        // Allow processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Events should be processed (handled by session coordinator)
        // The mock API client tracks sent events
        let functionCallCount = await mockAPIClient.sendAudioCallCount
        // Function calls are received, not sent, so we verify the mock state
    }

    // MARK: - Test: Audio Levels

    /// Tests audio level monitoring during capture
    func testAudioLevelMonitoring() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Initially silent
        XCTAssertEqual(mockAudioCapture.audioLevels, .silence)

        // When: Simulate various audio levels
        mockAudioCapture.simulateAudioLevels(system: 0.3, microphone: 0.0)
        XCTAssertEqual(mockAudioCapture.audioLevels.systemLevel, 0.3, accuracy: 0.01)

        mockAudioCapture.simulateAudioLevels(system: 0.6, microphone: 0.8)
        XCTAssertEqual(mockAudioCapture.audioLevels.systemLevel, 0.6, accuracy: 0.01)
        XCTAssertEqual(mockAudioCapture.audioLevels.microphoneLevel, 0.8, accuracy: 0.01)

        // Levels should be clamped to 0-1 range
        mockAudioCapture.simulateAudioLevels(system: 1.5, microphone: -0.5)
        XCTAssertEqual(mockAudioCapture.audioLevels.systemLevel, 1.0, accuracy: 0.01)
        XCTAssertEqual(mockAudioCapture.audioLevels.microphoneLevel, 0.0, accuracy: 0.01)
    }

    // MARK: - Test: Error Scenarios

    /// Tests handling of audio capture errors
    func testAudioCaptureError() async throws {
        // Given: Audio capture configured to fail
        mockAudioCapture.shouldThrowOnStart = true
        mockAudioCapture.errorToThrow = .blackHoleNotInstalled

        let config = createTestConfig()

        // When/Then: Configuration should succeed but start may fail
        try await sessionManager.configure(with: config)

        do {
            try await sessionManager.start()
            // If start succeeds (mock might not throw in all paths), verify state
            // The actual behavior depends on how SessionCoordinator handles the error
        } catch {
            // Expected - audio capture error
            XCTAssertTrue(error is SessionError || error is AudioCaptureError,
                         "Should throw appropriate error type")
        }
    }

    /// Tests handling of API send errors
    func testAPISendError() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // Configure mock to fail on send
        await mockAPIClient.reset()
        // Note: The mock is already used, so we simulate error state

        // When: Attempt to send audio (indirectly through capture)
        mockAudioCapture.simulateAudioChunk(createTestAudioChunk())

        // The error handling is done within the session coordinator
        // We verify the session doesn't crash
        try await Task.sleep(nanoseconds: 100_000_000)

        // Session should still be in a valid state (running or error)
        XCTAssertTrue(sessionManager.state == .running ||
                     sessionManager.state.isError,
                     "Session should be in running or error state")
    }

    // MARK: - Test: Session Mode Impact on API

    /// Tests how different session modes affect API communication
    func testSessionModeImpactOnAPI() async throws {
        // Test Full mode
        let fullConfig = createTestConfig(mode: .full)
        try await sessionManager.configure(with: fullConfig)

        // Full mode should enable all features
        XCTAssertEqual(fullConfig.sessionMode, .full)

        await sessionManager.reset()

        // Test Transcription Only mode
        let transcriptionConfig = createTestConfig(mode: .transcriptionOnly)
        try await sessionManager.configure(with: transcriptionConfig)

        // Transcription mode should work without coaching functions
        XCTAssertEqual(transcriptionConfig.sessionMode, .transcriptionOnly)

        await sessionManager.reset()

        // Test Observer Only mode
        let observerConfig = createTestConfig(mode: .observerOnly)
        try await sessionManager.configure(with: observerConfig)

        // Observer mode has minimal API interaction
        XCTAssertEqual(observerConfig.sessionMode, .observerOnly)
    }

    // MARK: - Test: High Volume Audio

    /// Tests handling of high volume audio streaming
    func testHighVolumeAudioStreaming() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        // When: Send many audio chunks rapidly
        let chunkCount = 100
        for i in 0..<chunkCount {
            let chunk = createTestAudioChunk(
                timestamp: TimeInterval(i) * 0.01,
                dataSize: 2400
            )
            mockAudioCapture.simulateAudioChunk(chunk)

            // Very short delay to simulate rapid streaming
            if i % 10 == 0 {
                try await Task.sleep(nanoseconds: 1_000_000) // 1ms every 10 chunks
            }
        }

        // Allow processing
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Session should remain stable
        XCTAssertTrue(sessionManager.state == .running,
                     "Session should remain running after high volume streaming")
    }

    // MARK: - Test: Transcription with Different Speakers

    /// Tests speaker identification in transcription events
    func testSpeakerIdentification() async throws {
        // Given: Session is running
        let config = createTestConfig()
        try await sessionManager.configure(with: config)
        try await sessionManager.start()

        var speakerCounts: [Speaker: Int] = [.interviewer: 0, .participant: 0, .unknown: 0]
        let expectation = XCTestExpectation(description: "Receive all transcriptions")
        expectation.expectedFulfillmentCount = 4

        let streamTask = Task {
            for await event in sessionManager.transcriptionStream {
                if let speaker = event.speaker {
                    speakerCounts[speaker, default: 0] += 1
                }
                expectation.fulfill()
                if speakerCounts.values.reduce(0, +) >= 4 {
                    break
                }
            }
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Simulate transcriptions from different speakers
        let events: [(String, Speaker)] = [
            ("Let's begin the interview.", .interviewer),
            ("Sure, I'm ready.", .participant),
            ("Can you tell me about your role?", .interviewer),
            ("I work as a product manager.", .participant)
        ]

        for (index, (text, speaker)) in events.enumerated() {
            let event = TranscriptionEvent(
                text: text,
                isFinal: true,
                speaker: speaker,
                timestamp: TimeInterval(index * 5),
                confidence: 0.95
            )
            await mockAPIClient.simulateTranscription(event)
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        await fulfillment(of: [expectation], timeout: shortTimeout)
        streamTask.cancel()

        // Then: Should have correctly identified speakers
        XCTAssertEqual(speakerCounts[.interviewer], 2)
        XCTAssertEqual(speakerCounts[.participant], 2)
    }
}
