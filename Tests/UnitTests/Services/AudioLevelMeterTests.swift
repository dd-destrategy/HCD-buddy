//
//  AudioLevelMeterTests.swift
//  HCDInterviewCoach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for AudioLevelMeter - Real-time Audio Level Metering
//

import XCTest
import AVFoundation
import Combine
@testable import HCDInterviewCoach

final class AudioLevelMeterTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    // MARK: - AudioLevels Tests

    func testAudioLevels_silence() {
        // Given: Silence constant

        // When: Check silence
        let silence = AudioLevels.silence

        // Then: Both levels should be 0
        XCTAssertEqual(silence.systemLevel, 0.0)
        XCTAssertEqual(silence.microphoneLevel, 0.0)
    }

    func testAudioLevels_init_clampsBelowZero() {
        // Given: Negative values

        // When: Create levels
        let levels = AudioLevels(systemLevel: -0.5, microphoneLevel: -1.0)

        // Then: Should be clamped to 0
        XCTAssertEqual(levels.systemLevel, 0.0)
        XCTAssertEqual(levels.microphoneLevel, 0.0)
    }

    func testAudioLevels_init_clampsAboveOne() {
        // Given: Values above 1.0

        // When: Create levels
        let levels = AudioLevels(systemLevel: 1.5, microphoneLevel: 2.0)

        // Then: Should be clamped to 1.0
        XCTAssertEqual(levels.systemLevel, 1.0)
        XCTAssertEqual(levels.microphoneLevel, 1.0)
    }

    func testAudioLevels_init_preservesValidValues() {
        // Given: Valid values

        // When: Create levels
        let levels = AudioLevels(systemLevel: 0.5, microphoneLevel: 0.7)

        // Then: Should preserve values
        XCTAssertEqual(levels.systemLevel, 0.5)
        XCTAssertEqual(levels.microphoneLevel, 0.7)
    }

    func testAudioLevels_init_boundaryValues() {
        // Given: Boundary values

        // When: Create levels at boundaries
        let zeroLevels = AudioLevels(systemLevel: 0.0, microphoneLevel: 0.0)
        let oneLevels = AudioLevels(systemLevel: 1.0, microphoneLevel: 1.0)

        // Then: Should accept boundary values
        XCTAssertEqual(zeroLevels.systemLevel, 0.0)
        XCTAssertEqual(zeroLevels.microphoneLevel, 0.0)
        XCTAssertEqual(oneLevels.systemLevel, 1.0)
        XCTAssertEqual(oneLevels.microphoneLevel, 1.0)
    }

    // MARK: - Decibel Conversion Tests

    func testLinearToDecibels_fullScale() {
        // Given: Full scale level (1.0)

        // When: Convert to dB
        let dB = AudioLevels.linearToDecibels(1.0)

        // Then: Should be 0 dB
        XCTAssertEqual(dB, 0.0, accuracy: 0.001)
    }

    func testLinearToDecibels_halfLevel() {
        // Given: Half level (0.5)

        // When: Convert to dB
        let dB = AudioLevels.linearToDecibels(0.5)

        // Then: Should be approximately -6 dB
        XCTAssertEqual(dB, -6.02, accuracy: 0.1)
    }

    func testLinearToDecibels_tenthLevel() {
        // Given: Tenth level (0.1)

        // When: Convert to dB
        let dB = AudioLevels.linearToDecibels(0.1)

        // Then: Should be approximately -20 dB
        XCTAssertEqual(dB, -20.0, accuracy: 0.1)
    }

    func testLinearToDecibels_zeroLevel() {
        // Given: Zero level

        // When: Convert to dB
        let dB = AudioLevels.linearToDecibels(0.0)

        // Then: Should be negative infinity
        XCTAssertEqual(dB, -Float.infinity)
    }

    func testLinearToDecibels_negativeLevel() {
        // Given: Negative level (invalid)

        // When: Convert to dB
        let dB = AudioLevels.linearToDecibels(-0.5)

        // Then: Should be negative infinity
        XCTAssertEqual(dB, -Float.infinity)
    }

    func testDecibelsToLinear_zeroDB() {
        // Given: 0 dB

        // When: Convert to linear
        let linear = AudioLevels.decibelsToLinear(0.0)

        // Then: Should be 1.0
        XCTAssertEqual(linear, 1.0, accuracy: 0.001)
    }

    func testDecibelsToLinear_minus6dB() {
        // Given: -6 dB

        // When: Convert to linear
        let linear = AudioLevels.decibelsToLinear(-6.02)

        // Then: Should be approximately 0.5
        XCTAssertEqual(linear, 0.5, accuracy: 0.01)
    }

    func testDecibelsToLinear_minus20dB() {
        // Given: -20 dB

        // When: Convert to linear
        let linear = AudioLevels.decibelsToLinear(-20.0)

        // Then: Should be approximately 0.1
        XCTAssertEqual(linear, 0.1, accuracy: 0.01)
    }

    func testDecibelsToLinear_negativeInfinity() {
        // Given: Negative infinity

        // When: Convert to linear
        let linear = AudioLevels.decibelsToLinear(-Float.infinity)

        // Then: Should be 0.0
        XCTAssertEqual(linear, 0.0)
    }

    func testDecibelsRoundTrip() {
        // Given: Various linear values
        let testValues: [Float] = [0.1, 0.25, 0.5, 0.75, 1.0]

        for value in testValues {
            // When: Convert to dB and back
            let dB = AudioLevels.linearToDecibels(value)
            let linear = AudioLevels.decibelsToLinear(dB)

            // Then: Should return to original value
            XCTAssertEqual(linear, value, accuracy: 0.001, "Round trip failed for \(value)")
        }
    }

    // MARK: - AudioLevels dB Property Tests

    func testAudioLevels_systemLevelDB() {
        // Given: Audio levels
        let levels = AudioLevels(systemLevel: 0.5, microphoneLevel: 0.0)

        // When: Get dB level
        let dB = levels.systemLevelDB

        // Then: Should be approximately -6 dB
        XCTAssertEqual(dB, -6.02, accuracy: 0.1)
    }

    func testAudioLevels_microphoneLevelDB() {
        // Given: Audio levels
        let levels = AudioLevels(systemLevel: 0.0, microphoneLevel: 0.5)

        // When: Get dB level
        let dB = levels.microphoneLevelDB

        // Then: Should be approximately -6 dB
        XCTAssertEqual(dB, -6.02, accuracy: 0.1)
    }

    func testAudioLevels_silenceDB() {
        // Given: Silence
        let levels = AudioLevels.silence

        // When: Get dB levels
        let systemDB = levels.systemLevelDB
        let micDB = levels.microphoneLevelDB

        // Then: Both should be negative infinity
        XCTAssertEqual(systemDB, -Float.infinity)
        XCTAssertEqual(micDB, -Float.infinity)
    }

    // MARK: - Silence Detection Tests

    func testIsSystemSilent_defaultThreshold() {
        // Given: Various levels
        let silentLevels = AudioLevels(systemLevel: 0.005, microphoneLevel: 0.5)
        let notSilentLevels = AudioLevels(systemLevel: 0.02, microphoneLevel: 0.5)

        // When: Check silence with default threshold
        let isSilent = silentLevels.isSystemSilent()
        let isNotSilent = notSilentLevels.isSystemSilent()

        // Then: Should correctly identify silence
        XCTAssertTrue(isSilent)
        XCTAssertFalse(isNotSilent)
    }

    func testIsSystemSilent_customThreshold() {
        // Given: Level at 0.05
        let levels = AudioLevels(systemLevel: 0.05, microphoneLevel: 0.5)

        // When: Check with different thresholds
        let silentWithHighThreshold = levels.isSystemSilent(threshold: 0.1)
        let notSilentWithLowThreshold = levels.isSystemSilent(threshold: 0.01)

        // Then: Should respect threshold
        XCTAssertTrue(silentWithHighThreshold)
        XCTAssertFalse(notSilentWithLowThreshold)
    }

    func testIsMicrophoneSilent_defaultThreshold() {
        // Given: Various levels
        let silentLevels = AudioLevels(systemLevel: 0.5, microphoneLevel: 0.005)
        let notSilentLevels = AudioLevels(systemLevel: 0.5, microphoneLevel: 0.02)

        // When: Check silence with default threshold
        let isSilent = silentLevels.isMicrophoneSilent()
        let isNotSilent = notSilentLevels.isMicrophoneSilent()

        // Then: Should correctly identify silence
        XCTAssertTrue(isSilent)
        XCTAssertFalse(isNotSilent)
    }

    func testIsMicrophoneSilent_customThreshold() {
        // Given: Level at 0.05
        let levels = AudioLevels(systemLevel: 0.5, microphoneLevel: 0.05)

        // When: Check with different thresholds
        let silentWithHighThreshold = levels.isMicrophoneSilent(threshold: 0.1)
        let notSilentWithLowThreshold = levels.isMicrophoneSilent(threshold: 0.01)

        // Then: Should respect threshold
        XCTAssertTrue(silentWithHighThreshold)
        XCTAssertFalse(notSilentWithLowThreshold)
    }

    func testIsSilent_exactThreshold() {
        // Given: Level exactly at threshold
        let levels = AudioLevels(systemLevel: 0.01, microphoneLevel: 0.01)

        // When: Check with exact threshold
        let isSystemSilent = levels.isSystemSilent(threshold: 0.01)
        let isMicSilent = levels.isMicrophoneSilent(threshold: 0.01)

        // Then: Should not be silent (at threshold, not below)
        XCTAssertFalse(isSystemSilent)
        XCTAssertFalse(isMicSilent)
    }

    // MARK: - AudioLevelMeter Initialization Tests

    func testAudioLevelMeter_initialState() {
        // Given: New meter

        // When: Create meter
        let meter = AudioLevelMeter()

        // Then: Should start with silence
        XCTAssertEqual(meter.currentLevels.systemLevel, 0.0)
        XCTAssertEqual(meter.currentLevels.microphoneLevel, 0.0)
    }

    func testAudioLevelMeter_hasLevelsPublisher() {
        // Given: New meter

        // When: Create meter
        let meter = AudioLevelMeter()

        // Then: Should have levels publisher
        let expectation = XCTestExpectation(description: "Receive initial value")

        meter.levelsPublisher
            .sink { levels in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - AudioLevelMeter Stop Tests

    func testAudioLevelMeter_stop_resetsLevels() {
        // Given: Meter (not started, just testing stop behavior)
        let meter = AudioLevelMeter()

        // When: Stop (even though not started)
        meter.stop()

        // Then: Levels should be silence
        XCTAssertEqual(meter.currentLevels, .silence)
    }

    func testAudioLevelMeter_stop_isIdempotent() {
        // Given: Meter
        let meter = AudioLevelMeter()

        // When: Stop multiple times
        meter.stop()
        meter.stop()
        meter.stop()

        // Then: Should not crash, levels should be silence
        XCTAssertEqual(meter.currentLevels, .silence)
    }

    // MARK: - Level Normalization Tests

    func testLevelNormalization_verySmallValues() {
        // Given: Very small linear values

        // When: Check if they're treated as silence
        let verySmallLevels = AudioLevels(systemLevel: 0.0001, microphoneLevel: 0.0001)

        // Then: Should be essentially silent with reasonable threshold
        XCTAssertTrue(verySmallLevels.isSystemSilent(threshold: 0.001))
        XCTAssertTrue(verySmallLevels.isMicrophoneSilent(threshold: 0.001))
    }

    func testLevelNormalization_nearFullScale() {
        // Given: Near full-scale values

        // When: Create levels
        let nearMaxLevels = AudioLevels(systemLevel: 0.99, microphoneLevel: 0.99)

        // Then: Should not be silent
        XCTAssertFalse(nearMaxLevels.isSystemSilent())
        XCTAssertFalse(nearMaxLevels.isMicrophoneSilent())
    }

    // MARK: - Peak Detection Tests

    func testPeakDetection_identifiesLouderChannel() {
        // Given: Audio levels with different values
        let levels = AudioLevels(systemLevel: 0.8, microphoneLevel: 0.3)

        // When: Check levels
        let systemDB = levels.systemLevelDB
        let micDB = levels.microphoneLevelDB

        // Then: System should have higher dB (less negative)
        XCTAssertGreaterThan(systemDB, micDB)
    }

    func testPeakDetection_identifiesPeak() {
        // Given: Series of levels
        let levels1 = AudioLevels(systemLevel: 0.3, microphoneLevel: 0.3)
        let levels2 = AudioLevels(systemLevel: 0.8, microphoneLevel: 0.3) // Peak
        let levels3 = AudioLevels(systemLevel: 0.5, microphoneLevel: 0.3)

        // When: Find max
        let maxSystemLevel = max(levels1.systemLevel, levels2.systemLevel, levels3.systemLevel)

        // Then: Peak should be identified
        XCTAssertEqual(maxSystemLevel, 0.8)
    }

    // MARK: - Average Level Tests

    func testAverageLevel_calculation() {
        // Given: Series of levels
        let levels: [Float] = [0.2, 0.4, 0.6, 0.8, 1.0]

        // When: Calculate average
        let average = levels.reduce(0, +) / Float(levels.count)

        // Then: Should be correct
        XCTAssertEqual(average, 0.6, accuracy: 0.001)
    }

    func testAverageLevel_withSilence() {
        // Given: Mix of silence and levels
        let levels: [Float] = [0.0, 0.0, 0.0, 0.5, 1.0]

        // When: Calculate average
        let average = levels.reduce(0, +) / Float(levels.count)

        // Then: Should include silence in average
        XCTAssertEqual(average, 0.3, accuracy: 0.001)
    }

    // MARK: - Thread Safety Tests

    func testAudioLevels_threadSafe() async {
        // Given: Need to test concurrent access

        // When: Create levels from multiple tasks
        await withTaskGroup(of: AudioLevels.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let value = Float(i) / 100.0
                    return AudioLevels(systemLevel: value, microphoneLevel: value)
                }
            }

            // Then: All should complete without crash
            for await levels in group {
                XCTAssertGreaterThanOrEqual(levels.systemLevel, 0.0)
                XCTAssertLessThanOrEqual(levels.systemLevel, 1.0)
            }
        }
    }
}

// MARK: - Mock Audio Level Meter for Testing

/// Mock implementation for testing scenarios where audio levels are controlled
class MockAudioLevelMeter {
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    var mockLevels: AudioLevels = .silence
    var isRunning: Bool = false

    @Published private(set) var currentLevels: AudioLevels = .silence

    var levelsPublisher: AnyPublisher<AudioLevels, Never> {
        $currentLevels.eraseToAnyPublisher()
    }

    func start() {
        startCallCount += 1
        isRunning = true
    }

    func stop() {
        stopCallCount += 1
        isRunning = false
        currentLevels = .silence
    }

    func simulateLevels(_ levels: AudioLevels) {
        currentLevels = levels
    }

    func simulateSystemLevel(_ level: Float) {
        currentLevels = AudioLevels(systemLevel: level, microphoneLevel: currentLevels.microphoneLevel)
    }

    func simulateMicrophoneLevel(_ level: Float) {
        currentLevels = AudioLevels(systemLevel: currentLevels.systemLevel, microphoneLevel: level)
    }

    func reset() {
        startCallCount = 0
        stopCallCount = 0
        isRunning = false
        currentLevels = .silence
        mockLevels = .silence
    }
}

// MARK: - Mock Audio Level Meter Tests

final class MockAudioLevelMeterTests: XCTestCase {

    var mockMeter: MockAudioLevelMeter!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockMeter = MockAudioLevelMeter()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        mockMeter = nil
        cancellables = nil
        super.tearDown()
    }

    func testMockMeter_start() {
        // Given: Mock meter

        // When: Start
        mockMeter.start()

        // Then: Should track call
        XCTAssertEqual(mockMeter.startCallCount, 1)
        XCTAssertTrue(mockMeter.isRunning)
    }

    func testMockMeter_stop() {
        // Given: Running meter
        mockMeter.start()

        // When: Stop
        mockMeter.stop()

        // Then: Should track call and reset levels
        XCTAssertEqual(mockMeter.stopCallCount, 1)
        XCTAssertFalse(mockMeter.isRunning)
        XCTAssertEqual(mockMeter.currentLevels, .silence)
    }

    func testMockMeter_simulateLevels() {
        // Given: Mock meter
        let levels = AudioLevels(systemLevel: 0.7, microphoneLevel: 0.3)

        // When: Simulate levels
        mockMeter.simulateLevels(levels)

        // Then: Should update levels
        XCTAssertEqual(mockMeter.currentLevels.systemLevel, 0.7)
        XCTAssertEqual(mockMeter.currentLevels.microphoneLevel, 0.3)
    }

    func testMockMeter_simulateSystemLevel() {
        // Given: Mock meter with existing levels
        mockMeter.simulateLevels(AudioLevels(systemLevel: 0.5, microphoneLevel: 0.5))

        // When: Simulate system level only
        mockMeter.simulateSystemLevel(0.9)

        // Then: Should update only system level
        XCTAssertEqual(mockMeter.currentLevels.systemLevel, 0.9)
        XCTAssertEqual(mockMeter.currentLevels.microphoneLevel, 0.5)
    }

    func testMockMeter_simulateMicrophoneLevel() {
        // Given: Mock meter with existing levels
        mockMeter.simulateLevels(AudioLevels(systemLevel: 0.5, microphoneLevel: 0.5))

        // When: Simulate microphone level only
        mockMeter.simulateMicrophoneLevel(0.1)

        // Then: Should update only microphone level
        XCTAssertEqual(mockMeter.currentLevels.systemLevel, 0.5)
        XCTAssertEqual(mockMeter.currentLevels.microphoneLevel, 0.1)
    }

    func testMockMeter_levelsPublisher() {
        // Given: Mock meter with publisher subscription
        let expectation = XCTestExpectation(description: "Receive levels")
        var receivedLevels: AudioLevels?

        mockMeter.levelsPublisher
            .dropFirst() // Skip initial value
            .sink { levels in
                receivedLevels = levels
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Simulate levels
        mockMeter.simulateLevels(AudioLevels(systemLevel: 0.8, microphoneLevel: 0.2))

        // Then: Should receive levels via publisher
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedLevels?.systemLevel, 0.8)
        XCTAssertEqual(receivedLevels?.microphoneLevel, 0.2)
    }

    func testMockMeter_reset() {
        // Given: Mock with state
        mockMeter.start()
        mockMeter.simulateLevels(AudioLevels(systemLevel: 0.8, microphoneLevel: 0.8))
        mockMeter.stop()

        // When: Reset
        mockMeter.reset()

        // Then: Should be reset
        XCTAssertEqual(mockMeter.startCallCount, 0)
        XCTAssertEqual(mockMeter.stopCallCount, 0)
        XCTAssertFalse(mockMeter.isRunning)
        XCTAssertEqual(mockMeter.currentLevels, .silence)
    }

    func testMockMeter_multipleStartStop() {
        // Given: Mock meter

        // When: Start and stop multiple times
        mockMeter.start()
        mockMeter.stop()
        mockMeter.start()
        mockMeter.stop()
        mockMeter.start()

        // Then: Should track all calls
        XCTAssertEqual(mockMeter.startCallCount, 3)
        XCTAssertEqual(mockMeter.stopCallCount, 2)
        XCTAssertTrue(mockMeter.isRunning)
    }
}
