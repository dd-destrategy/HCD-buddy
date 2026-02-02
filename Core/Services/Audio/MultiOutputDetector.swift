//
//  MultiOutputDetector.swift
//  HCD Interview Coach
//
//  Created by agent-e1 on 2026-02-01.
//  EPIC E1-S3: Multi-Output Device Detection
//

import Foundation
import CoreAudio

/// Status of Multi-Output Device configuration
enum MultiOutputStatus: Equatable {
    /// Multi-Output Device is properly configured with BlackHole and speakers
    case configured(deviceID: AudioDeviceID, blackHoleID: AudioDeviceID, speakerID: AudioDeviceID)

    /// Multi-Output Device exists but is not properly configured
    case notConfigured

    /// Multi-Output Device exists but BlackHole is not part of it
    case missingBlackHole

    /// Multi-Output Device exists but no speaker/output device is part of it
    case missingSpeakers

    /// No Multi-Output Device found
    case notFound
}

/// Detects Multi-Output Device configuration with BlackHole + speakers
class MultiOutputDetector {

    // MARK: - Public Methods

    /// Detects if a Multi-Output Device is configured with BlackHole and speakers
    /// - Returns: MultiOutputStatus indicating configuration state
    static func detectMultiOutputDevice() -> MultiOutputStatus {
        guard let devices = getAllAudioDevices() else {
            return .notFound
        }

        // Look for Multi-Output Device or Aggregate Device
        for deviceID in devices {
            if let deviceName = getDeviceName(deviceID: deviceID) {
                // Check if this is a Multi-Output or Aggregate device
                if isAggregateDevice(deviceID: deviceID) {
                    // Get sub-devices
                    if let subDevices = getAggregateSubDevices(deviceID: deviceID) {
                        return validateAggregateConfiguration(
                            deviceID: deviceID,
                            subDevices: subDevices
                        )
                    }
                }
            }
        }

        return .notFound
    }

    /// Gets the default output device
    /// - Returns: Audio device ID of the default output device
    static func getDefaultOutputDevice() -> AudioDeviceID? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )

        guard status == noErr else { return nil }

        return deviceID
    }

    /// Checks if the default output device is a Multi-Output Device with BlackHole
    /// - Returns: True if default output is properly configured for system audio capture
    static func isDefaultOutputConfigured() -> Bool {
        guard let defaultDevice = getDefaultOutputDevice() else {
            return false
        }

        let status = detectMultiOutputDevice()
        if case .configured(let deviceID, _, _) = status {
            return deviceID == defaultDevice
        }

        return false
    }

    // MARK: - Private Helper Methods

    /// Gets all audio devices on the system
    private static func getAllAudioDevices() -> [AudioDeviceID]? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var propertySize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        )

        guard status == noErr else { return nil }

        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &devices
        )

        guard status == noErr else { return nil }

        return devices
    }

    /// Gets the name of an audio device
    private static func getDeviceName(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceName: CFString = "" as CFString
        var propertySize = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceName
        )

        guard status == noErr else { return nil }

        return deviceName as String
    }

    /// Checks if a device is an aggregate device (includes Multi-Output devices)
    private static func isAggregateDevice(deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsAggregateDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var isAggregate: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<UInt32>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &isAggregate
        )

        guard status == noErr else { return false }

        return isAggregate == 1
    }

    /// Gets the sub-devices of an aggregate device
    private static func getAggregateSubDevices(deviceID: AudioDeviceID) -> [AudioDeviceID]? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioAggregateDevicePropertyActiveSubDeviceList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var propertySize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize
        )

        guard status == noErr else { return nil }

        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        guard deviceCount > 0 else { return nil }

        var subDevices = [AudioDeviceID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &subDevices
        )

        guard status == noErr else { return nil }

        return subDevices
    }

    /// Validates that an aggregate device contains BlackHole and speakers
    private static func validateAggregateConfiguration(
        deviceID: AudioDeviceID,
        subDevices: [AudioDeviceID]
    ) -> MultiOutputStatus {
        var blackHoleID: AudioDeviceID?
        var speakerID: AudioDeviceID?

        for subDeviceID in subDevices {
            if let name = getDeviceName(deviceID: subDeviceID) {
                // Check for BlackHole
                if name.contains("BlackHole") {
                    blackHoleID = subDeviceID
                }
                // Check for typical speaker/output devices
                else if name.contains("Built-in Output") ||
                        name.contains("External Headphones") ||
                        name.contains("AirPods") ||
                        name.contains("Speaker") ||
                        name.contains("Headphones") {
                    speakerID = subDeviceID
                }
            }
        }

        // Determine status based on what we found
        if let blackHole = blackHoleID, let speaker = speakerID {
            return .configured(deviceID: deviceID, blackHoleID: blackHole, speakerID: speaker)
        } else if blackHoleID == nil && speakerID != nil {
            return .missingBlackHole
        } else if blackHoleID != nil && speakerID == nil {
            return .missingSpeakers
        } else {
            return .notConfigured
        }
    }

    /// Gets detailed information about a Multi-Output Device
    static func getMultiOutputInfo(deviceID: AudioDeviceID) -> [String: Any]? {
        var info: [String: Any] = [:]

        info["name"] = getDeviceName(deviceID: deviceID)
        info["isAggregate"] = isAggregateDevice(deviceID: deviceID)

        if let subDevices = getAggregateSubDevices(deviceID: deviceID) {
            var subDeviceNames: [String] = []
            for subDeviceID in subDevices {
                if let name = getDeviceName(deviceID: subDeviceID) {
                    subDeviceNames.append(name)
                }
            }
            info["subDevices"] = subDeviceNames
            info["subDeviceCount"] = subDevices.count
        }

        return info
    }
}
