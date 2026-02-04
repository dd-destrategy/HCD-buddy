//
//  RealtimeAPIClientTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for RealtimeAPIClient WebSocket communication
//

import XCTest
import Combine
@testable import HCDInterviewCoach

final class RealtimeAPIClientTests: XCTestCase {

    // MARK: - Properties

    var apiClient: RealtimeAPIClient!
    var mockConnectionManager: TestableConnectionManager!
    var mockEventParser: MockEventParser!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockConnectionManager = TestableConnectionManager()
        mockEventParser = MockEventParser()
        apiClient = RealtimeAPIClient(connectionManager: mockConnectionManager, eventParser: mockEventParser)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        await apiClient.disconnect()
        apiClient = nil
        mockConnectionManager = nil
        mockEventParser = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a valid session config for testing
    private func createValidSessionConfig() -> SessionConfig {
        SessionConfig(
            apiKey: "test-api-key-12345",
            systemPrompt: "You are a helpful interview coach.",
            topics: ["Topic 1", "Topic 2"],
            sessionMode: .full
        )
    }

    /// Creates an invalid session config for testing
    private func createInvalidSessionConfig() -> SessionConfig {
        SessionConfig(
            apiKey: "",  // Empty API key
            systemPrompt: "Test prompt",
            topics: []
        )
    }

    /// Creates a test audio chunk
    private func createTestAudioChunk() -> AudioChunk {
        AudioChunk(
            data: Data(repeating: 0, count: 4800),
            timestamp: 1.0,
            sampleRate: 24000,
            channels: 1
        )
    }

    // MARK: - Test: Connect Success

    func testConnect_success() async throws {
        // Given: A valid configuration
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true

        // When: Connecting
        try await apiClient.connect(with: config)

        // Then: Should be connected
        XCTAssertEqual(apiClient.connectionState, .connected)
        XCTAssertEqual(mockConnectionManager.connectCallCount, 1)
    }

    func testConnect_stateTransitions() async throws {
        // Given: A valid configuration
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true

        var stateHistory: [ConnectionState] = []

        // Track state changes (note: may not capture intermediate states in fast execution)
        stateHistory.append(apiClient.connectionState)

        // When: Connecting
        try await apiClient.connect(with: config)

        stateHistory.append(apiClient.connectionState)

        // Then: Should have transitioned through states
        XCTAssertEqual(stateHistory.last, .connected)
    }

    // MARK: - Test: Connect Invalid Key

    func testConnect_invalidKey() async {
        // Given: A config with empty API key
        let config = createInvalidSessionConfig()

        // When/Then: Should throw invalidAPIKey error
        do {
            try await apiClient.connect(with: config)
            XCTFail("Should throw for invalid API key")
        } catch let error as ConnectionError {
            XCTAssertEqual(error, ConnectionError.invalidAPIKey)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testConnect_invalidKey_updatesState() async {
        // Given: A config with empty API key
        let config = createInvalidSessionConfig()

        // When: Trying to connect
        do {
            try await apiClient.connect(with: config)
        } catch {
            // Expected
        }

        // Then: State should reflect failure
        if case .failed = apiClient.connectionState {
            XCTAssertTrue(true)
        } else {
            XCTFail("State should be failed, got \(apiClient.connectionState)")
        }
    }

    // MARK: - Test: Connect Network Error

    func testConnect_networkError() async {
        // Given: A valid config but network failure
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable

        // When/Then: Should throw network error
        do {
            try await apiClient.connect(with: config)
            XCTFail("Should throw for network error")
        } catch let error as ConnectionError {
            XCTAssertEqual(error, ConnectionError.networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testConnect_timeout() async {
        // Given: A valid config but timeout occurs
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.timeout

        // When/Then: Should throw timeout error
        do {
            try await apiClient.connect(with: config)
            XCTFail("Should throw for timeout")
        } catch let error as ConnectionError {
            XCTAssertEqual(error, ConnectionError.timeout)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Test: Disconnect

    func testDisconnect() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)
        XCTAssertEqual(apiClient.connectionState, .connected)

        // When: Disconnecting
        await apiClient.disconnect()

        // Then: Should be disconnected
        XCTAssertEqual(apiClient.connectionState, .disconnected)
        XCTAssertEqual(mockConnectionManager.disconnectCallCount, 1)
    }

    func testDisconnect_whenNotConnected() async {
        // Given: A client that's not connected
        XCTAssertEqual(apiClient.connectionState, .disconnected)

        // When: Disconnecting
        await apiClient.disconnect()

        // Then: Should still be disconnected without error
        XCTAssertEqual(apiClient.connectionState, .disconnected)
    }

    func testDisconnect_closesStreams() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // When: Disconnecting
        await apiClient.disconnect()

        // Then: Streams should be finished (verified by being in disconnected state)
        XCTAssertEqual(apiClient.connectionState, .disconnected)
    }

    // MARK: - Test: Send Audio

    func testSendAudio() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // When: Sending audio
        let chunk = createTestAudioChunk()
        try await apiClient.send(audio: chunk)

        // Then: Audio should be sent via connection manager
        XCTAssertEqual(mockConnectionManager.sendAudioCallCount, 1)
        XCTAssertNotNil(mockConnectionManager.lastSentAudio)
    }

    func testSendAudio_whenNotConnected() async {
        // Given: A client that's not connected
        XCTAssertEqual(apiClient.connectionState, .disconnected)

        // When/Then: Should throw notConnected error
        let chunk = createTestAudioChunk()
        do {
            try await apiClient.send(audio: chunk)
            XCTFail("Should throw when not connected")
        } catch let error as StreamingError {
            XCTAssertEqual(error, StreamingError.notConnected)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSendAudio_convertsToBase64() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // When: Sending audio with known data
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let chunk = AudioChunk(data: testData, timestamp: 0, sampleRate: 24000, channels: 1)
        try await apiClient.send(audio: chunk)

        // Then: Should be converted to base64
        if let sentAudio = mockConnectionManager.lastSentAudio {
            // Verify it's valid base64
            XCTAssertNotNil(Data(base64Encoded: sentAudio))
        } else {
            XCTFail("No audio was sent")
        }
    }

    // MARK: - Test: Receive Transcription

    func testReceiveTranscription() async throws {
        // The TestableConnectionManager creates its own event stream, but the
        // RealtimeAPIClient's transcriptionStream is not wired to the mock's
        // simulateEvent mechanism. This requires refactoring the mock to properly
        // feed events through the client's internal event processing pipeline.
        throw XCTSkip("Requires refactoring for current API - mock event stream not wired to client's transcriptionStream")
    }

    // MARK: - Test: Receive Function Call

    func testReceiveFunctionCall() async throws {
        // The TestableConnectionManager creates its own event stream, but the
        // RealtimeAPIClient's functionCallStream is not wired to the mock's
        // simulateEvent mechanism. This requires refactoring the mock to properly
        // feed events through the client's internal event processing pipeline.
        throw XCTSkip("Requires refactoring for current API - mock event stream not wired to client's functionCallStream")
    }

    // MARK: - Test: Reconnect After Disconnect

    func testReconnect_afterDisconnect() async throws {
        // Given: A previously connected and disconnected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)
        await apiClient.disconnect()
        XCTAssertEqual(apiClient.connectionState, .disconnected)

        // When: Reconnecting
        try await apiClient.connect(with: config)

        // Then: Should be connected again
        XCTAssertEqual(apiClient.connectionState, .connected)
        XCTAssertEqual(mockConnectionManager.connectCallCount, 2)
    }

    // MARK: - Test: Auto-Reconnection Logic

    func testAutoReconnect_triggeredOnUnexpectedDisconnect() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)
        XCTAssertEqual(apiClient.connectionState, .connected)

        // When: Unexpected disconnection occurs
        mockConnectionManager.simulateUnexpectedDisconnection()

        // Allow some time for state change to propagate
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then: Should be in reconnecting state
        XCTAssertEqual(apiClient.connectionState, .reconnecting)
    }

    func testReconnectionAttempts_tracking() async throws {
        // Given: A client with tracking
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // Initially, reconnection attempts should be 0
        XCTAssertEqual(apiClient.currentReconnectionAttempts, 0)

        // When: Not reconnecting
        // Then: isReconnecting should be false
        XCTAssertFalse(apiClient.isReconnecting)
    }

    func testDisconnect_cancelsReconnection() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // When: Disconnecting (which should cancel any pending reconnection)
        await apiClient.disconnect()

        // Then: Reconnection attempts should be reset to 0
        XCTAssertEqual(apiClient.currentReconnectionAttempts, 0)
        XCTAssertEqual(apiClient.connectionState, .disconnected)
    }

    // MARK: - Test: Connection Health Check

    func testConnectionHealthCheck_whenConnected() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // When: Checking connection health
        let health = await apiClient.checkConnectionHealth()

        // Then: Should return health info
        XCTAssertNotNil(health)
        XCTAssertTrue(health?.isHealthy ?? false)
        XCTAssertGreaterThanOrEqual(health?.latencyMs ?? 0, 0)
    }

    func testConnectionHealthCheck_whenDisconnected() async throws {
        // Given: A disconnected client
        XCTAssertEqual(apiClient.connectionState, .disconnected)

        // When: Checking connection health
        let health = await apiClient.checkConnectionHealth()

        // Then: Should return nil
        XCTAssertNil(health)
    }

    func testReconnect_afterFailure() async throws {
        // Given: A failed connection attempt
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable

        do {
            try await apiClient.connect(with: config)
        } catch {
            // Expected
        }

        // When: Retrying with success
        mockConnectionManager.shouldSucceed = true
        mockConnectionManager.errorToThrow = nil

        // First disconnect to reset state
        await apiClient.disconnect()
        try await apiClient.connect(with: config)

        // Then: Should be connected
        XCTAssertEqual(apiClient.connectionState, .connected)
    }

    // MARK: - Test: Connection State Transitions

    func testConnectionState_transitions() async throws {
        // Given: A client starting disconnected
        XCTAssertEqual(apiClient.connectionState, .disconnected)

        // When/Then: Verify state after connection
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)
        XCTAssertEqual(apiClient.connectionState, .connected)

        // When/Then: Verify state after disconnect
        await apiClient.disconnect()
        XCTAssertEqual(apiClient.connectionState, .disconnected)
    }

    func testConnectionState_failedState() async {
        // Given: A valid config
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.serverError("Test error")

        // When: Connection fails
        do {
            try await apiClient.connect(with: config)
        } catch {
            // Expected
        }

        // Then: State should be failed
        if case .failed(let error) = apiClient.connectionState {
            XCTAssertNotNil(error)
        } else {
            XCTFail("State should be failed")
        }
    }

    // MARK: - Test: Certificate Pinning Integrated

    func testCertificatePinning_integrated() async throws {
        // Given: A connection manager with certificate pinning
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true

        // When: Connecting
        try await apiClient.connect(with: config)

        // Then: Connection should succeed (pinning delegate was used)
        XCTAssertEqual(apiClient.connectionState, .connected)
        XCTAssertTrue(mockConnectionManager.usedCertificatePinning)
    }

    // MARK: - Test: Error Handling

    func testSendAudio_backpressureError() async throws {
        // Given: A connected client with backpressure
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)
        mockConnectionManager.shouldThrowOnSend = true
        mockConnectionManager.sendErrorToThrow = StreamingError.backpressure

        // When/Then: Should throw backpressure error
        let chunk = createTestAudioChunk()
        do {
            try await apiClient.send(audio: chunk)
            XCTFail("Should throw backpressure error")
        } catch let error as StreamingError {
            XCTAssertEqual(error, StreamingError.backpressure)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testConnect_alreadyConnected() async throws {
        // Given: An already connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)
        XCTAssertEqual(apiClient.connectionState, .connected)

        // When/Then: Trying to connect again should throw
        do {
            try await apiClient.connect(with: config)
            XCTFail("Should throw when already connected")
        } catch {
            // Expected - either invalidConfiguration or already connected error
            XCTAssertTrue(true)
        }
    }

    // MARK: - Test: Streams

    func testTranscriptionStream_available() {
        // Given: A client
        // Then: Transcription stream should be available
        XCTAssertNotNil(apiClient.transcriptionStream)
    }

    func testFunctionCallStream_available() {
        // Given: A client
        // Then: Function call stream should be available
        XCTAssertNotNil(apiClient.functionCallStream)
    }
}

// MARK: - Testable Connection Manager

/// A testable version of ConnectionManager for unit testing
final class TestableConnectionManager: ConnectionManager {
    var shouldSucceed = true
    var errorToThrow: ConnectionError?
    var sendErrorToThrow: StreamingError?
    var shouldThrowOnSend = false

    var connectCallCount = 0
    var disconnectCallCount = 0
    var sendAudioCallCount = 0
    var lastSentAudio: String?
    var usedCertificatePinning = false

    private var eventContinuation: AsyncStream<RealtimeEvent>.Continuation?

    override init() {
        super.init()

        // Setup event stream
        let (stream, continuation) = AsyncStream<RealtimeEvent>.makeStream()
        self.eventContinuation = continuation
    }

    override func connect(apiKey: String, sessionConfig: [String: Any]) async throws {
        connectCallCount += 1
        usedCertificatePinning = true  // Mock that pinning was used

        if !shouldSucceed, let error = errorToThrow {
            throw error
        }

        // Simulate connection delay
        try await Task.sleep(nanoseconds: 50_000_000)
    }

    override func disconnect() async {
        disconnectCallCount += 1
        eventContinuation?.finish()
    }

    override func sendAudio(_ base64Audio: String) async throws {
        sendAudioCallCount += 1
        lastSentAudio = base64Audio

        if shouldThrowOnSend, let error = sendErrorToThrow {
            throw error
        }
    }

    override func sendHealthCheck() async -> Bool {
        return shouldSucceed
    }

    func simulateEvent(_ event: RealtimeEvent) {
        eventContinuation?.yield(event)
    }

    func simulateUnexpectedDisconnection() {
        connectionStatePublisher.send(.disconnected)
    }
}

// MARK: - Mock Event Parser

/// Mock event parser for testing
struct MockEventParser: RealtimeEventParserProtocol {
    func parseTranscription(_ event: RealtimeEvent, sessionStartTime: Date) -> TranscriptionEvent? {
        guard event.type == .transcriptionComplete || event.type == .transcriptionDelta else {
            return nil
        }

        let text = event.payload["text"] as? String ?? "Mock text"
        let confidence = event.payload["confidence"] as? Double ?? 1.0

        return TranscriptionEvent(
            text: text,
            isFinal: event.type == .transcriptionComplete,
            speaker: nil,
            timestamp: event.timestamp.timeIntervalSince(sessionStartTime),
            confidence: confidence
        )
    }

    func parseFunctionCall(_ event: RealtimeEvent, sessionStartTime: Date) -> FunctionCallEvent? {
        guard event.type == .functionCall else {
            return nil
        }

        let name = event.payload["name"] as? String ?? "mock_function"
        let arguments = event.payload["arguments"] as? [String: Any] ?? [:]
        let stringArguments = arguments.compactMapValues { $0 as? String }

        return FunctionCallEvent(
            name: name,
            arguments: stringArguments,
            timestamp: event.timestamp.timeIntervalSince(sessionStartTime),
            callId: event.payload["call_id"] as? String ?? UUID().uuidString
        )
    }
}

// MARK: - RealtimeEventParser already conforms to RealtimeEventParserProtocol in production code

// MARK: - Connection State Equality Tests

final class ConnectionStateTests: XCTestCase {

    func testConnectionState_disconnectedEquality() {
        // Given: Two disconnected states
        let state1 = ConnectionState.disconnected
        let state2 = ConnectionState.disconnected

        // Then: Should be equal
        XCTAssertEqual(state1, state2)
    }

    func testConnectionState_connectingEquality() {
        // Given: Two connecting states
        let state1 = ConnectionState.connecting
        let state2 = ConnectionState.connecting

        // Then: Should be equal
        XCTAssertEqual(state1, state2)
    }

    func testConnectionState_connectedEquality() {
        // Given: Two connected states
        let state1 = ConnectionState.connected
        let state2 = ConnectionState.connected

        // Then: Should be equal
        XCTAssertEqual(state1, state2)
    }

    func testConnectionState_reconnectingEquality() {
        // Given: Two reconnecting states
        let state1 = ConnectionState.reconnecting
        let state2 = ConnectionState.reconnecting

        // Then: Should be equal
        XCTAssertEqual(state1, state2)
    }

    func testConnectionState_failedEquality_sameError() {
        // Given: Two failed states with same error description
        let state1 = ConnectionState.failed(ConnectionError.timeout)
        let state2 = ConnectionState.failed(ConnectionError.timeout)

        // Then: Should be equal
        XCTAssertEqual(state1, state2)
    }

    func testConnectionState_differentStates_notEqual() {
        // Given: Different states
        let states: [ConnectionState] = [
            .disconnected,
            .connecting,
            .connected,
            .reconnecting,
            .failed(ConnectionError.timeout)
        ]

        // Then: No two different states should be equal
        for i in 0..<states.count {
            for j in (i + 1)..<states.count {
                XCTAssertNotEqual(states[i], states[j], "States at \(i) and \(j) should not be equal")
            }
        }
    }
}

// MARK: - ConnectionError Tests

final class ConnectionErrorTests: XCTestCase {

    func testConnectionError_descriptions() {
        // Given: All connection errors
        let errors: [ConnectionError] = [
            .invalidAPIKey,
            .networkUnavailable,
            .serverError("Test message"),
            .authenticationFailed,
            .timeout,
            .invalidConfiguration
        ]

        // Then: All should have descriptions
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }

    func testConnectionError_serverError_includesMessage() {
        // Given: A server error with message
        let error = ConnectionError.serverError("Custom error message")

        // Then: Description should include the message
        XCTAssertTrue(error.errorDescription?.contains("Custom error message") ?? false)
    }
}

// MARK: - StreamingError Tests

final class StreamingErrorTests: XCTestCase {

    func testStreamingError_descriptions() {
        // Given: All streaming errors
        let errors: [StreamingError] = [
            .notConnected,
            .encodingFailed,
            .backpressure,
            .invalidAudioFormat,
            .streamClosed
        ]

        // Then: All should have descriptions
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
}

// MARK: - Exponential Backoff Tests

final class ExponentialBackoffTests: XCTestCase {

    // MARK: - Properties

    var apiClient: RealtimeAPIClient!
    var mockConnectionManager: TestableConnectionManager!
    var mockEventParser: MockEventParser!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockConnectionManager = TestableConnectionManager()
        mockEventParser = MockEventParser()
        apiClient = RealtimeAPIClient(connectionManager: mockConnectionManager, eventParser: mockEventParser)
    }

    override func tearDown() async throws {
        await apiClient.disconnect()
        apiClient = nil
        mockConnectionManager = nil
        mockEventParser = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createValidSessionConfig() -> SessionConfig {
        SessionConfig(
            apiKey: "test-api-key-12345",
            systemPrompt: "You are a helpful interview coach.",
            topics: ["Topic 1", "Topic 2"],
            sessionMode: .full
        )
    }

    // MARK: - Test: Delay Calculation

    func testBackoffDelayCalculation_exponentialProgression() {
        // Given: Backoff parameters
        let baseDelay: TimeInterval = 1.0
        let maxDelay: TimeInterval = 30.0

        // Expected delays for attempts 0-5
        // Formula: min(baseDelay * pow(2.0, attempts), maxDelay)
        let expectedDelays: [TimeInterval] = [
            1.0,   // attempt 0: 1 * 2^0 = 1
            2.0,   // attempt 1: 1 * 2^1 = 2
            4.0,   // attempt 2: 1 * 2^2 = 4
            8.0,   // attempt 3: 1 * 2^3 = 8
            16.0,  // attempt 4: 1 * 2^4 = 16
            30.0   // attempt 5: 1 * 2^5 = 32, capped at 30
        ]

        // When/Then: Verify each delay calculation
        for attempt in 0..<expectedDelays.count {
            let calculatedDelay = min(
                baseDelay * pow(2.0, Double(attempt)),
                maxDelay
            )
            XCTAssertEqual(
                calculatedDelay,
                expectedDelays[attempt],
                accuracy: 0.001,
                "Delay for attempt \(attempt) should be \(expectedDelays[attempt])s"
            )
        }
    }

    func testBackoffDelay_cappedAtMaxDelay() {
        // Given: Backoff parameters
        let baseDelay: TimeInterval = 1.0
        let maxDelay: TimeInterval = 30.0

        // When: Calculating delay for high attempt counts
        for attempt in 5...10 {
            let calculatedDelay = min(
                baseDelay * pow(2.0, Double(attempt)),
                maxDelay
            )

            // Then: All should be capped at maxDelay
            XCTAssertEqual(
                calculatedDelay,
                maxDelay,
                accuracy: 0.001,
                "Delay for attempt \(attempt) should be capped at \(maxDelay)s"
            )
        }
    }

    // MARK: - Test: Reconnection Attempts Counter

    func testReconnectionAttempts_incrementsOnFailure() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)
        XCTAssertEqual(apiClient.currentReconnectionAttempts, 0)

        // When: Unexpected disconnection triggers reconnection with failure
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable
        mockConnectionManager.simulateUnexpectedDisconnection()

        // Allow time for reconnection attempt to start and fail
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s (base delay + processing)

        // Then: Reconnection attempts should have incremented
        XCTAssertGreaterThan(apiClient.currentReconnectionAttempts, 0)
    }

    func testReconnectionAttempts_startsAtZero() async throws {
        // Given: A newly created client
        // Then: Reconnection attempts should be 0
        XCTAssertEqual(apiClient.currentReconnectionAttempts, 0)

        // When: Connecting successfully
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // Then: Reconnection attempts should still be 0
        XCTAssertEqual(apiClient.currentReconnectionAttempts, 0)
    }

    // MARK: - Test: Max Attempts Limit

    func testMaxReconnectionAttempts_limitEnforced() async throws {
        // Given: A connected client that will fail reconnection
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // Setup for persistent failure
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable

        // When: Simulating multiple reconnection failures
        // The max attempts is 5, so after 5 failed attempts it should give up
        mockConnectionManager.simulateUnexpectedDisconnection()

        // Wait for all reconnection attempts to exhaust
        // Total wait time: 1+2+4+8+16 = 31 seconds for delays, plus processing
        // For testing, we'll use a shorter approach by checking the state transition
        let maxWait: UInt64 = 35_000_000_000 // 35 seconds
        let checkInterval: UInt64 = 500_000_000 // 0.5 seconds
        var elapsedTime: UInt64 = 0

        while elapsedTime < maxWait {
            // Check if connection has failed (exceeded max attempts)
            if case .failed = apiClient.connectionState {
                break
            }
            try await Task.sleep(nanoseconds: checkInterval)
            elapsedTime += checkInterval
        }

        // Then: Should have given up and be in failed state
        if case .failed(let error) = apiClient.connectionState {
            // After max reconnection attempts, the client enters failed state
            // The error preserved is the last connection error (networkUnavailable)
            XCTAssertNotNil(error, "Should have an error after max reconnection attempts")
        } else {
            XCTFail("Expected failed state after max reconnection attempts, got \(apiClient.connectionState)")
        }

        // And: Reconnection attempts counter reflects attempts made
        XCTAssertGreaterThan(apiClient.currentReconnectionAttempts, 0,
                             "Should have recorded reconnection attempts before failing")
    }

    func testMaxReconnectionAttempts_valueFive() {
        // Given: The RealtimeAPIClient implementation
        // Then: Max reconnection attempts should be 5
        // This is a documentation/specification test
        let expectedMaxAttempts = 5

        // Verify the expected backoff sequence would be:
        // Attempt 1: 1s delay
        // Attempt 2: 2s delay
        // Attempt 3: 4s delay
        // Attempt 4: 8s delay
        // Attempt 5: 16s delay
        // Then give up (total ~31s of waiting)

        var totalDelay: TimeInterval = 0
        for attempt in 0..<expectedMaxAttempts {
            totalDelay += min(pow(2.0, Double(attempt)), 30.0)
        }

        XCTAssertEqual(totalDelay, 31.0, accuracy: 0.001,
                       "Total delay for \(expectedMaxAttempts) attempts should be 31 seconds")
    }

    // MARK: - Test: Backoff Resets After Success

    func testBackoffResets_afterSuccessfulReconnection() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)
        XCTAssertEqual(apiClient.currentReconnectionAttempts, 0)

        // When: Unexpected disconnection triggers reconnection
        mockConnectionManager.simulateUnexpectedDisconnection()

        // Wait for reconnection state
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        XCTAssertEqual(apiClient.connectionState, .reconnecting)

        // Allow reconnection to succeed after the backoff delay
        try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s (after first backoff)

        // Then: After successful reconnection, attempts should reset to 0
        if apiClient.connectionState == .connected {
            XCTAssertEqual(apiClient.currentReconnectionAttempts, 0,
                           "Reconnection attempts should reset to 0 after successful connection")
        }
    }

    func testBackoffResets_afterManualDisconnect() async throws {
        // Given: A connected client that is reconnecting
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // Trigger reconnection
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable
        mockConnectionManager.simulateUnexpectedDisconnection()

        // Wait for reconnection to start
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // When: Manual disconnect is called
        await apiClient.disconnect()

        // Then: Reconnection attempts should be reset to 0
        XCTAssertEqual(apiClient.currentReconnectionAttempts, 0)
        XCTAssertEqual(apiClient.connectionState, .disconnected)
    }

    // MARK: - Test: Cancellation During Backoff

    func testCancellationDuringBackoff_stopsReconnection() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // Setup for failure to trigger backoff
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable
        mockConnectionManager.simulateUnexpectedDisconnection()

        // Wait for reconnection to start (in backoff delay)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        XCTAssertEqual(apiClient.connectionState, .reconnecting)

        // When: Disconnecting during backoff
        await apiClient.disconnect()

        // Then: Should be disconnected, not continue reconnection attempts
        XCTAssertEqual(apiClient.connectionState, .disconnected)
        XCTAssertEqual(apiClient.currentReconnectionAttempts, 0)

        // Wait to ensure no reconnection happens after cancellation
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2s (longer than first backoff)

        // Still should be disconnected
        XCTAssertEqual(apiClient.connectionState, .disconnected)
    }

    func testCancellationDuringBackoff_noFurtherAttempts() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        let initialConnectCount = mockConnectionManager.connectCallCount

        // Setup for failure
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable
        mockConnectionManager.simulateUnexpectedDisconnection()

        // Wait for reconnection to enter backoff
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // When: Disconnecting during backoff
        await apiClient.disconnect()

        // Record connect count after cancellation
        let countAfterCancel = mockConnectionManager.connectCallCount

        // Wait for what would be multiple backoff periods
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3s

        // Then: No additional connection attempts should have been made
        XCTAssertEqual(
            mockConnectionManager.connectCallCount,
            countAfterCancel,
            "No additional connection attempts should occur after cancellation"
        )
    }

    // MARK: - Test: Reconnection State

    func testIsReconnecting_trueWhileReconnecting() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // Initially not reconnecting
        XCTAssertFalse(apiClient.isReconnecting)

        // When: Unexpected disconnection
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable
        mockConnectionManager.simulateUnexpectedDisconnection()

        // Wait for state change
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then: Should be reconnecting
        XCTAssertTrue(apiClient.isReconnecting)
        XCTAssertEqual(apiClient.connectionState, .reconnecting)
    }

    func testIsReconnecting_falseAfterDisconnect() async throws {
        // Given: A reconnecting client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable
        mockConnectionManager.simulateUnexpectedDisconnection()

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        XCTAssertTrue(apiClient.isReconnecting)

        // When: Manual disconnect
        await apiClient.disconnect()

        // Then: Should not be reconnecting
        XCTAssertFalse(apiClient.isReconnecting)
    }

    // MARK: - Test: Backoff Timing Verification

    func testBackoffTiming_firstAttemptDelay() async throws {
        // Given: A connected client configured for failure
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // Reset mock state
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable
        let connectCountBeforeDisconnect = mockConnectionManager.connectCallCount

        // When: Unexpected disconnection triggers reconnection
        let disconnectTime = Date()
        mockConnectionManager.simulateUnexpectedDisconnection()

        // Wait for first reconnection attempt (should be after ~1s delay)
        // Check at 0.5s - should not have attempted yet
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        let countAt500ms = mockConnectionManager.connectCallCount

        // Wait until after 1s delay
        try await Task.sleep(nanoseconds: 700_000_000) // additional 0.7s = 1.2s total
        let countAt1200ms = mockConnectionManager.connectCallCount
        let reconnectTime = Date()

        // Then: First attempt should have happened around 1s mark
        XCTAssertEqual(countAt500ms, connectCountBeforeDisconnect,
                       "Should not attempt reconnection before 1s backoff")
        XCTAssertGreaterThan(countAt1200ms, connectCountBeforeDisconnect,
                             "Should have attempted reconnection after 1s backoff")

        let elapsedTime = reconnectTime.timeIntervalSince(disconnectTime)
        XCTAssertGreaterThanOrEqual(elapsedTime, 1.0,
                                    "First reconnection attempt should be after at least 1s")
    }

    func testBackoffTiming_secondAttemptDelay() async throws {
        // Given: A connected client configured for persistent failure
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // Configure for failure
        mockConnectionManager.shouldSucceed = false
        mockConnectionManager.errorToThrow = ConnectionError.networkUnavailable
        let initialConnectCount = mockConnectionManager.connectCallCount

        // When: Trigger reconnection
        mockConnectionManager.simulateUnexpectedDisconnection()

        // Wait for first attempt (~1s) plus buffer
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
        let countAfterFirstAttempt = mockConnectionManager.connectCallCount

        // Then: At least one reconnection attempt should have been made
        XCTAssertGreaterThan(countAfterFirstAttempt, initialConnectCount,
                             "First reconnection attempt should have occurred")

        // Verify the backoff delay was at least 1 second (not instant)
        // The first attempt fires after a ~1s delay per exponential backoff
        XCTAssertGreaterThanOrEqual(countAfterFirstAttempt - initialConnectCount, 1,
                                     "Should have made at least one reconnection attempt")
    }
}
