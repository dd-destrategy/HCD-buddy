//
//  MockSessionManager.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Mock implementation of SessionManaging protocol for testing
//

import Foundation
@testable import HCDInterviewCoach

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

    private var (sessionStateStream, sessionStateContinuation) = AsyncStream<SessionState>.makeStream()

    var stateStream: AsyncStream<SessionState> {
        sessionStateStream
    }

    // MARK: - SessionManaging Methods

    func createSession(config: SessionConfig) async throws -> UUID {
        createSessionCallCount += 1
        lastSessionConfig = config

        let sessionId = UUID()
        currentSessionId = sessionId
        _sessionState = .configuring

        sessionStateContinuation.yield(.configuring)

        return sessionId
    }

    func startSession() async throws {
        startSessionCallCount += 1

        if shouldThrowOnStart, let error = errorToThrow {
            _sessionState = .failed(error)
            sessionStateContinuation.yield(.failed(error))
            throw error
        }

        _sessionState = .running
        sessionStarted = true
        sessionStateContinuation.yield(.running)
    }

    func pauseSession() async {
        pauseSessionCallCount += 1
        _sessionState = .paused
        sessionPaused = true
        sessionStateContinuation.yield(.paused)
    }

    func resumeSession() async {
        resumeSessionCallCount += 1
        _sessionState = .running
        sessionPaused = false
        sessionStateContinuation.yield(.running)
    }

    func endSession() async throws -> MockSessionSummary {
        endSessionCallCount += 1
        _sessionState = .ended
        sessionEnded = true
        sessionStateContinuation.yield(.ended)

        return MockSessionSummary(
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
}

/// Mock session summary returned after ending
struct MockSessionSummary {
    let sessionId: UUID
    let duration: TimeInterval
    let utteranceCount: Int
    let insightCount: Int
    let topicsCovered: Int
    let coachingPromptCount: Int
}

/// Mock session errors for testing
enum MockSessionError: LocalizedError {
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
