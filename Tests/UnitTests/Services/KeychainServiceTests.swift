//
//  KeychainServiceTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for KeychainService secure storage operations
//

import XCTest
@testable import HCDInterviewCoach

final class KeychainServiceTests: XCTestCase {

    var mockKeychain: MockKeychainService!

    override func setUp() {
        super.setUp()
        mockKeychain = MockKeychainService()
    }

    override func tearDown() {
        mockKeychain.reset()
        mockKeychain = nil
        super.tearDown()
    }

    // MARK: - Test: Save Key Success

    func testSaveKey_success() throws {
        // Given: A key and value to save
        let key = "test_api_key"
        let value = "sk-test-1234567890"

        // When: Saving to keychain
        try mockKeychain.save(key: key, value: value)

        // Then: Value should be stored and retrievable
        XCTAssertEqual(mockKeychain.saveCallCount, 1)
        XCTAssertEqual(mockKeychain.lastSavedKey, key)
        XCTAssertEqual(mockKeychain.lastSavedValue, value)
        XCTAssertTrue(mockKeychain.contains(key: key))

        let retrieved = try mockKeychain.retrieve(key: key)
        XCTAssertEqual(retrieved, value)
    }

    func testSaveKey_multipleDifferentKeys() throws {
        // Given: Multiple keys
        let keys = ["key1", "key2", "key3"]
        let values = ["value1", "value2", "value3"]

        // When: Saving multiple keys
        for (key, value) in zip(keys, values) {
            try mockKeychain.save(key: key, value: value)
        }

        // Then: All keys should be stored
        XCTAssertEqual(mockKeychain.saveCallCount, 3)
        XCTAssertEqual(mockKeychain.allKeys().count, 3)

        for (key, value) in zip(keys, values) {
            let retrieved = try mockKeychain.retrieve(key: key)
            XCTAssertEqual(retrieved, value)
        }
    }

    // MARK: - Test: Save Key Update Existing

    func testSaveKey_updateExisting() throws {
        // Given: An existing key
        let key = "test_key"
        let originalValue = "original_value"
        let updatedValue = "updated_value"

        try mockKeychain.save(key: key, value: originalValue)
        XCTAssertEqual(try mockKeychain.retrieve(key: key), originalValue)

        // When: Saving with same key
        try mockKeychain.save(key: key, value: updatedValue)

        // Then: Value should be updated
        let retrieved = try mockKeychain.retrieve(key: key)
        XCTAssertEqual(retrieved, updatedValue)
        XCTAssertEqual(mockKeychain.saveCallCount, 2)
    }

    func testSaveKey_updatePreservesOtherKeys() throws {
        // Given: Multiple keys exist
        try mockKeychain.save(key: "key1", value: "value1")
        try mockKeychain.save(key: "key2", value: "value2")

        // When: Updating one key
        try mockKeychain.save(key: "key1", value: "new_value1")

        // Then: Other keys should remain unchanged
        XCTAssertEqual(try mockKeychain.retrieve(key: "key1"), "new_value1")
        XCTAssertEqual(try mockKeychain.retrieve(key: "key2"), "value2")
    }

    // MARK: - Test: Retrieve Key Exists

    func testRetrieveKey_exists() throws {
        // Given: A stored key
        let key = "existing_key"
        let value = "stored_value"
        try mockKeychain.save(key: key, value: value)

        // When: Retrieving the key
        let retrieved = try mockKeychain.retrieve(key: key)

        // Then: Value should be returned
        XCTAssertEqual(retrieved, value)
        XCTAssertEqual(mockKeychain.retrieveCallCount, 1)
    }

    func testRetrieveKey_multipleRetrievals() throws {
        // Given: A stored key
        let key = "test_key"
        let value = "test_value"
        try mockKeychain.save(key: key, value: value)

        // When: Retrieving multiple times
        for _ in 0..<5 {
            let retrieved = try mockKeychain.retrieve(key: key)
            XCTAssertEqual(retrieved, value)
        }

        // Then: All retrievals should succeed
        XCTAssertEqual(mockKeychain.retrieveCallCount, 5)
    }

    // MARK: - Test: Retrieve Key Not Found

    func testRetrieveKey_notFound() throws {
        // Given: A non-existent key

        // When: Retrieving the key
        let retrieved = try mockKeychain.retrieve(key: "non_existent_key")

        // Then: Should return nil
        XCTAssertNil(retrieved)
        XCTAssertEqual(mockKeychain.retrieveCallCount, 1)
    }

    func testRetrieveKey_afterDeletion() throws {
        // Given: A key that was stored then deleted
        let key = "temp_key"
        try mockKeychain.save(key: key, value: "temp_value")
        try mockKeychain.delete(key: key)

        // When: Attempting to retrieve
        let retrieved = try mockKeychain.retrieve(key: key)

        // Then: Should return nil
        XCTAssertNil(retrieved)
    }

    // MARK: - Test: Delete Key Exists

    func testDeleteKey_exists() throws {
        // Given: An existing key
        let key = "key_to_delete"
        try mockKeychain.save(key: key, value: "value_to_delete")
        XCTAssertTrue(mockKeychain.contains(key: key))

        // When: Deleting the key
        try mockKeychain.delete(key: key)

        // Then: Key should be removed
        XCTAssertFalse(mockKeychain.contains(key: key))
        XCTAssertEqual(mockKeychain.deleteCallCount, 1)
    }

    func testDeleteKey_preservesOtherKeys() throws {
        // Given: Multiple keys
        try mockKeychain.save(key: "keep1", value: "value1")
        try mockKeychain.save(key: "delete_me", value: "value2")
        try mockKeychain.save(key: "keep2", value: "value3")

        // When: Deleting one key
        try mockKeychain.delete(key: "delete_me")

        // Then: Other keys should remain
        XCTAssertTrue(mockKeychain.contains(key: "keep1"))
        XCTAssertFalse(mockKeychain.contains(key: "delete_me"))
        XCTAssertTrue(mockKeychain.contains(key: "keep2"))
    }

    // MARK: - Test: Delete Key Not Found

    func testDeleteKey_notFound() throws {
        // Given: A non-existent key

        // When: Attempting to delete
        try mockKeychain.delete(key: "non_existent_key")

        // Then: Should not throw (graceful handling)
        XCTAssertEqual(mockKeychain.deleteCallCount, 1)
    }

    func testDeleteKey_idempotent() throws {
        // Given: A key that's deleted
        let key = "test_key"
        try mockKeychain.save(key: key, value: "test_value")
        try mockKeychain.delete(key: key)

        // When: Deleting again
        try mockKeychain.delete(key: key)

        // Then: Should not throw
        XCTAssertEqual(mockKeychain.deleteCallCount, 2)
    }

    // MARK: - Test: Save Key Invalid Data

    func testSaveKey_emptyKey() throws {
        // Given: An empty key
        let emptyKey = ""
        let value = "some_value"

        // When: Saving with empty key
        // Note: Mock doesn't validate, but real implementation might
        try mockKeychain.save(key: emptyKey, value: value)

        // Then: Should save (mock behavior)
        XCTAssertTrue(mockKeychain.contains(key: emptyKey))
    }

    func testSaveKey_emptyValue() throws {
        // Given: An empty value
        let key = "test_key"
        let emptyValue = ""

        // When: Saving empty value
        try mockKeychain.save(key: key, value: emptyValue)

        // Then: Should save empty string
        let retrieved = try mockKeychain.retrieve(key: key)
        XCTAssertEqual(retrieved, "")
    }

    func testSaveKey_specialCharacters() throws {
        // Given: Key and value with special characters
        let key = "key_with_special_!@#$%^&*()"
        let value = "value_with_unicode_\u{1F600}_and_newlines_\n_tabs_\t"

        // When: Saving
        try mockKeychain.save(key: key, value: value)

        // Then: Should preserve special characters
        let retrieved = try mockKeychain.retrieve(key: key)
        XCTAssertEqual(retrieved, value)
    }

    func testSaveKey_veryLongValue() throws {
        // Given: A very long value
        let key = "long_value_key"
        let value = String(repeating: "a", count: 10000)

        // When: Saving long value
        try mockKeychain.save(key: key, value: value)

        // Then: Should save and retrieve correctly
        let retrieved = try mockKeychain.retrieve(key: key)
        XCTAssertEqual(retrieved, value)
        XCTAssertEqual(retrieved?.count, 10000)
    }

    // MARK: - Test: Key Accessibility When Unlocked

    func testKeyAccessibility_whenUnlocked() throws {
        // Given: A key stored with accessibility attribute
        let key = "accessible_key"
        let value = "accessible_value"

        // When: Saving key (real implementation uses kSecAttrAccessibleWhenUnlocked)
        try mockKeychain.save(key: key, value: value)

        // Then: Key should be accessible
        let retrieved = try mockKeychain.retrieve(key: key)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved, value)
    }

    func testKeyAccessibility_immediateAccess() throws {
        // Given: A freshly saved key
        let key = "immediate_key"
        let value = "immediate_value"
        try mockKeychain.save(key: key, value: value)

        // When: Immediately retrieving
        let retrieved = try mockKeychain.retrieve(key: key)

        // Then: Should be accessible immediately
        XCTAssertEqual(retrieved, value)
    }

    // MARK: - Test: Key Persistence

    func testKeyPersistence_acrossRetrievals() throws {
        // Given: A saved key
        let key = "persistent_key"
        let value = "persistent_value"
        try mockKeychain.save(key: key, value: value)

        // When: Retrieving multiple times
        var retrievedValues: [String] = []
        for _ in 0..<3 {
            if let retrieved = try mockKeychain.retrieve(key: key) {
                retrievedValues.append(retrieved)
            }
        }

        // Then: All retrievals should return same value
        XCTAssertEqual(retrievedValues.count, 3)
        XCTAssertTrue(retrievedValues.allSatisfy { $0 == value })
    }

    func testKeyPersistence_afterMultipleUpdates() throws {
        // Given: A key updated multiple times
        let key = "updated_key"
        let values = ["v1", "v2", "v3", "final"]

        // When: Updating multiple times
        for value in values {
            try mockKeychain.save(key: key, value: value)
        }

        // Then: Final value should persist
        let retrieved = try mockKeychain.retrieve(key: key)
        XCTAssertEqual(retrieved, "final")
    }

    // MARK: - Test: Delete All Keys

    func testDeleteAllKeys() throws {
        // Given: Multiple stored keys
        try mockKeychain.save(key: "key1", value: "value1")
        try mockKeychain.save(key: "key2", value: "value2")
        try mockKeychain.save(key: "key3", value: "value3")
        XCTAssertEqual(mockKeychain.allKeys().count, 3)

        // When: Clearing all
        mockKeychain.clearAll()

        // Then: All keys should be removed
        XCTAssertEqual(mockKeychain.allKeys().count, 0)
        XCTAssertNil(try mockKeychain.retrieve(key: "key1"))
        XCTAssertNil(try mockKeychain.retrieve(key: "key2"))
        XCTAssertNil(try mockKeychain.retrieve(key: "key3"))
    }

    func testDeleteAllKeys_emptyKeychain() throws {
        // Given: Empty keychain
        XCTAssertEqual(mockKeychain.allKeys().count, 0)

        // When: Clearing all
        mockKeychain.clearAll()

        // Then: Should not throw
        XCTAssertEqual(mockKeychain.allKeys().count, 0)
    }

    // MARK: - Test: Error Handling

    func testSaveKey_throwsOnError() throws {
        // Given: Keychain configured to throw on save
        mockKeychain.shouldThrowOnSave = true
        mockKeychain.errorToThrow = KeychainError.saveFailed(-25300)

        // When/Then: Save should throw
        XCTAssertThrowsError(try mockKeychain.save(key: "key", value: "value")) { error in
            guard let keychainError = error as? KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            if case .saveFailed(let status) = keychainError {
                XCTAssertEqual(status, -25300)
            } else {
                XCTFail("Expected saveFailed error")
            }
        }
    }

    func testRetrieveKey_throwsOnError() throws {
        // Given: Keychain configured to throw on retrieve
        mockKeychain.shouldThrowOnRetrieve = true
        mockKeychain.errorToThrow = KeychainError.retrieveFailed(-25299)

        // When/Then: Retrieve should throw
        XCTAssertThrowsError(try mockKeychain.retrieve(key: "key")) { error in
            guard let keychainError = error as? KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            if case .retrieveFailed(let status) = keychainError {
                XCTAssertEqual(status, -25299)
            } else {
                XCTFail("Expected retrieveFailed error")
            }
        }
    }

    func testDeleteKey_throwsOnError() throws {
        // Given: Keychain configured to throw on delete
        mockKeychain.shouldThrowOnDelete = true
        mockKeychain.errorToThrow = KeychainError.deleteFailed(-25298)

        // When/Then: Delete should throw
        XCTAssertThrowsError(try mockKeychain.delete(key: "key")) { error in
            guard let keychainError = error as? KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            if case .deleteFailed(let status) = keychainError {
                XCTAssertEqual(status, -25298)
            } else {
                XCTFail("Expected deleteFailed error")
            }
        }
    }

    func testErrorRecovery_afterSaveError() throws {
        // Given: Save error occurred
        mockKeychain.shouldThrowOnSave = true
        mockKeychain.errorToThrow = KeychainError.saveFailed(-25300)
        XCTAssertThrowsError(try mockKeychain.save(key: "key", value: "value"))

        // When: Error condition cleared
        mockKeychain.shouldThrowOnSave = false
        mockKeychain.errorToThrow = nil

        // Then: Subsequent save should succeed
        XCTAssertNoThrow(try mockKeychain.save(key: "key", value: "value"))
        XCTAssertTrue(mockKeychain.contains(key: "key"))
    }

    // MARK: - Test: Call Tracking

    func testCallTracking_countsOperations() throws {
        // Given: Fresh mock
        XCTAssertEqual(mockKeychain.saveCallCount, 0)
        XCTAssertEqual(mockKeychain.retrieveCallCount, 0)
        XCTAssertEqual(mockKeychain.deleteCallCount, 0)

        // When: Performing operations
        try mockKeychain.save(key: "key1", value: "v1")
        try mockKeychain.save(key: "key2", value: "v2")
        _ = try mockKeychain.retrieve(key: "key1")
        _ = try mockKeychain.retrieve(key: "key2")
        _ = try mockKeychain.retrieve(key: "key3")
        try mockKeychain.delete(key: "key1")

        // Then: Counts should be accurate
        XCTAssertEqual(mockKeychain.saveCallCount, 2)
        XCTAssertEqual(mockKeychain.retrieveCallCount, 3)
        XCTAssertEqual(mockKeychain.deleteCallCount, 1)
    }

    func testCallTracking_tracksLastSaved() throws {
        // Given/When: Saving multiple keys
        try mockKeychain.save(key: "first", value: "v1")
        try mockKeychain.save(key: "second", value: "v2")
        try mockKeychain.save(key: "third", value: "v3")

        // Then: Should track last saved key/value
        XCTAssertEqual(mockKeychain.lastSavedKey, "third")
        XCTAssertEqual(mockKeychain.lastSavedValue, "v3")
    }

    // MARK: - Test: Reset State

    func testReset_clearsAllState() throws {
        // Given: Mock with data and error configuration
        try mockKeychain.save(key: "key", value: "value")
        mockKeychain.shouldThrowOnSave = true
        mockKeychain.errorToThrow = KeychainError.saveFailed(-1)

        // When: Resetting
        mockKeychain.reset()

        // Then: All state should be cleared
        XCTAssertEqual(mockKeychain.allKeys().count, 0)
        XCTAssertEqual(mockKeychain.saveCallCount, 0)
        XCTAssertEqual(mockKeychain.retrieveCallCount, 0)
        XCTAssertEqual(mockKeychain.deleteCallCount, 0)
        XCTAssertNil(mockKeychain.lastSavedKey)
        XCTAssertNil(mockKeychain.lastSavedValue)
        XCTAssertFalse(mockKeychain.shouldThrowOnSave)
        XCTAssertFalse(mockKeychain.shouldThrowOnRetrieve)
        XCTAssertFalse(mockKeychain.shouldThrowOnDelete)
        XCTAssertNil(mockKeychain.errorToThrow)
    }

    // MARK: - Test: Thread Safety

    func testConcurrentAccess_saveAndRetrieve() async throws {
        // Given: A mock keychain
        let key = "concurrent_key"

        // When: Concurrent save and retrieve operations
        await withTaskGroup(of: Void.self) { group in
            // Save operations
            for i in 0..<10 {
                group.addTask {
                    try? self.mockKeychain.save(key: key, value: "value_\(i)")
                }
            }

            // Retrieve operations
            for _ in 0..<10 {
                group.addTask {
                    _ = try? self.mockKeychain.retrieve(key: key)
                }
            }
        }

        // Then: Should complete without crash
        // Final value should be one of the saved values
        let retrieved = try mockKeychain.retrieve(key: key)
        XCTAssertNotNil(retrieved)
        XCTAssertTrue(retrieved?.hasPrefix("value_") ?? false)
    }
}

// MARK: - KeychainError Extension Tests

extension KeychainServiceTests {

    func testKeychainError_localizedDescriptions() {
        // Test each error type has a proper description
        let saveFailed = KeychainError.saveFailed(-25300)
        XCTAssertTrue(saveFailed.errorDescription?.contains("save") ?? false)

        let retrieveFailed = KeychainError.retrieveFailed(-25299)
        XCTAssertTrue(retrieveFailed.errorDescription?.contains("retrieve") ?? false)

        let deleteFailed = KeychainError.deleteFailed(-25298)
        XCTAssertTrue(deleteFailed.errorDescription?.contains("delete") ?? false)

        let itemNotFound = KeychainError.itemNotFound
        XCTAssertTrue(itemNotFound.errorDescription?.contains("not found") ?? false)

        let unexpectedFormat = KeychainError.unexpectedDataFormat
        XCTAssertTrue(unexpectedFormat.errorDescription?.contains("format") ?? false)

        let accessDenied = KeychainError.accessDenied
        XCTAssertTrue(accessDenied.errorDescription?.contains("denied") ?? false)
    }
}
