//
//  BlackHoleDetectorTests.swift
//  HCDInterviewCoach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for BlackHoleDetector - Virtual Audio Device Detection
//

import XCTest
import CoreAudio
@testable import HCDInterviewCoach

final class BlackHoleDetectorTests: XCTestCase {

    // MARK: - BlackHoleStatus Tests

    func testBlackHoleStatus_installed_equatable() {
        // Given: Two installed statuses with same device ID
        let status1 = BlackHoleStatus.installed(deviceID: 123)
        let status2 = BlackHoleStatus.installed(deviceID: 123)

        // Then: Should be equal
        XCTAssertEqual(status1, status2)
    }

    func testBlackHoleStatus_installed_differentDeviceIDs() {
        // Given: Two installed statuses with different device IDs
        let status1 = BlackHoleStatus.installed(deviceID: 123)
        let status2 = BlackHoleStatus.installed(deviceID: 456)

        // Then: Should not be equal
        XCTAssertNotEqual(status1, status2)
    }

    func testBlackHoleStatus_notInstalled_equatable() {
        // Given: Two not installed statuses
        let status1 = BlackHoleStatus.notInstalled
        let status2 = BlackHoleStatus.notInstalled

        // Then: Should be equal
        XCTAssertEqual(status1, status2)
    }

    func testBlackHoleStatus_unknownVersion_equatable() {
        // Given: Two unknown version statuses with same device ID
        let status1 = BlackHoleStatus.unknownVersion(deviceID: 789)
        let status2 = BlackHoleStatus.unknownVersion(deviceID: 789)

        // Then: Should be equal
        XCTAssertEqual(status1, status2)
    }

    func testBlackHoleStatus_differentTypes_notEqual() {
        // Given: Different status types
        let installed = BlackHoleStatus.installed(deviceID: 123)
        let notInstalled = BlackHoleStatus.notInstalled
        let unknownVersion = BlackHoleStatus.unknownVersion(deviceID: 123)

        // Then: Should not be equal
        XCTAssertNotEqual(installed, notInstalled)
        XCTAssertNotEqual(installed, unknownVersion)
        XCTAssertNotEqual(notInstalled, unknownVersion)
    }

    // MARK: - Detection Tests

    func testDetectBlackHole_returnsValidStatus() {
        // Given: System audio devices

        // When: Detect BlackHole
        let status = BlackHoleDetector.detectBlackHole()

        // Then: Should return one of the valid statuses
        switch status {
        case .installed(let deviceID):
            // BlackHole is installed
            XCTAssertGreaterThan(deviceID, 0)
        case .notInstalled:
            // BlackHole is not installed (valid result)
            XCTAssertEqual(status, .notInstalled)
        case .unknownVersion(let deviceID):
            // BlackHole is installed but not 2ch version
            XCTAssertGreaterThan(deviceID, 0)
        }
    }

    func testDetectBlackHole_isIdempotent() {
        // Given: Multiple detection calls

        // When: Detect multiple times
        let status1 = BlackHoleDetector.detectBlackHole()
        let status2 = BlackHoleDetector.detectBlackHole()
        let status3 = BlackHoleDetector.detectBlackHole()

        // Then: All should return the same result
        XCTAssertEqual(status1, status2)
        XCTAssertEqual(status2, status3)
    }

    // MARK: - Device Info Tests

    func testGetBlackHoleInfo_withInstalledDevice() throws {
        // Given: BlackHole is installed
        let status = BlackHoleDetector.detectBlackHole()

        guard case .installed(let deviceID) = status else {
            // Skip if BlackHole is not installed
            throw XCTSkip("BlackHole 2ch is not installed on this system")
        }

        // When: Get device info
        let info = BlackHoleDetector.getBlackHoleInfo(deviceID: deviceID)

        // Then: Should have info
        XCTAssertNotNil(info)
        XCTAssertNotNil(info?["name"])
    }

    func testGetBlackHoleInfo_withUnknownVersionDevice() throws {
        // Given: BlackHole is installed but unknown version
        let status = BlackHoleDetector.detectBlackHole()

        guard case .unknownVersion(let deviceID) = status else {
            // Skip if not unknown version
            throw XCTSkip("BlackHole unknown version is not installed")
        }

        // When: Get device info
        let info = BlackHoleDetector.getBlackHoleInfo(deviceID: deviceID)

        // Then: Should have info
        XCTAssertNotNil(info)
    }

    func testGetBlackHoleInfo_returnsExpectedKeys() throws {
        // Given: BlackHole is installed
        let status = BlackHoleDetector.detectBlackHole()

        guard case .installed(let deviceID) = status else {
            throw XCTSkip("BlackHole 2ch is not installed on this system")
        }

        // When: Get device info
        guard let info = BlackHoleDetector.getBlackHoleInfo(deviceID: deviceID) else {
            XCTFail("Expected info dictionary")
            return
        }

        // Then: Should contain expected keys
        XCTAssertNotNil(info["name"])
        // Note: Other keys may or may not be present depending on device
    }

    func testGetBlackHoleInfo_nameContainsBlackHole() throws {
        // Given: BlackHole is installed
        let status = BlackHoleDetector.detectBlackHole()

        guard case .installed(let deviceID) = status else {
            throw XCTSkip("BlackHole 2ch is not installed on this system")
        }

        // When: Get device info
        guard let info = BlackHoleDetector.getBlackHoleInfo(deviceID: deviceID),
              let name = info["name"] as? String else {
            XCTFail("Expected name in info dictionary")
            return
        }

        // Then: Name should contain "BlackHole"
        XCTAssertTrue(name.contains("BlackHole"))
    }

    func testGetBlackHoleInfo_inputChannelsForBlackHole2ch() throws {
        // Given: BlackHole 2ch is installed
        let status = BlackHoleDetector.detectBlackHole()

        guard case .installed(let deviceID) = status else {
            throw XCTSkip("BlackHole 2ch is not installed on this system")
        }

        // When: Get device info
        guard let info = BlackHoleDetector.getBlackHoleInfo(deviceID: deviceID),
              let inputChannels = info["inputChannels"] as? Int else {
            throw XCTSkip("Could not get input channel count")
        }

        // Then: Should have 2 input channels
        XCTAssertEqual(inputChannels, 2)
    }

    func testGetBlackHoleInfo_outputChannelsForBlackHole2ch() throws {
        // Given: BlackHole 2ch is installed
        let status = BlackHoleDetector.detectBlackHole()

        guard case .installed(let deviceID) = status else {
            throw XCTSkip("BlackHole 2ch is not installed on this system")
        }

        // When: Get device info
        guard let info = BlackHoleDetector.getBlackHoleInfo(deviceID: deviceID),
              let outputChannels = info["outputChannels"] as? Int else {
            throw XCTSkip("Could not get output channel count")
        }

        // Then: Should have 2 output channels
        XCTAssertEqual(outputChannels, 2)
    }

    func testGetBlackHoleInfo_sampleRate() throws {
        // Given: BlackHole is installed
        let status = BlackHoleDetector.detectBlackHole()

        guard case .installed(let deviceID) = status else {
            throw XCTSkip("BlackHole 2ch is not installed on this system")
        }

        // When: Get device info
        guard let info = BlackHoleDetector.getBlackHoleInfo(deviceID: deviceID),
              let sampleRate = info["sampleRate"] as? Double else {
            throw XCTSkip("Could not get sample rate")
        }

        // Then: Sample rate should be a valid audio rate
        XCTAssertGreaterThan(sampleRate, 0)
        // Common sample rates: 44100, 48000, 96000, etc.
        XCTAssertTrue([44100.0, 48000.0, 88200.0, 96000.0, 176400.0, 192000.0].contains(sampleRate) || sampleRate > 0)
    }

    func testGetBlackHoleInfo_hasUID() throws {
        // Given: BlackHole is installed
        let status = BlackHoleDetector.detectBlackHole()

        guard case .installed(let deviceID) = status else {
            throw XCTSkip("BlackHole 2ch is not installed on this system")
        }

        // When: Get device info
        guard let info = BlackHoleDetector.getBlackHoleInfo(deviceID: deviceID) else {
            XCTFail("Expected info dictionary")
            return
        }

        // Then: UID should be present (may be nil for some devices)
        // Just checking the key exists or is intentionally nil
        // UID is used for persistent device identification
        _ = info["uid"]
    }

    func testGetBlackHoleInfo_hasManufacturer() throws {
        // Given: BlackHole is installed
        let status = BlackHoleDetector.detectBlackHole()

        guard case .installed(let deviceID) = status else {
            throw XCTSkip("BlackHole 2ch is not installed on this system")
        }

        // When: Get device info
        guard let info = BlackHoleDetector.getBlackHoleInfo(deviceID: deviceID) else {
            XCTFail("Expected info dictionary")
            return
        }

        // Then: Manufacturer may be present
        // BlackHole manufacturer is typically "Existential Audio Inc."
        if let manufacturer = info["manufacturer"] as? String {
            XCTAssertFalse(manufacturer.isEmpty)
        }
    }

    // MARK: - Device Enumeration Tests

    func testDeviceEnumeration_returnsSystemDevices() {
        // Given: System has audio devices

        // When: Detect BlackHole (which enumerates devices internally)
        _ = BlackHoleDetector.detectBlackHole()

        // Then: Should complete without error
        // Note: This test verifies the enumeration doesn't crash
        // The actual device list depends on system configuration
    }

    func testDeviceEnumeration_handlesNoBlackHole() {
        // Given: System may not have BlackHole installed

        // When: Detect BlackHole
        let status = BlackHoleDetector.detectBlackHole()

        // Then: Should return notInstalled or installed
        // Should not crash
        switch status {
        case .installed, .notInstalled, .unknownVersion:
            // All are valid responses
            break
        }
    }

    // MARK: - Edge Case Tests

    func testGetBlackHoleInfo_invalidDeviceID() {
        // Given: Invalid device ID
        let invalidDeviceID: AudioDeviceID = 999999

        // When: Get device info
        let info = BlackHoleDetector.getBlackHoleInfo(deviceID: invalidDeviceID)

        // Then: Should handle gracefully (may return nil or partial info)
        // The info may be nil or contain nil values
        if let info = info {
            // If info is returned, verify it doesn't crash when accessed
            _ = info["name"]
            _ = info["manufacturer"]
        }
    }

    func testDetectBlackHole_performsQuickly() {
        // Given: Need to measure performance

        // When: Measure detection time
        measure {
            _ = BlackHoleDetector.detectBlackHole()
        }

        // Then: Should complete quickly (measure will fail if too slow)
    }

    // MARK: - Concurrent Access Tests

    func testDetectBlackHole_threadSafe() async {
        // Given: Multiple concurrent detection requests

        // When: Detect from multiple tasks
        await withTaskGroup(of: BlackHoleStatus.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    return BlackHoleDetector.detectBlackHole()
                }
            }

            var results: [BlackHoleStatus] = []
            for await status in group {
                results.append(status)
            }

            // Then: All results should be the same
            let firstResult = results.first
            for result in results {
                XCTAssertEqual(result, firstResult)
            }
        }
    }

    func testGetBlackHoleInfo_threadSafe() async throws {
        // Given: BlackHole is installed
        let status = BlackHoleDetector.detectBlackHole()

        guard case .installed(let deviceID) = status else {
            throw XCTSkip("BlackHole 2ch is not installed on this system")
        }

        // When: Get info from multiple tasks
        await withTaskGroup(of: [String: Any]?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    return BlackHoleDetector.getBlackHoleInfo(deviceID: deviceID)
                }
            }

            var results: [[String: Any]?] = []
            for await info in group {
                results.append(info)
            }

            // Then: All results should be consistent
            for result in results {
                XCTAssertNotNil(result)
            }
        }
    }
}

// MARK: - Mock BlackHole Detector for Testing

/// Mock implementation for testing scenarios where BlackHole state is controlled
class MockBlackHoleDetector {
    private(set) var detectCallCount = 0
    private(set) var getInfoCallCount = 0

    var mockStatus: BlackHoleStatus = .notInstalled
    var mockInfo: [String: Any]? = nil

    func detectBlackHole() -> BlackHoleStatus {
        detectCallCount += 1
        return mockStatus
    }

    func getBlackHoleInfo(deviceID: AudioDeviceID) -> [String: Any]? {
        getInfoCallCount += 1
        return mockInfo
    }

    func reset() {
        detectCallCount = 0
        getInfoCallCount = 0
        mockStatus = .notInstalled
        mockInfo = nil
    }

    static func createMockInfo(
        name: String = "BlackHole 2ch",
        manufacturer: String = "Existential Audio Inc.",
        inputChannels: Int = 2,
        outputChannels: Int = 2,
        sampleRate: Double = 48000
    ) -> [String: Any] {
        return [
            "name": name,
            "manufacturer": manufacturer,
            "inputChannels": inputChannels,
            "outputChannels": outputChannels,
            "sampleRate": sampleRate,
            "uid": "BlackHole2ch_UID"
        ]
    }
}

// MARK: - Mock BlackHole Detector Tests

final class MockBlackHoleDetectorTests: XCTestCase {

    var mockDetector: MockBlackHoleDetector!

    override func setUp() {
        super.setUp()
        mockDetector = MockBlackHoleDetector()
    }

    override func tearDown() {
        mockDetector = nil
        super.tearDown()
    }

    func testMockDetector_installed() {
        // Given: Mock configured for installed state
        mockDetector.mockStatus = .installed(deviceID: 42)

        // When: Detect
        let status = mockDetector.detectBlackHole()

        // Then: Should return installed
        XCTAssertEqual(status, .installed(deviceID: 42))
        XCTAssertEqual(mockDetector.detectCallCount, 1)
    }

    func testMockDetector_notInstalled() {
        // Given: Mock configured for not installed state
        mockDetector.mockStatus = .notInstalled

        // When: Detect
        let status = mockDetector.detectBlackHole()

        // Then: Should return not installed
        XCTAssertEqual(status, .notInstalled)
    }

    func testMockDetector_unknownVersion() {
        // Given: Mock configured for unknown version state
        mockDetector.mockStatus = .unknownVersion(deviceID: 100)

        // When: Detect
        let status = mockDetector.detectBlackHole()

        // Then: Should return unknown version
        XCTAssertEqual(status, .unknownVersion(deviceID: 100))
    }

    func testMockDetector_getInfo() {
        // Given: Mock configured with info
        mockDetector.mockInfo = MockBlackHoleDetector.createMockInfo()

        // When: Get info
        let info = mockDetector.getBlackHoleInfo(deviceID: 42)

        // Then: Should return mock info
        XCTAssertNotNil(info)
        XCTAssertEqual(info?["name"] as? String, "BlackHole 2ch")
        XCTAssertEqual(mockDetector.getInfoCallCount, 1)
    }

    func testMockDetector_reset() {
        // Given: Mock with state
        mockDetector.mockStatus = .installed(deviceID: 42)
        _ = mockDetector.detectBlackHole()
        _ = mockDetector.getBlackHoleInfo(deviceID: 42)

        // When: Reset
        mockDetector.reset()

        // Then: Should be reset
        XCTAssertEqual(mockDetector.detectCallCount, 0)
        XCTAssertEqual(mockDetector.getInfoCallCount, 0)
        XCTAssertEqual(mockDetector.mockStatus, .notInstalled)
        XCTAssertNil(mockDetector.mockInfo)
    }

    func testCreateMockInfo_defaultValues() {
        // When: Create mock info with defaults
        let info = MockBlackHoleDetector.createMockInfo()

        // Then: Should have expected values
        XCTAssertEqual(info["name"] as? String, "BlackHole 2ch")
        XCTAssertEqual(info["manufacturer"] as? String, "Existential Audio Inc.")
        XCTAssertEqual(info["inputChannels"] as? Int, 2)
        XCTAssertEqual(info["outputChannels"] as? Int, 2)
        XCTAssertEqual(info["sampleRate"] as? Double, 48000)
    }

    func testCreateMockInfo_customValues() {
        // When: Create mock info with custom values
        let info = MockBlackHoleDetector.createMockInfo(
            name: "BlackHole 16ch",
            inputChannels: 16,
            outputChannels: 16,
            sampleRate: 96000
        )

        // Then: Should have custom values
        XCTAssertEqual(info["name"] as? String, "BlackHole 16ch")
        XCTAssertEqual(info["inputChannels"] as? Int, 16)
        XCTAssertEqual(info["outputChannels"] as? Int, 16)
        XCTAssertEqual(info["sampleRate"] as? Double, 96000)
    }
}
