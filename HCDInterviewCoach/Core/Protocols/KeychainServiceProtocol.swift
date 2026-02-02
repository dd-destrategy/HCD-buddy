import Foundation

/// Protocol for secure keychain storage operations
protocol KeychainServiceProtocol {
    /// Save a value to the keychain
    /// - Parameters:
    ///   - key: The key to store the value under
    ///   - value: The string value to store
    /// - Throws: HCDError if the operation fails
    func save(key: String, value: String) throws

    /// Retrieve a value from the keychain
    /// - Parameter key: The key to retrieve
    /// - Returns: The stored value, or nil if not found
    /// - Throws: HCDError if the operation fails
    func retrieve(key: String) throws -> String?

    /// Delete a value from the keychain
    /// - Parameter key: The key to delete
    /// - Throws: HCDError if the operation fails
    func delete(key: String) throws
}
