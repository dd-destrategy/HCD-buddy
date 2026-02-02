//
//  SessionCoordinator.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  Coordinates dependencies between audio capture, API, and data persistence
//

import Foundation
import Combine
import SwiftData

// MARK: - Session Coordinator

/// Coordinates the interaction between session components:
/// - Audio capture system
/// - Realtime API client
/// - Data persistence layer
/// - Transcription buffering
@MainActor
final class SessionCoordinator: ObservableObject {
    // MARK: - Published State

    /// Whether all dependencies are ready for a session
    @Published private(set) var isReady: Bool = false

    /// Current audio levels from capture
    @Published private(set) var audioLevels: AudioLevels = .silence

    /// Current API connection state
    @Published private(set) var apiConnectionState: ConnectionState = .disconnected

    /// Whether audio is currently being captured
    @Published private(set) var isCapturingAudio: Bool = false

    /// Error from any component
    @Published private(set) var lastError: SessionError?

    // MARK: - Dependencies

    private let audioCapture: AudioCapturing
    private let apiClient: RealtimeAPIConnecting
    private let dataManager: DataManager
    private let transcriptionBuffer: TranscriptionBuffer

    // MARK: - Internal State

    private var audioStreamTask: Task<Void, Never>?
    private var transcriptionStreamTask: Task<Void, Never>?
    private var functionCallStreamTask: Task<Void, Never>?
    private var audioLevelTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // Callbacks
    private var onTranscription: ((TranscriptionSegment) -> Void)?
    private var onFunctionCall: ((FunctionCallEvent) -> Void)?
    private var onError: ((SessionError) -> Void)?

    // Session reference
    private weak var currentSession: Session?
    private var sessionStartTime: Date?

    // MARK: - Initialization

    init(
        audioCapture: AudioCapturing,
        apiClient: RealtimeAPIConnecting,
        dataManager: DataManager = .shared,
        transcriptionBuffer: TranscriptionBuffer = TranscriptionBuffer()
    ) {
        self.audioCapture = audioCapture
        self.apiClient = apiClient
        self.dataManager = dataManager
        self.transcriptionBuffer = transcriptionBuffer
    }

    // MARK: - Configuration

    /// Sets up callbacks for session events
    func configure(
        onTranscription: @escaping (TranscriptionSegment) -> Void,
        onFunctionCall: @escaping (FunctionCallEvent) -> Void,
        onError: @escaping (SessionError) -> Void
    ) {
        self.onTranscription = onTranscription
        self.onFunctionCall = onFunctionCall
        self.onError = onError

        // Set up transcription buffer callback
        Task {
            await transcriptionBuffer.setOnSegmentFinalized { [weak self] segment in
                Task { @MainActor in
                    self?.onTranscription?(segment)
                }
            }
        }
    }

    // MARK: - Session Lifecycle

    /// Prepares all components for a session
    /// - Parameters:
    ///   - config: Session configuration
    ///   - session: The SwiftData session to associate with
    func prepare(with config: SessionConfig, session: Session) async throws {
        currentSession = session
        sessionStartTime = session.startedAt

        // Clear any previous state
        await transcriptionBuffer.clear()
        lastError = nil

        // Connect to API
        do {
            try await apiClient.connect(with: config)
            apiConnectionState = apiClient.connectionState
        } catch {
            throw SessionError(
                kind: .connectionFailed,
                underlyingError: error,
                context: "Failed to connect to Realtime API"
            )
        }

        // Set up stream listeners
        setupStreamListeners()

        isReady = true
        AppLogger.shared.info("SessionCoordinator prepared for session: \(session.id)")
    }

    /// Starts audio capture and streaming
    func startCapture() throws {
        guard isReady else {
            throw SessionError(kind: .invalidStateTransition, context: "Coordinator not ready")
        }

        do {
            try audioCapture.start()
            isCapturingAudio = true
            startAudioStreaming()
            startAudioLevelMonitoring()
            AppLogger.shared.info("Audio capture started")
        } catch {
            throw SessionError(
                kind: .audioCaptureFailed,
                underlyingError: error,
                context: "Failed to start audio capture"
            )
        }
    }

    /// Pauses audio capture
    func pauseCapture() {
        audioCapture.pause()
        isCapturingAudio = false
        stopAudioLevelMonitoring()
        AppLogger.shared.info("Audio capture paused")
    }

    /// Resumes audio capture
    func resumeCapture() {
        audioCapture.resume()
        isCapturingAudio = true
        startAudioLevelMonitoring()
        AppLogger.shared.info("Audio capture resumed")
    }

    /// Stops all capture and disconnects
    func stop() async {
        // Stop audio capture
        audioCapture.stop()
        isCapturingAudio = false
        stopAudioLevelMonitoring()

        // Cancel stream tasks
        audioStreamTask?.cancel()
        audioStreamTask = nil
        transcriptionStreamTask?.cancel()
        transcriptionStreamTask = nil
        functionCallStreamTask?.cancel()
        functionCallStreamTask = nil

        // Flush transcription buffer
        if let timestamp = currentSessionDuration {
            _ = await transcriptionBuffer.flush(at: timestamp)
        }

        // Disconnect from API
        await apiClient.disconnect()
        apiConnectionState = .disconnected

        isReady = false
        currentSession = nil
        sessionStartTime = nil

        AppLogger.shared.info("SessionCoordinator stopped")
    }

    /// Attempts to reconnect to the API
    func reconnect(with config: SessionConfig) async throws {
        await apiClient.disconnect()

        try await apiClient.connect(with: config)
        apiConnectionState = apiClient.connectionState

        setupStreamListeners()

        AppLogger.shared.info("SessionCoordinator reconnected")
    }

    // MARK: - Data Persistence

    /// Saves an utterance to the current session
    func saveUtterance(_ segment: TranscriptionSegment) async throws {
        guard let session = currentSession else {
            throw SessionError(kind: .persistenceFailed, context: "No active session")
        }

        let utterance = Utterance(
            speaker: segment.speaker,
            text: segment.text,
            timestampSeconds: segment.startTimestamp,
            confidence: segment.confidence
        )

        utterance.session = session
        session.utterances.append(utterance)

        do {
            try dataManager.save()
        } catch {
            throw SessionError(
                kind: .persistenceFailed,
                underlyingError: error,
                context: "Failed to save utterance"
            )
        }
    }

    /// Saves the final session state
    func finalizeSession() async throws {
        guard let session = currentSession else {
            throw SessionError(kind: .persistenceFailed, context: "No active session")
        }

        session.endedAt = Date()
        session.totalDurationSeconds = session.durationSeconds

        do {
            try dataManager.save()
            AppLogger.shared.info("Session finalized: \(session.id)")
        } catch {
            throw SessionError(
                kind: .persistenceFailed,
                underlyingError: error,
                context: "Failed to finalize session"
            )
        }
    }

    // MARK: - Stream Listeners

    private func setupStreamListeners() {
        // Listen to transcription stream
        transcriptionStreamTask = Task { [weak self] in
            guard let self = self else { return }

            for await event in self.apiClient.transcriptionStream {
                await self.handleTranscriptionEvent(event)
            }
        }

        // Listen to function call stream
        functionCallStreamTask = Task { [weak self] in
            guard let self = self else { return }

            for await event in self.apiClient.functionCallStream {
                await MainActor.run {
                    self.onFunctionCall?(event)
                }
            }
        }
    }

    private func handleTranscriptionEvent(_ event: TranscriptionEvent) async {
        let update = await transcriptionBuffer.process(event)

        await MainActor.run {
            switch update {
            case .finalized(let segment):
                Task {
                    try? await self.saveUtterance(segment)
                }

            case .finalizedWithNewPartial(let segment, _):
                Task {
                    try? await self.saveUtterance(segment)
                }

            case .partial, .dropped:
                // Partial updates are handled by UI observing the buffer
                break
            }
        }
    }

    // MARK: - Audio Streaming

    private func startAudioStreaming() {
        audioStreamTask = Task { [weak self] in
            guard let self = self else { return }

            for await chunk in self.audioCapture.audioStream {
                do {
                    try await self.apiClient.send(audio: chunk)
                } catch {
                    await MainActor.run {
                        self.handleStreamingError(error)
                    }
                }
            }
        }
    }

    private func handleStreamingError(_ error: Error) {
        // Check if it's a transient error
        if let streamingError = error as? StreamingError {
            switch streamingError {
            case .backpressure:
                // Backpressure is transient, log but don't propagate
                AppLogger.shared.logAPI("Audio streaming backpressure", level: .warning)
                return

            case .notConnected, .streamClosed:
                let sessionError = SessionError(
                    kind: .connectionLost,
                    underlyingError: error
                )
                lastError = sessionError
                onError?(sessionError)

            default:
                AppLogger.shared.logAPI("Audio streaming error: \(error.localizedDescription)", level: .error)
            }
        }
    }

    // MARK: - Audio Level Monitoring

    private func startAudioLevelMonitoring() {
        // Update audio levels at 10Hz
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.audioLevels = self?.audioCapture.audioLevels ?? .silence
            }
        }
    }

    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        audioLevels = .silence
    }

    // MARK: - Utilities

    /// Current duration of the session in seconds
    var currentSessionDuration: TimeInterval? {
        guard let startTime = sessionStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }

    /// Gets transcription buffer statistics
    func getBufferStatistics() async -> BufferStatistics {
        await transcriptionBuffer.getStatistics()
    }

    /// Gets the current partial transcription if any
    func getCurrentPartial() async -> PartialTranscription? {
        await transcriptionBuffer.getCurrentPartial()
    }
}

// MARK: - Coordinator Factory

/// Factory for creating session coordinators with proper dependencies
@MainActor
struct SessionCoordinatorFactory {
    /// Creates a coordinator with real dependencies
    static func createProduction(
        audioCapture: AudioCapturing,
        apiClient: RealtimeAPIConnecting
    ) -> SessionCoordinator {
        return SessionCoordinator(
            audioCapture: audioCapture,
            apiClient: apiClient,
            dataManager: .shared
        )
    }

    /// Creates a coordinator for testing with mock dependencies
    static func createForTesting(
        audioCapture: AudioCapturing,
        apiClient: RealtimeAPIConnecting,
        dataManager: DataManager
    ) -> SessionCoordinator {
        return SessionCoordinator(
            audioCapture: audioCapture,
            apiClient: apiClient,
            dataManager: dataManager
        )
    }
}
