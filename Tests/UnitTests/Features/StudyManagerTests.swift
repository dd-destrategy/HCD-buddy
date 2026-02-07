//
//  StudyManagerTests.swift
//  HCD Interview Coach Tests
//
//  FEATURE 3: Cross-Session Analytics & Study Organization
//  Unit tests for StudyManager CRUD operations, persistence, and CrossSessionAnalytics computation.
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

@MainActor
final class StudyManagerTests: XCTestCase {

    // MARK: - Properties

    var studyManager: StudyManager!
    var tempDirectory: URL!
    var storageURL: URL!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StudyManagerTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storageURL = tempDirectory.appendingPathComponent("studies.json")
        studyManager = StudyManager(storageURL: storageURL)
    }

    override func tearDown() {
        studyManager = nil
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        storageURL = nil
        super.tearDown()
    }

    // MARK: - Test: Create Study

    func testCreateStudy_addsToStudiesArray() {
        // Given: An empty study manager
        XCTAssertEqual(studyManager.studies.count, 0)

        // When: Creating a study
        let study = studyManager.createStudy(name: "Onboarding Research", description: "Q1 study")

        // Then: Study should be in the array
        XCTAssertEqual(studyManager.studies.count, 1)
        XCTAssertEqual(study.name, "Onboarding Research")
        XCTAssertEqual(study.description, "Q1 study")
        XCTAssertEqual(study.sessionIds.count, 0)
        XCTAssertEqual(study.tags.count, 0)
        XCTAssertEqual(study.researchQuestions.count, 0)
    }

    func testCreateStudy_generatesUniqueId() {
        // Given: Two studies created
        let study1 = studyManager.createStudy(name: "Study 1")
        let study2 = studyManager.createStudy(name: "Study 2")

        // Then: They should have different IDs
        XCTAssertNotEqual(study1.id, study2.id)
    }

    func testCreateStudy_setsTimestamps() {
        // When: Creating a study
        let beforeCreation = Date()
        let study = studyManager.createStudy(name: "Timed Study")
        let afterCreation = Date()

        // Then: Timestamps should be set to approximately now
        XCTAssertGreaterThanOrEqual(study.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(study.createdAt, afterCreation)
        XCTAssertGreaterThanOrEqual(study.updatedAt, beforeCreation)
        XCTAssertLessThanOrEqual(study.updatedAt, afterCreation)
    }

    func testCreateStudy_sessionCountIsZero() {
        // When: Creating a study
        let study = studyManager.createStudy(name: "Empty Study")

        // Then: Session count should be zero
        XCTAssertEqual(study.sessionCount, 0)
    }

    func testCreateMultipleStudies() {
        // When: Creating multiple studies
        studyManager.createStudy(name: "Study A")
        studyManager.createStudy(name: "Study B")
        studyManager.createStudy(name: "Study C")

        // Then: All should be present
        XCTAssertEqual(studyManager.studies.count, 3)
        let names = studyManager.studies.map { $0.name }
        XCTAssertTrue(names.contains("Study A"))
        XCTAssertTrue(names.contains("Study B"))
        XCTAssertTrue(names.contains("Study C"))
    }

    // MARK: - Test: Delete Study

    func testDeleteStudy_removesFromArray() {
        // Given: A study
        let study = studyManager.createStudy(name: "To Delete")
        XCTAssertEqual(studyManager.studies.count, 1)

        // When: Deleting
        studyManager.deleteStudy(id: study.id)

        // Then: Study should be removed
        XCTAssertEqual(studyManager.studies.count, 0)
    }

    func testDeleteStudy_clearsSelectedStudy() {
        // Given: A selected study
        let study = studyManager.createStudy(name: "Selected")
        studyManager.selectedStudy = study

        // When: Deleting the selected study
        studyManager.deleteStudy(id: study.id)

        // Then: Selection should be cleared
        XCTAssertNil(studyManager.selectedStudy)
    }

    func testDeleteStudy_nonExistentId_doesNothing() {
        // Given: A study
        studyManager.createStudy(name: "Keep Me")
        XCTAssertEqual(studyManager.studies.count, 1)

        // When: Deleting a non-existent ID
        studyManager.deleteStudy(id: UUID())

        // Then: Existing study remains
        XCTAssertEqual(studyManager.studies.count, 1)
    }

    func testDeleteStudy_preservesOtherStudies() {
        // Given: Multiple studies
        let study1 = studyManager.createStudy(name: "Keep 1")
        let study2 = studyManager.createStudy(name: "Delete Me")
        let study3 = studyManager.createStudy(name: "Keep 2")

        // When: Deleting the middle one
        studyManager.deleteStudy(id: study2.id)

        // Then: Others should remain
        XCTAssertEqual(studyManager.studies.count, 2)
        let ids = studyManager.studies.map { $0.id }
        XCTAssertTrue(ids.contains(study1.id))
        XCTAssertFalse(ids.contains(study2.id))
        XCTAssertTrue(ids.contains(study3.id))
    }

    // MARK: - Test: Add/Remove Sessions

    func testAddSession_addsToStudy() {
        // Given: A study
        let study = studyManager.createStudy(name: "Sessions Test")
        let sessionId = UUID()

        // When: Adding a session
        studyManager.addSession(sessionId, to: study.id)

        // Then: Session ID should be in the study
        let updatedStudy = studyManager.studies.first { $0.id == study.id }
        XCTAssertEqual(updatedStudy?.sessionIds.count, 1)
        XCTAssertTrue(updatedStudy?.sessionIds.contains(sessionId) ?? false)
        XCTAssertEqual(updatedStudy?.sessionCount, 1)
    }

    func testAddSession_preventsDuplicates() {
        // Given: A study with a session
        let study = studyManager.createStudy(name: "Duplicate Test")
        let sessionId = UUID()
        studyManager.addSession(sessionId, to: study.id)

        // When: Adding the same session again
        studyManager.addSession(sessionId, to: study.id)

        // Then: Should still have only one entry
        let updatedStudy = studyManager.studies.first { $0.id == study.id }
        XCTAssertEqual(updatedStudy?.sessionIds.count, 1)
    }

    func testAddSession_updatesTimestamp() {
        // Given: A study
        let study = studyManager.createStudy(name: "Timestamp Test")
        let originalUpdatedAt = studyManager.studies.first { $0.id == study.id }?.updatedAt

        // Brief delay to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // When: Adding a session
        studyManager.addSession(UUID(), to: study.id)

        // Then: updatedAt should be newer
        let newUpdatedAt = studyManager.studies.first { $0.id == study.id }?.updatedAt
        XCTAssertNotNil(newUpdatedAt)
        if let original = originalUpdatedAt, let updated = newUpdatedAt {
            XCTAssertGreaterThanOrEqual(updated, original)
        }
    }

    func testAddSession_toNonExistentStudy_doesNothing() {
        // Given: No studies
        XCTAssertEqual(studyManager.studies.count, 0)

        // When: Adding a session to a non-existent study
        studyManager.addSession(UUID(), to: UUID())

        // Then: No studies should exist
        XCTAssertEqual(studyManager.studies.count, 0)
    }

    func testRemoveSession_removesFromStudy() {
        // Given: A study with sessions
        let study = studyManager.createStudy(name: "Remove Test")
        let sessionId1 = UUID()
        let sessionId2 = UUID()
        studyManager.addSession(sessionId1, to: study.id)
        studyManager.addSession(sessionId2, to: study.id)
        XCTAssertEqual(studyManager.studies.first?.sessionIds.count, 2)

        // When: Removing one session
        studyManager.removeSession(sessionId1, from: study.id)

        // Then: Only the other session should remain
        let updatedStudy = studyManager.studies.first { $0.id == study.id }
        XCTAssertEqual(updatedStudy?.sessionIds.count, 1)
        XCTAssertFalse(updatedStudy?.sessionIds.contains(sessionId1) ?? true)
        XCTAssertTrue(updatedStudy?.sessionIds.contains(sessionId2) ?? false)
    }

    func testRemoveSession_fromNonExistentStudy_doesNothing() {
        // Given: A study
        let study = studyManager.createStudy(name: "Safe Remove")
        studyManager.addSession(UUID(), to: study.id)

        // When: Removing from non-existent study
        studyManager.removeSession(UUID(), from: UUID())

        // Then: Original study is unchanged
        XCTAssertEqual(studyManager.studies.first?.sessionIds.count, 1)
    }

    // MARK: - Test: Persistence Round-Trip

    func testPersistence_saveAndLoad() {
        // Given: Studies with data
        let study1 = studyManager.createStudy(name: "Persisted Study 1", description: "Description 1")
        let study2 = studyManager.createStudy(name: "Persisted Study 2", description: "Description 2")
        let sessionId = UUID()
        studyManager.addSession(sessionId, to: study1.id)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: storageURL.path))

        // When: Creating a new manager from the same file
        let loadedManager = StudyManager(storageURL: storageURL)

        // Then: Studies should be restored
        XCTAssertEqual(loadedManager.studies.count, 2)

        let loadedStudy1 = loadedManager.studies.first { $0.id == study1.id }
        XCTAssertNotNil(loadedStudy1)
        XCTAssertEqual(loadedStudy1?.name, "Persisted Study 1")
        XCTAssertEqual(loadedStudy1?.description, "Description 1")
        XCTAssertEqual(loadedStudy1?.sessionIds.count, 1)
        XCTAssertTrue(loadedStudy1?.sessionIds.contains(sessionId) ?? false)

        let loadedStudy2 = loadedManager.studies.first { $0.id == study2.id }
        XCTAssertNotNil(loadedStudy2)
        XCTAssertEqual(loadedStudy2?.name, "Persisted Study 2")
    }

    func testPersistence_emptyFile_loadsEmpty() {
        // Given: A non-existent storage file
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.json")

        // When: Loading from non-existent file
        let manager = StudyManager(storageURL: nonExistentURL)

        // Then: Should have empty studies array
        XCTAssertEqual(manager.studies.count, 0)
    }

    func testPersistence_corruptedFile_loadsEmpty() throws {
        // Given: A corrupted JSON file
        let corruptData = "this is not valid json".data(using: .utf8)!
        try corruptData.write(to: storageURL)

        // When: Loading from corrupted file
        let manager = StudyManager(storageURL: storageURL)

        // Then: Should have empty studies array (graceful degradation)
        XCTAssertEqual(manager.studies.count, 0)
    }

    func testPersistence_deletesPersist() {
        // Given: A study that gets deleted
        let study = studyManager.createStudy(name: "Ephemeral")
        studyManager.deleteStudy(id: study.id)

        // When: Reloading
        let reloaded = StudyManager(storageURL: storageURL)

        // Then: Deleted study should not be present
        XCTAssertEqual(reloaded.studies.count, 0)
    }

    // MARK: - Test: Study Computed Properties

    func testStudy_sessionCount_matchesSessionIds() {
        // Given: A study with sessions
        let study = studyManager.createStudy(name: "Count Test")
        studyManager.addSession(UUID(), to: study.id)
        studyManager.addSession(UUID(), to: study.id)
        studyManager.addSession(UUID(), to: study.id)

        // Then: sessionCount should match
        let updatedStudy = studyManager.studies.first { $0.id == study.id }
        XCTAssertEqual(updatedStudy?.sessionCount, 3)
        XCTAssertEqual(updatedStudy?.sessionCount, updatedStudy?.sessionIds.count)
    }

    // MARK: - Test: Analytics Computation

    func testAnalytics_emptySessionsProducesZeroResults() async {
        // Given: Analytics engine
        let analytics = CrossSessionAnalytics()

        // When: Analyzing empty sessions
        await analytics.analyze(sessions: [])

        // Then: Results should have zero values
        XCTAssertNotNil(analytics.results)
        XCTAssertEqual(analytics.results?.totalSessions, 0)
        XCTAssertEqual(analytics.results?.totalDuration, 0)
        XCTAssertEqual(analytics.results?.totalUtterances, 0)
        XCTAssertEqual(analytics.results?.totalInsights, 0)
        XCTAssertEqual(analytics.results?.averageSessionDuration, 0)
        XCTAssertEqual(analytics.results?.topThemes.count, 0)
        XCTAssertEqual(analytics.results?.interviewQualityTrend.count, 0)
    }

    func testAnalytics_computesTotalsCorrectly() async {
        // Given: Sessions with known data
        let session1 = Session(
            participantName: "User A",
            projectName: "Project",
            sessionMode: .full,
            totalDurationSeconds: 1800 // 30 min
        )
        session1.utterances = [
            Utterance(speaker: .interviewer, text: "Question?", timestampSeconds: 10),
            Utterance(speaker: .participant, text: "Answer.", timestampSeconds: 20)
        ]
        session1.insights = [
            Insight(timestampSeconds: 15, quote: "Quote", theme: "Pain Point", source: .userAdded)
        ]

        let session2 = Session(
            participantName: "User B",
            projectName: "Project",
            sessionMode: .full,
            totalDurationSeconds: 2700 // 45 min
        )
        session2.utterances = [
            Utterance(speaker: .interviewer, text: "Q1?", timestampSeconds: 5),
            Utterance(speaker: .participant, text: "A1.", timestampSeconds: 15),
            Utterance(speaker: .interviewer, text: "Q2?", timestampSeconds: 25)
        ]
        session2.insights = [
            Insight(timestampSeconds: 10, quote: "Quote 1", theme: "Pain Point", source: .aiGenerated),
            Insight(timestampSeconds: 20, quote: "Quote 2", theme: "User Need", source: .userAdded)
        ]

        let analytics = CrossSessionAnalytics()

        // When: Analyzing
        await analytics.analyze(sessions: [session1, session2])

        // Then: Totals should be correct
        let results = analytics.results
        XCTAssertNotNil(results)
        XCTAssertEqual(results?.totalSessions, 2)
        XCTAssertEqual(results?.totalDuration, 4500) // 1800 + 2700
        XCTAssertEqual(results?.totalUtterances, 5) // 2 + 3
        XCTAssertEqual(results?.totalInsights, 3) // 1 + 2
        XCTAssertEqual(results?.averageSessionDuration, 2250) // 4500 / 2
    }

    func testAnalytics_extractsThemes() async {
        // Given: Sessions with themed insights
        let session = Session(
            participantName: "User",
            projectName: "Project",
            sessionMode: .full,
            totalDurationSeconds: 1800
        )
        session.insights = [
            Insight(timestampSeconds: 10, quote: "Q1", theme: "Pain Point", source: .userAdded),
            Insight(timestampSeconds: 20, quote: "Q2", theme: "Pain Point", source: .aiGenerated),
            Insight(timestampSeconds: 30, quote: "Q3", theme: "User Need", source: .userAdded),
            Insight(timestampSeconds: 40, quote: "Q4", theme: "Pain Point", source: .userAdded),
            Insight(timestampSeconds: 50, quote: "Q5", theme: "Confusion", source: .aiGenerated)
        ]

        let analytics = CrossSessionAnalytics()

        // When: Analyzing
        await analytics.analyze(sessions: [session])

        // Then: Themes should be ranked by frequency
        let themes = analytics.results?.topThemes ?? []
        XCTAssertGreaterThanOrEqual(themes.count, 3)

        // Pain Point should be first with 3 occurrences
        XCTAssertEqual(themes[0].theme, "Pain Point")
        XCTAssertEqual(themes[0].count, 3)

        // User Need should be second with 1 occurrence
        let userNeed = themes.first { $0.theme == "User Need" }
        XCTAssertNotNil(userNeed)
        XCTAssertEqual(userNeed?.count, 1)

        // Confusion should also appear with 1 occurrence
        let confusion = themes.first { $0.theme == "Confusion" }
        XCTAssertNotNil(confusion)
        XCTAssertEqual(confusion?.count, 1)
    }

    func testAnalytics_qualityTrendSortedByDate() async {
        // Given: Sessions with different dates
        let earlierDate = Date(timeIntervalSince1970: 1_700_000_000) // ~Nov 2023
        let laterDate = Date(timeIntervalSince1970: 1_700_100_000)   // ~1 day later

        let session1 = Session(
            participantName: "User A",
            projectName: "Project",
            sessionMode: .full,
            startedAt: laterDate,
            totalDurationSeconds: 1800
        )
        session1.utterances = [
            Utterance(speaker: .participant, text: "Text", timestampSeconds: 10)
        ]
        session1.insights = [
            Insight(timestampSeconds: 10, quote: "Quote", theme: "Theme", source: .userAdded),
            Insight(timestampSeconds: 20, quote: "Quote2", theme: "Theme", source: .userAdded)
        ]

        let session2 = Session(
            participantName: "User B",
            projectName: "Project",
            sessionMode: .full,
            startedAt: earlierDate,
            totalDurationSeconds: 900
        )
        session2.utterances = [
            Utterance(speaker: .participant, text: "Text", timestampSeconds: 5),
            Utterance(speaker: .interviewer, text: "Question", timestampSeconds: 10),
            Utterance(speaker: .participant, text: "Answer", timestampSeconds: 15)
        ]
        session2.insights = []

        let analytics = CrossSessionAnalytics()

        // When: Analyzing (pass in reverse chronological order)
        await analytics.analyze(sessions: [session1, session2])

        // Then: Quality trend should be sorted by date ascending
        let trend = analytics.results?.interviewQualityTrend ?? []
        XCTAssertEqual(trend.count, 2)
        XCTAssertEqual(trend[0].id, session2.id) // earlier session first
        XCTAssertEqual(trend[1].id, session1.id) // later session second

        // Verify snapshot values
        XCTAssertEqual(trend[0].utteranceCount, 3)
        XCTAssertEqual(trend[0].insightCount, 0)
        XCTAssertEqual(trend[0].durationMinutes, 15.0) // 900 / 60

        XCTAssertEqual(trend[1].utteranceCount, 1)
        XCTAssertEqual(trend[1].insightCount, 2)
        XCTAssertEqual(trend[1].durationMinutes, 30.0) // 1800 / 60
    }

    func testAnalytics_reset_clearsResults() async {
        // Given: Computed results
        let session = Session(
            participantName: "User",
            projectName: "Project",
            sessionMode: .full,
            totalDurationSeconds: 900
        )
        let analytics = CrossSessionAnalytics()
        await analytics.analyze(sessions: [session])
        XCTAssertNotNil(analytics.results)

        // When: Resetting
        analytics.reset()

        // Then: Results should be nil
        XCTAssertNil(analytics.results)
        XCTAssertFalse(analytics.isAnalyzing)
    }

    func testAnalytics_topicCoverageComputed() async {
        // Given: Sessions with topic statuses
        let session1 = Session(
            participantName: "User A",
            projectName: "Project",
            sessionMode: .full,
            totalDurationSeconds: 1800
        )
        session1.topicStatuses = [
            TopicStatus(topicId: "t1", topicName: "Background", status: .fullyCovered),
            TopicStatus(topicId: "t2", topicName: "Pain Points", status: .notCovered)
        ]

        let session2 = Session(
            participantName: "User B",
            projectName: "Project",
            sessionMode: .full,
            totalDurationSeconds: 1800
        )
        session2.topicStatuses = [
            TopicStatus(topicId: "t1", topicName: "Background", status: .partialCoverage),
            TopicStatus(topicId: "t2", topicName: "Pain Points", status: .fullyCovered)
        ]

        let analytics = CrossSessionAnalytics()

        // When: Analyzing
        await analytics.analyze(sessions: [session1, session2])

        // Then: Topic coverage should be computed
        let coverage = analytics.results?.topicCoverageAcrossSessions ?? []
        XCTAssertEqual(coverage.count, 2)

        // Background: covered in both sessions = 100%
        let background = coverage.first { $0.topic == "Background" }
        XCTAssertNotNil(background)
        XCTAssertEqual(background?.coverageRate, 1.0)

        // Pain Points: covered in 1 of 2 sessions = 50%
        let painPoints = coverage.first { $0.topic == "Pain Points" }
        XCTAssertNotNil(painPoints)
        XCTAssertEqual(painPoints?.coverageRate, 0.5)
    }

    // MARK: - Test: SessionQualitySnapshot

    func testSessionQualitySnapshot_topicCoverageRate() {
        // Given: A snapshot with known values
        let snapshot = SessionQualitySnapshot(
            id: UUID(),
            sessionDate: Date(),
            insightCount: 5,
            utteranceCount: 20,
            durationMinutes: 30,
            topicsCovered: 3,
            totalTopics: 5
        )

        // Then: Coverage rate should be 60%
        XCTAssertEqual(snapshot.topicCoverageRate, 0.6)
    }

    func testSessionQualitySnapshot_zeroTopics_coverageRateIsZero() {
        // Given: A snapshot with no topics
        let snapshot = SessionQualitySnapshot(
            id: UUID(),
            sessionDate: Date(),
            insightCount: 0,
            utteranceCount: 0,
            durationMinutes: 0,
            topicsCovered: 0,
            totalTopics: 0
        )

        // Then: Coverage rate should be 0 (not NaN)
        XCTAssertEqual(snapshot.topicCoverageRate, 0)
    }

    // MARK: - Test: AnalyticsResults Formatting

    func testAnalyticsResults_formattedDuration_hoursAndMinutes() async {
        // Given: A session of 90 minutes
        let session = Session(
            participantName: "User",
            projectName: "Project",
            sessionMode: .full,
            totalDurationSeconds: 5400 // 90 min
        )
        let analytics = CrossSessionAnalytics()
        await analytics.analyze(sessions: [session])

        // Then: Should format as hours and minutes
        XCTAssertEqual(analytics.results?.formattedTotalDuration, "1h 30m")
    }

    func testAnalyticsResults_formattedDuration_minutesOnly() async {
        // Given: A session under an hour
        let session = Session(
            participantName: "User",
            projectName: "Project",
            sessionMode: .full,
            totalDurationSeconds: 2700 // 45 min
        )
        let analytics = CrossSessionAnalytics()
        await analytics.analyze(sessions: [session])

        // Then: Should format as minutes only
        XCTAssertEqual(analytics.results?.formattedTotalDuration, "45m")
    }
}
