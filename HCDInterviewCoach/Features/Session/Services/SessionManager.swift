//
//  SessionManager.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  Main orchestrator for interview session lifecycle
//

import Foundation
import Combine
import SwiftData

// MARK: - Session Manager

/// Main orchestrator for interview session lifecycle.
/// Coordinates audio capture, API connection, transcription, and data persistence.
///
/// State Machine:
/// ```
/// idle -> configuring -> ready -> running -> paused -> running -> ending -> ended
///                                    \-> error (recoverable) -> running
///                                    \-> failed (unrecoverable) -> ended
/// ```
@MainActor
class SessionManager: ObservableObject {
    // MARK: - Published State

    /// Current state of the session lifecycle
    @Published private(set) var state: SessionState = .idle

    /// The current active session (if any)
    @Published private(set) var currentSession: Session?

    /// Connection quality to the Realtime API
    @Published private(set) var connectionQuality: ConnectionQuality = .disconnected

    /// Current audio levels for UI display
    @Published private(set) var audioLevels: AudioLevels = .silence

    /// Session elapsed time in seconds
    @Published private(set) var elapsedTime: TimeInterval = 0

    /// Whether the session is in a degraded mode
    @Published private(set) var degradedMode: DegradedMode?

    /// Recent transcription events for UI
    @Published private(set) var recentTranscriptions: [TranscriptionSegment] = []

    /// Last error that occurred (for UI display)
    @Published private(set) var lastError: SessionError?

    // MARK: - Transcription Stream

    /// Async stream of transcription events for consumers
    var transcriptionStream: AsyncStream<TranscriptionEvent> {
        transcriptionStreamProvider.stream
    }

    private let transcriptionStreamProvider = TranscriptionEventStreamProvider()

    // MARK: - Dependencies

    private var coordinator: SessionCoordinator?
    private let connectionMonitor: ConnectionQualityMonitor
    private let recoveryService: SessionRecoveryService
    private let dataManager: DataManager

    // Dependency providers (for dependency injection)
    private let audioCapturerProvider: () -> AudioCapturing
    private let apiClientProvider: () -> RealtimeAPIConnecting

    // MARK: - Internal State

    private var currentConfig: SessionConfig?
    private var sessionTimer: Timer?
    private var stateHistory: [SessionStateChange] = []
    private var cancellables = Set<AnyCancellable>()
    private var recoveryTask: Task<Void, Never>?

    // Configuration
    private let maxRecentTranscriptions = 50

    // MARK: - Initialization

    init(
        audioCapturerProvider: @escaping () -> AudioCapturing,
        apiClientProvider: @escaping () -> RealtimeAPIConnecting,
        connectionMonitor: ConnectionQualityMonitor? = nil,
        recoveryService: SessionRecoveryService? = nil,
        dataManager: DataManager? = nil
    ) {
        self.audioCapturerProvider = audioCapturerProvider
        self.apiClientProvider = apiClientProvider
        self.connectionMonitor = connectionMonitor ?? ConnectionQualityMonitor()
        self.recoveryService = recoveryService ?? SessionRecoveryService()
        self.dataManager = dataManager ?? .shared

        setupConnectionMonitorBinding()
    }

    deinit {
        sessionTimer?.invalidate()
        recoveryTask?.cancel()
    }

    // MARK: - Public Interface

    /// Configures a new session with the given configuration
    /// - Parameter config: Session configuration including API key, prompts, topics
    /// - Throws: SessionError if configuration fails
    func configure(with config: SessionConfig) async throws {
        // Validate state transition
        guard state == .idle else {
            throw SessionError(
                kind: .invalidStateTransition,
                context: "Cannot configure: current state is \(state.displayName)"
            )
        }

        transitionTo(.configuring, reason: "Starting configuration")
        currentConfig = config

        do {
            // Create the SwiftData session
            let session = createSession(from: config)
            currentSession = session

            // Create coordinator with fresh dependencies
            let audioCapturer = audioCapturerProvider()
            let apiClient = apiClientProvider()
            coordinator = SessionCoordinator(
                audioCapture: audioCapturer,
                apiClient: apiClient,
                dataManager: dataManager
            )

            // Configure coordinator callbacks
            coordinator?.configure(
                onTranscription: { [weak self] segment in
                    self?.handleTranscription(segment)
                },
                onFunctionCall: { [weak self] event in
                    self?.handleFunctionCall(event)
                },
                onError: { [weak self] error in
                    self?.handleCoordinatorError(error)
                }
            )

            // Prepare coordinator
            try await coordinator?.prepare(with: config, session: session)

            // Start connection monitoring
            connectionMonitor.start()

            // Save the session
            dataManager.mainContext.insert(session)
            try dataManager.save()

            transitionTo(.ready, reason: "Configuration complete")
            AppLogger.shared.info("Session configured: \(session.id)")

        } catch let error as SessionError {
            transitionTo(.failed(error), reason: error.localizedDescription ?? "Configuration failed")
            throw error
        } catch {
            let sessionError = SessionError(
                kind: .invalidConfiguration,
                underlyingError: error,
                context: "Configuration failed"
            )
            transitionTo(.failed(sessionError), reason: error.localizedDescription)
            throw sessionError
        }
    }

    /// Starts the configured session
    /// - Throws: SessionError if session cannot be started
    func start() async throws {
        guard state == .ready else {
            throw SessionError(
                kind: .invalidStateTransition,
                context: "Cannot start: current state is \(state.displayName)"
            )
        }

        guard let coordinator = coordinator else {
            throw SessionError(kind: .missingDependency, context: "Coordinator not available")
        }

        do {
            try coordinator.startCapture()
            startSessionTimer()
            transitionTo(.running, reason: "Session started")
            AppLogger.shared.info("Session started")
        } catch let error as SessionError {
            transitionTo(.error(error), reason: error.localizedDescription ?? "Start failed")
            throw error
        } catch {
            let sessionError = SessionError(
                kind: .audioCaptureFailed,
                underlyingError: error,
                context: "Failed to start audio capture"
            )
            transitionTo(.error(sessionError), reason: error.localizedDescription)
            throw sessionError
        }
    }

    /// Pauses the running session
    func pause() {
        guard state == .running else {
            AppLogger.shared.warning("Cannot pause: current state is \(state.displayName)")
            return
        }

        coordinator?.pauseCapture()
        stopSessionTimer()
        transitionTo(.paused, reason: "User paused session")
        AppLogger.shared.info("Session paused at \(formattedElapsedTime)")
    }

    /// Resumes a paused session
    /// - Throws: SessionError if session cannot be resumed
    func resume() async throws {
        guard state.canResume else {
            throw SessionError(
                kind: .invalidStateTransition,
                context: "Cannot resume: current state is \(state.displayName)"
            )
        }

        // Handle resuming from error state
        if case .error(let error) = state {
            try await handleErrorRecovery(error)
        }

        coordinator?.resumeCapture()
        startSessionTimer()
        transitionTo(.running, reason: "Session resumed")
        AppLogger.shared.info("Session resumed")
    }

    /// Ends the current session
    /// - Throws: SessionError if session cannot be ended
    func end() async throws {
        guard state.canEnd else {
            throw SessionError(
                kind: .invalidStateTransition,
                context: "Cannot end: current state is \(state.displayName)"
            )
        }

        transitionTo(.ending, reason: "Ending session")

        // Stop timer
        stopSessionTimer()

        // Stop connection monitoring
        connectionMonitor.stop()

        // Stop coordinator
        if let coordinator = coordinator {
            await coordinator.stop()
            try await coordinator.finalizeSession()
        }

        // Finish transcription stream
        transcriptionStreamProvider.finish()

        // Update session
        if let session = currentSession {
            session.endedAt = Date()
            session.totalDurationSeconds = elapsedTime
            try dataManager.save()
            AppLogger.shared.info("Session ended: \(session.id), duration: \(formattedElapsedTime)")
        }

        // Clear recovery service
        await recoveryService.reset()

        transitionTo(.ended, reason: "Session completed")
    }

    /// Resets the manager to idle state for a new session
    func reset() async {
        guard state == .ended || state.isError else {
            AppLogger.shared.warning("Cannot reset: current state is \(state.displayName)")
            return
        }

        // Clean up
        coordinator = nil
        currentSession = nil
        currentConfig = nil
        elapsedTime = 0
        recentTranscriptions.removeAll()
        stateHistory.removeAll()
        lastError = nil
        degradedMode = nil
        recoveryTask?.cancel()
        recoveryTask = nil

        await recoveryService.reset()

        transitionTo(.idle, reason: "Manager reset")
        AppLogger.shared.info("SessionManager reset to idle")
    }

    // MARK: - Error Recovery

    /// Attempts to recover from the current error state
    func attemptRecovery() async throws {
        guard case .error(let error) = state else {
            throw SessionError(
                kind: .invalidStateTransition,
                context: "Not in error state"
            )
        }

        try await handleErrorRecovery(error)
    }

    /// Manually switches to degraded mode
    func switchToDegradedMode(_ mode: DegradedMode) {
        degradedMode = mode
        AppLogger.shared.warning("Manually switched to degraded mode: \(mode.description)")

        // If in error state, transition to running in degraded mode
        if case .error = state {
            transitionTo(.running, reason: "Switched to degraded mode: \(mode.description)")
        }
    }

    // MARK: - Session Info

    /// Formatted elapsed time string (MM:SS or HH:MM:SS)
    var formattedElapsedTime: String {
        TimeFormatting.formatDuration(elapsedTime)
    }

    /// Gets session statistics
    func getSessionStatistics() async -> SessionStatistics? {
        guard let session = currentSession else { return nil }

        let bufferStats = await coordinator?.getBufferStatistics()
        let connectionStats = connectionMonitor.getStatistics()

        return SessionStatistics(
            sessionId: session.id,
            duration: elapsedTime,
            utteranceCount: session.utteranceCount,
            insightCount: session.insightCount,
            bufferStatistics: bufferStats,
            connectionStatistics: connectionStats,
            degradedMode: degradedMode
        )
    }

    // MARK: - Private Methods

    private func createSession(from config: SessionConfig) -> Session {
        return Session(
            participantName: config.metadata?.participantName ?? "Unknown",
            projectName: config.metadata?.projectName ?? "Untitled Project",
            sessionMode: config.sessionMode,
            startedAt: Date()
        )
    }

    private func transitionTo(_ newState: SessionState, reason: String?) {
        guard SessionStateTransition.isValid(from: state, to: newState) else {
            AppLogger.shared.error("Invalid state transition: \(state.displayName) -> \(newState.displayName)")
            return
        }

        let change = SessionStateChange(from: state, to: newState, reason: reason)
        stateHistory.append(change)
        state = newState

        // Update error state
        if case .error(let error) = newState {
            lastError = error
        } else if case .failed(let error) = newState {
            lastError = error
        }

        AppLogger.shared.info("State transition: \(change.fromState.displayName) -> \(change.toState.displayName)" +
                             (reason.map { " (\($0))" } ?? ""))
    }

    private func setupConnectionMonitorBinding() {
        connectionMonitor.$quality
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quality in
                self?.connectionQuality = quality

                // Handle quality degradation
                if quality == .disconnected && self?.state == .running {
                    self?.handleConnectionLost()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Timer Management

    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedTime += 1
                self?.audioLevels = self?.coordinator?.audioLevels ?? .silence
            }
        }
    }

    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    // MARK: - Event Handlers

    private func handleTranscription(_ segment: TranscriptionSegment) {
        // Add to recent transcriptions
        recentTranscriptions.append(segment)
        if recentTranscriptions.count > maxRecentTranscriptions {
            recentTranscriptions.removeFirst()
        }

        // Create event for stream
        let event = TranscriptionEvent(
            text: segment.text,
            isFinal: true,
            speaker: segment.speaker,
            timestamp: segment.startTimestamp,
            confidence: segment.confidence
        )
        transcriptionStreamProvider.yield(event)

        // Record success for connection quality
        connectionMonitor.recordSuccess(latencyMs: 100) // Approximate
    }

    private func handleFunctionCall(_ event: FunctionCallEvent) {
        AppLogger.shared.info("Function call received: \(event.name)")
        // Function calls are handled by the coaching system (E5)
    }

    private func handleCoordinatorError(_ error: SessionError) {
        lastError = error

        // Determine if we should transition to error state
        if state == .running {
            if error.isRecoverable {
                transitionTo(.error(error), reason: error.localizedDescription)
                initiateRecovery(for: error)
            } else {
                transitionTo(.failed(error), reason: error.localizedDescription)
            }
        }
    }

    private func handleConnectionLost() {
        let error = SessionError(kind: .connectionLost, context: "API connection lost during session")
        handleCoordinatorError(error)
        connectionMonitor.recordDisconnection()
    }

    // MARK: - Recovery

    private func initiateRecovery(for error: SessionError) {
        recoveryTask = Task { [weak self] in
            guard let self = self else { return }

            let strategy = await self.recoveryService.determineStrategy(for: error)

            let result = await self.recoveryService.executeRecovery(strategy: strategy) { action in
                try await self.executeRecoveryAction(action)
            }

            await MainActor.run {
                self.handleRecoveryResult(result)
            }
        }
    }

    private func executeRecoveryAction(_ action: SessionRecoveryAction) async throws {
        switch action {
        case .reconnect:
            guard let config = currentConfig else {
                throw SessionError(kind: .invalidConfiguration, context: "No config available for reconnection")
            }
            try await coordinator?.reconnect(with: config)
            connectionMonitor.recordReconnection()

        case .restartAudio:
            coordinator?.pauseCapture()
            try? await Task.sleep(nanoseconds: 500_000_000)
            try coordinator?.startCapture()

        case .retrySave:
            try dataManager.save()

        case .requestPermissions:
            // Permission requests are handled at app level
            throw SessionError(kind: .microphonePermissionDenied, context: "Permissions must be granted in settings")
        }
    }

    private func handleRecoveryResult(_ result: RecoveryResult) {
        switch result {
        case .recovered:
            transitionTo(.running, reason: "Recovery successful")
            degradedMode = nil

        case .degraded(let mode):
            degradedMode = mode
            transitionTo(.running, reason: "Operating in \(mode.description)")

        case .failed(let error):
            // Still in error state, another recovery will be attempted
            AppLogger.shared.warning("Recovery failed: \(error.localizedDescription)")

        case .terminated(let reason):
            let error = SessionError(kind: .unknown, context: reason)
            transitionTo(.failed(error), reason: reason)

        case .conditionTimeout(let condition):
            AppLogger.shared.warning("Recovery condition timeout: \(condition.description)")

        case .alreadyRecovering:
            // Do nothing, recovery in progress
            break
        }
    }

    private func handleErrorRecovery(_ error: SessionError) async throws {
        // Wait for any existing recovery to complete
        recoveryTask?.cancel()
        recoveryTask = nil

        // Attempt recovery
        let strategy = await recoveryService.determineStrategy(for: error)
        let result = await recoveryService.executeRecovery(strategy: strategy) { [weak self] action in
            try await self?.executeRecoveryAction(action)
        }

        if !result.isSuccess {
            throw error
        }
    }
}

// MARK: - Transcription Event Stream Provider

/// Provides an AsyncStream of transcription events
private final class TranscriptionEventStreamProvider: @unchecked Sendable {
    private var continuation: AsyncStream<TranscriptionEvent>.Continuation?
    private let lock = NSLock()

    lazy var stream: AsyncStream<TranscriptionEvent> = {
        AsyncStream { continuation in
            self.lock.lock()
            self.continuation = continuation
            self.lock.unlock()
        }
    }()

    func yield(_ event: TranscriptionEvent) {
        lock.lock()
        continuation?.yield(event)
        lock.unlock()
    }

    func finish() {
        lock.lock()
        continuation?.finish()
        continuation = nil
        lock.unlock()
    }
}

// MARK: - Session Statistics

/// Aggregated statistics for a session
struct SessionStatistics: Sendable {
    let sessionId: UUID
    let duration: TimeInterval
    let utteranceCount: Int
    let insightCount: Int
    let bufferStatistics: BufferStatistics?
    let connectionStatistics: ConnectionStatistics
    let degradedMode: DegradedMode?

    /// Formatted duration string
    var formattedDuration: String {
        TimeFormatting.formatDuration(duration)
    }
}

// MARK: - Session Manager Factory

/// Factory for creating session managers with proper dependencies
@MainActor
struct SessionManagerFactory {
    /// Creates a production session manager
    static func createProduction(
        audioCapturerProvider: @escaping () -> AudioCapturing,
        apiClientProvider: @escaping () -> RealtimeAPIConnecting
    ) -> SessionManager {
        return SessionManager(
            audioCapturerProvider: audioCapturerProvider,
            apiClientProvider: apiClientProvider
        )
    }
}
