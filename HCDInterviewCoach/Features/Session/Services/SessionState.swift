//
//  SessionState.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  State machine definition for session lifecycle
//

import Foundation

// MARK: - Session State

/// Represents the current state of an interview session.
/// Follows the state machine:
/// idle -> configuring -> ready -> running -> paused -> running -> ending -> ended
///                                    \-> error (recoverable) -> running
///                                    \-> failed (unrecoverable) -> ended
enum SessionState: Equatable, Sendable {
    /// No active session, ready to start configuration
    case idle

    /// Session is being configured (setting up audio, API connection)
    case configuring

    /// Session is configured and ready to start recording
    case ready

    /// Session is actively running and recording
    case running

    /// Session is temporarily paused
    case paused

    /// Session is in the process of ending
    case ending

    /// Session has ended successfully
    case ended

    /// Recoverable error occurred (can retry or recover)
    case error(SessionError)

    /// Unrecoverable failure (session must end)
    case failed(SessionError)

    // MARK: - State Queries

    /// Whether the session is in an active state (running or paused)
    var isActive: Bool {
        switch self {
        case .running, .paused:
            return true
        default:
            return false
        }
    }

    /// Whether the session can be started
    var canStart: Bool {
        self == .ready
    }

    /// Whether the session can be paused
    var canPause: Bool {
        self == .running
    }

    /// Whether the session can be resumed
    var canResume: Bool {
        switch self {
        case .paused, .error:
            return true
        default:
            return false
        }
    }

    /// Whether the session can be ended
    var canEnd: Bool {
        switch self {
        case .running, .paused, .error, .ready:
            return true
        default:
            return false
        }
    }

    /// Whether this state represents an error condition
    var isError: Bool {
        switch self {
        case .error, .failed:
            return true
        default:
            return false
        }
    }

    /// Human-readable description of the state
    var displayName: String {
        switch self {
        case .idle:
            return "Idle"
        case .configuring:
            return "Configuring..."
        case .ready:
            return "Ready"
        case .running:
            return "Recording"
        case .paused:
            return "Paused"
        case .ending:
            return "Ending..."
        case .ended:
            return "Ended"
        case .error(let error):
            return "Error: \(error.localizedDescription)"
        case .failed(let error):
            return "Failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Equatable

    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.configuring, .configuring),
             (.ready, .ready),
             (.running, .running),
             (.paused, .paused),
             (.ending, .ending),
             (.ended, .ended):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.id == rhsError.id
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.id == rhsError.id
        default:
            return false
        }
    }
}

// MARK: - Session State Transition

/// Validates and manages state transitions for the session lifecycle
struct SessionStateTransition {
    /// Attempts to transition from current state to target state
    /// - Parameters:
    ///   - from: Current state
    ///   - to: Target state
    /// - Returns: True if transition is valid, false otherwise
    static func isValid(from: SessionState, to: SessionState) -> Bool {
        switch (from, to) {
        // From idle: can only configure
        case (.idle, .configuring):
            return true

        // From configuring: can go to ready, error, or failed
        case (.configuring, .ready),
             (.configuring, .error),
             (.configuring, .failed):
            return true

        // From ready: can start running or end without starting
        case (.ready, .running),
             (.ready, .ending),
             (.ready, .idle): // Cancel configuration
            return true

        // From running: can pause, end, error, or fail
        case (.running, .paused),
             (.running, .ending),
             (.running, .error),
             (.running, .failed):
            return true

        // From paused: can resume, end, or fail
        case (.paused, .running),
             (.paused, .ending),
             (.paused, .failed):
            return true

        // From error: can recover to running, go to paused, or fail
        case (.error, .running),
             (.error, .paused),
             (.error, .ending),
             (.error, .failed):
            return true

        // From ending: can only go to ended
        case (.ending, .ended):
            return true

        // From ended or failed: can only reset to idle
        case (.ended, .idle),
             (.failed, .idle):
            return true

        default:
            return false
        }
    }

    /// Returns the appropriate error state based on the error type
    /// - Parameter error: The session error that occurred
    /// - Returns: Either .error or .failed state
    static func errorState(for error: SessionError) -> SessionState {
        if error.isRecoverable {
            return .error(error)
        } else {
            return .failed(error)
        }
    }
}

// MARK: - Session Error

/// Errors that can occur during a session
struct SessionError: LocalizedError, Identifiable, Sendable {
    let id: UUID
    let kind: ErrorKind
    let underlyingError: Error?
    let timestamp: Date
    let context: String?

    init(
        kind: ErrorKind,
        underlyingError: Error? = nil,
        context: String? = nil
    ) {
        self.id = UUID()
        self.kind = kind
        self.underlyingError = underlyingError
        self.timestamp = Date()
        self.context = context
    }

    // MARK: - Error Kind

    enum ErrorKind: Sendable {
        // Audio errors
        case audioCaptureFailed
        case audioDeviceUnavailable
        case microphonePermissionDenied

        // Connection errors
        case connectionFailed
        case connectionLost
        case reconnectionFailed
        case apiKeyInvalid
        case serverError

        // Configuration errors
        case invalidConfiguration
        case missingDependency

        // Data errors
        case persistenceFailed
        case dataCorrupted

        // State errors
        case invalidStateTransition

        // General
        case unknown
    }

    // MARK: - Recovery

    /// Whether this error can be recovered from
    var isRecoverable: Bool {
        switch kind {
        case .connectionLost, .reconnectionFailed, .audioCaptureFailed:
            return true
        case .apiKeyInvalid, .microphonePermissionDenied, .invalidConfiguration,
             .missingDependency, .dataCorrupted, .invalidStateTransition:
            return false
        case .connectionFailed, .serverError, .audioDeviceUnavailable,
             .persistenceFailed, .unknown:
            // These may be recoverable depending on context
            return true
        }
    }

    /// Suggested recovery action
    var recoveryAction: RecoveryAction {
        switch kind {
        case .connectionFailed, .connectionLost, .reconnectionFailed:
            return .reconnect
        case .audioCaptureFailed, .audioDeviceUnavailable:
            return .restartAudio
        case .serverError:
            return .retry
        case .apiKeyInvalid:
            return .updateAPIKey
        case .microphonePermissionDenied:
            return .requestPermission
        case .invalidConfiguration, .missingDependency:
            return .reconfigure
        case .persistenceFailed, .dataCorrupted:
            return .restartSession
        case .invalidStateTransition, .unknown:
            return .endSession
        }
    }

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch kind {
        case .audioCaptureFailed:
            return "Audio capture failed"
        case .audioDeviceUnavailable:
            return "Audio device unavailable"
        case .microphonePermissionDenied:
            return "Microphone permission denied"
        case .connectionFailed:
            return "Failed to connect to API"
        case .connectionLost:
            return "Connection lost"
        case .reconnectionFailed:
            return "Failed to reconnect"
        case .apiKeyInvalid:
            return "Invalid API key"
        case .serverError:
            return "Server error"
        case .invalidConfiguration:
            return "Invalid configuration"
        case .missingDependency:
            return "Missing required dependency"
        case .persistenceFailed:
            return "Failed to save data"
        case .dataCorrupted:
            return "Data corrupted"
        case .invalidStateTransition:
            return "Invalid state transition"
        case .unknown:
            return underlyingError?.localizedDescription ?? "Unknown error"
        }
    }

    var recoverySuggestion: String? {
        switch recoveryAction {
        case .reconnect:
            return "Attempting to reconnect automatically..."
        case .restartAudio:
            return "Check audio device and try again"
        case .retry:
            return "Please try again"
        case .updateAPIKey:
            return "Please update your API key in settings"
        case .requestPermission:
            return "Please grant microphone permission in System Settings"
        case .reconfigure:
            return "Please check your configuration and try again"
        case .restartSession:
            return "Please end this session and start a new one"
        case .endSession:
            return "Please end the session"
        }
    }
}

// MARK: - Recovery Action

/// Suggested actions for error recovery
enum RecoveryAction: Sendable {
    case reconnect
    case restartAudio
    case retry
    case updateAPIKey
    case requestPermission
    case reconfigure
    case restartSession
    case endSession
}

// MARK: - State Change Event

/// Represents a state change event for logging and debugging
struct SessionStateChange: Sendable {
    let fromState: SessionState
    let toState: SessionState
    let timestamp: Date
    let reason: String?

    init(from: SessionState, to: SessionState, reason: String? = nil) {
        self.fromState = from
        self.toState = to
        self.timestamp = Date()
        self.reason = reason
    }
}
