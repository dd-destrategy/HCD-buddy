import Foundation
import SwiftUI

// Note: SessionMode is defined in HCDInterviewCoach/Core/Models/SessionMode.swift
// This file uses that canonical definition which includes displayName, description, and feature flags

/// Central settings model backed by UserDefaults
/// Uses @AppStorage for automatic persistence and reactive updates
@MainActor
class AppSettings: ObservableObject {
    // MARK: - General Settings
    @AppStorage("defaultSessionMode")
    var defaultSessionMode: String = SessionMode.full.rawValue

    @AppStorage("launchAtLogin")
    var launchAtLogin: Bool = false

    @AppStorage("checkForUpdates")
    var checkForUpdates: Bool = true

    // MARK: - Audio Settings
    @AppStorage("currentAudioDeviceID")
    var currentAudioDeviceID: String = ""

    @AppStorage("audioInputDeviceID")
    var audioInputDeviceID: String = ""

    // MARK: - Coaching Settings
    @AppStorage("coachingEnabled")
    var coachingEnabled: Bool = true

    @AppStorage("autoDismissTime")
    var autoDismissTime: Double = 8.0

    @AppStorage("maxPromptsPerSession")
    var maxPromptsPerSession: Int = 3

    // MARK: - API Settings
    @AppStorage("hasAPIKey")
    var hasAPIKey: Bool = false

    @AppStorage("apiKeyLastFourCharacters")
    var apiKeyLastFourCharacters: String = ""

    // MARK: - Session Management
    @AppStorage("hasCompletedFirstSession")
    var hasCompletedFirstSession: Bool = false

    @AppStorage("hasCompletedAudioSetup")
    var hasCompletedAudioSetup: Bool = false

    // MARK: - Initialization
    init() {
        // Settings are automatically initialized from UserDefaults
    }

    // MARK: - Public Methods

    /// Reset all settings to defaults
    func resetToDefaults() {
        defaultSessionMode = SessionMode.full.rawValue
        launchAtLogin = false
        checkForUpdates = true
        coachingEnabled = true
        autoDismissTime = 8.0
        maxPromptsPerSession = 3
        // Note: API key and audio devices are not reset to preserve sensitive data
    }

    /// Get current session mode
    var sessionMode: SessionMode {
        SessionMode(rawValue: defaultSessionMode) ?? .full
    }

    /// Get formatted auto-dismiss time
    var autoDismissTimeFormatted: String {
        String(format: "%.0f seconds", autoDismissTime)
    }

    /// Check if an API key is configured
    var isAPIKeyConfigured: Bool {
        hasAPIKey && !apiKeyLastFourCharacters.isEmpty
    }
}

// MARK: - Keychain Access
// NOTE: Use KeychainService from HCDInterviewCoach/Core/Services/KeychainService.swift
// for secure storage with proper kSecAttrAccessibleWhenUnlocked protection
