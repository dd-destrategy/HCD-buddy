//
//  MockAudioCaptureService.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Mock implementation of AudioCapturing protocol for testing
//

import Foundation
import AVFoundation

/// Mock audio capture service for testing
@MainActor
final class MockAudioCaptureService: AudioCapturing {

    // MARK: - Mock State

    var isRunning = false
    var isPaused = false
    var shouldThrowOnStart = false
    var errorToThrow: AudioCaptureError?

    // MARK: - Call Tracking

    var startCallCount = 0
    var stopCallCount = 0
    var pauseCallCount = 0
    var resumeCallCount = 0

    // MARK: - AudioCapturing Protocol

    private var _audioLevels = AudioLevels.silence
    var audioLevels: AudioLevels {
        get { _audioLevels }
        set { _audioLevels = newValue }
    }

    private var audioStreamContinuation: AsyncStream<AudioChunk>.Continuation!
    private var _audioStream: AsyncStream<AudioChunk>!

    var audioStream: AsyncStream<AudioChunk> {
        _audioStream
    }

    // MARK: - Initialization

    init() {
        let (stream, continuation) = AsyncStream<AudioChunk>.makeStream()
        self._audioStream = stream
        self.audioStreamContinuation = continuation
    }

    // MARK: - AudioCapturing Methods

    func start() throws {
        startCallCount += 1

        if shouldThrowOnStart, let error = errorToThrow {
            throw error
        }

        isRunning = true
        isPaused = false
    }

    func stop() {
        stopCallCount += 1
        isRunning = false
        isPaused = false
        audioStreamContinuation.finish()
    }

    func pause() {
        pauseCallCount += 1
        isPaused = true
    }

    func resume() {
        resumeCallCount += 1
        isPaused = false
    }

    // MARK: - Test Helpers

    /// Simulate sending an audio chunk
    func simulateAudioChunk(_ chunk: AudioChunk) {
        audioStreamContinuation.yield(chunk)
    }

    /// Simulate audio levels
    func simulateAudioLevels(system: Float, microphone: Float) {
        _audioLevels = AudioLevels(systemLevel: system, microphoneLevel: microphone)
    }

    /// Reset mock state
    func reset() {
        startCallCount = 0
        stopCallCount = 0
        pauseCallCount = 0
        resumeCallCount = 0
        isRunning = false
        isPaused = false
        shouldThrowOnStart = false
        errorToThrow = nil
        _audioLevels = .silence
    }

    /// Create a test audio chunk with sample data
    static func createTestAudioChunk(
        timestamp: TimeInterval = 0,
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
}
