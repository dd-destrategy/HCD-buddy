//
//  AudioStreamingService.swift
//  HCD Interview Coach
//
//  EPIC E3-S4: Implement Audio Streaming
//  Handles audio chunk streaming to OpenAI Realtime API
//

import Foundation
import Combine

/// Service for streaming audio to the Realtime API with rate limiting and backpressure handling
final class AudioStreamingService {
    // MARK: - Properties

    /// Maximum chunks per second to prevent overwhelming the API
    private let maxChunksPerSecond: Int = 50  // 24kHz with 100ms chunks = ~50 chunks/sec

    /// Size of the buffer before applying backpressure
    private let bufferSize: Int = 100

    /// Current buffer of pending audio chunks
    private var audioBuffer: [AudioChunk] = []

    /// Lock for thread-safe buffer access
    private let bufferLock = NSLock()

    /// Rate limiter for chunk sending
    private let rateLimiter: RateLimiter

    /// Statistics for monitoring
    private(set) var statistics = StreamingStatistics()

    /// Whether streaming is active
    private var isStreaming = false

    /// Streaming task
    private var streamingTask: Task<Void, Never>?

    /// API connection for sending
    private weak var connection: ConnectionManager?

    // MARK: - Initialization

    init(connection: ConnectionManager, maxChunksPerSecond: Int = 50) {
        self.connection = connection
        self.rateLimiter = RateLimiter(maxOperationsPerSecond: maxChunksPerSecond)
    }

    // MARK: - Public Methods

    /// Start streaming audio chunks
    func startStreaming() {
        guard !isStreaming else { return }

        isStreaming = true
        statistics = StreamingStatistics()

        streamingTask = Task { [weak self] in
            await self?.streamingLoop()
        }
    }

    /// Stop streaming audio chunks
    func stopStreaming() {
        isStreaming = false
        streamingTask?.cancel()
        streamingTask = nil

        bufferLock.lock()
        audioBuffer.removeAll()
        bufferLock.unlock()
    }

    /// Queue an audio chunk for streaming
    /// - Parameter chunk: Audio chunk to send
    /// - Throws: StreamingError if buffer is full or streaming is stopped
    func queueAudioChunk(_ chunk: AudioChunk) throws {
        guard isStreaming else {
            throw StreamingError.streamClosed
        }

        bufferLock.lock()
        defer { bufferLock.unlock() }

        // Check for backpressure
        guard audioBuffer.count < bufferSize else {
            statistics.backpressureEvents += 1
            throw StreamingError.backpressure
        }

        // Validate audio format
        guard validateAudioFormat(chunk) else {
            throw StreamingError.invalidAudioFormat
        }

        audioBuffer.append(chunk)
        statistics.chunksQueued += 1
    }

    /// Get current buffer utilization (0.0 - 1.0)
    var bufferUtilization: Double {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        return Double(audioBuffer.count) / Double(bufferSize)
    }

    // MARK: - Private Methods

    private func streamingLoop() async {
        while isStreaming {
            // Get next chunk from buffer
            let chunk: AudioChunk? = {
                bufferLock.lock()
                defer { bufferLock.unlock() }
                return audioBuffer.isEmpty ? nil : audioBuffer.removeFirst()
            }()

            // If we have a chunk, send it
            if let chunk = chunk {
                await sendChunk(chunk)
            } else {
                // Buffer empty, wait a bit
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }

            // Rate limiting
            await rateLimiter.waitIfNeeded()
        }
    }

    private func sendChunk(_ chunk: AudioChunk) async {
        let startTime = Date()

        do {
            // Convert to base64
            let base64Audio = chunk.data.base64EncodedString()

            // Send via connection
            try await connection?.sendAudio(base64Audio)

            // Update statistics
            statistics.chunksSent += 1
            statistics.totalBytesSent += chunk.data.count

            let latency = Date().timeIntervalSince(startTime)
            updateLatencyStatistics(latency)

        } catch {
            statistics.sendErrors += 1

            // Handle specific error types
            if let streamingError = error as? StreamingError {
                handleStreamingError(streamingError)
            } else {
                // Unknown error, log and continue
                AppLogger.shared.logAudio("Audio streaming error: \(error.localizedDescription)", level: .error)
            }
        }
    }

    private func validateAudioFormat(_ chunk: AudioChunk) -> Bool {
        // Validate format matches requirements (24kHz, 16-bit, mono)
        guard chunk.sampleRate == 24000 else { return false }
        guard chunk.bitsPerSample == 16 else { return false }
        guard chunk.channels == 1 else { return false }
        guard !chunk.data.isEmpty else { return false }

        return true
    }

    private func updateLatencyStatistics(_ latency: TimeInterval) {
        if statistics.averageLatency == 0 {
            statistics.averageLatency = latency
        } else {
            // Exponential moving average
            statistics.averageLatency = statistics.averageLatency * 0.9 + latency * 0.1
        }

        statistics.maxLatency = max(statistics.maxLatency, latency)
        statistics.minLatency = min(statistics.minLatency, latency)
    }

    private func handleStreamingError(_ error: StreamingError) {
        switch error {
        case .backpressure:
            // Backpressure - slow down sending
            AppLogger.shared.logAudio("Backpressure detected, buffer full", level: .warning)

        case .notConnected:
            // Connection lost - stop streaming
            AppLogger.shared.logAudio("Connection lost during streaming", level: .error)
            stopStreaming()

        case .streamClosed:
            // Stream closed - stop streaming
            AppLogger.shared.logAudio("Stream closed", level: .warning)
            stopStreaming()

        case .encodingFailed:
            // Encoding error - log and continue
            AppLogger.shared.logAudio("Audio encoding failed", level: .error)

        case .invalidAudioFormat:
            // Invalid format - log
            AppLogger.shared.logAudio("Invalid audio format", level: .error)
        }
    }
}

// MARK: - Rate Limiter

/// Simple rate limiter for controlling operation frequency
final class RateLimiter {
    private let maxOperationsPerSecond: Int
    private var lastOperationTime: Date?
    private let lock = NSLock()

    init(maxOperationsPerSecond: Int) {
        self.maxOperationsPerSecond = maxOperationsPerSecond
    }

    /// Wait if necessary to maintain rate limit
    func waitIfNeeded() async {
        lock.lock()
        defer { lock.unlock() }

        guard let lastTime = lastOperationTime else {
            lastOperationTime = Date()
            return
        }

        let minimumInterval = 1.0 / Double(maxOperationsPerSecond)
        let elapsed = Date().timeIntervalSince(lastTime)

        if elapsed < minimumInterval {
            let waitTime = minimumInterval - elapsed
            lock.unlock() // Unlock while waiting
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            lock.lock()
        }

        lastOperationTime = Date()
    }
}

// MARK: - Streaming Statistics

/// Statistics for monitoring streaming performance
struct StreamingStatistics {
    /// Number of chunks queued for sending
    var chunksQueued: Int = 0

    /// Number of chunks successfully sent
    var chunksSent: Int = 0

    /// Total bytes sent
    var totalBytesSent: Int = 0

    /// Number of backpressure events
    var backpressureEvents: Int = 0

    /// Number of send errors
    var sendErrors: Int = 0

    /// Average latency per chunk send
    var averageLatency: TimeInterval = 0

    /// Maximum latency observed
    var maxLatency: TimeInterval = 0

    /// Minimum latency observed
    var minLatency: TimeInterval = .infinity

    /// Success rate (0.0 - 1.0)
    var successRate: Double {
        guard chunksQueued > 0 else { return 0.0 }
        return Double(chunksSent) / Double(chunksQueued)
    }

    /// Throughput in bytes per second
    var throughput: Double {
        guard averageLatency > 0 else { return 0.0 }
        let averageChunkSize = Double(totalBytesSent) / Double(max(chunksSent, 1))
        return averageChunkSize / averageLatency
    }
}

// MARK: - Audio Chunk Extensions

extension AudioChunk {
    /// Create an audio chunk from raw PCM data
    /// - Parameters:
    ///   - pcmData: Raw PCM audio data
    ///   - timestamp: Timestamp in seconds from session start
    /// - Returns: Audio chunk configured for API (24kHz, 16-bit, mono)
    static func from(pcmData: Data, timestamp: TimeInterval) -> AudioChunk {
        AudioChunk(
            data: pcmData,
            timestamp: timestamp,
            sampleRate: 24000,
            bitsPerSample: 16,
            channels: 1
        )
    }

    /// Duration of this audio chunk in seconds
    var duration: TimeInterval {
        let bytesPerSample = bitsPerSample / 8
        let totalSamples = data.count / (bytesPerSample * channels)
        return Double(totalSamples) / Double(sampleRate)
    }

    /// Number of samples in this chunk
    var sampleCount: Int {
        let bytesPerSample = bitsPerSample / 8
        return data.count / (bytesPerSample * channels)
    }
}

// MARK: - Error Recovery

/// Handles error recovery for audio streaming
final class StreamingErrorRecovery {
    private var consecutiveErrors = 0
    private let maxConsecutiveErrors = 5
    private var lastErrorTime: Date?

    /// Check if streaming should continue after an error
    /// - Parameter error: The error that occurred
    /// - Returns: True if streaming should continue, false if it should stop
    func shouldContinueAfterError(_ error: Error) -> Bool {
        let now = Date()

        // Reset error count if last error was more than 5 seconds ago
        if let lastError = lastErrorTime, now.timeIntervalSince(lastError) > 5.0 {
            consecutiveErrors = 0
        }

        consecutiveErrors += 1
        lastErrorTime = now

        // Stop if too many consecutive errors
        if consecutiveErrors >= maxConsecutiveErrors {
            return false
        }

        // Continue for most errors
        return true
    }

    /// Reset error count (call when streaming succeeds)
    func reset() {
        consecutiveErrors = 0
        lastErrorTime = nil
    }

    /// Get delay before retrying based on error count
    var retryDelay: TimeInterval {
        // Exponential backoff: 0.1s, 0.2s, 0.4s, 0.8s, 1.6s
        return min(0.1 * pow(2.0, Double(consecutiveErrors)), 1.6)
    }
}
