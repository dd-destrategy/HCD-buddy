//
//  MockSessionManager.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Mock implementation of SessionManaging protocol for testing
//

import Foundation

/// Mock session manager for testing
@MainActor
final class MockSessionManager: SessionManaging {

    // MARK: - Mock State

    var currentSessionId: UUID?
    var sessionStarted = false
    var sessionPaused = false
    var sessionEnded = false

    // MARK: - Call Tracking

    var createSessionCallCount = 0
    var startSessionCallCount = 0
    var pauseSessionCallCount = 0
    var resumeSessionCallCount = 0
    var endSessionCallCount = 0
    var lastSessionConfig: SessionConfig?

    // MARK: - Error Simulation

    var shouldThrowOnStart = false
    var errorToThrow: SessionError?

    // MARK: - SessionManaging Protocol

    private var _sessionState: SessionState = .idle
    var sessionState: SessionState {
        get { _sessionState }
        set { _sessionState = newValue }
    }

    private var (sessionStateContinuation, sessionStateStream) = AsyncStream<SessionState>.makeStream()

    var stateStream: AsyncStream<SessionState> {
        sessionStateStream
    }

    // MARK: - SessionManaging Methods

    func createSession(config: SessionConfig) async throws -> UUID {
        createSessionCallCount += 1
        lastSessionConfig = config

        let sessionId = UUID()
        currentSessionId = sessionId
        _sessionState = .setup

        sessionStateContinuation.yield(.setup)

        return sessionId
    }

    func startSession() async throws {
        startSessionCallCount += 1

        if shouldThrowOnStart, let error = errorToThrow {
            _sessionState = .failed
            sessionStateContinuation.yield(.failed)
            throw error
        }

        _sessionState = .streaming
        sessionStarted = true
        sessionStateContinuation.yield(.streaming)
    }

    func pauseSession() async {
        pauseSessionCallCount += 1
        _sessionState = .paused
        sessionPaused = true
        sessionStateContinuation.yield(.paused)
    }

    func resumeSession() async {
        resumeSessionCallCount += 1
        _sessionState = .streaming
        sessionPaused = false
        sessionStateContinuation.yield(.streaming)
    }

    func endSession() async throws -> SessionSummary {
        endSessionCallCount += 1
        _sessionState = .ended
        sessionEnded = true
        sessionStateContinuation.yield(.ended)

        return SessionSummary(
            sessionId: currentSessionId ?? UUID(),
            duration: 60.0,
            utteranceCount: 10,
            insightCount: 2,
            topicsCovered: 3,
            coachingPromptCount: 1
        )
    }

    // MARK: - Test Helpers

    /// Simulate state change
    func simulateStateChange(_ state: SessionState) {
        _sessionState = state
        sessionStateContinuation.yield(state)
    }

    /// Reset mock state
    func reset() {
        createSessionCallCount = 0
        startSessionCallCount = 0
        pauseSessionCallCount = 0
        resumeSessionCallCount = 0
        endSessionCallCount = 0
        currentSessionId = nil
        sessionStarted = false
        sessionPaused = false
        sessionEnded = false
        shouldThrowOnStart = false
        errorToThrow = nil
        lastSessionConfig = nil
        _sessionState = .idle
    }
}

// MARK: - Supporting Types

/// Protocol defining session management interface
protocol SessionManaging {
    var sessionState: SessionState { get }
    var stateStream: AsyncStream<SessionState> { get }

    func createSession(config: SessionConfig) async throws -> UUID
    func startSession() async throws
    func pauseSession() async
    func resumeSession() async
    func endSession() async throws -> SessionSummary
}

/// Session state machine states
enum SessionState: Equatable {
    case idle
    case setup
    case connecting
    case ready
    case streaming
    case paused
    case reconnecting
    case ending
    case ended
    case failed
}

/// Session summary returned after ending
struct SessionSummary {
    let sessionId: UUID
    let duration: TimeInterval
    let utteranceCount: Int
    let insightCount: Int
    let topicsCovered: Int
    let coachingPromptCount: Int
}

/// Session errors
enum SessionError: LocalizedError {
    case notConnected
    case alreadyStarted
    case notStarted
    case audioCaptureFailed
    case apiConnectionFailed

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to API"
        case .alreadyStarted:
            return "Session already started"
        case .notStarted:
            return "Session not started"
        case .audioCaptureFailed:
            return "Audio capture failed"
        case .apiConnectionFailed:
            return "API connection failed"
        }
    }
}
