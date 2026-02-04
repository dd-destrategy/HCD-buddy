//
//  IntegrationTestCase.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Base class for integration tests with common setup
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

/// Base class for integration tests providing common setup infrastructure.
/// Provides in-memory SwiftData container, mock dependencies, and helper utilities.
@MainActor
class IntegrationTestCase: XCTestCase {

    // MARK: - Test Infrastructure

    /// In-memory SwiftData container for isolated testing
    var testContainer: ModelContainer!

    /// Test model context for data operations
    var testContext: ModelContext!

    /// Test DataManager backed by the in-memory container
    var testDataManager: DataManager!

    /// Mock audio capture service for testing
    var mockAudioCapture: MockAudioCaptureService!

    /// Mock API client for testing
    var mockAPIClient: MockRealtimeAPIClient!

    /// Default timeout for async operations
    let defaultTimeout: TimeInterval = 10.0

    /// Short timeout for quick operations
    let shortTimeout: TimeInterval = 2.0

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory SwiftData container and test DataManager
        testContainer = try createInMemoryContainer()
        testContext = testContainer.mainContext
        testDataManager = DataManager(container: testContainer)

        // Create fresh mocks
        mockAudioCapture = MockAudioCaptureService()
        mockAPIClient = MockRealtimeAPIClient()
    }

    override func tearDown() async throws {
        // Clean up mocks
        mockAudioCapture?.reset()
        await mockAPIClient?.reset()

        // Delete model objects before destroying container to prevent SwiftData crash
        if let context = testContext {
            for obj in (try? context.fetch(FetchDescriptor<Session>())) ?? [] { context.delete(obj) }
            for obj in (try? context.fetch(FetchDescriptor<Utterance>())) ?? [] { context.delete(obj) }
            for obj in (try? context.fetch(FetchDescriptor<Insight>())) ?? [] { context.delete(obj) }
            for obj in (try? context.fetch(FetchDescriptor<CoachingEvent>())) ?? [] { context.delete(obj) }
            for obj in (try? context.fetch(FetchDescriptor<TopicStatus>())) ?? [] { context.delete(obj) }
            try? context.save()
        }

        // Clean up container
        testContext = nil
        testDataManager = nil
        testContainer = nil
        mockAudioCapture = nil
        mockAPIClient = nil

        try await super.tearDown()
    }

    // MARK: - Container Setup

    /// Creates an in-memory SwiftData container for testing
    /// - Returns: Configured ModelContainer with test schema
    func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Session.self,
            Utterance.self,
            Insight.self,
            TopicStatus.self,
            CoachingEvent.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    // MARK: - Session Manager Factory

    /// Creates a SessionManager configured with test mocks and in-memory DataManager
    /// - Returns: SessionManager ready for testing
    func createTestSessionManager() -> SessionManager {
        return SessionManager(
            audioCapturerProvider: { [weak self] in
                self?.mockAudioCapture ?? MockAudioCaptureService()
            },
            apiClientProvider: { [weak self] in
                self?.mockAPIClient ?? MockRealtimeAPIClient()
            },
            dataManager: testDataManager
        )
    }

    // MARK: - Test Data Factories

    /// Creates a test session configuration
    /// - Parameters:
    ///   - apiKey: API key for the session
    ///   - prompt: System prompt
    ///   - topics: Research topics
    ///   - mode: Session mode
    /// - Returns: Configured SessionConfig
    func createTestConfig(
        apiKey: String = "test-api-key-integration",
        prompt: String = "Test integration prompt",
        topics: [String] = ["Topic A", "Topic B"],
        mode: SessionMode = .full
    ) -> SessionConfig {
        return SessionConfig(
            apiKey: apiKey,
            systemPrompt: prompt,
            topics: topics,
            sessionMode: mode,
            metadata: SessionMetadata(
                participantName: "Integration Test User",
                projectName: "Integration Test Project",
                plannedDuration: 1800  // 30 minutes
            )
        )
    }

    /// Creates a test Session model
    /// - Parameters:
    ///   - participantName: Name of the participant
    ///   - projectName: Name of the project
    ///   - mode: Session mode
    /// - Returns: Session model for testing
    func createTestSession(
        participantName: String = "Test Participant",
        projectName: String = "Test Project",
        mode: SessionMode = .full
    ) -> Session {
        return Session(
            participantName: participantName,
            projectName: projectName,
            sessionMode: mode
        )
    }

    /// Creates a test Utterance model
    /// - Parameters:
    ///   - speaker: Speaker type
    ///   - text: Utterance text
    ///   - timestamp: Timestamp in seconds
    ///   - confidence: Confidence score
    /// - Returns: Utterance model for testing
    func createTestUtterance(
        speaker: Speaker = .interviewer,
        text: String = "Test utterance text",
        timestamp: Double = 0.0,
        confidence: Double = 0.95
    ) -> Utterance {
        return Utterance(
            speaker: speaker,
            text: text,
            timestampSeconds: timestamp,
            confidence: confidence
        )
    }

    /// Creates a test TranscriptionEvent
    /// - Parameters:
    ///   - text: Transcription text
    ///   - isFinal: Whether this is final transcription
    ///   - speaker: Speaker type
    ///   - timestamp: Timestamp
    ///   - confidence: Confidence score
    /// - Returns: TranscriptionEvent for testing
    func createTestTranscriptionEvent(
        text: String = "Test transcription text",
        isFinal: Bool = true,
        speaker: Speaker = .participant,
        timestamp: TimeInterval = 1.0,
        confidence: Double = 0.92
    ) -> TranscriptionEvent {
        return TranscriptionEvent(
            text: text,
            isFinal: isFinal,
            speaker: speaker,
            timestamp: timestamp,
            confidence: confidence
        )
    }

    /// Creates a test FunctionCallEvent
    /// - Parameters:
    ///   - name: Function name
    ///   - arguments: Function arguments
    ///   - timestamp: Timestamp
    /// - Returns: FunctionCallEvent for testing
    func createTestFunctionCallEvent(
        name: String = "show_nudge",
        arguments: [String: String] = ["text": "Test nudge", "reason": "Test reason", "confidence": "0.90"],
        timestamp: TimeInterval = 5.0
    ) -> FunctionCallEvent {
        return FunctionCallEvent(
            name: name,
            arguments: arguments,
            timestamp: timestamp
        )
    }

    /// Creates a test AudioChunk
    /// - Parameters:
    ///   - timestamp: Timestamp for the chunk
    ///   - dataSize: Size of audio data in bytes
    /// - Returns: AudioChunk for testing
    func createTestAudioChunk(
        timestamp: TimeInterval = 0.0,
        dataSize: Int = 1024
    ) -> AudioChunk {
        let data = Data(repeating: 0, count: dataSize)
        return AudioChunk(
            data: data,
            timestamp: timestamp,
            sampleRate: 24000,
            channels: 1
        )
    }

    // MARK: - Async Helpers

    /// Waits for a condition to become true with timeout
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - description: Description for failure message
    ///   - condition: Closure returning the condition to check
    func waitForCondition(
        timeout: TimeInterval? = nil,
        description: String = "Condition",
        condition: @escaping () -> Bool
    ) async throws {
        let maxWait = timeout ?? defaultTimeout
        let startTime = Date()

        while !condition() {
            if Date().timeIntervalSince(startTime) > maxWait {
                XCTFail("\(description) did not become true within \(maxWait) seconds")
                return
            }
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
    }

    /// Waits for a published property to reach expected value
    /// - Parameters:
    ///   - keyPath: KeyPath to the property
    ///   - object: The ObservableObject containing the property
    ///   - expected: Expected value
    ///   - timeout: Maximum time to wait
    func waitForValue<T: ObservableObject, V: Equatable>(
        _ keyPath: KeyPath<T, V>,
        on object: T,
        toEqual expected: V,
        timeout: TimeInterval? = nil
    ) async throws {
        try await waitForCondition(
            timeout: timeout,
            description: "Property \(keyPath) to equal \(expected)"
        ) {
            object[keyPath: keyPath] == expected
        }
    }

    /// Simulates the passage of time for testing time-dependent behaviors
    /// - Parameter seconds: Number of seconds to simulate
    func simulateTime(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    // MARK: - Mock Configuration Helpers

    /// Configures the mock API client for successful operations
    func configureMockAPIClientForSuccess() async {
        await mockAPIClient.reset()
        mockAPIClient = MockRealtimeAPIClient()
    }

    /// Configures the mock API client to fail on connect
    /// - Parameter error: Error to throw on connect
    func configureMockAPIClientToFailConnect(with error: ConnectionError = .networkUnavailable) async {
        await mockAPIClient.reset()
        mockAPIClient = MockRealtimeAPIClient()
        // Set error state after getting fresh instance
        Task {
            await mockAPIClient.simulateConnectionFailure(error)
        }
    }

    /// Configures the mock audio capture for success
    func configureMockAudioCaptureForSuccess() {
        mockAudioCapture.reset()
        mockAudioCapture.shouldThrowOnStart = false
    }

    /// Configures the mock audio capture to fail on start
    /// - Parameter error: Error to throw on start
    func configureMockAudioCaptureToFail(with error: AudioCaptureError = .blackHoleNotInstalled) {
        mockAudioCapture.reset()
        mockAudioCapture.shouldThrowOnStart = true
        mockAudioCapture.errorToThrow = error
    }

    // MARK: - Assertion Helpers

    /// Asserts that a session is in the expected state
    /// - Parameters:
    ///   - manager: SessionManager to check
    ///   - expectedState: Expected session state
    ///   - message: Custom failure message
    func assertSessionState(
        _ manager: SessionManager,
        is expectedState: SessionState,
        _ message: String = ""
    ) {
        XCTAssertEqual(
            manager.state,
            expectedState,
            "Expected session state \(expectedState.displayName), got \(manager.state.displayName). \(message)"
        )
    }

    /// Asserts that the session manager has an active session
    /// - Parameters:
    ///   - manager: SessionManager to check
    ///   - message: Custom failure message
    func assertHasActiveSession(
        _ manager: SessionManager,
        _ message: String = ""
    ) {
        XCTAssertNotNil(manager.currentSession, "Expected active session but found nil. \(message)")
    }

    /// Asserts that the mock audio capture is running
    /// - Parameter message: Custom failure message
    func assertAudioCaptureIsRunning(_ message: String = "") {
        XCTAssertTrue(mockAudioCapture.isRunning, "Expected audio capture to be running. \(message)")
    }

    /// Asserts that the mock API client is connected
    /// - Parameter message: Custom failure message
    func assertAPIClientIsConnected(_ message: String = "") async {
        let isConnected = await mockAPIClient.isConnected
        XCTAssertTrue(isConnected, "Expected API client to be connected. \(message)")
    }
}

// MARK: - XCTestCase Async Extensions

extension XCTestCase {
    /// Runs an async test with proper main actor context
    /// - Parameters:
    ///   - timeout: Test timeout
    ///   - testFunction: Async test function to run
    @MainActor
    func runAsyncTest(
        timeout: TimeInterval = 10.0,
        testFunction: @escaping () async throws -> Void
    ) async throws {
        try await withTimeout(seconds: timeout) {
            try await testFunction()
        }
    }
}

/// Helper to add timeout to async operations
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError(seconds: seconds)
        }

        guard let result = try await group.next() else {
            throw TimeoutError(seconds: seconds)
        }
        group.cancelAll()
        return result
    }
}

/// Error thrown when an operation times out
struct TimeoutError: LocalizedError {
    let seconds: TimeInterval

    var errorDescription: String? {
        "Operation timed out after \(seconds) seconds"
    }
}
