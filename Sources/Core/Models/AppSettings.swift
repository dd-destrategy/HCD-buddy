import Foundation
import SwiftUI

/// Enumeration for session modes
enum SessionMode: String, CaseIterable {
    case full = "Full"
    case focusedTopics = "Focused Topics"
    case freeform = "Freeform"

    var displayName: String {
        self.rawValue
    }
}

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

// MARK: - Keychain Service for API Key Storage
/// Securely stores and retrieves API keys from the Keychain
@MainActor
class KeychainService {
    static let shared = KeychainService()

    private let serviceName = "com.hcdinterviewcoach.apikey"
    private let accountName = "openai"

    // MARK: - Public Methods

    /// Save API key to Keychain
    func saveAPIKey(_ key: String) throws {
        // Create query dictionary
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: key.data(using: .utf8) ?? Data()
        ]

        // Try to delete existing key first
        SecItemDelete(query as CFDictionary)

        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    /// Retrieve API key from Keychain
    func retrieveAPIKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.retrieveFailed(status: status)
        }

        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    /// Delete API key from Keychain
    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }

    /// Get masked API key display (shows last 4 characters)
    func getMaskedAPIKey(_ key: String) -> String {
        guard key.count > 4 else {
            return String(repeating: "•", count: max(1, key.count))
        }
        let lastFour = String(key.suffix(4))
        let maskedLength = key.count - 4
        return String(repeating: "•", count: maskedLength) + lastFour
    }
}

// MARK: - Keychain Errors
enum KeychainError: LocalizedError {
    case saveFailed(status: OSStatus)
    case retrieveFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save API key to Keychain"
        case .retrieveFailed:
            return "Failed to retrieve API key from Keychain"
        case .deleteFailed:
            return "Failed to delete API key from Keychain"
        }
    }
}
