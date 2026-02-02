//
//  SessionRecoveryService.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  Handles error recovery and graceful degradation
//

import Foundation

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

    // MARK: - Initialization

    init() {}

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
        executor: @escaping (RecoveryAction) async throws -> Void
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
        AppLogger.shared.info("Recovery successful, state reset")
    }

    /// Records a failed recovery attempt
    func recordFailure(_ error: Error) {
        AppLogger.shared.warning("Recovery attempt \(currentAttemptCount) failed: \(error.localizedDescription)")
    }

    /// Resets all recovery state
    func reset() {
        currentAttemptCount = 0
        isRecovering = false
        currentDegradedMode = nil
        recoveryHistory.removeAll()
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
            // In a real implementation, this would check audio device availability
            return true

        case .networkAvailable:
            // This would check network reachability
            return true

        case .apiReachable:
            // This would ping the API
            return true
        }
    }
}

// MARK: - Recovery Strategy

/// Defines what recovery action to take
enum RecoveryStrategy: Sendable {
    /// Retry the failed operation after a delay
    case retry(after: TimeInterval, action: RecoveryAction)

    /// Switch to a degraded mode of operation
    case degrade(to: DegradedMode)

    /// Wait for a condition to be met before retrying
    case waitForCondition(condition: RecoveryCondition, timeout: TimeInterval)

    /// Terminate the session
    case terminate(reason: String)
}

// MARK: - Recovery Action

/// Specific actions that can be taken during recovery
enum RecoveryAction: Sendable {
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
enum DegradedMode: Sendable {
    /// Only transcription, no AI coaching
    case transcriptionOnly

    /// Audio recording but no real-time transcription
    case localRecordingOnly

    /// Manual notes only, no audio or AI
    case manualNotesOnly

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
enum RecoveryCondition: Sendable {
    case audioDeviceAvailable
    case networkAvailable
    case apiReachable

    var description: String {
        switch self {
        case .audioDeviceAvailable:
            return "Waiting for audio device"
        case .networkAvailable:
            return "Waiting for network connection"
        case .apiReachable:
            return "Waiting for API availability"
        }
    }
}

// MARK: - Recovery Attempt

/// Record of a recovery attempt for history/debugging
struct RecoveryAttempt: Sendable {
    let attemptNumber: Int
    let action: RecoveryAction
    let timestamp: Date
    var result: RecoveryResult?
    var duration: TimeInterval?
}
