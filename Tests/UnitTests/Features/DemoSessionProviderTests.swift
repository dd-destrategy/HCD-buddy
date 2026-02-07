//
//  DemoSessionProviderTests.swift
//  HCDInterviewCoach Tests
//
//  Unit tests for DemoSessionProvider
//  Tests demo session creation, transcript content, playback start/stop,
//  and reset functionality.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class DemoSessionProviderTests: XCTestCase {

    var demoProvider: DemoSessionProvider!

    override func setUp() {
        super.setUp()
        demoProvider = DemoSessionProvider.shared
        demoProvider.resetPlayback()
    }

    override func tearDown() {
        demoProvider.stopPlayback()
        demoProvider.resetPlayback()
        demoProvider = nil
        super.tearDown()
    }

    // MARK: - Test: Demo Session Creation

    func testDemoSession_hasCorrectParticipantName() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Participant name should be "Sarah (Demo)"
        XCTAssertEqual(session.participantName, "Sarah (Demo)", "Demo session should have 'Sarah (Demo)' as participant")
    }

    func testDemoSession_hasCorrectProjectName() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Project name should be "Task Management Research"
        XCTAssertEqual(session.projectName, "Task Management Research", "Demo session should have correct project name")
    }

    func testDemoSession_hasFullSessionMode() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Session mode should be full
        XCTAssertEqual(session.sessionMode, .full, "Demo session should use full session mode")
    }

    func testDemoSession_hasDuration() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Should have a 30-minute simulated duration
        XCTAssertEqual(session.totalDurationSeconds, 1800, "Demo session should have 1800 seconds duration")
    }

    // MARK: - Test: Utterance Count

    func testDemoSession_hasExpectedUtteranceCount() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Should have 20 or more utterances
        XCTAssertGreaterThanOrEqual(
            session.utterances.count, 20,
            "Demo session should have at least 20 utterances, got \(session.utterances.count)"
        )
    }

    func testDemoSession_hasBothSpeakers() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Should have utterances from both interviewer and participant
        let interviewerCount = session.utterances.filter { $0.speaker == .interviewer }.count
        let participantCount = session.utterances.filter { $0.speaker == .participant }.count

        XCTAssertGreaterThan(interviewerCount, 0, "Demo should have interviewer utterances")
        XCTAssertGreaterThan(participantCount, 0, "Demo should have participant utterances")
    }

    func testDemoSession_utterancesHaveTimestamps() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: All utterances should have positive timestamps
        for utterance in session.utterances {
            XCTAssertGreaterThan(
                utterance.timestampSeconds, 0,
                "Utterance should have a positive timestamp"
            )
        }
    }

    func testDemoSession_utterancesAreChronological() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Utterances should be in chronological order
        for i in 1..<session.utterances.count {
            XCTAssertGreaterThanOrEqual(
                session.utterances[i].timestampSeconds,
                session.utterances[i - 1].timestampSeconds,
                "Utterances should be in chronological order at index \(i)"
            )
        }
    }

    func testDemoSession_utterancesHaveNonEmptyText() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: All utterances should have non-empty text
        for utterance in session.utterances {
            XCTAssertFalse(
                utterance.text.isEmpty,
                "Utterance at \(utterance.timestampSeconds)s should have non-empty text"
            )
        }
    }

    // MARK: - Test: Insights

    func testDemoSession_hasInsights() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Should have insights
        XCTAssertFalse(session.insights.isEmpty, "Demo session should have insights")
        XCTAssertGreaterThanOrEqual(session.insights.count, 3, "Demo session should have at least 3 insights")
    }

    func testDemoSession_insightsHaveThemes() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: All insights should have non-empty themes
        for insight in session.insights {
            XCTAssertFalse(insight.theme.isEmpty, "Insight should have a non-empty theme")
        }
    }

    func testDemoSession_insightsHaveQuotes() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: All insights should have non-empty quotes
        for insight in session.insights {
            XCTAssertFalse(insight.quote.isEmpty, "Insight should have a non-empty quote")
        }
    }

    func testDemoSession_insightsHaveValidTimestamps() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: All insights should have positive timestamps within session duration
        for insight in session.insights {
            XCTAssertGreaterThan(insight.timestampSeconds, 0, "Insight timestamp should be positive")
            XCTAssertLessThanOrEqual(
                insight.timestampSeconds,
                session.totalDurationSeconds,
                "Insight timestamp should be within session duration"
            )
        }
    }

    // MARK: - Test: Topic Statuses

    func testDemoSession_hasTopicStatuses() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Should have topic statuses
        XCTAssertFalse(session.topicStatuses.isEmpty, "Demo session should have topic statuses")
        XCTAssertGreaterThanOrEqual(session.topicStatuses.count, 3, "Demo session should have at least 3 topics")
    }

    func testDemoSession_topicStatusesHaveMixedCoverage() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Should have a mix of coverage levels
        let statuses = Set(session.topicStatuses.map { $0.status })
        XCTAssertGreaterThan(statuses.count, 1, "Topic statuses should have mixed coverage levels")
    }

    func testDemoSession_topicStatusesHaveNames() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: All topic statuses should have non-empty names
        for topic in session.topicStatuses {
            XCTAssertFalse(topic.topicName.isEmpty, "Topic should have a non-empty name")
            XCTAssertFalse(topic.topicId.isEmpty, "Topic should have a non-empty ID")
        }
    }

    // MARK: - Test: Coaching Events

    func testDemoSession_hasCoachingEvents() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Should have coaching events
        XCTAssertFalse(session.coachingEvents.isEmpty, "Demo session should have coaching events")
        XCTAssertGreaterThanOrEqual(session.coachingEvents.count, 1, "Should have at least 1 coaching event")
    }

    func testDemoSession_coachingEventsHaveContent() {
        // Given/When: Create a demo session
        let session = demoProvider.createDemoSession()

        // Then: Coaching events should have prompt text and reason
        for event in session.coachingEvents {
            XCTAssertFalse(event.promptText.isEmpty, "Coaching event should have prompt text")
            XCTAssertFalse(event.reason.isEmpty, "Coaching event should have a reason")
        }
    }

    // MARK: - Test: Demo Transcript Property

    func testDemoTranscript_isNotEmpty() {
        // Given/When: Access the demo transcript
        let transcript = demoProvider.demoTranscript

        // Then: Should not be empty
        XCTAssertFalse(transcript.isEmpty, "Demo transcript should not be empty")
        XCTAssertGreaterThanOrEqual(transcript.count, 20, "Demo transcript should have at least 20 entries")
    }

    func testDemoTranscript_matchesSessionUtterances() {
        // Given: Create a demo session and access the transcript
        let session = demoProvider.createDemoSession()
        let transcript = demoProvider.demoTranscript

        // Then: Session utterances should match the transcript
        XCTAssertEqual(
            session.utterances.count,
            transcript.count,
            "Session utterance count should match transcript count"
        )
    }

    // MARK: - Test: Playback Start/Stop

    func testPlayback_initialState() {
        // Given: Fresh provider (reset in setUp)

        // Then: Should not be playing
        XCTAssertFalse(demoProvider.isPlayingDemo, "Should not be playing initially")
        XCTAssertEqual(demoProvider.playbackProgress, 0.0, "Progress should be 0 initially")
        XCTAssertEqual(demoProvider.currentUtteranceIndex, 0, "Utterance index should be 0 initially")
    }

    func testPlayback_startSetsPlaying() {
        // Given: Not playing
        XCTAssertFalse(demoProvider.isPlayingDemo)

        // When: Start playback
        demoProvider.startPlayback(speed: 1.0)

        // Then: Should be playing
        XCTAssertTrue(demoProvider.isPlayingDemo, "Should be playing after start")
    }

    func testPlayback_stopSetsNotPlaying() {
        // Given: Playing
        demoProvider.startPlayback(speed: 1.0)
        XCTAssertTrue(demoProvider.isPlayingDemo)

        // When: Stop playback
        demoProvider.stopPlayback()

        // Then: Should not be playing
        XCTAssertFalse(demoProvider.isPlayingDemo, "Should not be playing after stop")
    }

    func testPlayback_doubleStartIsIgnored() {
        // Given: Already playing
        demoProvider.startPlayback(speed: 1.0)

        // When: Start again
        demoProvider.startPlayback(speed: 2.0)

        // Then: Should still be playing (not crash or error)
        XCTAssertTrue(demoProvider.isPlayingDemo)
    }

    func testPlayback_doubleStopIsIgnored() {
        // Given: Not playing
        XCTAssertFalse(demoProvider.isPlayingDemo)

        // When: Stop (when already stopped)
        demoProvider.stopPlayback()

        // Then: Should still not be playing (not crash or error)
        XCTAssertFalse(demoProvider.isPlayingDemo)
    }

    func testPlayback_progressUpdates() async throws {
        // Given: Start fast playback
        demoProvider.startPlayback(speed: 100.0) // Very fast speed for testing

        // When: Wait briefly for timer to fire
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Then: Progress should have advanced
        XCTAssertGreaterThan(demoProvider.playbackProgress, 0.0, "Progress should advance during playback")

        // Cleanup
        demoProvider.stopPlayback()
    }

    // MARK: - Test: Reset

    func testReset_returnsToBeginning() {
        // Given: Started and potentially advanced playback
        demoProvider.startPlayback(speed: 1.0)

        // When: Reset
        demoProvider.resetPlayback()

        // Then: Should be at beginning and stopped
        XCTAssertFalse(demoProvider.isPlayingDemo, "Should not be playing after reset")
        XCTAssertEqual(demoProvider.playbackProgress, 0.0, "Progress should be 0 after reset")
        XCTAssertEqual(demoProvider.currentUtteranceIndex, 0, "Utterance index should be 0 after reset")
    }

    func testReset_whileNotPlaying() {
        // Given: Not playing, but with some state
        demoProvider.startPlayback(speed: 1.0)
        demoProvider.stopPlayback()

        // When: Reset
        demoProvider.resetPlayback()

        // Then: Should be at beginning
        XCTAssertEqual(demoProvider.playbackProgress, 0.0)
        XCTAssertEqual(demoProvider.currentUtteranceIndex, 0)
    }

    // MARK: - Test: Singleton

    func testSingleton_returnsSameInstance() {
        // Given/When: Access shared instance twice
        let instance1 = DemoSessionProvider.shared
        let instance2 = DemoSessionProvider.shared

        // Then: Should be the same object
        XCTAssertTrue(instance1 === instance2, "Shared instances should be identical")
    }

    // MARK: - Test: Multiple Session Creation

    func testCreateDemoSession_canBeCalledMultipleTimes() {
        // Given/When: Create demo sessions multiple times
        let session1 = demoProvider.createDemoSession()
        let session2 = demoProvider.createDemoSession()

        // Then: Both should be valid
        XCTAssertEqual(session1.participantName, "Sarah (Demo)")
        XCTAssertEqual(session2.participantName, "Sarah (Demo)")
        XCTAssertFalse(session1.utterances.isEmpty)
        XCTAssertFalse(session2.utterances.isEmpty)
    }
}
