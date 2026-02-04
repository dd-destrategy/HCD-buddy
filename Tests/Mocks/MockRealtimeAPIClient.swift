//
//  MockRealtimeAPIClient.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Mock implementation of RealtimeAPIConnecting protocol for testing
//

import Foundation
@testable import HCDInterviewCoach

/// Mock Realtime API client for testing
@MainActor
final class MockRealtimeAPIClient: RealtimeAPIConnecting {

    // MARK: - Mock State

    var isConnected = false
    var shouldThrowOnConnect = false
    var shouldThrowOnSend = false
    var connectionErrorToThrow: ConnectionError?
    var streamingErrorToThrow: StreamingError?

    // MARK: - Call Tracking

    var connectCallCount = 0
    var disconnectCallCount = 0
    var sendAudioCallCount = 0
    var lastSessionConfig: SessionConfig?
    var sentAudioChunks: [AudioChunk] = []

    // MARK: - RealtimeAPIConnecting Protocol

    private var _connectionState: ConnectionState = .disconnected
    var connectionState: ConnectionState {
        get { _connectionState }
    }

    private let transcriptionContinuation: AsyncStream<TranscriptionEvent>.Continuation
    private let functionCallContinuation: AsyncStream<FunctionCallEvent>.Continuation

    let transcriptionStream: AsyncStream<TranscriptionEvent>
    let functionCallStream: AsyncStream<FunctionCallEvent>

    // MARK: - Initialization

    init() {
        let (transcriptionStream, transcriptionContinuation) = AsyncStream<TranscriptionEvent>.makeStream()
        let (functionCallStream, functionCallContinuation) = AsyncStream<FunctionCallEvent>.makeStream()

        self.transcriptionStream = transcriptionStream
        self.functionCallStream = functionCallStream
        self.transcriptionContinuation = transcriptionContinuation
        self.functionCallContinuation = functionCallContinuation
    }

    // MARK: - RealtimeAPIConnecting Methods

    func connect(with config: SessionConfig) async throws {
        connectCallCount += 1
        lastSessionConfig = config

        if shouldThrowOnConnect, let error = connectionErrorToThrow {
            _connectionState = .failed(error)
            throw error
        }

        _connectionState = .connecting
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        _connectionState = .connected
        isConnected = true
    }

    func send(audio: AudioChunk) async throws {
        sendAudioCallCount += 1
        sentAudioChunks.append(audio)

        guard isConnected else {
            throw StreamingError.notConnected
        }

        if shouldThrowOnSend, let error = streamingErrorToThrow {
            throw error
        }
    }

    func disconnect() async {
        disconnectCallCount += 1
        isConnected = false
        _connectionState = .disconnected
        transcriptionContinuation.finish()
        functionCallContinuation.finish()
    }

    // MARK: - Test Helpers

    /// Simulate receiving a transcription event
    func simulateTranscription(_ event: TranscriptionEvent) {
        transcriptionContinuation.yield(event)
    }

    /// Simulate receiving a function call event
    func simulateFunctionCall(_ event: FunctionCallEvent) {
        functionCallContinuation.yield(event)
    }

    /// Simulate disconnection
    func simulateDisconnect() {
        isConnected = false
        _connectionState = .disconnected
    }

    /// Simulate reconnection
    func simulateReconnect() async {
        _connectionState = .reconnecting
        try? await Task.sleep(nanoseconds: 100_000_000)
        _connectionState = .connected
        isConnected = true
    }

    /// Simulate connection failure
    func simulateConnectionFailure(_ error: ConnectionError) {
        _connectionState = .failed(error)
        isConnected = false
    }

    /// Reset mock state
    func reset() {
        connectCallCount = 0
        disconnectCallCount = 0
        sendAudioCallCount = 0
        isConnected = false
        shouldThrowOnConnect = false
        shouldThrowOnSend = false
        connectionErrorToThrow = nil
        streamingErrorToThrow = nil
        lastSessionConfig = nil
        sentAudioChunks.removeAll()
        _connectionState = .disconnected
    }

    // MARK: - Test Data Helpers

    /// Create a test transcription event
    nonisolated static func createTestTranscription(
        text: String = "Test transcription",
        isFinal: Bool = true,
        speaker: Speaker? = .interviewer,
        timestamp: TimeInterval = 0.0,
        confidence: Double = 0.95
    ) -> TranscriptionEvent {
        TranscriptionEvent(
            text: text,
            isFinal: isFinal,
            speaker: speaker,
            timestamp: timestamp,
            confidence: confidence
        )
    }

    /// Create a test function call event
    nonisolated static func createTestFunctionCall(
        name: String = "show_nudge",
        arguments: [String: String] = ["message": "Test nudge"],
        timestamp: TimeInterval = 0.0
    ) -> FunctionCallEvent {
        FunctionCallEvent(
            name: name,
            arguments: arguments,
            timestamp: timestamp
        )
    }
}
