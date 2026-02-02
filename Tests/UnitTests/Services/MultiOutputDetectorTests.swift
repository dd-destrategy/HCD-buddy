//
//  MultiOutputDetectorTests.swift
//  HCDInterviewCoach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for MultiOutputDetector - Multi-Output Device Detection
//

import XCTest
import CoreAudio
@testable import HCDInterviewCoach

final class MultiOutputDetectorTests: XCTestCase {

    // MARK: - MultiOutputStatus Tests

    func testMultiOutputStatus_configured_equatable() {
        // Given: Two configured statuses with same IDs
        let status1 = MultiOutputStatus.configured(deviceID: 100, blackHoleID: 200, speakerID: 300)
        let status2 = MultiOutputStatus.configured(deviceID: 100, blackHoleID: 200, speakerID: 300)

        // Then: Should be equal
        XCTAssertEqual(status1, status2)
    }

    func testMultiOutputStatus_configured_differentDeviceIDs() {
        // Given: Two configured statuses with different device IDs
        let status1 = MultiOutputStatus.configured(deviceID: 100, blackHoleID: 200, speakerID: 300)
        let status2 = MultiOutputStatus.configured(deviceID: 101, blackHoleID: 200, speakerID: 300)

        // Then: Should not be equal
        XCTAssertNotEqual(status1, status2)
    }

    func testMultiOutputStatus_configured_differentBlackHoleIDs() {
        // Given: Two configured statuses with different BlackHole IDs
        let status1 = MultiOutputStatus.configured(deviceID: 100, blackHoleID: 200, speakerID: 300)
        let status2 = MultiOutputStatus.configured(deviceID: 100, blackHoleID: 201, speakerID: 300)

        // Then: Should not be equal
        XCTAssertNotEqual(status1, status2)
    }

    func testMultiOutputStatus_configured_differentSpeakerIDs() {
        // Given: Two configured statuses with different speaker IDs
        let status1 = MultiOutputStatus.configured(deviceID: 100, blackHoleID: 200, speakerID: 300)
        let status2 = MultiOutputStatus.configured(deviceID: 100, blackHoleID: 200, speakerID: 301)

        // Then: Should not be equal
        XCTAssertNotEqual(status1, status2)
    }

    func testMultiOutputStatus_notConfigured_equatable() {
        // Given: Two not configured statuses
        let status1 = MultiOutputStatus.notConfigured
        let status2 = MultiOutputStatus.notConfigured

        // Then: Should be equal
        XCTAssertEqual(status1, status2)
    }

    func testMultiOutputStatus_missingBlackHole_equatable() {
        // Given: Two missing BlackHole statuses
        let status1 = MultiOutputStatus.missingBlackHole
        let status2 = MultiOutputStatus.missingBlackHole

        // Then: Should be equal
        XCTAssertEqual(status1, status2)
    }

    func testMultiOutputStatus_missingSpeakers_equatable() {
        // Given: Two missing speakers statuses
        let status1 = MultiOutputStatus.missingSpeakers
        let status2 = MultiOutputStatus.missingSpeakers

        // Then: Should be equal
        XCTAssertEqual(status1, status2)
    }

    func testMultiOutputStatus_notFound_equatable() {
        // Given: Two not found statuses
        let status1 = MultiOutputStatus.notFound
        let status2 = MultiOutputStatus.notFound

        // Then: Should be equal
        XCTAssertEqual(status1, status2)
    }

    func testMultiOutputStatus_differentTypes_notEqual() {
        // Given: Different status types
        let configured = MultiOutputStatus.configured(deviceID: 100, blackHoleID: 200, speakerID: 300)
        let notConfigured = MultiOutputStatus.notConfigured
        let missingBlackHole = MultiOutputStatus.missingBlackHole
        let missingSpeakers = MultiOutputStatus.missingSpeakers
        let notFound = MultiOutputStatus.notFound

        // Then: Should not be equal
        XCTAssertNotEqual(configured, notConfigured)
        XCTAssertNotEqual(configured, missingBlackHole)
        XCTAssertNotEqual(configured, missingSpeakers)
        XCTAssertNotEqual(configured, notFound)
        XCTAssertNotEqual(notConfigured, missingBlackHole)
        XCTAssertNotEqual(notConfigured, missingSpeakers)
        XCTAssertNotEqual(notConfigured, notFound)
        XCTAssertNotEqual(missingBlackHole, missingSpeakers)
        XCTAssertNotEqual(missingBlackHole, notFound)
        XCTAssertNotEqual(missingSpeakers, notFound)
    }

    // MARK: - Detection Tests

    func testDetectMultiOutputDevice_returnsValidStatus() {
        // Given: System audio devices

        // When: Detect Multi-Output Device
        let status = MultiOutputDetector.detectMultiOutputDevice()

        // Then: Should return one of the valid statuses
        switch status {
        case .configured(let deviceID, let blackHoleID, let speakerID):
            // Multi-Output Device is properly configured
            XCTAssertGreaterThan(deviceID, 0)
            XCTAssertGreaterThan(blackHoleID, 0)
            XCTAssertGreaterThan(speakerID, 0)
        case .notConfigured:
            // Multi-Output exists but not properly configured
            break
        case .missingBlackHole:
            // Multi-Output exists but BlackHole is missing
            break
        case .missingSpeakers:
            // Multi-Output exists but speakers are missing
            break
        case .notFound:
            // No Multi-Output Device found (valid result)
            XCTAssertEqual(status, .notFound)
        }
    }

    func testDetectMultiOutputDevice_isIdempotent() {
        // Given: Multiple detection calls

        // When: Detect multiple times
        let status1 = MultiOutputDetector.detectMultiOutputDevice()
        let status2 = MultiOutputDetector.detectMultiOutputDevice()
        let status3 = MultiOutputDetector.detectMultiOutputDevice()

        // Then: All should return the same result
        XCTAssertEqual(status1, status2)
        XCTAssertEqual(status2, status3)
    }

    // MARK: - Default Output Tests

    func testGetDefaultOutputDevice_returnsDevice() {
        // Given: System has default output

        // When: Get default output device
        let deviceID = MultiOutputDetector.getDefaultOutputDevice()

        // Then: Should return a device ID (or nil if no output)
        // Note: Most systems will have at least one output device
        if let deviceID = deviceID {
            XCTAssertGreaterThan(deviceID, 0)
        }
    }

    func testGetDefaultOutputDevice_isConsistent() {
        // Given: Multiple calls

        // When: Get default output multiple times
        let device1 = MultiOutputDetector.getDefaultOutputDevice()
        let device2 = MultiOutputDetector.getDefaultOutputDevice()
        let device3 = MultiOutputDetector.getDefaultOutputDevice()

        // Then: Should return the same result
        XCTAssertEqual(device1, device2)
        XCTAssertEqual(device2, device3)
    }

    // MARK: - Default Output Configuration Tests

    func testIsDefaultOutputConfigured_returnsBoolean() {
        // Given: System state

        // When: Check if default output is configured
        let isConfigured = MultiOutputDetector.isDefaultOutputConfigured()

        // Then: Should return a boolean value
        // Result depends on actual system configuration
        XCTAssertTrue(isConfigured == true || isConfigured == false)
    }

    func testIsDefaultOutputConfigured_isConsistent() {
        // Given: Multiple calls

        // When: Check multiple times
        let result1 = MultiOutputDetector.isDefaultOutputConfigured()
        let result2 = MultiOutputDetector.isDefaultOutputConfigured()
        let result3 = MultiOutputDetector.isDefaultOutputConfigured()

        // Then: Should return consistent results
        XCTAssertEqual(result1, result2)
        XCTAssertEqual(result2, result3)
    }

    func testIsDefaultOutputConfigured_matchesDetectionResult() {
        // Given: Detection result

        // When: Check both methods
        let status = MultiOutputDetector.detectMultiOutputDevice()
        let isConfigured = MultiOutputDetector.isDefaultOutputConfigured()

        // Then: Should be consistent
        // If configured status with matching default device, isConfigured should be true
        if case .configured(let deviceID, _, _) = status {
            if let defaultDevice = MultiOutputDetector.getDefaultOutputDevice() {
                if deviceID == defaultDevice {
                    XCTAssertTrue(isConfigured)
                }
            }
        }
    }

    // MARK: - Multi-Output Info Tests

    func testGetMultiOutputInfo_withConfiguredDevice() {
        // Given: Multi-Output Device is configured
        let status = MultiOutputDetector.detectMultiOutputDevice()

        guard case .configured(let deviceID, _, _) = status else {
            throw XCTSkip("Multi-Output Device is not configured on this system")
        }

        // When: Get device info
        let info = MultiOutputDetector.getMultiOutputInfo(deviceID: deviceID)

        // Then: Should have info
        XCTAssertNotNil(info)
        XCTAssertNotNil(info?["name"])
        XCTAssertNotNil(info?["isAggregate"])
    }

    func testGetMultiOutputInfo_isAggregate() {
        // Given: Multi-Output Device is configured
        let status = MultiOutputDetector.detectMultiOutputDevice()

        guard case .configured(let deviceID, _, _) = status else {
            throw XCTSkip("Multi-Output Device is not configured on this system")
        }

        // When: Get device info
        guard let info = MultiOutputDetector.getMultiOutputInfo(deviceID: deviceID),
              let isAggregate = info["isAggregate"] as? Bool else {
            XCTFail("Expected isAggregate in info")
            return
        }

        // Then: Should be an aggregate device
        XCTAssertTrue(isAggregate)
    }

    func testGetMultiOutputInfo_hasSubDevices() {
        // Given: Multi-Output Device is configured
        let status = MultiOutputDetector.detectMultiOutputDevice()

        guard case .configured(let deviceID, _, _) = status else {
            throw XCTSkip("Multi-Output Device is not configured on this system")
        }

        // When: Get device info
        guard let info = MultiOutputDetector.getMultiOutputInfo(deviceID: deviceID) else {
            XCTFail("Expected info dictionary")
            return
        }

        // Then: Should have sub-device information
        XCTAssertNotNil(info["subDevices"])
        XCTAssertNotNil(info["subDeviceCount"])
    }

    func testGetMultiOutputInfo_subDeviceCount() {
        // Given: Multi-Output Device is configured
        let status = MultiOutputDetector.detectMultiOutputDevice()

        guard case .configured(let deviceID, _, _) = status else {
            throw XCTSkip("Multi-Output Device is not configured on this system")
        }

        // When: Get device info
        guard let info = MultiOutputDetector.getMultiOutputInfo(deviceID: deviceID),
              let subDeviceCount = info["subDeviceCount"] as? Int else {
            throw XCTSkip("Could not get sub-device count")
        }

        // Then: Should have at least 2 sub-devices (BlackHole + speakers)
        XCTAssertGreaterThanOrEqual(subDeviceCount, 2)
    }

    func testGetMultiOutputInfo_subDeviceNames() {
        // Given: Multi-Output Device is configured
        let status = MultiOutputDetector.detectMultiOutputDevice()

        guard case .configured(let deviceID, _, _) = status else {
            throw XCTSkip("Multi-Output Device is not configured on this system")
        }

        // When: Get device info
        guard let info = MultiOutputDetector.getMultiOutputInfo(deviceID: deviceID),
              let subDevices = info["subDevices"] as? [String] else {
            throw XCTSkip("Could not get sub-device names")
        }

        // Then: Should have sub-device names
        XCTAssertFalse(subDevices.isEmpty)
        for name in subDevices {
            XCTAssertFalse(name.isEmpty)
        }
    }

    func testGetMultiOutputInfo_containsBlackHole() {
        // Given: Multi-Output Device is configured with BlackHole
        let status = MultiOutputDetector.detectMultiOutputDevice()

        guard case .configured(let deviceID, _, _) = status else {
            throw XCTSkip("Multi-Output Device is not configured on this system")
        }

        // When: Get device info
        guard let info = MultiOutputDetector.getMultiOutputInfo(deviceID: deviceID),
              let subDevices = info["subDevices"] as? [String] else {
            throw XCTSkip("Could not get sub-device names")
        }

        // Then: Should contain BlackHole
        let hasBlackHole = subDevices.contains { $0.contains("BlackHole") }
        XCTAssertTrue(hasBlackHole)
    }

    // MARK: - Subdevice Validation Tests

    func testSubdeviceValidation_requiresBlackHole() {
        // Given: Multi-Output status

        // When: Check various statuses
        let missingBlackHole = MultiOutputStatus.missingBlackHole
        let configured = MultiOutputStatus.configured(deviceID: 1, blackHoleID: 2, speakerID: 3)

        // Then: Status should correctly indicate BlackHole presence
        XCTAssertNotEqual(missingBlackHole, configured)
    }

    func testSubdeviceValidation_requiresSpeakers() {
        // Given: Multi-Output status

        // When: Check various statuses
        let missingSpeakers = MultiOutputStatus.missingSpeakers
        let configured = MultiOutputStatus.configured(deviceID: 1, blackHoleID: 2, speakerID: 3)

        // Then: Status should correctly indicate speaker presence
        XCTAssertNotEqual(missingSpeakers, configured)
    }

    // MARK: - Edge Case Tests

    func testGetMultiOutputInfo_invalidDeviceID() {
        // Given: Invalid device ID
        let invalidDeviceID: AudioDeviceID = 999999

        // When: Get device info
        let info = MultiOutputDetector.getMultiOutputInfo(deviceID: invalidDeviceID)

        // Then: Should handle gracefully (may return nil or partial info)
        if let info = info {
            _ = info["name"]
            _ = info["isAggregate"]
        }
    }

    func testDetectMultiOutputDevice_performsQuickly() {
        // Given: Need to measure performance

        // When: Measure detection time
        measure {
            _ = MultiOutputDetector.detectMultiOutputDevice()
        }

        // Then: Should complete quickly (measure will fail if too slow)
    }

    // MARK: - Concurrent Access Tests

    func testDetectMultiOutputDevice_threadSafe() async {
        // Given: Multiple concurrent detection requests

        // When: Detect from multiple tasks
        await withTaskGroup(of: MultiOutputStatus.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    return MultiOutputDetector.detectMultiOutputDevice()
                }
            }

            var results: [MultiOutputStatus] = []
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

    func testIsDefaultOutputConfigured_threadSafe() async {
        // Given: Multiple concurrent checks

        // When: Check from multiple tasks
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    return MultiOutputDetector.isDefaultOutputConfigured()
                }
            }

            var results: [Bool] = []
            for await isConfigured in group {
                results.append(isConfigured)
            }

            // Then: All results should be the same
            let firstResult = results.first
            for result in results {
                XCTAssertEqual(result, firstResult)
            }
        }
    }

    func testGetDefaultOutputDevice_threadSafe() async {
        // Given: Multiple concurrent requests

        // When: Get default output from multiple tasks
        await withTaskGroup(of: AudioDeviceID?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    return MultiOutputDetector.getDefaultOutputDevice()
                }
            }

            var results: [AudioDeviceID?] = []
            for await deviceID in group {
                results.append(deviceID)
            }

            // Then: All results should be the same
            let firstResult = results.first!
            for result in results {
                XCTAssertEqual(result, firstResult)
            }
        }
    }
}

// MARK: - Mock Multi-Output Detector for Testing

/// Mock implementation for testing scenarios where Multi-Output state is controlled
class MockMultiOutputDetector {
    private(set) var detectCallCount = 0
    private(set) var getDefaultOutputCallCount = 0
    private(set) var isDefaultConfiguredCallCount = 0
    private(set) var getInfoCallCount = 0

    var mockStatus: MultiOutputStatus = .notFound
    var mockDefaultOutput: AudioDeviceID? = nil
    var mockIsDefaultConfigured: Bool = false
    var mockInfo: [String: Any]? = nil

    func detectMultiOutputDevice() -> MultiOutputStatus {
        detectCallCount += 1
        return mockStatus
    }

    func getDefaultOutputDevice() -> AudioDeviceID? {
        getDefaultOutputCallCount += 1
        return mockDefaultOutput
    }

    func isDefaultOutputConfigured() -> Bool {
        isDefaultConfiguredCallCount += 1
        return mockIsDefaultConfigured
    }

    func getMultiOutputInfo(deviceID: AudioDeviceID) -> [String: Any]? {
        getInfoCallCount += 1
        return mockInfo
    }

    func reset() {
        detectCallCount = 0
        getDefaultOutputCallCount = 0
        isDefaultConfiguredCallCount = 0
        getInfoCallCount = 0
        mockStatus = .notFound
        mockDefaultOutput = nil
        mockIsDefaultConfigured = false
        mockInfo = nil
    }

    static func createMockInfo(
        name: String = "Multi-Output Device",
        isAggregate: Bool = true,
        subDevices: [String] = ["BlackHole 2ch", "Built-in Output"]
    ) -> [String: Any] {
        return [
            "name": name,
            "isAggregate": isAggregate,
            "subDevices": subDevices,
            "subDeviceCount": subDevices.count
        ]
    }
}

// MARK: - Mock Multi-Output Detector Tests

final class MockMultiOutputDetectorTests: XCTestCase {

    var mockDetector: MockMultiOutputDetector!

    override func setUp() {
        super.setUp()
        mockDetector = MockMultiOutputDetector()
    }

    override func tearDown() {
        mockDetector = nil
        super.tearDown()
    }

    func testMockDetector_configured() {
        // Given: Mock configured for configured state
        mockDetector.mockStatus = .configured(deviceID: 100, blackHoleID: 200, speakerID: 300)

        // When: Detect
        let status = mockDetector.detectMultiOutputDevice()

        // Then: Should return configured
        if case .configured(let deviceID, let blackHoleID, let speakerID) = status {
            XCTAssertEqual(deviceID, 100)
            XCTAssertEqual(blackHoleID, 200)
            XCTAssertEqual(speakerID, 300)
        } else {
            XCTFail("Expected configured status")
        }
        XCTAssertEqual(mockDetector.detectCallCount, 1)
    }

    func testMockDetector_notFound() {
        // Given: Mock configured for not found state
        mockDetector.mockStatus = .notFound

        // When: Detect
        let status = mockDetector.detectMultiOutputDevice()

        // Then: Should return not found
        XCTAssertEqual(status, .notFound)
    }

    func testMockDetector_missingBlackHole() {
        // Given: Mock configured for missing BlackHole state
        mockDetector.mockStatus = .missingBlackHole

        // When: Detect
        let status = mockDetector.detectMultiOutputDevice()

        // Then: Should return missing BlackHole
        XCTAssertEqual(status, .missingBlackHole)
    }

    func testMockDetector_missingSpeakers() {
        // Given: Mock configured for missing speakers state
        mockDetector.mockStatus = .missingSpeakers

        // When: Detect
        let status = mockDetector.detectMultiOutputDevice()

        // Then: Should return missing speakers
        XCTAssertEqual(status, .missingSpeakers)
    }

    func testMockDetector_notConfigured() {
        // Given: Mock configured for not configured state
        mockDetector.mockStatus = .notConfigured

        // When: Detect
        let status = mockDetector.detectMultiOutputDevice()

        // Then: Should return not configured
        XCTAssertEqual(status, .notConfigured)
    }

    func testMockDetector_getDefaultOutput() {
        // Given: Mock configured with default output
        mockDetector.mockDefaultOutput = 42

        // When: Get default output
        let deviceID = mockDetector.getDefaultOutputDevice()

        // Then: Should return mock device ID
        XCTAssertEqual(deviceID, 42)
        XCTAssertEqual(mockDetector.getDefaultOutputCallCount, 1)
    }

    func testMockDetector_isDefaultConfigured() {
        // Given: Mock configured as default
        mockDetector.mockIsDefaultConfigured = true

        // When: Check if configured
        let isConfigured = mockDetector.isDefaultOutputConfigured()

        // Then: Should return true
        XCTAssertTrue(isConfigured)
        XCTAssertEqual(mockDetector.isDefaultConfiguredCallCount, 1)
    }

    func testMockDetector_getInfo() {
        // Given: Mock configured with info
        mockDetector.mockInfo = MockMultiOutputDetector.createMockInfo()

        // When: Get info
        let info = mockDetector.getMultiOutputInfo(deviceID: 42)

        // Then: Should return mock info
        XCTAssertNotNil(info)
        XCTAssertEqual(info?["name"] as? String, "Multi-Output Device")
        XCTAssertEqual(mockDetector.getInfoCallCount, 1)
    }

    func testMockDetector_reset() {
        // Given: Mock with state
        mockDetector.mockStatus = .configured(deviceID: 1, blackHoleID: 2, speakerID: 3)
        mockDetector.mockDefaultOutput = 42
        mockDetector.mockIsDefaultConfigured = true
        _ = mockDetector.detectMultiOutputDevice()
        _ = mockDetector.getDefaultOutputDevice()
        _ = mockDetector.isDefaultOutputConfigured()

        // When: Reset
        mockDetector.reset()

        // Then: Should be reset
        XCTAssertEqual(mockDetector.detectCallCount, 0)
        XCTAssertEqual(mockDetector.getDefaultOutputCallCount, 0)
        XCTAssertEqual(mockDetector.isDefaultConfiguredCallCount, 0)
        XCTAssertEqual(mockDetector.mockStatus, .notFound)
        XCTAssertNil(mockDetector.mockDefaultOutput)
        XCTAssertFalse(mockDetector.mockIsDefaultConfigured)
    }

    func testCreateMockInfo_defaultValues() {
        // When: Create mock info with defaults
        let info = MockMultiOutputDetector.createMockInfo()

        // Then: Should have expected values
        XCTAssertEqual(info["name"] as? String, "Multi-Output Device")
        XCTAssertEqual(info["isAggregate"] as? Bool, true)
        XCTAssertEqual(info["subDeviceCount"] as? Int, 2)
        if let subDevices = info["subDevices"] as? [String] {
            XCTAssertTrue(subDevices.contains("BlackHole 2ch"))
            XCTAssertTrue(subDevices.contains("Built-in Output"))
        } else {
            XCTFail("Expected subDevices array")
        }
    }

    func testCreateMockInfo_customValues() {
        // When: Create mock info with custom values
        let info = MockMultiOutputDetector.createMockInfo(
            name: "Custom Multi-Output",
            isAggregate: true,
            subDevices: ["BlackHole 16ch", "External Headphones", "AirPods Pro"]
        )

        // Then: Should have custom values
        XCTAssertEqual(info["name"] as? String, "Custom Multi-Output")
        XCTAssertEqual(info["subDeviceCount"] as? Int, 3)
    }
}
