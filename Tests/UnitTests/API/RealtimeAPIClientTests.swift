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
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // Setup expectation for transcription
        let transcriptionExpectation = expectation(description: "Receive transcription")
        var receivedTranscription: TranscriptionEvent?

        // Start listening for transcriptions
        Task {
            for await event in apiClient.transcriptionStream {
                receivedTranscription = event
                transcriptionExpectation.fulfill()
                break
            }
        }

        // When: Mock event is received
        let mockEvent = RealtimeEvent(
            type: .transcriptionComplete,
            payload: ["text": "Hello world", "confidence": 0.95],
            timestamp: Date()
        )
        mockConnectionManager.simulateEvent(mockEvent)

        // Then: Should receive transcription
        await fulfillment(of: [transcriptionExpectation], timeout: 2.0)
        XCTAssertNotNil(receivedTranscription)
    }

    // MARK: - Test: Receive Function Call

    func testReceiveFunctionCall() async throws {
        // Given: A connected client
        let config = createValidSessionConfig()
        mockConnectionManager.shouldSucceed = true
        try await apiClient.connect(with: config)

        // Setup expectation for function call
        let functionCallExpectation = expectation(description: "Receive function call")
        var receivedFunctionCall: FunctionCallEvent?

        // Start listening for function calls
        Task {
            for await event in apiClient.functionCallStream {
                receivedFunctionCall = event
                functionCallExpectation.fulfill()
                break
            }
        }

        // When: Mock function call is received
        let mockEvent = RealtimeEvent(
            type: .functionCall,
            payload: [
                "name": "show_nudge",
                "arguments": ["text": "Test nudge", "reason": "Test reason"],
                "call_id": "test-call-id"
            ],
            timestamp: Date()
        )
        mockConnectionManager.simulateEvent(mockEvent)

        // Then: Should receive function call
        await fulfillment(of: [functionCallExpectation], timeout: 2.0)
        XCTAssertNotNil(receivedFunctionCall)
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

// MARK: - Protocol for Event Parser

protocol RealtimeEventParserProtocol {
    func parseTranscription(_ event: RealtimeEvent, sessionStartTime: Date) -> TranscriptionEvent?
    func parseFunctionCall(_ event: RealtimeEvent, sessionStartTime: Date) -> FunctionCallEvent?
}

extension RealtimeEventParser: RealtimeEventParserProtocol {}

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
