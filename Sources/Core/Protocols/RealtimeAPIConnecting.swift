//
//  RealtimeAPIConnecting.swift
//  HCD Interview Coach
//
//  EPIC E3-S1: Define API Protocols
//  Protocol definitions for OpenAI Realtime API integration
//

import Foundation

// MARK: - Main Protocol

/// Protocol defining the interface for connecting to OpenAI Realtime API
protocol RealtimeAPIConnecting {
    /// Current connection state
    var connectionState: ConnectionState { get }

    /// Stream of transcription events (partial and final)
    var transcriptionStream: AsyncStream<TranscriptionEvent> { get }

    /// Stream of function call events from AI
    var functionCallStream: AsyncStream<FunctionCallEvent> { get }

    /// Establish connection to the API with given configuration
    /// - Parameter config: Session configuration including API key, prompts, topics
    /// - Throws: ConnectionError if connection fails
    func connect(with config: SessionConfig) async throws

    /// Send audio chunk to the API for transcription and analysis
    /// - Parameter audio: Audio chunk in PCM format
    /// - Throws: StreamingError if audio cannot be sent
    func send(audio: AudioChunk) async throws

    /// Disconnect from the API, closing all streams
    func disconnect() async
}

// MARK: - Connection State

/// Represents the current state of the API connection
enum ConnectionState: Equatable {
    /// Not connected to API
    case disconnected

    /// Attempting initial connection
    case connecting

    /// Successfully connected and ready
    case connected

    /// Attempting to reconnect after disconnection
    case reconnecting

    /// Connection failed with error
    case failed(Error)

    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected),
             (.reconnecting, .reconnecting):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Transcription Event

/// Event containing transcription text from the API
struct TranscriptionEvent: Equatable {
    /// The transcribed text
    let text: String

    /// Whether this is a final transcription (true) or partial/delta (false)
    let isFinal: Bool

    /// Identified speaker, if available
    let speaker: Speaker?

    /// Timestamp in seconds from session start
    let timestamp: TimeInterval

    /// Confidence score from the API (0.0 - 1.0)
    let confidence: Double

    init(
        text: String,
        isFinal: Bool,
        speaker: Speaker? = nil,
        timestamp: TimeInterval,
        confidence: Double = 1.0
    ) {
        self.text = text
        self.isFinal = isFinal
        self.speaker = speaker
        self.timestamp = timestamp
        self.confidence = confidence
    }
}

// Note: Speaker is defined in HCDInterviewCoach/Core/Models/Speaker.swift
// This file uses that canonical definition which includes displayName and icon properties

// MARK: - Function Call Event

/// Event containing a function call from the AI
struct FunctionCallEvent: Equatable {
    /// Name of the function being called
    let name: String

    /// Arguments as key-value pairs
    let arguments: [String: String]

    /// Timestamp when function was called
    let timestamp: TimeInterval

    /// Call ID for tracking
    let callId: String

    init(name: String, arguments: [String: String], timestamp: TimeInterval, callId: String = UUID().uuidString) {
        self.name = name
        self.arguments = arguments
        self.timestamp = timestamp
        self.callId = callId
    }
}

// MARK: - Session Configuration

/// Configuration for a Realtime API session
struct SessionConfig {
    /// OpenAI API key
    let apiKey: String

    /// System prompt defining AI behavior (silence-first coaching)
    let systemPrompt: String

    /// Research topics for the session
    let topics: [String]

    /// Session mode (full, transcription only, observer only)
    let sessionMode: SessionMode

    /// Optional session metadata
    let metadata: SessionMetadata?

    init(
        apiKey: String,
        systemPrompt: String,
        topics: [String] = [],
        sessionMode: SessionMode = .full,
        metadata: SessionMetadata? = nil
    ) {
        self.apiKey = apiKey
        self.systemPrompt = systemPrompt
        self.topics = topics
        self.sessionMode = sessionMode
        self.metadata = metadata
    }
}

// Note: SessionMode is defined in HCDInterviewCoach/Core/Models/SessionMode.swift
// This file uses that canonical definition which includes displayName, description, and feature flags

/// Optional metadata about the session
struct SessionMetadata {
    let participantName: String?
    let projectName: String?
    let templateId: String?
    let plannedDuration: TimeInterval?
    let researcherNotes: String?

    init(
        participantName: String? = nil,
        projectName: String? = nil,
        templateId: String? = nil,
        plannedDuration: TimeInterval? = nil,
        researcherNotes: String? = nil
    ) {
        self.participantName = participantName
        self.projectName = projectName
        self.templateId = templateId
        self.plannedDuration = plannedDuration
        self.researcherNotes = researcherNotes
    }
}

// MARK: - Audio Types

// Note: AudioChunk is defined in Core/Protocols/AudioCapturing.swift
// This file uses that canonical definition which includes data, timestamp, sampleRate, and channels

// MARK: - Errors

/// Errors that can occur during API connection
enum ConnectionError: LocalizedError {
    case invalidAPIKey
    case networkUnavailable
    case serverError(String)
    case authenticationFailed
    case timeout
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid OpenAI API key"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .serverError(let message):
            return "Server error: \(message)"
        case .authenticationFailed:
            return "Authentication failed"
        case .timeout:
            return "Connection timeout"
        case .invalidConfiguration:
            return "Invalid session configuration"
        }
    }
}

/// Errors that can occur during audio streaming
enum StreamingError: LocalizedError {
    case notConnected
    case encodingFailed
    case backpressure
    case invalidAudioFormat
    case streamClosed

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to API"
        case .encodingFailed:
            return "Failed to encode audio"
        case .backpressure:
            return "Stream backpressure detected"
        case .invalidAudioFormat:
            return "Invalid audio format"
        case .streamClosed:
            return "Stream has been closed"
        }
    }
}
