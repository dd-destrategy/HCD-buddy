import Foundation
import Security

/// Service for secure storage of sensitive data using macOS Keychain
final class KeychainService: KeychainServiceProtocol {
    static let shared = KeychainService()

    private let service = "com.hcdinterviewcoach.app"

    private init() {}

    /// Redact key name for secure logging - shows only first 3 characters
    /// This prevents sensitive key identifiers from appearing in logs
    private func redactedKey(_ key: String) -> String {
        guard key.count > 3 else {
            return String(repeating: "*", count: key.count)
        }
        return String(key.prefix(3)) + "***"
    }

    // MARK: - KeychainServiceProtocol

    func save(key: String, value: String) throws {
        guard let valueData = value.data(using: .utf8) else {
            throw HCDError.keychain(.encodingFailed)
        }

        // First try to delete any existing item
        try? delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: valueData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            AppLogger.shared.error("Failed to save to keychain: \(status)")
            throw HCDError.keychain(.saveFailed(status))
        }

        AppLogger.shared.debug("Successfully saved to keychain: \(redactedKey(key))")
    }

    func retrieve(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            return nil
        }

        guard status == errSecSuccess else {
            AppLogger.shared.error("Failed to retrieve from keychain: \(status)")
            throw HCDError.keychain(.retrieveFailed(status))
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw HCDError.keychain(.decodingFailed)
        }

        AppLogger.shared.debug("Successfully retrieved from keychain: \(redactedKey(key))")
        return string
    }

    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            AppLogger.shared.error("Failed to delete from keychain: \(status)")
            throw HCDError.keychain(.deleteFailed(status))
        }

        AppLogger.shared.debug("Successfully deleted from keychain: \(redactedKey(key))")
    }

    // MARK: - Convenience Methods

    /// Save OpenAI API key
    func saveOpenAIKey(_ key: String) throws {
        try save(key: "openai_api_key", value: key)
    }

    /// Retrieve OpenAI API key
    func retrieveOpenAIKey() throws -> String? {
        try retrieve(key: "openai_api_key")
    }

    /// Delete OpenAI API key
    func deleteOpenAIKey() throws {
        try delete(key: "openai_api_key")
    }
}
