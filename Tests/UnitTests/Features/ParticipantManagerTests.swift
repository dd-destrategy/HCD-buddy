//
//  ParticipantManagerTests.swift
//  HCD Interview Coach Tests
//
//  FEATURE F: Participant Management System
//  Unit tests for ParticipantManager CRUD operations, search, session linking,
//  GDPR export/deletion, calendar integration, and persistence.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class ParticipantManagerTests: XCTestCase {

    // MARK: - Properties

    var manager: ParticipantManager!
    var tempDirectory: URL!
    var storageURL: URL!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ParticipantManagerTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storageURL = tempDirectory.appendingPathComponent("participants.json")
        manager = ParticipantManager(storageURL: storageURL)
    }

    override func tearDown() {
        manager = nil
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        storageURL = nil
        super.tearDown()
    }

    // MARK: - Test: Create Participant

    func testCreateParticipant_addsToArray() {
        // Given: An empty manager
        XCTAssertEqual(manager.participants.count, 0)

        // When: Creating a participant
        let participant = manager.createParticipant(
            name: "Jane Doe",
            email: "jane@example.com",
            role: "Product Manager",
            department: "Product",
            organization: "Acme Corp",
            experienceLevel: .intermediate,
            notes: "Test participant"
        )

        // Then: Participant should be in the array with correct fields
        XCTAssertEqual(manager.participants.count, 1)
        XCTAssertEqual(participant.name, "Jane Doe")
        XCTAssertEqual(participant.email, "jane@example.com")
        XCTAssertEqual(participant.role, "Product Manager")
        XCTAssertEqual(participant.department, "Product")
        XCTAssertEqual(participant.organization, "Acme Corp")
        XCTAssertEqual(participant.experienceLevel, .intermediate)
        XCTAssertEqual(participant.notes, "Test participant")
        XCTAssertTrue(participant.metadata.isEmpty)
        XCTAssertTrue(participant.sessionIds.isEmpty)
    }

    func testCreateParticipant_generatesUniqueId() {
        // Given: Two participants created
        let p1 = manager.createParticipant(name: "Alice")
        let p2 = manager.createParticipant(name: "Bob")

        // Then: They should have different IDs
        XCTAssertNotEqual(p1.id, p2.id)
    }

    func testCreateParticipant_setsTimestamps() {
        // When: Creating a participant
        let before = Date()
        let participant = manager.createParticipant(name: "Timed Participant")
        let after = Date()

        // Then: Timestamps should be set to approximately now
        XCTAssertGreaterThanOrEqual(participant.createdAt, before)
        XCTAssertLessThanOrEqual(participant.createdAt, after)
        XCTAssertGreaterThanOrEqual(participant.updatedAt, before)
        XCTAssertLessThanOrEqual(participant.updatedAt, after)
    }

    func testCreateParticipant_withMetadata() {
        // When: Creating with custom metadata
        let participant = manager.createParticipant(
            name: "Screened User",
            metadata: ["Screening Score": "85", "Source": "UserTesting.com"]
        )

        // Then: Metadata should be set
        XCTAssertEqual(participant.metadata.count, 2)
        XCTAssertEqual(participant.metadata["Screening Score"], "85")
        XCTAssertEqual(participant.metadata["Source"], "UserTesting.com")
    }

    // MARK: - Test: Update Participant

    func testUpdateParticipant_updatesName() {
        // Given: A participant
        let participant = manager.createParticipant(name: "Original Name")

        // When: Updating the name
        manager.updateParticipant(participant.id, name: "Updated Name")

        // Then: Name should be updated
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.name, "Updated Name")
    }

    func testUpdateParticipant_updatesEmail() {
        // Given: A participant
        let participant = manager.createParticipant(name: "User", email: "old@test.com")

        // When: Updating the email
        manager.updateParticipant(participant.id, email: "new@test.com")

        // Then: Email should be updated
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.email, "new@test.com")
    }

    func testUpdateParticipant_updatesRole() {
        // Given: A participant
        let participant = manager.createParticipant(name: "User", role: "Junior")

        // When: Updating the role
        manager.updateParticipant(participant.id, role: "Senior")

        // Then: Role should be updated
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.role, "Senior")
    }

    func testUpdateParticipant_updatesDepartment() {
        // Given: A participant
        let participant = manager.createParticipant(name: "User", department: "Engineering")

        // When: Updating the department
        manager.updateParticipant(participant.id, department: "Design")

        // Then: Department should be updated
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.department, "Design")
    }

    func testUpdateParticipant_updatesOrganization() {
        // Given: A participant
        let participant = manager.createParticipant(name: "User", organization: "OldCo")

        // When: Updating the organization
        manager.updateParticipant(participant.id, organization: "NewCo")

        // Then: Organization should be updated
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.organization, "NewCo")
    }

    func testUpdateParticipant_updatesExperienceLevel() {
        // Given: A participant
        let participant = manager.createParticipant(name: "User", experienceLevel: .novice)

        // When: Updating the experience level
        manager.updateParticipant(participant.id, experienceLevel: .expert)

        // Then: Experience level should be updated
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.experienceLevel, .expert)
    }

    func testUpdateParticipant_updatesMetadata() {
        // Given: A participant with metadata
        let participant = manager.createParticipant(
            name: "User",
            metadata: ["Key1": "Value1"]
        )

        // When: Updating metadata
        manager.updateParticipant(participant.id, metadata: ["Key2": "Value2", "Key3": "Value3"])

        // Then: Metadata should be replaced
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.metadata.count, 2)
        XCTAssertNil(updated?.metadata["Key1"])
        XCTAssertEqual(updated?.metadata["Key2"], "Value2")
    }

    func testUpdateParticipant_updatesTimestamp() {
        // Given: A participant
        let participant = manager.createParticipant(name: "User")
        let originalUpdatedAt = manager.participant(byId: participant.id)?.updatedAt

        // Brief delay
        Thread.sleep(forTimeInterval: 0.01)

        // When: Updating
        manager.updateParticipant(participant.id, notes: "Updated notes")

        // Then: updatedAt should be newer
        let newUpdatedAt = manager.participant(byId: participant.id)?.updatedAt
        XCTAssertNotNil(newUpdatedAt)
        if let original = originalUpdatedAt, let updated = newUpdatedAt {
            XCTAssertGreaterThanOrEqual(updated, original)
        }
    }

    func testUpdateParticipant_nonExistentId_doesNothing() {
        // Given: A participant
        manager.createParticipant(name: "Existing")

        // When: Updating a non-existent ID
        manager.updateParticipant(UUID(), name: "Ghost")

        // Then: Existing participant is unchanged
        XCTAssertEqual(manager.participants.count, 1)
        XCTAssertEqual(manager.participants.first?.name, "Existing")
    }

    // MARK: - Test: Delete Participant

    func testDeleteParticipant_removesFromArray() {
        // Given: A participant
        let participant = manager.createParticipant(name: "To Delete")
        XCTAssertEqual(manager.participants.count, 1)

        // When: Deleting
        manager.deleteParticipant(participant.id)

        // Then: Participant should be removed
        XCTAssertEqual(manager.participants.count, 0)
    }

    func testDeleteParticipant_nonExistentId_doesNothing() {
        // Given: A participant
        manager.createParticipant(name: "Keep Me")
        XCTAssertEqual(manager.participants.count, 1)

        // When: Deleting a non-existent ID
        manager.deleteParticipant(UUID())

        // Then: Existing participant remains
        XCTAssertEqual(manager.participants.count, 1)
    }

    func testDeleteParticipant_preservesOthers() {
        // Given: Multiple participants
        let p1 = manager.createParticipant(name: "Keep 1")
        let p2 = manager.createParticipant(name: "Delete Me")
        let p3 = manager.createParticipant(name: "Keep 2")

        // When: Deleting the middle one
        manager.deleteParticipant(p2.id)

        // Then: Others should remain
        XCTAssertEqual(manager.participants.count, 2)
        let ids = manager.participants.map { $0.id }
        XCTAssertTrue(ids.contains(p1.id))
        XCTAssertFalse(ids.contains(p2.id))
        XCTAssertTrue(ids.contains(p3.id))
    }

    // MARK: - Test: Session Linking

    func testLinkSession_addsToParticipant() {
        // Given: A participant
        let participant = manager.createParticipant(name: "Session User")
        let sessionId = UUID()

        // When: Linking a session
        manager.linkSession(sessionId, to: participant.id)

        // Then: Session should be linked
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.sessionIds.count, 1)
        XCTAssertTrue(updated?.sessionIds.contains(sessionId) ?? false)
    }

    func testLinkSession_preventsDuplicates() {
        // Given: A participant with a linked session
        let participant = manager.createParticipant(name: "Duplicate Test")
        let sessionId = UUID()
        manager.linkSession(sessionId, to: participant.id)

        // When: Linking the same session again
        manager.linkSession(sessionId, to: participant.id)

        // Then: Should still have only one entry
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.sessionIds.count, 1)
    }

    func testLinkSession_toNonExistentParticipant_doesNothing() {
        // When: Linking to a non-existent participant
        manager.linkSession(UUID(), to: UUID())

        // Then: No participants should exist
        XCTAssertEqual(manager.participants.count, 0)
    }

    func testUnlinkSession_removesFromParticipant() {
        // Given: A participant with two sessions
        let participant = manager.createParticipant(name: "Unlink Test")
        let session1 = UUID()
        let session2 = UUID()
        manager.linkSession(session1, to: participant.id)
        manager.linkSession(session2, to: participant.id)

        // When: Unlinking one session
        manager.unlinkSession(session1, from: participant.id)

        // Then: Only the other session should remain
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.sessionIds.count, 1)
        XCTAssertFalse(updated?.sessionIds.contains(session1) ?? true)
        XCTAssertTrue(updated?.sessionIds.contains(session2) ?? false)
    }

    func testSessionsFor_returnsCorrectIds() {
        // Given: A participant with sessions
        let participant = manager.createParticipant(name: "Sessions User")
        let session1 = UUID()
        let session2 = UUID()
        let session3 = UUID()
        manager.linkSession(session1, to: participant.id)
        manager.linkSession(session2, to: participant.id)
        manager.linkSession(session3, to: participant.id)

        // When: Querying sessions
        let sessions = manager.sessions(for: participant.id)

        // Then: All three sessions should be returned
        XCTAssertEqual(sessions.count, 3)
        XCTAssertTrue(sessions.contains(session1))
        XCTAssertTrue(sessions.contains(session2))
        XCTAssertTrue(sessions.contains(session3))
    }

    // MARK: - Test: Lookup

    func testParticipantForSessionId_findsCorrectParticipant() {
        // Given: Two participants with different sessions
        let p1 = manager.createParticipant(name: "Participant A")
        let p2 = manager.createParticipant(name: "Participant B")
        let sessionA = UUID()
        let sessionB = UUID()
        manager.linkSession(sessionA, to: p1.id)
        manager.linkSession(sessionB, to: p2.id)

        // When: Looking up by session ID
        let found = manager.participant(for: sessionA)

        // Then: Correct participant should be returned
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, p1.id)
    }

    func testParticipantForSessionId_returnsNilForUnknownSession() {
        // Given: A participant
        manager.createParticipant(name: "User")

        // When: Looking up an unlinked session
        let found = manager.participant(for: UUID())

        // Then: Should return nil
        XCTAssertNil(found)
    }

    func testParticipantByName_caseInsensitive() {
        // Given: A participant
        manager.createParticipant(name: "Jane Doe")

        // When: Looking up by name with different casing
        let found1 = manager.participant(byName: "jane doe")
        let found2 = manager.participant(byName: "JANE DOE")
        let found3 = manager.participant(byName: "Jane Doe")
        let found4 = manager.participant(byName: "  Jane Doe  ")

        // Then: All should find the participant
        XCTAssertNotNil(found1)
        XCTAssertNotNil(found2)
        XCTAssertNotNil(found3)
        XCTAssertNotNil(found4)
        XCTAssertEqual(found1?.name, "Jane Doe")
    }

    func testParticipantByName_returnsNilForNoMatch() {
        // Given: A participant
        manager.createParticipant(name: "Jane Doe")

        // When: Looking up a non-existent name
        let found = manager.participant(byName: "John Smith")

        // Then: Should return nil
        XCTAssertNil(found)
    }

    func testParticipantById_findsCorrectParticipant() {
        // Given: Multiple participants
        let p1 = manager.createParticipant(name: "Alice")
        manager.createParticipant(name: "Bob")

        // When: Looking up by ID
        let found = manager.participant(byId: p1.id)

        // Then: Correct participant should be returned
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Alice")
    }

    // MARK: - Test: Search

    func testSearchParticipants_byName() {
        // Given: Multiple participants
        manager.createParticipant(name: "Alice Johnson")
        manager.createParticipant(name: "Bob Smith")
        manager.createParticipant(name: "Alice Cooper")

        // When: Searching by name
        let results = manager.searchParticipants(query: "alice")

        // Then: Both Alices should be found
        XCTAssertEqual(results.count, 2)
    }

    func testSearchParticipants_byEmail() {
        // Given: Participants with emails
        manager.createParticipant(name: "User A", email: "alice@acme.com")
        manager.createParticipant(name: "User B", email: "bob@techco.com")

        // When: Searching by email domain
        let results = manager.searchParticipants(query: "acme")

        // Then: Only the matching one should be found
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "User A")
    }

    func testSearchParticipants_byRole() {
        // Given: Participants with roles
        manager.createParticipant(name: "User A", role: "Product Manager")
        manager.createParticipant(name: "User B", role: "Developer")

        // When: Searching by role
        let results = manager.searchParticipants(query: "product")

        // Then: Only matching result
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "User A")
    }

    func testSearchParticipants_byOrganization() {
        // Given: Participants with organizations
        manager.createParticipant(name: "User A", organization: "Acme Corp")
        manager.createParticipant(name: "User B", organization: "TechCo")

        // When: Searching by organization
        let results = manager.searchParticipants(query: "techco")

        // Then: Only matching result
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "User B")
    }

    func testSearchParticipants_emptyQuery_returnsAll() {
        // Given: Multiple participants
        manager.createParticipant(name: "Alice")
        manager.createParticipant(name: "Bob")
        manager.createParticipant(name: "Charlie")

        // When: Searching with empty query
        let results = manager.searchParticipants(query: "")

        // Then: All should be returned
        XCTAssertEqual(results.count, 3)
    }

    func testFilteredParticipants_usesSearchQuery() {
        // Given: Participants
        manager.createParticipant(name: "Alice")
        manager.createParticipant(name: "Bob")

        // When: Setting searchQuery
        manager.searchQuery = "bob"

        // Then: filteredParticipants should reflect the query
        XCTAssertEqual(manager.filteredParticipants.count, 1)
        XCTAssertEqual(manager.filteredParticipants.first?.name, "Bob")
    }

    // MARK: - Test: Calendar Integration

    func testFindOrSuggest_matchesByName() {
        // Given: A participant named "Jane Doe"
        let participant = manager.createParticipant(name: "Jane Doe")

        // When: Finding from an UpcomingInterview with matching name
        let interview = UpcomingInterview(
            id: "event-1",
            title: "User Interview",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            notes: nil,
            participantName: "Jane Doe",
            projectName: "Test Project",
            calendarName: "Work"
        )
        let found = manager.findOrSuggest(from: interview)

        // Then: Should find the participant
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, participant.id)
    }

    func testFindOrSuggest_caseInsensitiveMatch() {
        // Given: A participant
        manager.createParticipant(name: "Jane Doe")

        // When: Finding with different casing
        let interview = UpcomingInterview(
            id: "event-2",
            title: "Interview",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            notes: nil,
            participantName: "jane doe",
            projectName: nil,
            calendarName: "Calendar"
        )
        let found = manager.findOrSuggest(from: interview)

        // Then: Should still match
        XCTAssertNotNil(found)
    }

    func testFindOrSuggest_returnsNilForNoParticipantName() {
        // Given: A participant
        manager.createParticipant(name: "Jane Doe")

        // When: Interview has no participant name
        let interview = UpcomingInterview(
            id: "event-3",
            title: "Interview",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            notes: nil,
            participantName: nil,
            projectName: nil,
            calendarName: "Calendar"
        )
        let found = manager.findOrSuggest(from: interview)

        // Then: Should return nil
        XCTAssertNil(found)
    }

    // MARK: - Test: GDPR Export

    func testExportParticipantData_containsAllFields() {
        // Given: A participant with full data
        let participant = manager.createParticipant(
            name: "Jane Doe",
            email: "jane@example.com",
            role: "Product Manager",
            department: "Product",
            organization: "Acme Corp",
            experienceLevel: .advanced,
            notes: "Test notes for export.",
            metadata: ["Source": "Referral"]
        )
        let sessionId = UUID()
        manager.linkSession(sessionId, to: participant.id)

        // When: Exporting
        let export = manager.exportParticipantData(participant.id)

        // Then: Export should contain all fields
        XCTAssertTrue(export.contains("Participant Data Export"))
        XCTAssertTrue(export.contains("Jane Doe"))
        XCTAssertTrue(export.contains("jane@example.com"))
        XCTAssertTrue(export.contains("Product Manager"))
        XCTAssertTrue(export.contains("Product"))
        XCTAssertTrue(export.contains("Acme Corp"))
        XCTAssertTrue(export.contains("Advanced"))
        XCTAssertTrue(export.contains("Test notes for export."))
        XCTAssertTrue(export.contains("Source"))
        XCTAssertTrue(export.contains("Referral"))
        XCTAssertTrue(export.contains(sessionId.uuidString))
        XCTAssertTrue(export.contains(participant.id.uuidString))
    }

    func testExportParticipantData_nonExistentId_returnsNotFound() {
        // When: Exporting a non-existent participant
        let export = manager.exportParticipantData(UUID())

        // Then: Should indicate not found
        XCTAssertTrue(export.contains("No participant found"))
    }

    // MARK: - Test: GDPR Deletion

    func testDeleteParticipantAndData_removesParticipant() {
        // Given: A participant with sessions
        let participant = manager.createParticipant(name: "GDPR User")
        manager.linkSession(UUID(), to: participant.id)
        manager.linkSession(UUID(), to: participant.id)
        XCTAssertEqual(manager.participants.count, 1)

        // When: Performing GDPR deletion
        manager.deleteParticipantAndData(participant.id)

        // Then: Participant should be completely removed
        XCTAssertEqual(manager.participants.count, 0)
        XCTAssertNil(manager.participant(byId: participant.id))
    }

    func testDeleteParticipantAndData_nonExistentId_doesNothing() {
        // Given: A participant
        manager.createParticipant(name: "Safe User")

        // When: GDPR deleting a non-existent ID
        manager.deleteParticipantAndData(UUID())

        // Then: Existing participant should remain
        XCTAssertEqual(manager.participants.count, 1)
    }

    // MARK: - Test: Persistence

    func testPersistence_saveAndLoad() {
        // Given: Participants with data
        let p1 = manager.createParticipant(
            name: "Persisted User",
            email: "persist@test.com",
            role: "Tester",
            experienceLevel: .expert
        )
        let sessionId = UUID()
        manager.linkSession(sessionId, to: p1.id)
        manager.createParticipant(name: "Second User")

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: storageURL.path))

        // When: Creating a new manager from the same file
        let loaded = ParticipantManager(storageURL: storageURL)

        // Then: Participants should be restored
        XCTAssertEqual(loaded.participants.count, 2)

        let loadedP1 = loaded.participant(byId: p1.id)
        XCTAssertNotNil(loadedP1)
        XCTAssertEqual(loadedP1?.name, "Persisted User")
        XCTAssertEqual(loadedP1?.email, "persist@test.com")
        XCTAssertEqual(loadedP1?.role, "Tester")
        XCTAssertEqual(loadedP1?.experienceLevel, .expert)
        XCTAssertEqual(loadedP1?.sessionIds.count, 1)
        XCTAssertTrue(loadedP1?.sessionIds.contains(sessionId) ?? false)
    }

    func testPersistence_emptyFile_loadsEmpty() {
        // Given: A non-existent storage file
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.json")

        // When: Loading from non-existent file
        let loaded = ParticipantManager(storageURL: nonExistentURL)

        // Then: Should have empty participants array
        XCTAssertEqual(loaded.participants.count, 0)
    }

    func testPersistence_corruptedFile_loadsEmpty() throws {
        // Given: A corrupted JSON file
        let corruptData = "this is not valid json".data(using: .utf8)!
        try corruptData.write(to: storageURL)

        // When: Loading from corrupted file
        let loaded = ParticipantManager(storageURL: storageURL)

        // Then: Should have empty participants array (graceful degradation)
        XCTAssertEqual(loaded.participants.count, 0)
    }

    func testPersistence_deletesPersist() {
        // Given: A participant that gets deleted
        let participant = manager.createParticipant(name: "Ephemeral")
        manager.deleteParticipant(participant.id)

        // When: Reloading
        let reloaded = ParticipantManager(storageURL: storageURL)

        // Then: Deleted participant should not be present
        XCTAssertEqual(reloaded.participants.count, 0)
    }

    // MARK: - Test: Computed Properties

    func testSessionCount_matchesLinkedSessions() {
        // Given: A participant with sessions
        let participant = manager.createParticipant(name: "Count Test")
        manager.linkSession(UUID(), to: participant.id)
        manager.linkSession(UUID(), to: participant.id)
        manager.linkSession(UUID(), to: participant.id)

        // Then: sessionCount should match
        let updated = manager.participant(byId: participant.id)
        XCTAssertEqual(updated?.sessionCount, 3)
    }

    func testHasSessionHistory_trueWhenLinked() {
        // Given: A participant with a session
        let participant = manager.createParticipant(name: "Has History")
        manager.linkSession(UUID(), to: participant.id)

        // Then: hasSessionHistory should be true
        let updated = manager.participant(byId: participant.id)
        XCTAssertTrue(updated?.hasSessionHistory ?? false)
    }

    func testHasSessionHistory_falseWhenEmpty() {
        // Given: A participant without sessions
        let participant = manager.createParticipant(name: "No History")

        // Then: hasSessionHistory should be false
        XCTAssertFalse(participant.hasSessionHistory)
    }

    // MARK: - Test: Statistics

    func testTotalCount_matchesParticipants() {
        // Given: Multiple participants
        manager.createParticipant(name: "A")
        manager.createParticipant(name: "B")
        manager.createParticipant(name: "C")

        // Then: totalCount should match
        XCTAssertEqual(manager.totalCount, 3)
    }

    func testParticipantsWithMultipleSessions_returnsCorrect() {
        // Given: Participants with varying session counts
        let p1 = manager.createParticipant(name: "One Session")
        manager.linkSession(UUID(), to: p1.id)

        let p2 = manager.createParticipant(name: "Two Sessions")
        manager.linkSession(UUID(), to: p2.id)
        manager.linkSession(UUID(), to: p2.id)

        let p3 = manager.createParticipant(name: "Three Sessions")
        manager.linkSession(UUID(), to: p3.id)
        manager.linkSession(UUID(), to: p3.id)
        manager.linkSession(UUID(), to: p3.id)

        manager.createParticipant(name: "No Sessions")

        // When: Querying for multiple sessions
        let result = manager.participantsWithMultipleSessions()

        // Then: Only participants with >1 session should be returned
        XCTAssertEqual(result.count, 2)
        let names = result.map { $0.name }
        XCTAssertTrue(names.contains("Two Sessions"))
        XCTAssertTrue(names.contains("Three Sessions"))
    }

    // MARK: - Test: ExperienceLevel Enum

    func testExperienceLevel_displayNames() {
        XCTAssertEqual(ExperienceLevel.novice.displayName, "Novice")
        XCTAssertEqual(ExperienceLevel.intermediate.displayName, "Intermediate")
        XCTAssertEqual(ExperienceLevel.advanced.displayName, "Advanced")
        XCTAssertEqual(ExperienceLevel.expert.displayName, "Expert")
    }

    func testExperienceLevel_rawValues() {
        XCTAssertEqual(ExperienceLevel.novice.rawValue, "novice")
        XCTAssertEqual(ExperienceLevel.intermediate.rawValue, "intermediate")
        XCTAssertEqual(ExperienceLevel.advanced.rawValue, "advanced")
        XCTAssertEqual(ExperienceLevel.expert.rawValue, "expert")
    }

    func testExperienceLevel_allCases() {
        XCTAssertEqual(ExperienceLevel.allCases.count, 4)
    }
}
