//
//  AudioCapturing.swift
//  HCD Interview Coach
//
//  Created by agent-e1 on 2026-02-01.
//  EPIC E1: Audio Capture System
//

import Foundation
import AVFoundation

/// Protocol defining the audio capture interface for the HCD Interview Coach.
/// Captures system audio (via BlackHole) and microphone input, converting to 24kHz mono PCM.
protocol AudioCapturing {
    /// AsyncStream providing captured audio chunks
    var audioStream: AsyncStream<AudioChunk> { get }

    /// Current audio levels for system and microphone
    var audioLevels: AudioLevels { get }

    /// Start audio capture
    /// - Throws: AudioCaptureError if capture cannot be started
    func start() throws

    /// Stop audio capture completely
    func stop()

    /// Pause audio capture temporarily
    func pause()

    /// Resume audio capture after pause
    func resume()
}

/// Represents a chunk of captured audio data
struct AudioChunk: Sendable {
    /// Raw PCM audio data (16-bit signed integer)
    let data: Data

    /// Timestamp when this chunk was captured (relative to session start)
    let timestamp: TimeInterval

    /// Sample rate in Hz (always 24000 for OpenAI Realtime API)
    let sampleRate: Int // 24000

    /// Number of channels (always 1 for mono)
    let channels: Int // 1 (mono)

    /// Bits per sample (always 16 for OpenAI Realtime API)
    let bitsPerSample: Int // 16

    /// Creates a new audio chunk
    init(data: Data, timestamp: TimeInterval, sampleRate: Int = 24000, channels: Int = 1, bitsPerSample: Int = 16) {
        self.data = data
        self.timestamp = timestamp
        self.sampleRate = sampleRate
        self.channels = channels
        self.bitsPerSample = bitsPerSample
    }
}

/// Real-time audio levels for system and microphone inputs
struct AudioLevels: Sendable {
    /// System audio level (0.0 = silence, 1.0 = maximum)
    let systemLevel: Float // 0.0 - 1.0

    /// Microphone audio level (0.0 = silence, 1.0 = maximum)
    let microphoneLevel: Float // 0.0 - 1.0

    /// Creates new audio levels
    init(systemLevel: Float, microphoneLevel: Float) {
        self.systemLevel = min(max(systemLevel, 0.0), 1.0)
        self.microphoneLevel = min(max(microphoneLevel, 0.0), 1.0)
    }

    /// Silent audio levels (both channels at 0.0)
    static let silence = AudioLevels(systemLevel: 0.0, microphoneLevel: 0.0)
}

/// Errors that can occur during audio capture
enum AudioCaptureError: Error, LocalizedError {
    /// BlackHole virtual audio device is not installed
    case blackHoleNotInstalled

    /// Multi-Output Device is not properly configured
    case multiOutputNotConfigured

    /// Audio capture failed with a specific reason
    case captureFailure(String)

    /// Audio format conversion failed
    case formatConversionError

    /// Microphone permission not granted
    case microphonePermissionDenied

    /// Invalid audio device configuration
    case invalidDeviceConfiguration

    var errorDescription: String? {
        switch self {
        case .blackHoleNotInstalled:
            return "BlackHole 2ch virtual audio device is not installed. Please install BlackHole to capture system audio."
        case .multiOutputNotConfigured:
            return "Multi-Output Device is not configured. Please set up a Multi-Output Device with BlackHole and your speakers."
        case .captureFailure(let reason):
            return "Audio capture failed: \(reason)"
        case .formatConversionError:
            return "Failed to convert audio to required format (24kHz, 16-bit mono PCM)."
        case .microphonePermissionDenied:
            return "Microphone permission denied. Please grant microphone access in System Settings."
        case .invalidDeviceConfiguration:
            return "Invalid audio device configuration detected."
        }
    }
}
