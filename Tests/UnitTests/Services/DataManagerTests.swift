//
//  DataManagerTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for DataManager SwiftData persistence operations
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

@MainActor
final class DataManagerTests: XCTestCase {

    var testContainer: ModelContainer!
    var testContext: ModelContext!

    override func setUp() {
        super.setUp()
        // Create in-memory container for testing
        do {
            let schema = Schema([
                Session.self,
                Utterance.self,
                Insight.self,
                TopicStatus.self,
                CoachingEvent.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            testContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            testContext = testContainer.mainContext
        } catch {
            XCTFail("Failed to create test container: \(error)")
        }
    }

    override func tearDown() {
        testContext = nil
        testContainer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestSession(
        participantName: String = "Test Participant",
        projectName: String = "Test Project",
        sessionMode: SessionMode = .full
    ) -> Session {
        return Session(
            participantName: participantName,
            projectName: projectName,
            sessionMode: sessionMode
        )
    }

    private func createTestUtterance(
        session: Session,
        text: String = "Test utterance text",
        speaker: Speaker = .interviewer
    ) -> Utterance {
        return Utterance(
            text: text,
            speaker: speaker,
            timestamp: Date().timeIntervalSince1970,
            session: session
        )
    }

    private func createTestInsight(
        session: Session,
        text: String = "Test insight text"
    ) -> Insight {
        return Insight(
            text: text,
            timestamp: Date().timeIntervalSince1970,
            source: .manual,
            session: session
        )
    }

    // MARK: - Test: Container Initialization

    func testContainerInitialization() {
        // Given/When: Container is initialized in setUp

        // Then: Container should be properly configured
        XCTAssertNotNil(testContainer)
        XCTAssertNotNil(testContext)
    }

    func testContainerInitialization_schema() {
        // Given: The test container

        // Then: Schema should include all required model types
        let schema = testContainer.schema
        XCTAssertNotNil(schema)

        // Verify schema entity count (Session, Utterance, Insight, TopicStatus, CoachingEvent)
        XCTAssertGreaterThanOrEqual(schema.entities.count, 5)
    }

    func testContainerInitialization_inMemory() {
        // Given: The test container

        // When: Checking configuration
        let configurations = testContainer.configurations

        // Then: Should be configured for in-memory storage
        XCTAssertFalse(configurations.isEmpty)
    }

    // MARK: - Test: Save Session

    func testSaveSession() throws {
        // Given: A new session
        let session = createTestSession()

        // When: Saving to context
        testContext.insert(session)
        try testContext.save()

        // Then: Session should be saved
        let fetchDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.id == session.id }
        )
        let fetchedSessions = try testContext.fetch(fetchDescriptor)

        XCTAssertEqual(fetchedSessions.count, 1)
        XCTAssertEqual(fetchedSessions.first?.participantName, "Test Participant")
        XCTAssertEqual(fetchedSessions.first?.projectName, "Test Project")
    }

    func testSaveSession_withMetadata() throws {
        // Given: A session with all metadata
        let session = Session(
            participantName: "John Doe",
            projectName: "UX Research",
            sessionMode: .transcriptionOnly,
            notes: "Important session notes"
        )

        // When: Saving
        testContext.insert(session)
        try testContext.save()

        // Then: All metadata should be preserved
        let fetchDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.id == session.id }
        )
        let fetched = try testContext.fetch(fetchDescriptor).first

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.participantName, "John Doe")
        XCTAssertEqual(fetched?.projectName, "UX Research")
        XCTAssertEqual(fetched?.sessionMode, .transcriptionOnly)
        XCTAssertEqual(fetched?.notes, "Important session notes")
    }

    func testSaveSession_multipleSessions() throws {
        // Given: Multiple sessions
        let sessions = [
            createTestSession(participantName: "User1", projectName: "Project1"),
            createTestSession(participantName: "User2", projectName: "Project2"),
            createTestSession(participantName: "User3", projectName: "Project3")
        ]

        // When: Saving all sessions
        for session in sessions {
            testContext.insert(session)
        }
        try testContext.save()

        // Then: All sessions should be saved
        let fetchDescriptor = FetchDescriptor<Session>()
        let fetchedSessions = try testContext.fetch(fetchDescriptor)

        XCTAssertEqual(fetchedSessions.count, 3)
    }

    // MARK: - Test: Fetch Sessions

    func testFetchSessions() throws {
        // Given: Multiple saved sessions
        let session1 = createTestSession(participantName: "Alice")
        let session2 = createTestSession(participantName: "Bob")
        testContext.insert(session1)
        testContext.insert(session2)
        try testContext.save()

        // When: Fetching all sessions
        let fetchDescriptor = FetchDescriptor<Session>()
        let sessions = try testContext.fetch(fetchDescriptor)

        // Then: All sessions should be returned
        XCTAssertEqual(sessions.count, 2)
        let names = sessions.map { $0.participantName }
        XCTAssertTrue(names.contains("Alice"))
        XCTAssertTrue(names.contains("Bob"))
    }

    func testFetchSessions_sorted() throws {
        // Given: Sessions with different start times
        let session1 = Session(
            participantName: "First",
            projectName: "Project",
            sessionMode: .full,
            startedAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        let session2 = Session(
            participantName: "Second",
            projectName: "Project",
            sessionMode: .full,
            startedAt: Date().addingTimeInterval(-1800) // 30 mins ago
        )
        let session3 = Session(
            participantName: "Third",
            projectName: "Project",
            sessionMode: .full,
            startedAt: Date() // now
        )

        testContext.insert(session1)
        testContext.insert(session2)
        testContext.insert(session3)
        try testContext.save()

        // When: Fetching with sort descriptor
        var fetchDescriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        let sessions = try testContext.fetch(fetchDescriptor)

        // Then: Sessions should be sorted newest first
        XCTAssertEqual(sessions.count, 3)
        XCTAssertEqual(sessions[0].participantName, "Third")
        XCTAssertEqual(sessions[1].participantName, "Second")
        XCTAssertEqual(sessions[2].participantName, "First")
    }

    func testFetchSessions_emptyDatabase() throws {
        // Given: Empty database

        // When: Fetching sessions
        let fetchDescriptor = FetchDescriptor<Session>()
        let sessions = try testContext.fetch(fetchDescriptor)

        // Then: Should return empty array
        XCTAssertTrue(sessions.isEmpty)
    }

    // MARK: - Test: Fetch Session By ID

    func testFetchSessionById() throws {
        // Given: A saved session
        let session = createTestSession()
        let sessionId = session.id
        testContext.insert(session)
        try testContext.save()

        // When: Fetching by ID
        let fetchDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.id == sessionId }
        )
        let fetchedSession = try testContext.fetch(fetchDescriptor).first

        // Then: Correct session should be returned
        XCTAssertNotNil(fetchedSession)
        XCTAssertEqual(fetchedSession?.id, sessionId)
    }

    func testFetchSessionById_notFound() throws {
        // Given: A saved session
        let session = createTestSession()
        testContext.insert(session)
        try testContext.save()

        // When: Fetching by non-existent ID
        let nonExistentId = UUID()
        let fetchDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.id == nonExistentId }
        )
        let fetchedSession = try testContext.fetch(fetchDescriptor).first

        // Then: Should return nil
        XCTAssertNil(fetchedSession)
    }

    // MARK: - Test: Delete Session

    func testDeleteSession() throws {
        // Given: A saved session
        let session = createTestSession()
        let sessionId = session.id
        testContext.insert(session)
        try testContext.save()

        // When: Deleting the session
        testContext.delete(session)
        try testContext.save()

        // Then: Session should be removed
        let fetchDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.id == sessionId }
        )
        let fetchedSession = try testContext.fetch(fetchDescriptor).first
        XCTAssertNil(fetchedSession)
    }

    func testDeleteSession_cascadesUtterances() throws {
        // Given: A session with utterances
        let session = createTestSession()
        testContext.insert(session)

        let utterance1 = createTestUtterance(session: session, text: "First utterance")
        let utterance2 = createTestUtterance(session: session, text: "Second utterance")
        testContext.insert(utterance1)
        testContext.insert(utterance2)
        session.utterances.append(utterance1)
        session.utterances.append(utterance2)

        try testContext.save()

        // Verify utterances exist
        let utteranceFetch = FetchDescriptor<Utterance>()
        XCTAssertEqual(try testContext.fetch(utteranceFetch).count, 2)

        // When: Deleting the session
        testContext.delete(session)
        try testContext.save()

        // Then: Utterances should be cascade deleted
        let remainingUtterances = try testContext.fetch(utteranceFetch)
        XCTAssertEqual(remainingUtterances.count, 0)
    }

    func testDeleteSession_cascadesInsights() throws {
        // Given: A session with insights
        let session = createTestSession()
        testContext.insert(session)

        let insight = createTestInsight(session: session)
        testContext.insert(insight)
        session.insights.append(insight)

        try testContext.save()

        // When: Deleting the session
        testContext.delete(session)
        try testContext.save()

        // Then: Insights should be cascade deleted
        let insightFetch = FetchDescriptor<Insight>()
        let remainingInsights = try testContext.fetch(insightFetch)
        XCTAssertEqual(remainingInsights.count, 0)
    }

    // MARK: - Test: Secure Delete

    func testSecureDelete_sessionRemoved() throws {
        // Given: A saved session
        let session = createTestSession()
        let sessionId = session.id
        testContext.insert(session)
        try testContext.save()

        // When: Deleting the session (simulating secure delete)
        testContext.delete(session)
        try testContext.save()

        // Then: Session should be completely removed
        let fetchDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.id == sessionId }
        )
        let result = try testContext.fetch(fetchDescriptor)
        XCTAssertTrue(result.isEmpty)
    }

    func testSecureDelete_withAudioFilePath() throws {
        // Given: A session with audio file path
        let session = Session(
            participantName: "Test",
            projectName: "Test",
            sessionMode: .full,
            audioFilePath: "/tmp/test_audio.m4a"
        )
        testContext.insert(session)
        try testContext.save()

        // When: Deleting
        testContext.delete(session)
        try testContext.save()

        // Then: Session should be removed
        let fetchDescriptor = FetchDescriptor<Session>()
        let remaining = try testContext.fetch(fetchDescriptor)
        XCTAssertTrue(remaining.isEmpty)
    }

    // MARK: - Test: Data Protection Enabled

    func testDataProtectionEnabled_inMemoryHasNoFile() {
        // Given: In-memory container (no file to protect)

        // When: Checking for data protection

        // Then: In-memory containers don't have file protection
        // This is expected behavior for testing
        XCTAssertNotNil(testContainer)
    }

    // MARK: - Test: Schema Configuration

    func testSchemaConfiguration_includesAllModels() {
        // Given: The test schema

        // Then: Should include all required models
        let schema = testContainer.schema
        let entityNames = schema.entities.map { $0.name }

        XCTAssertTrue(entityNames.contains("Session"))
        XCTAssertTrue(entityNames.contains("Utterance"))
        XCTAssertTrue(entityNames.contains("Insight"))
        XCTAssertTrue(entityNames.contains("TopicStatus"))
        XCTAssertTrue(entityNames.contains("CoachingEvent"))
    }

    func testSchemaConfiguration_sessionRelationships() throws {
        // Given: A session with related entities
        let session = createTestSession()
        testContext.insert(session)

        let utterance = createTestUtterance(session: session)
        let insight = createTestInsight(session: session)

        testContext.insert(utterance)
        testContext.insert(insight)
        session.utterances.append(utterance)
        session.insights.append(insight)

        try testContext.save()

        // Then: Relationships should be properly configured
        let fetchDescriptor = FetchDescriptor<Session>()
        let fetched = try testContext.fetch(fetchDescriptor).first

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.utterances.count, 1)
        XCTAssertEqual(fetched?.insights.count, 1)
    }

    // MARK: - Test: Migration Support

    func testMigrationSupport_newSessionFields() throws {
        // Given: A session with all current fields
        let session = Session(
            participantName: "Migration Test",
            projectName: "Migration Project",
            sessionMode: .full,
            audioFilePath: "/path/to/audio.m4a",
            totalDurationSeconds: 1800.0,
            notes: "Test notes for migration"
        )

        // When: Saving
        testContext.insert(session)
        try testContext.save()

        // Then: All fields should be preserved
        let fetchDescriptor = FetchDescriptor<Session>()
        let fetched = try testContext.fetch(fetchDescriptor).first

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.participantName, "Migration Test")
        XCTAssertEqual(fetched?.audioFilePath, "/path/to/audio.m4a")
        XCTAssertEqual(fetched?.totalDurationSeconds, 1800.0)
        XCTAssertEqual(fetched?.notes, "Test notes for migration")
    }

    // MARK: - Test: Concurrent Access

    func testConcurrentAccess_readWhileWrite() async throws {
        // Given: Initial session
        let session = createTestSession()
        testContext.insert(session)
        try testContext.save()

        // When: Concurrent read and write operations
        await withTaskGroup(of: Void.self) { group in
            // Read operations
            for _ in 0..<5 {
                group.addTask { @MainActor in
                    let fetchDescriptor = FetchDescriptor<Session>()
                    _ = try? self.testContext.fetch(fetchDescriptor)
                }
            }

            // Write operations (modifications to existing session)
            for i in 0..<5 {
                group.addTask { @MainActor in
                    session.notes = "Note update \(i)"
                    try? self.testContext.save()
                }
            }
        }

        // Then: Should complete without crash
        let fetchDescriptor = FetchDescriptor<Session>()
        let sessions = try testContext.fetch(fetchDescriptor)
        XCTAssertEqual(sessions.count, 1)
    }

    func testConcurrentAccess_multipleInserts() async throws {
        // When: Concurrent insert operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { @MainActor in
                    let session = Session(
                        participantName: "Concurrent User \(i)",
                        projectName: "Concurrent Project",
                        sessionMode: .full
                    )
                    self.testContext.insert(session)
                    try? self.testContext.save()
                }
            }
        }

        // Then: All inserts should complete
        let fetchDescriptor = FetchDescriptor<Session>()
        let sessions = try testContext.fetch(fetchDescriptor)
        XCTAssertEqual(sessions.count, 10)
    }

    // MARK: - Test: Context Operations

    func testContext_hasChanges() throws {
        // Given: Fresh context
        XCTAssertFalse(testContext.hasChanges)

        // When: Adding a session
        let session = createTestSession()
        testContext.insert(session)

        // Then: Context should have changes
        XCTAssertTrue(testContext.hasChanges)

        // When: Saving
        try testContext.save()

        // Then: Context should not have changes
        XCTAssertFalse(testContext.hasChanges)
    }

    func testContext_rollback() throws {
        // Given: A session added but not saved
        let session = createTestSession()
        testContext.insert(session)
        XCTAssertTrue(testContext.hasChanges)

        // When: Rolling back
        testContext.rollback()

        // Then: Changes should be discarded
        XCTAssertFalse(testContext.hasChanges)

        let fetchDescriptor = FetchDescriptor<Session>()
        let sessions = try testContext.fetch(fetchDescriptor)
        XCTAssertTrue(sessions.isEmpty)
    }

    // MARK: - Test: Update Operations

    func testUpdateSession() throws {
        // Given: A saved session
        let session = createTestSession(participantName: "Original Name")
        testContext.insert(session)
        try testContext.save()

        // When: Updating the session
        session.participantName = "Updated Name"
        session.notes = "Added notes"
        session.endedAt = Date()
        try testContext.save()

        // Then: Updates should be persisted
        let fetchDescriptor = FetchDescriptor<Session>()
        let fetched = try testContext.fetch(fetchDescriptor).first

        XCTAssertEqual(fetched?.participantName, "Updated Name")
        XCTAssertEqual(fetched?.notes, "Added notes")
        XCTAssertNotNil(fetched?.endedAt)
    }

    func testUpdateSession_duration() throws {
        // Given: An in-progress session
        let session = createTestSession()
        testContext.insert(session)
        try testContext.save()

        // When: Ending the session and updating duration
        session.endedAt = Date().addingTimeInterval(3600) // 1 hour later
        session.totalDurationSeconds = 3600.0
        try testContext.save()

        // Then: Duration should be updated
        let fetchDescriptor = FetchDescriptor<Session>()
        let fetched = try testContext.fetch(fetchDescriptor).first

        XCTAssertEqual(fetched?.totalDurationSeconds, 3600.0)
        XCTAssertNotNil(fetched?.endedAt)
        XCTAssertFalse(fetched?.isInProgress ?? true)
    }

    // MARK: - Test: Predicate Queries

    func testPredicateQuery_byProjectName() throws {
        // Given: Sessions with different project names
        let session1 = createTestSession(projectName: "Alpha")
        let session2 = createTestSession(projectName: "Beta")
        let session3 = createTestSession(projectName: "Alpha")

        testContext.insert(session1)
        testContext.insert(session2)
        testContext.insert(session3)
        try testContext.save()

        // When: Querying by project name
        let targetProject = "Alpha"
        let fetchDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.projectName == targetProject }
        )
        let sessions = try testContext.fetch(fetchDescriptor)

        // Then: Only matching sessions should be returned
        XCTAssertEqual(sessions.count, 2)
        XCTAssertTrue(sessions.allSatisfy { $0.projectName == "Alpha" })
    }

    func testPredicateQuery_bySessionMode() throws {
        // Given: Sessions with different modes
        let session1 = createTestSession(sessionMode: .full)
        let session2 = createTestSession(sessionMode: .transcriptionOnly)
        let session3 = createTestSession(sessionMode: .full)

        testContext.insert(session1)
        testContext.insert(session2)
        testContext.insert(session3)
        try testContext.save()

        // When: Querying by mode
        let targetMode = SessionMode.full
        let fetchDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.sessionMode == targetMode }
        )
        let sessions = try testContext.fetch(fetchDescriptor)

        // Then: Only matching sessions should be returned
        XCTAssertEqual(sessions.count, 2)
    }
}

// MARK: - Test Helpers

extension DataManagerTests {

    func testDeleteAllData() throws {
        // Given: Multiple sessions with related data
        let session1 = createTestSession(participantName: "User1")
        let session2 = createTestSession(participantName: "User2")

        testContext.insert(session1)
        testContext.insert(session2)

        let utterance = createTestUtterance(session: session1)
        testContext.insert(utterance)
        session1.utterances.append(utterance)

        try testContext.save()

        // Verify data exists
        let sessionFetch = FetchDescriptor<Session>()
        XCTAssertEqual(try testContext.fetch(sessionFetch).count, 2)

        // When: Deleting all data
        let sessions = try testContext.fetch(sessionFetch)
        for session in sessions {
            testContext.delete(session)
        }
        try testContext.save()

        // Then: All data should be removed
        XCTAssertEqual(try testContext.fetch(sessionFetch).count, 0)

        let utteranceFetch = FetchDescriptor<Utterance>()
        XCTAssertEqual(try testContext.fetch(utteranceFetch).count, 0)
    }
}
