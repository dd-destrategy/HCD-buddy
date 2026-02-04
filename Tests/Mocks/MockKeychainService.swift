//
//  MockKeychainService.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Mock implementation of KeychainService protocol for testing
//

import Foundation
import Security
@testable import HCDInterviewCoach

/// Mock keychain service for testing
final class MockKeychainService: KeychainService {

    // MARK: - Mock Storage

    private var storage: [String: String] = [:]

    // MARK: - Call Tracking

    var saveCallCount = 0
    var retrieveCallCount = 0
    var deleteCallCount = 0
    var lastSavedKey: String?
    var lastSavedValue: String?

    // MARK: - Error Simulation

    var shouldThrowOnSave = false
    var shouldThrowOnRetrieve = false
    var shouldThrowOnDelete = false
    var errorToThrow: KeychainError?

    // MARK: - KeychainService Protocol

    func save(key: String, value: String) throws {
        saveCallCount += 1
        lastSavedKey = key
        lastSavedValue = value

        if shouldThrowOnSave, let error = errorToThrow {
            throw error
        }

        storage[key] = value
    }

    func retrieve(key: String) throws -> String? {
        retrieveCallCount += 1

        if shouldThrowOnRetrieve, let error = errorToThrow {
            throw error
        }

        return storage[key]
    }

    func delete(key: String) throws {
        deleteCallCount += 1

        if shouldThrowOnDelete, let error = errorToThrow {
            throw error
        }

        storage.removeValue(forKey: key)
    }

    // MARK: - Test Helpers

    /// Check if a key exists in mock storage
    func contains(key: String) -> Bool {
        return storage[key] != nil
    }

    /// Get all stored keys
    func allKeys() -> [String] {
        return Array(storage.keys)
    }

    /// Clear all mock storage
    func clearAll() {
        storage.removeAll()
    }

    /// Reset mock state
    func reset() {
        storage.removeAll()
        saveCallCount = 0
        retrieveCallCount = 0
        deleteCallCount = 0
        lastSavedKey = nil
        lastSavedValue = nil
        shouldThrowOnSave = false
        shouldThrowOnRetrieve = false
        shouldThrowOnDelete = false
        errorToThrow = nil
    }
}

// MARK: - Supporting Types

/// Protocol defining keychain service interface
protocol KeychainService {
    func save(key: String, value: String) throws
    func retrieve(key: String) throws -> String?
    func delete(key: String) throws
}

/// Keychain errors
enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case itemNotFound
    case unexpectedDataFormat
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        case .itemNotFound:
            return "Item not found in keychain"
        case .unexpectedDataFormat:
            return "Unexpected data format in keychain"
        case .accessDenied:
            return "Access to keychain denied"
        }
    }
}
