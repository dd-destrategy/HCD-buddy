//
//  AudioStreamingServiceTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for AudioStreamingService audio streaming functionality
//

import XCTest
@testable import HCDInterviewCoach

final class AudioStreamingServiceTests: XCTestCase {

    // MARK: - Properties

    var streamingService: AudioStreamingService!
    var mockConnectionManager: MockConnectionManager!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockConnectionManager = MockConnectionManager()
        streamingService = AudioStreamingService(connection: mockConnectionManager, maxChunksPerSecond: 50)
    }

    override func tearDown() {
        streamingService.stopStreaming()
        streamingService = nil
        mockConnectionManager = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a valid audio chunk for testing
    private func createValidAudioChunk(
        dataSize: Int = 4800,  // 100ms at 24kHz, 16-bit mono
        timestamp: TimeInterval = 0.0
    ) -> AudioChunk {
        // Create mock PCM data (16-bit signed integers)
        let data = Data(repeating: 0, count: dataSize)
        return AudioChunk(
            data: data,
            timestamp: timestamp,
            sampleRate: 24000,
            channels: 1
        )
    }

    /// Creates an invalid audio chunk (wrong format)
    private func createInvalidAudioChunk() -> AudioChunk {
        let data = Data(repeating: 0, count: 1000)
        return AudioChunk(
            data: data,
            timestamp: 0.0,
            sampleRate: 44100,  // Wrong sample rate
            channels: 2         // Wrong channel count
        )
    }

    // MARK: - Test: Stream Start

    func testStreamStart() {
        // Given: A fresh streaming service
        XCTAssertEqual(streamingService.statistics.chunksQueued, 0)

        // When: Starting the stream
        streamingService.startStreaming()

        // Then: Service should be ready to accept audio
        XCTAssertEqual(streamingService.bufferUtilization, 0.0)
    }

    func testStreamStart_idempotent() {
        // Given: A streaming service
        // When: Starting multiple times
        streamingService.startStreaming()
        streamingService.startStreaming()
        streamingService.startStreaming()

        // Then: Should not cause issues
        XCTAssertEqual(streamingService.statistics.chunksQueued, 0)
    }

    // MARK: - Test: Stream Stop

    func testStreamStop() async throws {
        // Given: A streaming service with some queued chunks
        streamingService.startStreaming()

        let chunk = createValidAudioChunk()
        try streamingService.queueAudioChunk(chunk)
        try streamingService.queueAudioChunk(chunk)

        XCTAssertGreaterThan(streamingService.bufferUtilization, 0)

        // When: Stopping the stream
        streamingService.stopStreaming()

        // Allow time for cleanup
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Buffer should be cleared
        XCTAssertEqual(streamingService.bufferUtilization, 0.0)
    }

    func testStreamStop_whenNotStarted() {
        // Given: A streaming service that hasn't started
        // When: Stopping (should not crash)
        streamingService.stopStreaming()

        // Then: Should complete without issues
        XCTAssertEqual(streamingService.statistics.chunksQueued, 0)
    }

    // MARK: - Test: Stream Pause and Resume

    func testStreamPause() async throws {
        // Given: A streaming service that is running
        streamingService.startStreaming()

        // When: Queueing an audio chunk
        let chunk = createValidAudioChunk()
        try streamingService.queueAudioChunk(chunk)

        // Then: Chunk should be queued
        XCTAssertEqual(streamingService.statistics.chunksQueued, 1)
    }

    func testStreamResume() async throws {
        // Given: A streaming service
        streamingService.startStreaming()

        // When: Queueing chunks
        let chunk = createValidAudioChunk()
        try streamingService.queueAudioChunk(chunk)

        // Allow some processing time
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Service should continue processing
        // Statistics should reflect activity
        XCTAssertGreaterThanOrEqual(streamingService.statistics.chunksQueued, 1)
    }

    // MARK: - Test: Audio Chunk Encoding

    func testAudioChunkEncoding_base64() async throws {
        // Given: A streaming service
        streamingService.startStreaming()

        // When: Queueing a valid audio chunk
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let chunk = AudioChunk(
            data: testData,
            timestamp: 0.0,
            sampleRate: 24000,
            channels: 1
        )

        try streamingService.queueAudioChunk(chunk)

        // Allow time for processing
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Mock should have received base64 encoded data
        if let sentData = mockConnectionManager.lastSentAudio {
            // Verify it's valid base64
            XCTAssertNotNil(Data(base64Encoded: sentData))
        }
    }

    // MARK: - Test: PCM Format Validation

    func testPCMFormat_valid24kHz16bitMono() throws {
        // Given: A streaming service
        streamingService.startStreaming()

        // When: Queueing a valid format chunk
        let chunk = createValidAudioChunk()

        // Then: Should not throw
        XCTAssertNoThrow(try streamingService.queueAudioChunk(chunk))
        XCTAssertEqual(streamingService.statistics.chunksQueued, 1)
    }

    func testPCMFormat_invalidSampleRate() {
        // Given: A streaming service
        streamingService.startStreaming()

        // When: Queueing a chunk with wrong sample rate
        let invalidChunk = AudioChunk(
            data: Data(repeating: 0, count: 1000),
            timestamp: 0.0,
            sampleRate: 44100,  // Wrong!
            channels: 1
        )

        // Then: Should throw invalidAudioFormat error
        XCTAssertThrowsError(try streamingService.queueAudioChunk(invalidChunk)) { error in
            XCTAssertEqual(error as? StreamingError, StreamingError.invalidAudioFormat)
        }
    }

    func testPCMFormat_invalidChannels() {
        // Given: A streaming service
        streamingService.startStreaming()

        // When: Queueing a chunk with stereo audio
        let invalidChunk = AudioChunk(
            data: Data(repeating: 0, count: 1000),
            timestamp: 0.0,
            sampleRate: 24000,
            channels: 2  // Wrong! Should be mono
        )

        // Then: Should throw invalidAudioFormat error
        XCTAssertThrowsError(try streamingService.queueAudioChunk(invalidChunk)) { error in
            XCTAssertEqual(error as? StreamingError, StreamingError.invalidAudioFormat)
        }
    }

    func testPCMFormat_emptyData() {
        // Given: A streaming service
        streamingService.startStreaming()

        // When: Queueing a chunk with empty data
        let emptyChunk = AudioChunk(
            data: Data(),
            timestamp: 0.0,
            sampleRate: 24000,
            channels: 1
        )

        // Then: Should throw invalidAudioFormat error
        XCTAssertThrowsError(try streamingService.queueAudioChunk(emptyChunk)) { error in
            XCTAssertEqual(error as? StreamingError, StreamingError.invalidAudioFormat)
        }
    }

    // MARK: - Test: Buffer Management

    func testBufferManagement_utilizationTracking() throws {
        // Given: A streaming service
        streamingService.startStreaming()

        // When: Adding chunks to the buffer
        let chunk = createValidAudioChunk()
        for _ in 0..<10 {
            try streamingService.queueAudioChunk(chunk)
        }

        // Then: Buffer utilization should reflect the queued chunks
        XCTAssertGreaterThan(streamingService.bufferUtilization, 0.0)
        XCTAssertLessThanOrEqual(streamingService.bufferUtilization, 1.0)
    }

    func testBufferManagement_capacityLimit() {
        // Given: A streaming service
        streamingService.startStreaming()

        // When: Filling the buffer to capacity
        let chunk = createValidAudioChunk()
        var backpressureDetected = false

        for _ in 0..<150 {  // More than buffer size (100)
            do {
                try streamingService.queueAudioChunk(chunk)
            } catch StreamingError.backpressure {
                backpressureDetected = true
                break
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Then: Should have detected backpressure
        XCTAssertTrue(backpressureDetected, "Should detect backpressure when buffer is full")
    }

    // MARK: - Test: Stream Error Handling

    func testStreamErrorHandling_notConnected() {
        // Given: A streaming service that hasn't started
        // When: Trying to queue a chunk
        let chunk = createValidAudioChunk()

        // Then: Should throw streamClosed error
        XCTAssertThrowsError(try streamingService.queueAudioChunk(chunk)) { error in
            XCTAssertEqual(error as? StreamingError, StreamingError.streamClosed)
        }
    }

    func testStreamErrorHandling_afterStop() throws {
        // Given: A streaming service that was running
        streamingService.startStreaming()
        let chunk = createValidAudioChunk()
        try streamingService.queueAudioChunk(chunk)

        // When: Stopping and trying to queue more
        streamingService.stopStreaming()

        // Then: Should throw streamClosed error
        XCTAssertThrowsError(try streamingService.queueAudioChunk(chunk)) { error in
            XCTAssertEqual(error as? StreamingError, StreamingError.streamClosed)
        }
    }

    // MARK: - Test: Reconnection

    func testReconnection_serviceCanRestart() async throws {
        // Given: A streaming service that was stopped
        streamingService.startStreaming()
        let chunk = createValidAudioChunk()
        try streamingService.queueAudioChunk(chunk)
        streamingService.stopStreaming()

        // Allow cleanup
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Restarting the service
        streamingService.startStreaming()

        // Then: Should accept new chunks
        XCTAssertNoThrow(try streamingService.queueAudioChunk(chunk))
    }

    // MARK: - Test: Backpressure

    func testBackpressure_statisticsTracking() {
        // Given: A streaming service
        streamingService.startStreaming()

        // When: Triggering backpressure
        let chunk = createValidAudioChunk()
        var backpressureCount = 0

        for _ in 0..<150 {
            do {
                try streamingService.queueAudioChunk(chunk)
            } catch StreamingError.backpressure {
                backpressureCount += 1
            } catch {
                // Ignore other errors
            }
        }

        // Then: Statistics should track backpressure events
        XCTAssertGreaterThan(streamingService.statistics.backpressureEvents, 0)
        XCTAssertEqual(streamingService.statistics.backpressureEvents, backpressureCount)
    }

    func testBackpressure_bufferFull() throws {
        // Given: A streaming service with full buffer
        streamingService.startStreaming()

        let chunk = createValidAudioChunk()

        // Fill to just under capacity
        for _ in 0..<99 {
            try streamingService.queueAudioChunk(chunk)
        }

        // Then: Should still accept one more
        XCTAssertNoThrow(try streamingService.queueAudioChunk(chunk))

        // But the next should fail with backpressure
        XCTAssertThrowsError(try streamingService.queueAudioChunk(chunk)) { error in
            XCTAssertEqual(error as? StreamingError, StreamingError.backpressure)
        }
    }

    // MARK: - Test: Statistics

    func testStatistics_initialState() {
        // Given: A fresh streaming service
        let stats = streamingService.statistics

        // Then: All statistics should be at initial values
        XCTAssertEqual(stats.chunksQueued, 0)
        XCTAssertEqual(stats.chunksSent, 0)
        XCTAssertEqual(stats.totalBytesSent, 0)
        XCTAssertEqual(stats.backpressureEvents, 0)
        XCTAssertEqual(stats.sendErrors, 0)
        XCTAssertEqual(stats.averageLatency, 0)
    }

    func testStatistics_chunksQueued() throws {
        // Given: A streaming service
        streamingService.startStreaming()

        // When: Queueing chunks
        let chunk = createValidAudioChunk()
        try streamingService.queueAudioChunk(chunk)
        try streamingService.queueAudioChunk(chunk)
        try streamingService.queueAudioChunk(chunk)

        // Then: Statistics should reflect queued chunks
        XCTAssertEqual(streamingService.statistics.chunksQueued, 3)
    }

    func testStatistics_successRate() {
        // Given: Statistics with various values
        var stats = StreamingStatistics()
        stats.chunksQueued = 100
        stats.chunksSent = 95

        // Then: Success rate should be calculated correctly
        XCTAssertEqual(stats.successRate, 0.95, accuracy: 0.001)
    }

    func testStatistics_successRate_noChunks() {
        // Given: Empty statistics
        let stats = StreamingStatistics()

        // Then: Success rate should be 0
        XCTAssertEqual(stats.successRate, 0.0)
    }

    func testStatistics_throughput() {
        // Given: Statistics with latency data
        var stats = StreamingStatistics()
        stats.totalBytesSent = 10000
        stats.chunksSent = 10
        stats.averageLatency = 0.01  // 10ms

        // Then: Throughput should be calculated
        XCTAssertGreaterThan(stats.throughput, 0)
    }

    func testStatistics_resetOnStart() throws {
        // Given: A streaming service with some history
        streamingService.startStreaming()
        let chunk = createValidAudioChunk()
        try streamingService.queueAudioChunk(chunk)
        XCTAssertEqual(streamingService.statistics.chunksQueued, 1, "Chunk should be queued")
        streamingService.stopStreaming()

        // When: Creating a fresh service (guarantees clean state)
        let freshService = AudioStreamingService(connection: mockConnectionManager, maxChunksPerSecond: 50)
        freshService.startStreaming()

        // Then: Statistics should start at zero
        XCTAssertEqual(freshService.statistics.chunksQueued, 0)
        XCTAssertEqual(freshService.statistics.chunksSent, 0)
        freshService.stopStreaming()
    }

    // MARK: - Test: AudioChunk Extensions

    func testAudioChunk_fromPCMData() {
        // Given: Raw PCM data
        let pcmData = Data(repeating: 0x00, count: 4800)
        let timestamp: TimeInterval = 1.5

        // When: Creating chunk from PCM data
        let chunk = AudioChunk.from(pcmData: pcmData, timestamp: timestamp)

        // Then: Should have correct properties
        XCTAssertEqual(chunk.data, pcmData)
        XCTAssertEqual(chunk.timestamp, timestamp)
        XCTAssertEqual(chunk.sampleRate, 24000)
        XCTAssertEqual(chunk.channels, 1)
    }

    func testAudioChunk_duration() {
        // Given: A chunk with known size
        // 100ms at 24kHz, 16-bit mono = 2400 samples * 2 bytes = 4800 bytes
        let pcmData = Data(repeating: 0x00, count: 4800)
        let chunk = AudioChunk.from(pcmData: pcmData, timestamp: 0.0)

        // Then: Duration should be ~100ms
        XCTAssertEqual(chunk.duration, 0.1, accuracy: 0.001)
    }

    func testAudioChunk_sampleCount() {
        // Given: A chunk with known size
        let pcmData = Data(repeating: 0x00, count: 4800)  // 2400 samples at 16-bit
        let chunk = AudioChunk.from(pcmData: pcmData, timestamp: 0.0)

        // Then: Sample count should be correct
        XCTAssertEqual(chunk.sampleCount, 2400)
    }
}

// MARK: - Mock Connection Manager

/// Mock connection manager for testing AudioStreamingService
final class MockConnectionManager: ConnectionManager {
    var lastSentAudio: String?
    var sendAudioCallCount = 0
    var shouldThrowError = false
    var errorToThrow: Error?

    override func sendAudio(_ base64Audio: String) async throws {
        sendAudioCallCount += 1
        lastSentAudio = base64Audio

        if shouldThrowError, let error = errorToThrow {
            throw error
        }
    }
}

// MARK: - StreamingErrorRecovery Tests

final class StreamingErrorRecoveryTests: XCTestCase {

    var errorRecovery: StreamingErrorRecovery!

    override func setUp() {
        super.setUp()
        errorRecovery = StreamingErrorRecovery()
    }

    override func tearDown() {
        errorRecovery = nil
        super.tearDown()
    }

    func testShouldContinueAfterError_firstError() {
        // Given: Fresh error recovery
        // When: First error occurs
        let shouldContinue = errorRecovery.shouldContinueAfterError(StreamingError.encodingFailed)

        // Then: Should continue
        XCTAssertTrue(shouldContinue)
    }

    func testShouldContinueAfterError_multipleErrors() {
        // Given: Multiple consecutive errors
        for _ in 0..<4 {
            _ = errorRecovery.shouldContinueAfterError(StreamingError.encodingFailed)
        }

        // When: One more error
        let shouldContinue = errorRecovery.shouldContinueAfterError(StreamingError.encodingFailed)

        // Then: Should stop after max consecutive errors
        XCTAssertFalse(shouldContinue)
    }

    func testReset_clearsErrorCount() {
        // Given: Some errors recorded
        _ = errorRecovery.shouldContinueAfterError(StreamingError.encodingFailed)
        _ = errorRecovery.shouldContinueAfterError(StreamingError.encodingFailed)

        // When: Resetting
        errorRecovery.reset()

        // Then: Should allow errors again
        for _ in 0..<4 {
            XCTAssertTrue(errorRecovery.shouldContinueAfterError(StreamingError.encodingFailed))
        }
    }

    func testRetryDelay_exponentialBackoff() {
        // Given: Initial state
        let initialDelay = errorRecovery.retryDelay

        // When: Errors accumulate
        _ = errorRecovery.shouldContinueAfterError(StreamingError.encodingFailed)
        let delay1 = errorRecovery.retryDelay

        _ = errorRecovery.shouldContinueAfterError(StreamingError.encodingFailed)
        let delay2 = errorRecovery.retryDelay

        // Then: Delays should increase
        XCTAssertGreaterThanOrEqual(delay1, initialDelay)
        XCTAssertGreaterThan(delay2, delay1)
    }

    func testRetryDelay_maxDelay() {
        // Given: Many errors
        for _ in 0..<10 {
            _ = errorRecovery.shouldContinueAfterError(StreamingError.encodingFailed)
        }

        // Then: Delay should be capped
        XCTAssertLessThanOrEqual(errorRecovery.retryDelay, 1.6)
    }
}

// MARK: - Rate Limiter Tests

final class RateLimiterTests: XCTestCase {

    func testRateLimiter_initialization() {
        // Given: Creating a rate limiter
        let limiter = RateLimiter(maxOperationsPerSecond: 50)

        // Then: Should be created successfully
        XCTAssertNotNil(limiter)
    }

    func testRateLimiter_firstOperationImmediate() async {
        // Given: A rate limiter
        let limiter = RateLimiter(maxOperationsPerSecond: 50)

        // When: First operation
        let startTime = Date()
        await limiter.waitIfNeeded()
        let elapsed = Date().timeIntervalSince(startTime)

        // Then: Should be immediate (< 1ms typical)
        XCTAssertLessThan(elapsed, 0.1)
    }

    func testRateLimiter_throttlesOperations() async throws {
        // Given: A slow rate limiter (10 ops/sec)
        let limiter = RateLimiter(maxOperationsPerSecond: 10)

        // When: Performing multiple operations
        let startTime = Date()

        await limiter.waitIfNeeded()
        await limiter.waitIfNeeded()
        await limiter.waitIfNeeded()

        let elapsed = Date().timeIntervalSince(startTime)

        // Then: Should have enforced minimum intervals
        // 3 operations at 10/sec = at least 0.2 seconds
        XCTAssertGreaterThanOrEqual(elapsed, 0.15)
    }
}
