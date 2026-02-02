//
//  BlackHoleDetector.swift
//  HCD Interview Coach
//
//  Created by agent-e1 on 2026-02-01.
//  EPIC E1-S2: BlackHole Detection
//

import Foundation
import CoreAudio

/// Status of BlackHole virtual audio device installation
enum BlackHoleStatus: Equatable {
    /// BlackHole 2ch is installed and detected
    case installed(deviceID: AudioDeviceID)

    /// BlackHole is not installed on this system
    case notInstalled

    /// BlackHole is installed but version is unknown or unexpected
    case unknownVersion(deviceID: AudioDeviceID)
}

/// Detects BlackHole 2ch virtual audio device installation
class BlackHoleDetector {

    // MARK: - Public Methods

    /// Detects if BlackHole 2ch is installed on the system
    /// - Returns: BlackHoleStatus indicating installation state
    static func detectBlackHole() -> BlackHoleStatus {
        guard let devices = getAllAudioDevices() else {
            return .notInstalled
        }

        // Look for BlackHole 2ch specifically
        for deviceID in devices {
            if let deviceName = getDeviceName(deviceID: deviceID) {
                // BlackHole 2ch is the standard name
                if deviceName.contains("BlackHole 2ch") {
                    return .installed(deviceID: deviceID)
                }
                // Also check for just "BlackHole" but flag as unknown version
                if deviceName.contains("BlackHole") && !deviceName.contains("2ch") {
                    return .unknownVersion(deviceID: deviceID)
                }
            }
        }

        return .notInstalled
    }

    /// Gets detailed information about a BlackHole device
    /// - Parameter deviceID: The audio device ID
    /// - Returns: Dictionary with device information
    static func getBlackHoleInfo(deviceID: AudioDeviceID) -> [String: Any]? {
        var info: [String: Any] = [:]

        info["name"] = getDeviceName(deviceID: deviceID)
        info["manufacturer"] = getDeviceManufacturer(deviceID: deviceID)
        info["uid"] = getDeviceUID(deviceID: deviceID)

        if let channels = getDeviceChannelCount(deviceID: deviceID, scope: kAudioDevicePropertyScopeInput) {
            info["inputChannels"] = channels
        }

        if let channels = getDeviceChannelCount(deviceID: deviceID, scope: kAudioDevicePropertyScopeOutput) {
            info["outputChannels"] = channels
        }

        if let sampleRate = getDeviceSampleRate(deviceID: deviceID) {
            info["sampleRate"] = sampleRate
        }

        return info
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

    /// Gets the manufacturer of an audio device
    private static func getDeviceManufacturer(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceManufacturerCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var manufacturer: CFString = "" as CFString
        var propertySize = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &manufacturer
        )

        guard status == noErr else { return nil }

        return manufacturer as String
    }

    /// Gets the UID of an audio device
    private static func getDeviceUID(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var uid: CFString = "" as CFString
        var propertySize = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &uid
        )

        guard status == noErr else { return nil }

        return uid as String
    }

    /// Gets the channel count for an audio device
    private static func getDeviceChannelCount(deviceID: AudioDeviceID, scope: AudioObjectPropertyScope) -> Int? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
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

        let bufferListPointer = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferListPointer.deallocate() }

        status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            bufferListPointer
        )

        guard status == noErr else { return nil }

        let bufferList = bufferListPointer.pointee
        var channelCount = 0

        let bufferCount = Int(bufferList.mNumberBuffers)
        let bufferPointer = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(bufferListPointer))

        for i in 0..<bufferCount {
            channelCount += Int(bufferPointer[i].mNumberChannels)
        }

        return channelCount
    }

    /// Gets the current sample rate of an audio device
    private static func getDeviceSampleRate(deviceID: AudioDeviceID) -> Double? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var sampleRate: Float64 = 0.0
        var propertySize = UInt32(MemoryLayout<Float64>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &sampleRate
        )

        guard status == noErr else { return nil }

        return sampleRate
    }
}
