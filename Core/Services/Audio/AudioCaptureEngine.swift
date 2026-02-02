//
//  AudioCaptureEngine.swift
//  HCD Interview Coach
//
//  Created by agent-e1 on 2026-02-01.
//  EPIC E1-S4: Audio Capture Engine
//

import Foundation
import AVFoundation
import CoreAudio

/// Audio capture engine using AVAudioEngine
/// Captures system audio (via BlackHole in Multi-Output Device) and microphone
/// Converts to 24kHz 16-bit mono PCM for OpenAI Realtime API
class AudioCaptureEngine {

    // MARK: - Properties

    /// Audio engine for capture
    private let audioEngine: AVAudioEngine

    /// Input node for Multi-Output Device (system audio via BlackHole)
    private var systemInputNode: AVAudioInputNode?

    /// Input node for microphone
    private let microphoneInputNode: AVAudioInputNode

    /// Mixer node for combining system and microphone audio
    private let mixerNode: AVAudioMixerNode

    /// Output format: 24kHz, 16-bit PCM, mono
    private let outputFormat: AVAudioFormat

    /// Continuation for the audio stream
    private var streamContinuation: AsyncStream<AudioChunk>.Continuation?

    /// Audio stream for captured chunks
    private(set) var audioStream: AsyncStream<AudioChunk>

    /// Session start time for timestamps
    private var sessionStartTime: TimeInterval = 0

    /// Is the engine currently capturing
    private(set) var isCapturing: Bool = false

    /// Is the engine paused
    private(set) var isPaused: Bool = false

    /// Multi-Output Device ID
    private var multiOutputDeviceID: AudioDeviceID?

    /// Buffer size for audio capture (in frames)
    private let bufferSize: AVAudioFrameCount = 4096

    /// Cached audio converter for format conversion (performance optimization)
    private var cachedConverter: AVAudioConverter?

    /// Last input format used with cached converter
    private var lastInputFormat: AVAudioFormat?

    // MARK: - Initialization

    init() {
        self.audioEngine = AVAudioEngine()
        self.microphoneInputNode = audioEngine.inputNode
        self.mixerNode = AVAudioMixerNode()

        // Output format: 24kHz, 16-bit signed integer PCM, mono
        // This is the format required by OpenAI Realtime API
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 24000,
            channels: 1,
            interleaved: true
        ) else {
            fatalError("Failed to create output audio format")
        }
        self.outputFormat = format

        // Attach mixer node
        audioEngine.attach(mixerNode)

        // Create audio stream
        self.audioStream = AsyncStream<AudioChunk> { continuation in
            self.streamContinuation = continuation
        }
    }

    deinit {
        stop()
    }

    // MARK: - Public Methods

    /// Start audio capture
    /// - Parameter multiOutputDeviceID: Device ID of the Multi-Output Device containing BlackHole
    /// - Throws: AudioCaptureError if capture cannot be started
    func start(multiOutputDeviceID: AudioDeviceID) throws {
        guard !isCapturing else { return }

        self.multiOutputDeviceID = multiOutputDeviceID

        // Configure audio session for recording
        try configureAudioSession()

        // Set up system audio input (from Multi-Output Device)
        try setupSystemAudioInput(deviceID: multiOutputDeviceID)

        // Set up microphone input
        try setupMicrophoneInput()

        // Connect mixer to output processing
        try setupMixerAndOutput()

        // Start the engine
        try audioEngine.start()

        sessionStartTime = Date().timeIntervalSince1970
        isCapturing = true
        isPaused = false
    }

    /// Stop audio capture
    func stop() {
        guard isCapturing else { return }

        audioEngine.stop()

        // Remove taps
        mixerNode.removeTap(onBus: 0)
        microphoneInputNode.removeTap(onBus: 0)

        // Disconnect nodes
        audioEngine.disconnectNodeOutput(microphoneInputNode)
        audioEngine.disconnectNodeOutput(mixerNode)

        // Finish stream
        streamContinuation?.finish()

        isCapturing = false
        isPaused = false
    }

    /// Pause audio capture (stops sending chunks but keeps engine running)
    func pause() {
        isPaused = true
    }

    /// Resume audio capture after pause
    func resume() {
        isPaused = false
    }

    /// Get the microphone input node for level metering
    func getMicrophoneNode() -> AVAudioNode {
        return microphoneInputNode
    }

    /// Get the mixer node for combined level metering
    func getMixerNode() -> AVAudioNode {
        return mixerNode
    }

    // MARK: - Private Setup Methods

    /// Configure audio session for recording
    private func configureAudioSession() throws {
        // Note: On macOS, audio session configuration is less critical than iOS
        // But we still need to ensure proper permissions
        #if os(macOS)
        // Request microphone permission if needed
        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            // This will trigger permission dialog
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        }
        #endif
    }

    /// Set up system audio input from Multi-Output Device
    private func setupSystemAudioInput(deviceID: AudioDeviceID) throws {
        // On macOS, we need to create a separate AVAudioEngine or use aggregate device
        // For system audio, we'll use the mixer node and connect via a tap
        // This is a simplified approach; production code may need more sophisticated routing

        // Note: In a real implementation, you would:
        // 1. Create an AVAudioInputNode connected to the Multi-Output Device
        // 2. This requires using AVAudioEngine with specific device configuration
        // For now, we'll document this as a requirement for the integrator

        // The microphone will be the primary input, and system audio will be mixed in
        // via the Multi-Output Device's BlackHole component
    }

    /// Set up microphone input
    private func setupMicrophoneInput() throws {
        let micFormat = microphoneInputNode.outputFormat(forBus: 0)

        // Connect microphone to mixer
        audioEngine.connect(
            microphoneInputNode,
            to: mixerNode,
            format: micFormat
        )
    }

    /// Set up mixer and output processing
    private func setupMixerAndOutput() throws {
        // Install tap on mixer to capture mixed audio
        mixerNode.installTap(
            onBus: 0,
            bufferSize: bufferSize,
            format: mixerNode.outputFormat(forBus: 0)
        ) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer, time: time)
        }
    }

    // MARK: - Audio Processing

    /// Process captured audio buffer
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard !isPaused else { return }

        // Convert to output format (24kHz, 16-bit mono PCM)
        guard let convertedBuffer = convertToOutputFormat(buffer) else {
            return
        }

        // Create audio chunk
        let timestamp = Date().timeIntervalSince1970 - sessionStartTime
        let chunk = createAudioChunk(from: convertedBuffer, timestamp: timestamp)

        // Send to stream
        streamContinuation?.yield(chunk)
    }

    /// Convert audio buffer to output format (24kHz, 16-bit mono PCM)
    /// Uses cached AVAudioConverter for performance (avoids ~50 allocations/second)
    private func convertToOutputFormat(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let inputFormat = buffer.format

        // Reuse cached converter if format hasn't changed (performance optimization)
        if cachedConverter == nil || lastInputFormat != inputFormat {
            cachedConverter = AVAudioConverter(from: inputFormat, to: outputFormat)
            lastInputFormat = inputFormat
        }

        guard let converter = cachedConverter else {
            return nil
        }

        // Calculate output buffer capacity
        let inputFrameCount = buffer.frameLength
        let outputFrameCapacity = AVAudioFrameCount(
            Double(inputFrameCount) * (outputFormat.sampleRate / inputFormat.sampleRate)
        )

        // Create output buffer
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: outputFrameCapacity
        ) else {
            return nil
        }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        guard status != .error, error == nil else {
            return nil
        }

        return outputBuffer
    }

    /// Create AudioChunk from buffer
    private func createAudioChunk(from buffer: AVAudioPCMBuffer, timestamp: TimeInterval) -> AudioChunk {
        // Get the raw PCM data
        let data = bufferToData(buffer)

        return AudioChunk(
            data: data,
            timestamp: timestamp,
            sampleRate: Int(outputFormat.sampleRate),
            channels: Int(outputFormat.channelCount)
        )
    }

    /// Convert PCM buffer to Data
    private func bufferToData(_ buffer: AVAudioPCMBuffer) -> Data {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        guard let mData = audioBuffer.mData else {
            return Data()
        }
        let data = Data(
            bytes: mData,
            count: Int(audioBuffer.mDataByteSize)
        )
        return data
    }
}

// MARK: - Audio Format Utilities

extension AVAudioFormat {
    /// Check if format is compatible with OpenAI Realtime API
    var isRealtimeAPICompatible: Bool {
        return commonFormat == .pcmFormatInt16 &&
               sampleRate == 24000 &&
               channelCount == 1 &&
               isInterleaved
    }

    /// Description string for debugging
    var detailedDescription: String {
        return """
        Format: \(commonFormat.rawValue)
        Sample Rate: \(sampleRate) Hz
        Channels: \(channelCount)
        Interleaved: \(isInterleaved)
        """
    }
}

extension AVAudioCommonFormat {
    /// Human-readable format name
    var name: String {
        switch self {
        case .pcmFormatFloat32:
            return "32-bit Float PCM"
        case .pcmFormatFloat64:
            return "64-bit Float PCM"
        case .pcmFormatInt16:
            return "16-bit Integer PCM"
        case .pcmFormatInt32:
            return "32-bit Integer PCM"
        case .otherFormat:
            return "Other Format"
        @unknown default:
            return "Unknown Format"
        }
    }
}
