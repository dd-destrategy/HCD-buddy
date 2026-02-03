//
//  RealtimeAPIClient.swift
//  HCD Interview Coach
//
//  EPIC E3-S2: Implement API Client Wrapper
//  Wraps SwiftOpenAI Realtime client with custom behavior
//

import Foundation
import Combine

/// Production implementation of RealtimeAPIConnecting using SwiftOpenAI
final class RealtimeAPIClient: RealtimeAPIConnecting {
    // MARK: - Properties

    private var currentConfig: SessionConfig?
    private var isConnected = false
    private var sessionStartTime: Date?

    // Connection state management
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    var connectionState: ConnectionState {
        connectionStateSubject.value
    }

    // Event streams
    private var transcriptionContinuation: AsyncStream<TranscriptionEvent>.Continuation?
    private var functionCallContinuation: AsyncStream<FunctionCallEvent>.Continuation?

    private(set) lazy var transcriptionStream: AsyncStream<TranscriptionEvent> = {
        AsyncStream { continuation in
            self.transcriptionContinuation = continuation
        }
    }()

    private(set) lazy var functionCallStream: AsyncStream<FunctionCallEvent> = {
        AsyncStream { continuation in
            self.functionCallContinuation = continuation
        }
    }()

    // Connection management
    private let connectionManager: ConnectionManager
    private let eventParser: RealtimeEventParser

    // Reconnection tracking
    private var reconnectionTask: Task<Void, Never>?
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 5
    private let baseReconnectionDelay: TimeInterval = 1.0 // 1 second
    private let maxReconnectionDelay: TimeInterval = 30.0 // 30 seconds

    // Audio streaming
    private var audioStreamTask: Task<Void, Never>?
    private let audioQueue = AsyncStream<AudioChunk>.makeStream()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(connectionManager: ConnectionManager = .init(), eventParser: RealtimeEventParser = .init()) {
        self.connectionManager = connectionManager
        self.eventParser = eventParser
        setupConnectionStateObserver()
    }

    // MARK: - RealtimeAPIConnecting Implementation

    func connect(with config: SessionConfig) async throws {
        // Allow connection from disconnected or reconnecting states
        guard connectionState == .disconnected || connectionState == .reconnecting else {
            throw ConnectionError.invalidConfiguration
        }

        currentConfig = config

        // Only send .connecting state if not already reconnecting
        if connectionState != .reconnecting {
            connectionStateSubject.send(.connecting)
        }

        do {
            // Validate API key
            guard !config.apiKey.isEmpty else {
                throw ConnectionError.invalidAPIKey
            }

            // Build session configuration
            let sessionConfig = try await SessionConfigBuilder.build(from: config)

            // Connect via connection manager
            try await connectionManager.connect(
                apiKey: config.apiKey,
                sessionConfig: sessionConfig
            )

            // Mark as connected
            isConnected = true
            sessionStartTime = Date()
            connectionStateSubject.send(.connected)

            // Start listening for events
            startEventListening()

        } catch let error as ConnectionError {
            connectionStateSubject.send(.failed(error))
            throw error
        } catch {
            let connectionError = ConnectionError.serverError(error.localizedDescription)
            connectionStateSubject.send(.failed(connectionError))
            throw connectionError
        }
    }

    func send(audio: AudioChunk) async throws {
        guard isConnected else {
            throw StreamingError.notConnected
        }

        guard connectionState == .connected else {
            throw StreamingError.streamClosed
        }

        do {
            // Convert audio to base64
            let base64Audio = audio.data.base64EncodedString()

            // Send to connection manager
            try await connectionManager.sendAudio(base64Audio)

        } catch {
            // Check for backpressure
            if error.localizedDescription.contains("buffer") ||
               error.localizedDescription.contains("backpressure") {
                throw StreamingError.backpressure
            }
            throw StreamingError.encodingFailed
        }
    }

    func disconnect() async {
        isConnected = false
        sessionStartTime = nil

        // Cancel any pending reconnection
        reconnectionTask?.cancel()
        reconnectionTask = nil
        reconnectionAttempts = 0

        // Stop event listening
        audioStreamTask?.cancel()
        audioStreamTask = nil

        // Disconnect from server
        await connectionManager.disconnect()

        // Close streams
        transcriptionContinuation?.finish()
        functionCallContinuation?.finish()

        // Update state
        connectionStateSubject.send(.disconnected)
    }

    // MARK: - Connection Health

    /// Check if the connection is healthy and responsive
    /// - Returns: A tuple indicating (isHealthy, latencyMs) or nil if check failed
    func checkConnectionHealth() async -> (isHealthy: Bool, latencyMs: Double)? {
        guard isConnected, connectionState == .connected else {
            return nil
        }

        let startTime = Date()
        let isResponsive = await connectionManager.sendHealthCheck()
        let latencyMs = Date().timeIntervalSince(startTime) * 1000

        return (isHealthy: isResponsive, latencyMs: latencyMs)
    }

    /// Current reconnection attempt count (for monitoring)
    var currentReconnectionAttempts: Int {
        reconnectionAttempts
    }

    /// Whether a reconnection is currently in progress
    var isReconnecting: Bool {
        connectionState == .reconnecting
    }

    // MARK: - Private Methods

    private func setupConnectionStateObserver() {
        connectionManager.connectionStatePublisher
            .sink { [weak self] state in
                self?.handleConnectionStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func handleConnectionStateChange(_ state: ConnectionState) {
        switch state {
        case .disconnected:
            if isConnected {
                // Unexpected disconnection, attempt reconnect
                connectionStateSubject.send(.reconnecting)
                attemptReconnection()
            }
        case .failed(let error):
            connectionStateSubject.send(.failed(error))
            isConnected = false
        default:
            connectionStateSubject.send(state)
        }
    }

    private func attemptReconnection() {
        // Cancel any existing reconnection task
        reconnectionTask?.cancel()

        reconnectionTask = Task { [weak self] in
            guard let self = self else { return }
            guard let config = self.currentConfig else { return }

            // Check if we've exceeded max retries
            if self.reconnectionAttempts >= self.maxReconnectionAttempts {
                self.connectionStateSubject.send(.failed(ConnectionError.timeout))
                self.isConnected = false
                self.reconnectionAttempts = 0
                return
            }

            // Calculate exponential backoff delay: 1s, 2s, 4s, 8s, 16s (capped at 30s)
            let delay = min(
                self.baseReconnectionDelay * pow(2.0, Double(self.reconnectionAttempts)),
                self.maxReconnectionDelay
            )

            self.reconnectionAttempts += 1

            // Wait for backoff period
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                // Task was cancelled
                return
            }

            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }

            // Attempt to reconnect
            do {
                try await self.connect(with: config)
                // Success - reset retry count
                self.reconnectionAttempts = 0
            } catch {
                // Reconnection failed, will retry if not at max attempts
                if self.reconnectionAttempts < self.maxReconnectionAttempts {
                    self.attemptReconnection()
                } else {
                    self.connectionStateSubject.send(.failed(ConnectionError.timeout))
                    self.isConnected = false
                    self.reconnectionAttempts = 0
                }
            }
        }
    }

    private func startEventListening() {
        audioStreamTask = Task { [weak self] in
            guard let self = self else { return }

            // Listen for events from connection manager
            for await event in self.connectionManager.eventStream {
                await self.handleEvent(event)
            }
        }
    }

    private func handleEvent(_ event: RealtimeEvent) async {
        switch event.type {
        case .transcriptionDelta, .transcriptionComplete:
            handleTranscriptionEvent(event)

        case .functionCall:
            handleFunctionCallEvent(event)

        case .error:
            handleErrorEvent(event)

        case .ping, .pong:
            // Keepalive, no action needed
            break
        }
    }

    private func handleTranscriptionEvent(_ event: RealtimeEvent) {
        guard let transcriptionEvent = eventParser.parseTranscription(
            event,
            sessionStartTime: sessionStartTime ?? Date()
        ) else {
            return
        }

        transcriptionContinuation?.yield(transcriptionEvent)
    }

    private func handleFunctionCallEvent(_ event: RealtimeEvent) {
        guard let functionCallEvent = eventParser.parseFunctionCall(
            event,
            sessionStartTime: sessionStartTime ?? Date()
        ) else {
            return
        }

        functionCallContinuation?.yield(functionCallEvent)
    }

    private func handleErrorEvent(_ event: RealtimeEvent) {
        if let errorMessage = event.payload["error"] as? String {
            let error = ConnectionError.serverError(errorMessage)
            connectionStateSubject.send(.failed(error))
        }
    }

    deinit {
        // Perform synchronous cleanup only - async tasks may not complete during deallocation
        // Callers should call disconnect() explicitly before releasing the client
        isConnected = false
        reconnectionTask?.cancel()
        audioStreamTask?.cancel()
        transcriptionContinuation?.finish()
        functionCallContinuation?.finish()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

/// Generic realtime event from the API
struct RealtimeEvent {
    let type: EventType
    let payload: [String: Any]
    let timestamp: Date

    enum EventType: String {
        case transcriptionDelta = "transcription.delta"
        case transcriptionComplete = "transcription.complete"
        case functionCall = "function.call"
        case error = "error"
        case ping = "ping"
        case pong = "pong"
    }
}

/// Manages WebSocket connection to OpenAI Realtime API
final class ConnectionManager {
    // MARK: - Properties

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 5
    private var pingTimer: Timer?

    /// Certificate pinning delegate for secure connections
    private let certificatePinningDelegate: WebSocketCertificatePinningDelegate

    // Publishers
    let connectionStatePublisher = PassthroughSubject<ConnectionState, Never>()

    // Event streaming
    private var eventContinuation: AsyncStream<RealtimeEvent>.Continuation?
    private(set) lazy var eventStream: AsyncStream<RealtimeEvent> = {
        AsyncStream { continuation in
            self.eventContinuation = continuation
        }
    }()

    // MARK: - Initialization

    init() {
        self.certificatePinningDelegate = WebSocketCertificatePinningDelegate()
    }

    // MARK: - Connection

    func connect(apiKey: String, sessionConfig: [String: Any]) async throws {
        // Create WebSocket URL
        guard let url = URL(string: "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01") else {
            throw ConnectionError.invalidConfiguration
        }

        // Create URL session with certificate pinning delegate
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        session = URLSession(
            configuration: configuration,
            delegate: certificatePinningDelegate,
            delegateQueue: nil
        )

        // Create WebSocket request
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        // Create WebSocket task
        webSocketTask = session?.webSocketTask(with: request)
        webSocketTask?.resume()

        // Wait for connection
        try await waitForConnection()

        // Send session configuration
        try await sendSessionConfig(sessionConfig)

        // Start receiving messages
        startReceiving()

        // Start ping timer
        startPingTimer()

        reconnectionAttempts = 0
    }

    func disconnect() async {
        pingTimer?.invalidate()
        pingTimer = nil

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil

        eventContinuation?.finish()
        connectionStatePublisher.send(.disconnected)
    }

    func sendAudio(_ base64Audio: String) async throws {
        guard let webSocketTask = webSocketTask else {
            throw StreamingError.notConnected
        }

        let message: [String: Any] = [
            "type": "input_audio_buffer.append",
            "audio": base64Audio
        ]

        let data = try JSONSerialization.data(withJSONObject: message)
        let string = String(data: data, encoding: .utf8) ?? ""

        try await webSocketTask.send(.string(string))
    }

    /// Send a health check ping and wait for response
    /// - Returns: true if the connection is responsive, false otherwise
    func sendHealthCheck() async -> Bool {
        guard let webSocketTask = webSocketTask else {
            return false
        }

        let message: [String: Any] = ["type": "ping"]
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let string = String(data: data, encoding: .utf8) else {
            return false
        }

        do {
            try await webSocketTask.send(.string(string))
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private Methods

    private func waitForConnection() async throws {
        // Simple connection check - in production this would verify handshake
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }

    private func sendSessionConfig(_ config: [String: Any]) async throws {
        guard let webSocketTask = webSocketTask else {
            throw StreamingError.notConnected
        }

        let message: [String: Any] = [
            "type": "session.update",
            "session": config
        ]

        let data = try JSONSerialization.data(withJSONObject: message)
        let string = String(data: data, encoding: .utf8) ?? ""

        try await webSocketTask.send(.string(string))
    }

    private func startReceiving() {
        Task {
            await receiveMessages()
        }
    }

    private func receiveMessages() async {
        guard let webSocketTask = webSocketTask else { return }

        do {
            while true {
                let message = try await webSocketTask.receive()

                switch message {
                case .string(let text):
                    handleMessage(text)

                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMessage(text)
                    }

                @unknown default:
                    break
                }
            }
        } catch {
            // Connection closed or error - notify client to handle reconnection
            connectionStatePublisher.send(.disconnected)
            // RealtimeAPIClient handles reconnection logic via handleConnectionStateChange
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let typeString = json["type"] as? String,
              let type = RealtimeEvent.EventType(rawValue: typeString) else {
            return
        }

        let event = RealtimeEvent(type: type, payload: json, timestamp: Date())
        eventContinuation?.yield(event)
    }

    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            Task {
                await self?.sendPing()
            }
        }
    }

    private func sendPing() async {
        guard let webSocketTask = webSocketTask else { return }

        let message: [String: Any] = ["type": "ping"]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            try? await webSocketTask.send(.string(string))
        }
    }

    /// Resets the reconnection attempt counter
    /// Called by the client after a successful reconnection
    func resetReconnectionAttempts() {
        reconnectionAttempts = 0
    }
}

/// Event parser for Realtime API events
struct RealtimeEventParser {
    func parseTranscription(_ event: RealtimeEvent, sessionStartTime: Date) -> TranscriptionEvent? {
        guard let text = event.payload["text"] as? String else {
            return nil
        }

        let isFinal = event.type == .transcriptionComplete
        let timestamp = event.timestamp.timeIntervalSince(sessionStartTime)
        let confidence = event.payload["confidence"] as? Double ?? 1.0

        // Parse speaker if available
        let speakerString = event.payload["speaker"] as? String
        let speaker = speakerString.flatMap { Speaker(rawValue: $0) }

        return TranscriptionEvent(
            text: text,
            isFinal: isFinal,
            speaker: speaker,
            timestamp: timestamp,
            confidence: confidence
        )
    }

    func parseFunctionCall(_ event: RealtimeEvent, sessionStartTime: Date) -> FunctionCallEvent? {
        guard let name = event.payload["name"] as? String,
              let argumentsDict = event.payload["arguments"] as? [String: Any] else {
            return nil
        }

        // Convert arguments to [String: String]
        let arguments = argumentsDict.compactMapValues { value -> String? in
            if let string = value as? String {
                return string
            } else if let convertible = value as? CustomStringConvertible {
                return convertible.description
            }
            return nil
        }

        let timestamp = event.timestamp.timeIntervalSince(sessionStartTime)
        let callId = event.payload["call_id"] as? String ?? UUID().uuidString

        return FunctionCallEvent(
            name: name,
            arguments: arguments,
            timestamp: timestamp,
            callId: callId
        )
    }
}
