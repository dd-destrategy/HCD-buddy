//
//  TranscriptionBufferTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for TranscriptionBuffer partial and final handling
//

import XCTest
@testable import HCDInterviewCoach

final class TranscriptionBufferTests: XCTestCase {

    var buffer: TranscriptionBuffer!

    override func setUp() {
        super.setUp()
        buffer = TranscriptionBuffer()
    }

    override func tearDown() async throws {
        await buffer.clear()
        buffer = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createPartialEvent(
        text: String,
        speaker: Speaker? = .participant,
        timestamp: TimeInterval = 0.0,
        confidence: Double = 0.8
    ) -> TranscriptionEvent {
        TranscriptionEvent(
            text: text,
            isFinal: false,
            speaker: speaker,
            timestamp: timestamp,
            confidence: confidence
        )
    }

    private func createFinalEvent(
        text: String,
        speaker: Speaker? = .participant,
        timestamp: TimeInterval = 0.0,
        confidence: Double = 0.95
    ) -> TranscriptionEvent {
        TranscriptionEvent(
            text: text,
            isFinal: true,
            speaker: speaker,
            timestamp: timestamp,
            confidence: confidence
        )
    }

    // MARK: - Test: Buffer Partial Transcription

    func testBufferPartialTranscription_storesText() async {
        // Given: A partial transcription event
        let event = createPartialEvent(text: "Hello, how are")

        // When: Process the event
        let update = await buffer.process(event)

        // Then: Should return partial update
        guard case .partial(let partial) = update else {
            XCTFail("Expected partial update")
            return
        }
        XCTAssertEqual(partial.text, "Hello, how are")
    }

    func testBufferPartialTranscription_storesSpeaker() async {
        // Given: Partial event with speaker
        let event = createPartialEvent(text: "Testing", speaker: .interviewer)

        // When: Process the event
        let update = await buffer.process(event)

        // Then: Should include speaker
        guard case .partial(let partial) = update else {
            XCTFail("Expected partial update")
            return
        }
        XCTAssertEqual(partial.speaker, .interviewer)
    }

    func testBufferPartialTranscription_storesTimestamp() async {
        // Given: Partial event with timestamp
        let event = createPartialEvent(text: "Test", timestamp: 5.5)

        // When: Process the event
        let update = await buffer.process(event)

        // Then: Should include timestamp
        guard case .partial(let partial) = update else {
            XCTFail("Expected partial update")
            return
        }
        XCTAssertEqual(partial.startTimestamp, 5.5)
    }

    // MARK: - Test: Buffer Final Transcription

    func testBufferFinalTranscription_createsSegment() async {
        // Given: A final transcription event
        let event = createFinalEvent(
            text: "Hello, how are you today?",
            speaker: .participant,
            timestamp: 2.0,
            confidence: 0.98
        )

        // When: Process the event
        let update = await buffer.process(event)

        // Then: Should return finalized segment
        guard case .finalized(let segment) = update else {
            XCTFail("Expected finalized update")
            return
        }
        XCTAssertEqual(segment.text, "Hello, how are you today?")
        XCTAssertEqual(segment.speaker, .participant)
        XCTAssertEqual(segment.confidence, 0.98)
    }

    func testBufferFinalTranscription_storesInSegments() async {
        // Given: Final event
        let event = createFinalEvent(text: "Complete sentence.", timestamp: 3.0)

        // When: Process the event
        _ = await buffer.process(event)

        // Then: Should be in segments list
        let segments = await buffer.getAllSegments()
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments.first?.text, "Complete sentence.")
    }

    func testBufferFinalTranscription_dropsShortText() async {
        // Given: Final event with very short text
        let event = createFinalEvent(text: "H", timestamp: 1.0)

        // When: Process the event
        let update = await buffer.process(event)

        // Then: Should be dropped (too short)
        guard case .dropped(let reason) = update else {
            XCTFail("Expected dropped update")
            return
        }
        XCTAssertTrue(reason.contains("short"))
    }

    // MARK: - Test: Buffer Merges Partials

    func testBufferMergesPartials_replacesText() async {
        // Given: Multiple partial events (streaming behavior replaces)
        let event1 = createPartialEvent(text: "Hello", timestamp: 0.0)
        let event2 = createPartialEvent(text: "Hello, how", timestamp: 0.5)
        let event3 = createPartialEvent(text: "Hello, how are you", timestamp: 1.0)

        // When: Process all events
        _ = await buffer.process(event1)
        _ = await buffer.process(event2)
        let update = await buffer.process(event3)

        // Then: Should have latest text (API sends cumulative partials)
        guard case .partial(let partial) = update else {
            XCTFail("Expected partial update")
            return
        }
        XCTAssertEqual(partial.text, "Hello, how are you")
    }

    func testBufferMergesPartials_keepsStartTimestamp() async {
        // Given: Multiple partial events
        let event1 = createPartialEvent(text: "Hello", timestamp: 1.0)
        let event2 = createPartialEvent(text: "Hello world", timestamp: 2.0)

        // When: Process events
        _ = await buffer.process(event1)
        let update = await buffer.process(event2)

        // Then: Should keep original start timestamp
        guard case .partial(let partial) = update else {
            XCTFail("Expected partial update")
            return
        }
        XCTAssertEqual(partial.startTimestamp, 1.0)
    }

    // MARK: - Test: Buffer Clears On Final

    func testBufferClearsOnFinal_clearsPartial() async {
        // Given: Partial followed by final
        let partialEvent = createPartialEvent(text: "Testing", timestamp: 0.0)
        let finalEvent = createFinalEvent(text: "Testing complete", timestamp: 1.0)

        _ = await buffer.process(partialEvent)

        // Verify partial exists
        let partial = await buffer.getCurrentPartial()
        XCTAssertNotNil(partial)

        // When: Process final event
        _ = await buffer.process(finalEvent)

        // Then: Partial should be cleared
        let partialAfter = await buffer.getCurrentPartial()
        XCTAssertNil(partialAfter)
    }

    func testBufferClearsOnFinal_resetsSpeaker() async {
        // Given: Partial with speaker
        let partialEvent = createPartialEvent(text: "Test", speaker: .interviewer)
        let finalEvent = createFinalEvent(text: "Test done", speaker: .interviewer)

        _ = await buffer.process(partialEvent)
        _ = await buffer.process(finalEvent)

        // When: New partial without speaker
        let newPartial = createPartialEvent(text: "New", speaker: nil)
        let update = await buffer.process(newPartial)

        // Then: Should not inherit previous speaker
        guard case .partial(let partial) = update else {
            XCTFail("Expected partial update")
            return
        }
        // Speaker should be nil or default for new segment
        XCTAssertTrue(partial.speaker == nil)
    }

    // MARK: - Test: Buffer Handles Multiple Speakers

    func testBufferHandlesMultipleSpeakers_finalizeOnChange() async {
        // Given: Partial from one speaker
        let event1 = createPartialEvent(text: "Question asked", speaker: .interviewer, timestamp: 0.0)
        _ = await buffer.process(event1)

        // When: New speaker starts
        let event2 = createPartialEvent(text: "Answer given", speaker: .participant, timestamp: 2.0)
        let update = await buffer.process(event2)

        // Then: Should finalize previous and start new
        guard case .finalizedWithNewPartial(let segment, let newText) = update else {
            XCTFail("Expected finalizedWithNewPartial update")
            return
        }
        XCTAssertEqual(segment.speaker, .interviewer)
        XCTAssertEqual(segment.text, "Question asked")
        XCTAssertEqual(newText, "Answer given")
    }

    func testBufferHandlesMultipleSpeakers_tracksSeparately() async {
        // Given: Alternating speakers with finals
        let event1 = createFinalEvent(text: "First question", speaker: .interviewer, timestamp: 1.0)
        let event2 = createFinalEvent(text: "First answer", speaker: .participant, timestamp: 3.0)
        let event3 = createFinalEvent(text: "Second question", speaker: .interviewer, timestamp: 5.0)

        _ = await buffer.process(event1)
        _ = await buffer.process(event2)
        _ = await buffer.process(event3)

        // Then: All segments should be stored
        let segments = await buffer.getAllSegments()
        XCTAssertEqual(segments.count, 3)
        XCTAssertEqual(segments[0].speaker, .interviewer)
        XCTAssertEqual(segments[1].speaker, .participant)
        XCTAssertEqual(segments[2].speaker, .interviewer)
    }

    func testBufferHandlesMultipleSpeakers_unknownSpeaker() async {
        // Given: Partial without speaker
        let event = createPartialEvent(text: "Unknown speech", speaker: nil, timestamp: 0.0)
        _ = await buffer.process(event)

        // When: Finalize
        let finalEvent = createFinalEvent(text: "Unknown speech final", speaker: nil, timestamp: 1.0)
        let update = await buffer.process(finalEvent)

        // Then: Should use unknown speaker
        guard case .finalized(let segment) = update else {
            XCTFail("Expected finalized update")
            return
        }
        XCTAssertEqual(segment.speaker, .unknown)
    }

    // MARK: - Test: Buffer Timestamp Ordering

    func testBufferTimestampOrdering_preservesOrder() async {
        // Given: Events with increasing timestamps
        let events = [
            createFinalEvent(text: "First segment", timestamp: 1.0),
            createFinalEvent(text: "Second segment", timestamp: 3.0),
            createFinalEvent(text: "Third segment", timestamp: 5.0)
        ]

        // When: Process all events
        for event in events {
            _ = await buffer.process(event)
        }

        // Then: Segments should be in order
        let segments = await buffer.getAllSegments()
        XCTAssertEqual(segments.count, 3)
        XCTAssertLessThan(segments[0].endTimestamp, segments[1].endTimestamp)
        XCTAssertLessThan(segments[1].endTimestamp, segments[2].endTimestamp)
    }

    func testBufferTimestampOrdering_calculatesDuration() async {
        // Given: Event with known timestamps
        let partial = createPartialEvent(text: "Start", timestamp: 10.0)
        _ = await buffer.process(partial)

        let final = createFinalEvent(text: "Complete text", timestamp: 15.0)
        let update = await buffer.process(final)

        // Then: Duration should be calculated correctly
        guard case .finalized(let segment) = update else {
            XCTFail("Expected finalized update")
            return
        }
        XCTAssertEqual(segment.startTimestamp, 10.0)
        XCTAssertEqual(segment.endTimestamp, 15.0)
        XCTAssertEqual(segment.duration, 5.0)
    }

    // MARK: - Test: Buffer Capacity Limit (Auto-finalize)

    func testBufferCapacityLimit_autoFinalizeOnTimeout() async {
        // Given: Partial that exceeds max duration
        let event1 = createPartialEvent(text: "Long running partial", timestamp: 0.0)
        _ = await buffer.process(event1)

        // When: New event comes after max duration (30s default)
        let event2 = createPartialEvent(text: "New text", timestamp: 35.0)
        let update = await buffer.process(event2)

        // Then: Should auto-finalize previous
        guard case .finalizedWithNewPartial(let segment, _) = update else {
            XCTFail("Expected finalizedWithNewPartial for timeout")
            return
        }
        XCTAssertEqual(segment.finalizationReason, .timeout)
        // Auto-finalized segments have lower confidence
        XCTAssertEqual(segment.confidence, 0.7)
    }

    func testBufferCapacityLimit_normalDurationNotAffected() async {
        // Given: Partial within normal duration
        let event1 = createPartialEvent(text: "Normal partial", timestamp: 0.0)
        _ = await buffer.process(event1)

        // When: New partial within limit
        let event2 = createPartialEvent(text: "Updated partial", timestamp: 5.0)
        let update = await buffer.process(event2)

        // Then: Should just update partial
        guard case .partial = update else {
            XCTFail("Expected partial update, not finalized")
            return
        }
    }

    // MARK: - Test: Buffer Flush

    func testBufferFlush_finalizesCurrentPartial() async {
        // Given: Active partial
        let event = createPartialEvent(text: "Pending partial text", timestamp: 10.0)
        _ = await buffer.process(event)

        // When: Flush buffer
        let segment = await buffer.flush(at: 15.0)

        // Then: Should return finalized segment
        XCTAssertNotNil(segment)
        XCTAssertEqual(segment?.text, "Pending partial text")
        XCTAssertEqual(segment?.finalizationReason, .manualFlush)
        XCTAssertEqual(segment?.endTimestamp, 15.0)
    }

    func testBufferFlush_returnsNilWhenEmpty() async {
        // Given: Empty buffer

        // When: Flush buffer
        let segment = await buffer.flush(at: 10.0)

        // Then: Should return nil
        XCTAssertNil(segment)
    }

    func testBufferFlush_clearsPartialState() async {
        // Given: Active partial
        let event = createPartialEvent(text: "Some text", timestamp: 0.0)
        _ = await buffer.process(event)

        // When: Flush
        _ = await buffer.flush(at: 5.0)

        // Then: Partial should be cleared
        let partial = await buffer.getCurrentPartial()
        XCTAssertNil(partial)
    }

    func testBufferFlush_addsFlushedToSegments() async {
        // Given: Active partial
        let event = createPartialEvent(text: "Flush me", timestamp: 0.0)
        _ = await buffer.process(event)

        // When: Flush
        _ = await buffer.flush(at: 5.0)

        // Then: Should be in segments list
        let segments = await buffer.getAllSegments()
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments.first?.text, "Flush me")
    }

    // MARK: - Test: Buffer Clear

    func testBufferClear_removesAllData() async {
        // Given: Buffer with data
        _ = await buffer.process(createFinalEvent(text: "Segment 1", timestamp: 1.0))
        _ = await buffer.process(createFinalEvent(text: "Segment 2", timestamp: 2.0))
        _ = await buffer.process(createPartialEvent(text: "Partial", timestamp: 3.0))

        // When: Clear buffer
        await buffer.clear()

        // Then: All data should be cleared
        let segments = await buffer.getAllSegments()
        let partial = await buffer.getCurrentPartial()
        let stats = await buffer.getStatistics()

        XCTAssertTrue(segments.isEmpty)
        XCTAssertNil(partial)
        XCTAssertEqual(stats.totalPartialEvents, 0)
        XCTAssertEqual(stats.totalFinalEvents, 0)
    }

    // MARK: - Test: Statistics

    func testStatistics_tracksPartialEvents() async {
        // Given: Multiple partial events
        _ = await buffer.process(createPartialEvent(text: "P1", timestamp: 0))
        _ = await buffer.process(createPartialEvent(text: "P2", timestamp: 1))
        _ = await buffer.process(createPartialEvent(text: "P3", timestamp: 2))

        // When: Get statistics
        let stats = await buffer.getStatistics()

        // Then: Should count partials
        XCTAssertEqual(stats.totalPartialEvents, 3)
    }

    func testStatistics_tracksFinalEvents() async {
        // Given: Multiple final events
        _ = await buffer.process(createFinalEvent(text: "F1", timestamp: 0))
        _ = await buffer.process(createFinalEvent(text: "F2", timestamp: 1))

        // When: Get statistics
        let stats = await buffer.getStatistics()

        // Then: Should count finals
        XCTAssertEqual(stats.totalFinalEvents, 2)
    }

    func testStatistics_tracksDroppedPartials() async {
        // Given: Events that will be dropped (short text)
        _ = await buffer.process(createFinalEvent(text: "A", timestamp: 0))
        _ = await buffer.process(createFinalEvent(text: "B", timestamp: 1))

        // When: Get statistics
        let stats = await buffer.getStatistics()

        // Then: Should count dropped
        XCTAssertEqual(stats.droppedPartials, 2)
    }

    func testStatistics_hasActivePartial() async {
        // Given: No partial
        var stats = await buffer.getStatistics()
        XCTAssertFalse(stats.hasActivePartial)

        // When: Add partial
        _ = await buffer.process(createPartialEvent(text: "Active", timestamp: 0))

        // Then: Should indicate active
        stats = await buffer.getStatistics()
        XCTAssertTrue(stats.hasActivePartial)
    }

    func testStatistics_finalizationRate() async {
        // Given: Mix of partial and final events
        _ = await buffer.process(createPartialEvent(text: "P1", timestamp: 0))
        _ = await buffer.process(createPartialEvent(text: "P2", timestamp: 1))
        _ = await buffer.process(createFinalEvent(text: "Final text", timestamp: 2))

        // When: Get statistics
        let stats = await buffer.getStatistics()

        // Then: Finalization rate should be calculated
        // 1 final / 3 total events (2 partial + 1 final as partial counter might not count final)
        XCTAssertGreaterThan(stats.finalizationRate, 0)
    }

    // MARK: - Test: Segment Properties

    func testSegmentProperties_wordCount() async {
        // Given: Final event with multiple words
        let event = createFinalEvent(text: "This is a test sentence with words", timestamp: 0)
        let update = await buffer.process(event)

        // Then: Word count should be calculated
        guard case .finalized(let segment) = update else {
            XCTFail("Expected finalized")
            return
        }
        XCTAssertEqual(segment.wordCount, 7)
    }

    func testSegmentProperties_duration() async {
        // Given: Partial followed by final
        let partial = createPartialEvent(text: "Start", timestamp: 5.0)
        _ = await buffer.process(partial)

        let final = createFinalEvent(text: "Start to finish", timestamp: 10.0)
        let update = await buffer.process(final)

        // Then: Duration should be calculated
        guard case .finalized(let segment) = update else {
            XCTFail("Expected finalized")
            return
        }
        XCTAssertEqual(segment.duration, 5.0)
    }

    // MARK: - Test: Callback Notification

    func testCallbackNotification_calledOnFinalize() async {
        // Given: Callback configured
        let expectation = XCTestExpectation(description: "Callback called")
        var receivedSegment: TranscriptionSegment?

        await buffer.setOnSegmentFinalized { segment in
            receivedSegment = segment
            expectation.fulfill()
        }

        // When: Process final event
        let event = createFinalEvent(text: "Callback test", timestamp: 0)
        _ = await buffer.process(event)

        // Then: Callback should be called
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedSegment)
        XCTAssertEqual(receivedSegment?.text, "Callback test")
    }

    func testCallbackNotification_calledOnSpeakerChange() async {
        // Given: Callback configured
        let expectation = XCTestExpectation(description: "Callback on speaker change")

        await buffer.setOnSegmentFinalized { _ in
            expectation.fulfill()
        }

        // Process partial from speaker 1
        let partial1 = createPartialEvent(text: "Speaker one", speaker: .interviewer, timestamp: 0)
        _ = await buffer.process(partial1)

        // When: New speaker triggers finalization
        let partial2 = createPartialEvent(text: "Speaker two", speaker: .participant, timestamp: 2)
        _ = await buffer.process(partial2)

        // Then: Callback should be called for finalized segment
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Test: Finalization Reasons

    func testFinalizationReasons_apiFinalized() async {
        // Given: Normal final event
        let event = createFinalEvent(text: "API final", timestamp: 0)
        let update = await buffer.process(event)

        // Then: Reason should be apiFinalized
        guard case .finalized(let segment) = update else {
            XCTFail("Expected finalized")
            return
        }
        XCTAssertEqual(segment.finalizationReason, .apiFinalized)
    }

    func testFinalizationReasons_speakerChange() async {
        // Given: Partial from one speaker
        let partial1 = createPartialEvent(text: "First speaker", speaker: .interviewer, timestamp: 0)
        _ = await buffer.process(partial1)

        // When: Different speaker
        let partial2 = createPartialEvent(text: "Second speaker", speaker: .participant, timestamp: 2)
        let update = await buffer.process(partial2)

        // Then: First segment should have speakerChange reason
        guard case .finalizedWithNewPartial(let segment, _) = update else {
            XCTFail("Expected finalizedWithNewPartial")
            return
        }
        XCTAssertEqual(segment.finalizationReason, .speakerChange)
    }

    func testFinalizationReasons_manualFlush() async {
        // Given: Active partial
        let partial = createPartialEvent(text: "To flush", timestamp: 0)
        _ = await buffer.process(partial)

        // When: Manual flush
        let segment = await buffer.flush(at: 5.0)

        // Then: Reason should be manualFlush
        XCTAssertEqual(segment?.finalizationReason, .manualFlush)
    }
}

// MARK: - Transcription Stream Provider Tests

final class TranscriptionStreamProviderTests: XCTestCase {

    func testStreamProvider_yieldsUpdates() async {
        // Given: Stream provider
        let provider = TranscriptionStreamProvider()

        // Set up consumer
        let expectation = XCTestExpectation(description: "Receive update")
        var received: TranscriptionUpdate?

        Task {
            for await update in provider.stream {
                received = update
                expectation.fulfill()
                break
            }
        }

        // When: Yield an update
        try? await Task.sleep(nanoseconds: 100_000_000)
        let segment = TranscriptionSegment(
            id: UUID(),
            text: "Test",
            speaker: .participant,
            startTimestamp: 0,
            endTimestamp: 1,
            confidence: 0.9,
            finalizationReason: .apiFinalized
        )
        provider.yield(.finalized(segment))

        // Then: Should receive update
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(received)
    }

    func testStreamProvider_finishes() async {
        // Given: Stream provider
        let provider = TranscriptionStreamProvider()

        let expectation = XCTestExpectation(description: "Stream finishes")

        Task {
            for await _ in provider.stream {
                // Consume
            }
            expectation.fulfill()
        }

        // When: Finish the stream
        try? await Task.sleep(nanoseconds: 100_000_000)
        provider.finish()

        // Then: Consumer should complete
        await fulfillment(of: [expectation], timeout: 2.0)
    }
}
