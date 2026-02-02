//
//  AudioCaptureServiceTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14-S1: Set Up Unit Testing
//  Example unit tests for audio capture service
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class AudioCaptureServiceTests: XCTestCase {

    var mockAudioService: MockAudioCaptureService!

    override func setUp() {
        super.setUp()
        mockAudioService = MockAudioCaptureService()
    }

    override func tearDown() {
        mockAudioService = nil
        super.tearDown()
    }

    // MARK: - Start/Stop Tests

    func testStartAudioCapture() throws {
        // When
        try mockAudioService.start()

        // Then
        XCTAssertEqual(mockAudioService.startCallCount, 1)
        XCTAssertTrue(mockAudioService.isRunning)
        XCTAssertFalse(mockAudioService.isPaused)
    }

    func testStopAudioCapture() throws {
        // Given
        try mockAudioService.start()

        // When
        mockAudioService.stop()

        // Then
        XCTAssertEqual(mockAudioService.stopCallCount, 1)
        XCTAssertFalse(mockAudioService.isRunning)
    }

    func testStartThrowsError() {
        // Given
        mockAudioService.shouldThrowOnStart = true
        mockAudioService.errorToThrow = .blackHoleNotInstalled

        // When/Then
        XCTAssertThrowsError(try mockAudioService.start()) { error in
            XCTAssertEqual(error as? AudioCaptureError, .blackHoleNotInstalled)
        }
    }

    // MARK: - Pause/Resume Tests

    func testPauseAudioCapture() throws {
        // Given
        try mockAudioService.start()

        // When
        mockAudioService.pause()

        // Then
        XCTAssertEqual(mockAudioService.pauseCallCount, 1)
        XCTAssertTrue(mockAudioService.isPaused)
        XCTAssertTrue(mockAudioService.isRunning) // Still running, just paused
    }

    func testResumeAudioCapture() throws {
        // Given
        try mockAudioService.start()
        mockAudioService.pause()

        // When
        mockAudioService.resume()

        // Then
        XCTAssertEqual(mockAudioService.resumeCallCount, 1)
        XCTAssertFalse(mockAudioService.isPaused)
    }

    // MARK: - Audio Stream Tests

    func testAudioStreamReceivesChunks() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Receive audio chunk")
        let testChunk = MockAudioCaptureService.createTestAudioChunk(timestamp: 1.0)

        // When
        Task {
            for await chunk in mockAudioService.audioStream {
                XCTAssertEqual(chunk.timestamp, 1.0)
                XCTAssertEqual(chunk.sampleRate, 24000)
                XCTAssertEqual(chunk.channels, 1)
                expectation.fulfill()
                break
            }
        }

        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        mockAudioService.simulateAudioChunk(testChunk)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Audio Levels Tests

    func testAudioLevels() {
        // When
        mockAudioService.simulateAudioLevels(system: 0.7, microphone: 0.5)

        // Then
        let levels = mockAudioService.audioLevels
        XCTAssertEqual(levels.systemLevel, 0.7, accuracy: 0.01)
        XCTAssertEqual(levels.microphoneLevel, 0.5, accuracy: 0.01)
    }

    func testAudioLevelsClampedToValidRange() {
        // When
        mockAudioService.simulateAudioLevels(system: 1.5, microphone: -0.2)

        // Then
        let levels = mockAudioService.audioLevels
        XCTAssertEqual(levels.systemLevel, 1.0) // Clamped to max
        XCTAssertEqual(levels.microphoneLevel, 0.0) // Clamped to min
    }

    func testSilentAudioLevels() {
        // Given
        let silence = AudioLevels.silence

        // Then
        XCTAssertEqual(silence.systemLevel, 0.0)
        XCTAssertEqual(silence.microphoneLevel, 0.0)
    }

    // MARK: - Reset Tests

    func testReset() throws {
        // Given
        try mockAudioService.start()
        mockAudioService.pause()

        // When
        mockAudioService.reset()

        // Then
        XCTAssertEqual(mockAudioService.startCallCount, 0)
        XCTAssertEqual(mockAudioService.pauseCallCount, 0)
        XCTAssertFalse(mockAudioService.isRunning)
        XCTAssertFalse(mockAudioService.isPaused)
    }

    // MARK: - Audio Chunk Creation Tests

    func testCreateTestAudioChunk() {
        // When
        let chunk = MockAudioCaptureService.createTestAudioChunk(
            timestamp: 5.0,
            dataSize: 2048
        )

        // Then
        XCTAssertEqual(chunk.timestamp, 5.0)
        XCTAssertEqual(chunk.data.count, 2048)
        XCTAssertEqual(chunk.sampleRate, 24000)
        XCTAssertEqual(chunk.channels, 1)
    }
}
