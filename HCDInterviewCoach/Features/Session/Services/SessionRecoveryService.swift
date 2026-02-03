//
//  SessionRecoveryService.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  Handles error recovery and graceful degradation
//

import Foundation
import Network

// MARK: - Session Recovery Service

/// Handles error recovery logic for session failures.
/// Implements retry strategies and graceful degradation.
actor SessionRecoveryService {
    // MARK: - Properties

    /// Current recovery attempt count for the active error
    private var currentAttemptCount = 0

    /// Maximum retry attempts before giving up
    private let maxRetryAttempts = 3

    /// Base delay for exponential backoff (in seconds)
    private let baseDelaySeconds: TimeInterval = 1.0

    /// Maximum delay cap for backoff (in seconds)
    private let maxDelaySeconds: TimeInterval = 30.0

    /// History of recovery attempts
    private var recoveryHistory: [RecoveryAttempt] = []

    /// Whether we're currently in a recovery process
    private var isRecovering = false

    /// Current degraded mode if any
    private var currentDegradedMode: DegradedMode?

    /// Network path monitor for checking network availability
    private let networkMonitor: NWPathMonitor

    /// Current network path status
    private var currentNetworkPath: NWPath?

    /// Dispatch queue for network monitoring
    private let networkMonitorQueue = DispatchQueue(label: "com.hcdinterviewcoach.recovery.network")

    /// Maximum time elapsed (in seconds) before recovery is no longer possible
    private let maxRecoveryTimeSeconds: TimeInterval = 30 * 60 // 30 minutes

    /// Timestamp when the error first occurred (for time-based recovery limits)
    private var errorOccurredAt: Date?

    /// Session ID being recovered
    private var recoveringSessionId: UUID?

    /// UserDefaults keys for persistence
    private enum PersistenceKeys {
        static let recoveryState = "com.hcdinterviewcoach.recoveryState"
        static let errorTimestamp = "com.hcdinterviewcoach.errorTimestamp"
        static let sessionId = "com.hcdinterviewcoach.recoveringSessionId"
        static let attemptCount = "com.hcdinterviewcoach.attemptCount"
        static let degradedMode = "com.hcdinterviewcoach.degradedMode"
    }

    // MARK: - Initialization

    init() {
        self.networkMonitor = NWPathMonitor()
        self.startNetworkMonitoring()
        self.loadPersistedState()
    }

    deinit {
        networkMonitor.cancel()
    }

    // MARK: - Network Monitoring

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.updateNetworkPath(path)
            }
        }
        networkMonitor.start(queue: networkMonitorQueue)
    }

    private func updateNetworkPath(_ path: NWPath) {
        currentNetworkPath = path
    }

    // MARK: - State Persistence

    private func loadPersistedState() {
        let defaults = UserDefaults.standard

        if let timestamp = defaults.object(forKey: PersistenceKeys.errorTimestamp) as? Date {
            errorOccurredAt = timestamp
        }

        if let sessionIdString = defaults.string(forKey: PersistenceKeys.sessionId),
           let sessionId = UUID(uuidString: sessionIdString) {
            recoveringSessionId = sessionId
        }

        currentAttemptCount = defaults.integer(forKey: PersistenceKeys.attemptCount)

        if let degradedModeRaw = defaults.string(forKey: PersistenceKeys.degradedMode) {
            currentDegradedMode = DegradedMode(rawValue: degradedModeRaw)
        }
    }

    private func persistState() {
        let defaults = UserDefaults.standard

        if let timestamp = errorOccurredAt {
            defaults.set(timestamp, forKey: PersistenceKeys.errorTimestamp)
        } else {
            defaults.removeObject(forKey: PersistenceKeys.errorTimestamp)
        }

        if let sessionId = recoveringSessionId {
            defaults.set(sessionId.uuidString, forKey: PersistenceKeys.sessionId)
        } else {
            defaults.removeObject(forKey: PersistenceKeys.sessionId)
        }

        defaults.set(currentAttemptCount, forKey: PersistenceKeys.attemptCount)

        if let mode = currentDegradedMode {
            defaults.set(mode.rawValue, forKey: PersistenceKeys.degradedMode)
        } else {
            defaults.removeObject(forKey: PersistenceKeys.degradedMode)
        }
    }

    private func clearPersistedState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: PersistenceKeys.errorTimestamp)
        defaults.removeObject(forKey: PersistenceKeys.sessionId)
        defaults.removeObject(forKey: PersistenceKeys.attemptCount)
        defaults.removeObject(forKey: PersistenceKeys.degradedMode)
    }

    // MARK: - Session Recovery Validation

    /// Checks if recovery is possible for a given session
    /// - Parameters:
    ///   - sessionId: The session ID to recover
    ///   - sessionStartTime: When the session started
    /// - Returns: Whether recovery is possible
    func canRecover(sessionId: UUID, sessionStartTime: Date?) -> Bool {
        // Check if too much time has elapsed since error occurred
        if let errorTime = errorOccurredAt {
            let elapsed = Date().timeIntervalSince(errorTime)
            if elapsed > maxRecoveryTimeSeconds {
                AppLogger.shared.warning("Recovery time limit exceeded: \(elapsed)s > \(maxRecoveryTimeSeconds)s")
                return false
            }
        }

        // Validate session ID matches
        if let recoveringId = recoveringSessionId, recoveringId != sessionId {
            AppLogger.shared.warning("Session ID mismatch for recovery")
            return false
        }

        return true
    }

    /// Sets the session being recovered
    func setRecoveringSession(sessionId: UUID) {
        recoveringSessionId = sessionId
        if errorOccurredAt == nil {
            errorOccurredAt = Date()
        }
        persistState()
    }

    // MARK: - Recovery Logic

    /// Determines the appropriate recovery strategy for an error
    /// - Parameter error: The session error that occurred
    /// - Returns: The recovery strategy to execute
    func determineStrategy(for error: SessionError) -> RecoveryStrategy {
        // Check if error is recoverable at all
        guard error.isRecoverable else {
            return .terminate(reason: "Unrecoverable error: \(error.localizedDescription ?? "Unknown")")
        }

        // Check if we've exceeded max attempts
        if currentAttemptCount >= maxRetryAttempts {
            // Try to degrade gracefully before terminating
            if let degradedMode = suggestDegradedMode(for: error) {
                return .degrade(to: degradedMode)
            }
            return .terminate(reason: "Maximum recovery attempts exceeded")
        }

        // Determine specific strategy based on error kind
        switch error.kind {
        case .connectionLost, .reconnectionFailed:
            return .retry(
                after: calculateBackoffDelay(),
                action: .reconnect
            )

        case .connectionFailed:
            if currentAttemptCount == 0 {
                return .retry(after: 0.5, action: .reconnect)
            }
            return .retry(
                after: calculateBackoffDelay(),
                action: .reconnect
            )

        case .audioCaptureFailed:
            return .retry(
                after: 1.0,
                action: .restartAudio
            )

        case .audioDeviceUnavailable:
            return .waitForCondition(
                condition: .audioDeviceAvailable,
                timeout: 30.0
            )

        case .serverError:
            return .retry(
                after: calculateBackoffDelay(),
                action: .reconnect
            )

        case .persistenceFailed:
            return .retry(
                after: 0.5,
                action: .retrySave
            )

        default:
            return .terminate(reason: error.localizedDescription ?? "Unknown error")
        }
    }

    /// Executes a recovery attempt
    /// - Parameters:
    ///   - strategy: The strategy to execute
    ///   - executor: Closure that performs the actual recovery action
    /// - Returns: Result of the recovery attempt
    func executeRecovery(
        strategy: RecoveryStrategy,
        executor: @escaping (SessionRecoveryAction) async throws -> Void
    ) async -> RecoveryResult {
        guard !isRecovering else {
            return .alreadyRecovering
        }

        isRecovering = true
        defer { isRecovering = false }

        switch strategy {
        case .retry(let delay, let action):
            currentAttemptCount += 1

            // Wait for backoff delay
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            // Record attempt
            let attempt = RecoveryAttempt(
                attemptNumber: currentAttemptCount,
                action: action,
                timestamp: Date()
            )
            recoveryHistory.append(attempt)

            // Execute recovery action
            do {
                try await executor(action)
                recordSuccess()
                return .recovered
            } catch {
                recordFailure(error)
                return .failed(error)
            }

        case .degrade(let mode):
            currentDegradedMode = mode
            AppLogger.shared.warning("Session degraded to: \(mode.description)")
            return .degraded(mode)

        case .waitForCondition(let condition, let timeout):
            // Wait for condition with timeout
            let startTime = Date()
            while Date().timeIntervalSince(startTime) < timeout {
                if await checkCondition(condition) {
                    currentAttemptCount = 0 // Reset on success
                    return .recovered
                }
                try? await Task.sleep(nanoseconds: 500_000_000) // Check every 0.5s
            }
            return .conditionTimeout(condition)

        case .terminate(let reason):
            AppLogger.shared.error("Session termination: \(reason)")
            return .terminated(reason)
        }
    }

    /// Resets recovery state after successful recovery
    func recordSuccess() {
        currentAttemptCount = 0
        currentDegradedMode = nil
        errorOccurredAt = nil
        recoveringSessionId = nil
        clearPersistedState()
        AppLogger.shared.info("Recovery successful, state reset")
    }

    /// Records a failed recovery attempt
    func recordFailure(_ error: Error) {
        persistState()
        AppLogger.shared.warning("Recovery attempt \(currentAttemptCount) failed: \(error.localizedDescription)")
    }

    /// Resets all recovery state
    func reset() {
        currentAttemptCount = 0
        isRecovering = false
        currentDegradedMode = nil
        recoveryHistory.removeAll()
        errorOccurredAt = nil
        recoveringSessionId = nil
        clearPersistedState()
    }

    /// Gets the current degraded mode if any
    func getDegradedMode() -> DegradedMode? {
        return currentDegradedMode
    }

    /// Gets recovery attempt history
    func getHistory() -> [RecoveryAttempt] {
        return recoveryHistory
    }

    // MARK: - Private Methods

    private func calculateBackoffDelay() -> TimeInterval {
        let exponentialDelay = baseDelaySeconds * pow(2.0, Double(currentAttemptCount))
        // Add jitter (random factor 0.5-1.5)
        let jitter = Double.random(in: 0.5...1.5)
        let delayWithJitter = exponentialDelay * jitter
        return min(delayWithJitter, maxDelaySeconds)
    }

    private func suggestDegradedMode(for error: SessionError) -> DegradedMode? {
        switch error.kind {
        case .connectionFailed, .connectionLost, .reconnectionFailed, .serverError:
            // If API connection fails, we can still capture audio locally
            return .transcriptionOnly

        case .audioCaptureFailed, .audioDeviceUnavailable:
            // If audio fails but API works, switch to manual notes mode
            return .manualNotesOnly

        default:
            return nil
        }
    }

    private func checkCondition(_ condition: RecoveryCondition) async -> Bool {
        switch condition {
        case .audioDeviceAvailable:
            return checkAudioDeviceAvailable()

        case .networkAvailable:
            return checkNetworkAvailable()

        case .apiReachable:
            return await checkAPIReachable()

        case .sessionDataValid(let sessionId):
            return await checkSessionDataValid(sessionId: sessionId)
        }
    }

    /// Checks if audio devices (BlackHole and Multi-Output) are available
    private func checkAudioDeviceAvailable() -> Bool {
        // Check if BlackHole is installed
        let blackHoleStatus = BlackHoleDetector.detectBlackHole()
        guard case .installed = blackHoleStatus else {
            AppLogger.shared.warning("BlackHole not installed for recovery")
            return false
        }

        // Check if Multi-Output device is configured
        let multiOutputStatus = MultiOutputDetector.detectMultiOutputDevice()
        switch multiOutputStatus {
        case .configured:
            AppLogger.shared.info("Audio devices available for recovery")
            return true
        case .notFound:
            AppLogger.shared.warning("Multi-Output device not found for recovery")
            return false
        case .notConfigured, .missingBlackHole, .missingSpeakers:
            AppLogger.shared.warning("Multi-Output device not properly configured: \(multiOutputStatus)")
            return false
        }
    }

    /// Checks if network is available using NWPathMonitor
    private func checkNetworkAvailable() -> Bool {
        guard let path = currentNetworkPath else {
            // If we haven't received a path update yet, assume unavailable
            AppLogger.shared.warning("Network path not yet determined")
            return false
        }

        let isAvailable = path.status == .satisfied
        if !isAvailable {
            AppLogger.shared.warning("Network not available: \(path.status)")
        }
        return isAvailable
    }

    /// Checks if the OpenAI API is reachable by performing a lightweight connectivity check
    private func checkAPIReachable() async -> Bool {
        // First check network availability
        guard checkNetworkAvailable() else {
            return false
        }

        // Perform a lightweight HEAD request to the API endpoint
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0 // Short timeout for health check

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                // 401 means the API is reachable but needs auth (expected without key)
                // 200 means it's reachable and working
                let isReachable = httpResponse.statusCode == 200 || httpResponse.statusCode == 401
                if !isReachable {
                    AppLogger.shared.warning("API returned unexpected status: \(httpResponse.statusCode)")
                }
                return isReachable
            }
            return false
        } catch {
            AppLogger.shared.warning("API reachability check failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Validates that session data exists and is valid for recovery
    private func checkSessionDataValid(sessionId: UUID) async -> Bool {
        // Check if the session ID matches what we're recovering
        if let recoveringId = recoveringSessionId, recoveringId != sessionId {
            AppLogger.shared.warning("Session ID mismatch: expected \(recoveringId), got \(sessionId)")
            return false
        }

        // Check if recovery time hasn't exceeded the limit
        if let errorTime = errorOccurredAt {
            let elapsed = Date().timeIntervalSince(errorTime)
            if elapsed > maxRecoveryTimeSeconds {
                AppLogger.shared.warning("Session recovery time limit exceeded")
                return false
            }
        }

        // Session data validation would typically involve checking the database
        // For now, we check that a session ID is set and time limit hasn't passed
        return true
    }
}

// MARK: - Recovery Strategy

/// Defines what recovery action to take
enum RecoveryStrategy: Sendable {
    /// Retry the failed operation after a delay
    case retry(after: TimeInterval, action: SessionRecoveryAction)

    /// Switch to a degraded mode of operation
    case degrade(to: DegradedMode)

    /// Wait for a condition to be met before retrying
    case waitForCondition(condition: RecoveryCondition, timeout: TimeInterval)

    /// Terminate the session
    case terminate(reason: String)
}

// MARK: - Recovery Action

/// Specific actions that can be taken during recovery
enum SessionRecoveryAction: Sendable {
    /// Reconnect to the API
    case reconnect

    /// Restart audio capture
    case restartAudio

    /// Retry saving data
    case retrySave

    /// Request permissions again
    case requestPermissions

    var description: String {
        switch self {
        case .reconnect:
            return "Reconnecting to API"
        case .restartAudio:
            return "Restarting audio capture"
        case .retrySave:
            return "Retrying data save"
        case .requestPermissions:
            return "Requesting permissions"
        }
    }
}

// MARK: - Recovery Result

/// Result of a recovery attempt
enum RecoveryResult: Sendable {
    /// Successfully recovered
    case recovered

    /// Recovery failed with error
    case failed(Error)

    /// Switched to degraded mode
    case degraded(DegradedMode)

    /// Condition wait timed out
    case conditionTimeout(RecoveryCondition)

    /// Session was terminated
    case terminated(String)

    /// Already in recovery process
    case alreadyRecovering

    var isSuccess: Bool {
        switch self {
        case .recovered, .degraded:
            return true
        default:
            return false
        }
    }
}

// MARK: - Degraded Mode

/// Modes of degraded operation when full functionality is unavailable
enum DegradedMode: String, Sendable {
    /// Only transcription, no AI coaching
    case transcriptionOnly = "transcriptionOnly"

    /// Audio recording but no real-time transcription
    case localRecordingOnly = "localRecordingOnly"

    /// Manual notes only, no audio or AI
    case manualNotesOnly = "manualNotesOnly"

    var description: String {
        switch self {
        case .transcriptionOnly:
            return "Transcription Only Mode"
        case .localRecordingOnly:
            return "Local Recording Only Mode"
        case .manualNotesOnly:
            return "Manual Notes Only Mode"
        }
    }

    /// What features are still available in this mode
    var availableFeatures: [String] {
        switch self {
        case .transcriptionOnly:
            return ["Audio capture", "Real-time transcription", "Manual notes", "Topic tracking"]
        case .localRecordingOnly:
            return ["Audio capture", "Audio file export", "Manual notes"]
        case .manualNotesOnly:
            return ["Manual notes", "Timer"]
        }
    }

    /// What features are disabled in this mode
    var disabledFeatures: [String] {
        switch self {
        case .transcriptionOnly:
            return ["AI coaching prompts", "Automatic insights"]
        case .localRecordingOnly:
            return ["AI coaching prompts", "Real-time transcription", "Automatic insights"]
        case .manualNotesOnly:
            return ["AI coaching prompts", "Real-time transcription", "Audio capture", "Automatic insights"]
        }
    }
}

// MARK: - Recovery Condition

/// Conditions to wait for during recovery
enum RecoveryCondition: Sendable, Equatable {
    case audioDeviceAvailable
    case networkAvailable
    case apiReachable
    case sessionDataValid(sessionId: UUID)

    var description: String {
        switch self {
        case .audioDeviceAvailable:
            return "Waiting for audio device"
        case .networkAvailable:
            return "Waiting for network connection"
        case .apiReachable:
            return "Waiting for API availability"
        case .sessionDataValid:
            return "Validating session data"
        }
    }

    static func == (lhs: RecoveryCondition, rhs: RecoveryCondition) -> Bool {
        switch (lhs, rhs) {
        case (.audioDeviceAvailable, .audioDeviceAvailable),
             (.networkAvailable, .networkAvailable),
             (.apiReachable, .apiReachable):
            return true
        case (.sessionDataValid(let lhsId), .sessionDataValid(let rhsId)):
            return lhsId == rhsId
        default:
            return false
        }
    }
}

// MARK: - Recovery Attempt

/// Record of a recovery attempt for history/debugging
struct RecoveryAttempt: Sendable {
    let attemptNumber: Int
    let action: SessionRecoveryAction
    let timestamp: Date
    var result: RecoveryResult?
    var duration: TimeInterval?
}
