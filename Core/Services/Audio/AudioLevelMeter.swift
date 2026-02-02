//
//  AudioLevelMeter.swift
//  HCD Interview Coach
//
//  Created by agent-e1 on 2026-02-01.
//  EPIC E1-S5: Audio Level Metering
//

import Foundation
import AVFoundation
import Combine

/// Real-time audio level metering for system and microphone inputs
/// Provides RMS levels at 10Hz update rate
class AudioLevelMeter {

    // MARK: - Properties

    /// Published audio levels updated at 10Hz
    @Published private(set) var currentLevels: AudioLevels = .silence

    /// Publisher for audio levels
    var levelsPublisher: AnyPublisher<AudioLevels, Never> {
        $currentLevels.eraseToAnyPublisher()
    }

    /// Update interval for level metering (0.1 seconds = 10Hz)
    private let updateInterval: TimeInterval = 0.1

    /// Timer for periodic level updates
    private var meteringTimer: Timer?

    /// System audio tap node
    private weak var systemNode: AVAudioNode?

    /// Microphone audio tap node
    private weak var microphoneNode: AVAudioNode?

    /// Lock for thread-safe level access
    private let lock = NSLock()

    /// Current system audio level
    private var systemLevel: Float = 0.0

    /// Current microphone audio level
    private var microphoneLevel: Float = 0.0

    /// Audio format for metering
    private let meteringFormat: AVAudioFormat

    // MARK: - Initialization

    init() {
        // Standard format for metering (doesn't need to match output format)
        self.meteringFormat = AVAudioFormat(
            standardFormatWithSampleRate: 48000,
            channels: 2
        )!
    }

    deinit {
        stop()
    }

    // MARK: - Public Methods

    /// Start metering audio levels from the provided nodes
    /// - Parameters:
    ///   - systemNode: Audio node for system audio (from Multi-Output Device)
    ///   - microphoneNode: Audio node for microphone input
    func start(systemNode: AVAudioNode, microphoneNode: AVAudioNode) {
        stop() // Clean up any existing taps

        self.systemNode = systemNode
        self.microphoneNode = microphoneNode

        // Install tap on system audio node
        installTap(on: systemNode, isSystemAudio: true)

        // Install tap on microphone node
        installTap(on: microphoneNode, isSystemAudio: false)

        // Start periodic timer for level updates
        startMeteringTimer()
    }

    /// Stop metering audio levels
    func stop() {
        meteringTimer?.invalidate()
        meteringTimer = nil

        // Remove taps
        systemNode?.removeTap(onBus: 0)
        microphoneNode?.removeTap(onBus: 0)

        // Reset levels
        lock.lock()
        systemLevel = 0.0
        microphoneLevel = 0.0
        lock.unlock()

        currentLevels = .silence
    }

    // MARK: - Private Methods

    /// Install audio tap on a node for level metering
    private func installTap(on node: AVAudioNode, isSystemAudio: Bool) {
        let format = node.outputFormat(forBus: 0)

        // Install tap with a small buffer (1024 frames)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }

            let level = self.calculateRMS(from: buffer)

            self.lock.lock()
            if isSystemAudio {
                self.systemLevel = level
            } else {
                self.microphoneLevel = level
            }
            self.lock.unlock()
        }
    }

    /// Calculate RMS (Root Mean Square) level from audio buffer
    /// - Parameter buffer: Audio buffer to analyze
    /// - Returns: RMS level from 0.0 to 1.0
    private func calculateRMS(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else {
            return 0.0
        }

        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)

        guard frameLength > 0, channelCount > 0 else {
            return 0.0
        }

        var sum: Float = 0.0

        // Calculate RMS across all channels
        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for frame in 0..<frameLength {
                let sample = samples[frame]
                sum += sample * sample
            }
        }

        let meanSquare = sum / Float(frameLength * channelCount)
        let rms = sqrt(meanSquare)

        // Normalize to 0.0 - 1.0 range
        // RMS values typically don't exceed 0.7 for full-scale signals
        // We'll use a factor of 1.5 to map typical levels to 0-1 range
        return min(rms * 1.5, 1.0)
    }

    /// Start the periodic timer for level updates
    private func startMeteringTimer() {
        meteringTimer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateLevels()
        }

        // Ensure timer runs on main run loop
        if let timer = meteringTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// Update the published audio levels
    private func updateLevels() {
        lock.lock()
        let system = systemLevel
        let microphone = microphoneLevel
        lock.unlock()

        // Apply smoothing to reduce jitter (simple exponential moving average)
        let smoothingFactor: Float = 0.3
        let newLevels = AudioLevels(
            systemLevel: currentLevels.systemLevel * (1 - smoothingFactor) + system * smoothingFactor,
            microphoneLevel: currentLevels.microphoneLevel * (1 - smoothingFactor) + microphone * smoothingFactor
        )

        // Update on main thread since this is a @Published property
        DispatchQueue.main.async { [weak self] in
            self?.currentLevels = newLevels
        }
    }
}

// MARK: - Audio Level Utilities

extension AudioLevels {
    /// Convert linear level (0.0-1.0) to decibels
    /// - Parameter linearLevel: Linear level value
    /// - Returns: Level in decibels (typically -∞ to 0 dB)
    static func linearToDecibels(_ linearLevel: Float) -> Float {
        if linearLevel <= 0.0 {
            return -Float.infinity
        }
        return 20.0 * log10(linearLevel)
    }

    /// Convert decibels to linear level (0.0-1.0)
    /// - Parameter decibels: Level in decibels
    /// - Returns: Linear level value
    static func decibelsToLinear(_ decibels: Float) -> Float {
        if decibels == -Float.infinity {
            return 0.0
        }
        return pow(10.0, decibels / 20.0)
    }

    /// System level in decibels
    var systemLevelDB: Float {
        AudioLevels.linearToDecibels(systemLevel)
    }

    /// Microphone level in decibels
    var microphoneLevelDB: Float {
        AudioLevels.linearToDecibels(microphoneLevel)
    }

    /// Check if system audio is effectively silent (below threshold)
    func isSystemSilent(threshold: Float = 0.01) -> Bool {
        return systemLevel < threshold
    }

    /// Check if microphone audio is effectively silent (below threshold)
    func isMicrophoneSilent(threshold: Float = 0.01) -> Bool {
        return microphoneLevel < threshold
    }
}
