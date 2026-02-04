//
//  MockRealtimeAPIServer.swift
//  HCD Interview Coach Tests
//
//  EPIC E0-S13 & E14: Testing & Quality
//  Mock WebSocket server for integration testing
//

import Foundation
import Network
@testable import HCDInterviewCoach

/// Mock Realtime API server for integration testing
/// Simulates OpenAI Realtime API WebSocket behavior
actor MockRealtimeAPIServer {

    // MARK: - Server State

    private var isRunning = false
    private var port: Int = 8765
    private var listener: NWListener?
    private var connections: [NWConnection] = []

    // MARK: - Event Queues

    private var queuedTranscriptions: [TranscriptionEvent] = []
    private var queuedFunctionCalls: [FunctionCallEvent] = []

    // MARK: - Configuration

    var autoRespondToAudio = true
    var connectionDelay: TimeInterval = 0.1
    var shouldSimulateErrors = false

    // MARK: - Lifecycle

    /// Start the mock server on the specified port
    func start(port: Int = 8765) throws {
        self.port = port

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        guard let listener = try? NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: UInt16(port))) else {
            throw MockServerError.failedToStart
        }

        self.listener = listener

        listener.stateUpdateHandler = { [weak listener] state in
            switch state {
            case .ready:
                print("✅ Mock API Server listening on port \(port)")
            case .failed(let error):
                print("❌ Mock API Server failed: \(error)")
                listener?.cancel()
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            Task {
                await self?.handleNewConnection(connection)
            }
        }

        listener.start(queue: .main)
        isRunning = true
    }

    /// Stop the mock server
    func stop() {
        listener?.cancel()
        listener = nil

        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()

        isRunning = false
        print("🛑 Mock API Server stopped")
    }

    // MARK: - Connection Handling

    private func handleNewConnection(_ connection: NWConnection) {
        connections.append(connection)

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("📡 Client connected")
                Task {
                    await self?.sendWelcomeMessage(to: connection)
                }
            case .failed(let error):
                print("❌ Connection failed: \(error)")
            case .cancelled:
                print("👋 Client disconnected")
                Task {
                    await self?.removeConnection(connection)
                }
            default:
                break
            }
        }

        connection.start(queue: .main)
        receiveMessages(on: connection)
    }

    private func removeConnection(_ connection: NWConnection) {
        connections.removeAll { $0 === connection }
    }

    // MARK: - Message Handling

    private func receiveMessages(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                Task {
                    await self?.handleReceivedData(data, from: connection)
                }
            }

            if !isComplete {
                self?.receiveMessages(on: connection)
            }
        }
    }

    private func handleReceivedData(_ data: Data, from connection: NWConnection) {
        // Parse incoming audio or control messages
        // In a real implementation, this would parse WebSocket frames
        // For testing, we'll simulate immediate responses

        if autoRespondToAudio {
            // Simulate transcription response
            Task {
                try? await Task.sleep(nanoseconds: UInt64(connectionDelay * 1_000_000_000))
                await sendNextQueuedEvent(to: connection)
            }
        }
    }

    // MARK: - Sending Events

    private func sendWelcomeMessage(to connection: NWConnection) {
        let welcome = """
        {"type":"session.created","session":{"id":"test-session-\(UUID().uuidString)"}}
        """
        send(message: welcome, to: connection)
    }

    private func sendNextQueuedEvent(to connection: NWConnection) {
        if !queuedTranscriptions.isEmpty {
            let event = queuedTranscriptions.removeFirst()
            sendTranscriptionEvent(event, to: connection)
        } else if !queuedFunctionCalls.isEmpty {
            let event = queuedFunctionCalls.removeFirst()
            sendFunctionCallEvent(event, to: connection)
        }
    }

    private func sendTranscriptionEvent(_ event: TranscriptionEvent, to connection: NWConnection) {
        let json = """
        {
            "type": "\(event.isFinal ? "conversation.item.created" : "response.audio_transcript.delta")",
            "text": "\(event.text)",
            "speaker": "\(event.speaker?.rawValue ?? "unknown")",
            "timestamp": \(event.timestamp),
            "confidence": \(event.confidence)
        }
        """
        send(message: json, to: connection)
    }

    private func sendFunctionCallEvent(_ event: FunctionCallEvent, to connection: NWConnection) {
        let argsJson = try? JSONSerialization.data(withJSONObject: event.arguments, options: [])
        let argsString = argsJson.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let json = """
        {
            "type": "response.function_call_arguments.done",
            "call_id": "\(event.callId)",
            "name": "\(event.name)",
            "arguments": \(argsString),
            "timestamp": \(event.timestamp)
        }
        """
        send(message: json, to: connection)
    }

    private func send(message: String, to connection: NWConnection) {
        guard let data = message.data(using: .utf8) else { return }

        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("❌ Failed to send message: \(error)")
            }
        })
    }

    // MARK: - Test Control Methods

    /// Queue a transcription event to be sent
    func sendTranscription(_ text: String, isFinal: Bool = true, speaker: Speaker = .interviewer) {
        let event = TranscriptionEvent(
            text: text,
            isFinal: isFinal,
            speaker: speaker,
            timestamp: Date().timeIntervalSince1970,
            confidence: 0.95
        )
        queuedTranscriptions.append(event)

        // Send immediately if auto-respond is on
        if autoRespondToAudio, !connections.isEmpty {
            Task {
                await sendNextQueuedEvent(to: connections[0])
            }
        }
    }

    /// Queue a function call event to be sent
    func sendFunctionCall(_ call: FunctionCallEvent) {
        queuedFunctionCalls.append(call)

        if autoRespondToAudio, !connections.isEmpty {
            Task {
                await sendNextQueuedEvent(to: connections[0])
            }
        }
    }

    /// Simulate server disconnection
    func simulateDisconnect() {
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
    }

    /// Simulate server reconnection
    func simulateReconnect() async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        // Connections will be re-established by clients
    }

    /// Simulate network error
    func simulateNetworkError() {
        shouldSimulateErrors = true
        for connection in connections {
            connection.forceCancel()
        }
    }

    /// Clear all queued events
    func clearQueue() {
        queuedTranscriptions.removeAll()
        queuedFunctionCalls.removeAll()
    }

    /// Get number of active connections
    func connectionCount() -> Int {
        return connections.count
    }

    // MARK: - Test Helpers

    /// Create a coaching nudge function call
    static func createCoachingNudge(message: String, confidence: Double = 0.9) -> FunctionCallEvent {
        FunctionCallEvent(
            name: "show_nudge",
            arguments: [
                "message": message,
                "confidence": String(confidence)
            ],
            timestamp: Date().timeIntervalSince1970
        )
    }

    /// Create an insight flag function call
    static func createInsightFlag(quote: String, theme: String) -> FunctionCallEvent {
        FunctionCallEvent(
            name: "flag_insight",
            arguments: [
                "quote": quote,
                "theme": theme,
                "confidence": "0.88"
            ],
            timestamp: Date().timeIntervalSince1970
        )
    }

    /// Create a topic update function call
    static func createTopicUpdate(topic: String, status: String) -> FunctionCallEvent {
        FunctionCallEvent(
            name: "update_topic",
            arguments: [
                "topic": topic,
                "status": status
            ],
            timestamp: Date().timeIntervalSince1970
        )
    }
}

// MARK: - Mock Server Errors

enum MockServerError: LocalizedError {
    case failedToStart
    case alreadyRunning
    case notRunning

    var errorDescription: String? {
        switch self {
        case .failedToStart:
            return "Failed to start mock server"
        case .alreadyRunning:
            return "Mock server is already running"
        case .notRunning:
            return "Mock server is not running"
        }
    }
}
