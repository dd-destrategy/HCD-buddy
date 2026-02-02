//
//  TranscriptionEventHandlerTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for TranscriptionEventHandler transcription parsing
//

import XCTest
@testable import HCDInterviewCoach

final class TranscriptionEventHandlerTests: XCTestCase {

    // MARK: - Properties

    var eventHandler: TranscriptionEventHandler!
    var sessionStartTime: Date!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sessionStartTime = Date()
        eventHandler = TranscriptionEventHandler(sessionStartTime: sessionStartTime)
    }

    override func tearDown() {
        eventHandler = nil
        sessionStartTime = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a delta event for testing
    private func createDeltaEvent(
        delta: String,
        speaker: String? = nil,
        confidence: Double? = nil,
        timestamp: Date? = nil
    ) -> RealtimeEvent {
        var payload: [String: Any] = ["delta": delta]
        if let speaker = speaker {
            payload["speaker"] = speaker
        }
        if let confidence = confidence {
            payload["confidence"] = confidence
        }
        return RealtimeEvent(
            type: .transcriptionDelta,
            payload: payload,
            timestamp: timestamp ?? Date()
        )
    }

    /// Creates a complete event for testing
    private func createCompleteEvent(
        transcript: String,
        speaker: String? = nil,
        confidence: Double? = nil,
        timestamp: Date? = nil
    ) -> RealtimeEvent {
        var payload: [String: Any] = ["transcript": transcript]
        if let speaker = speaker {
            payload["speaker"] = speaker
        }
        if let confidence = confidence {
            payload["confidence"] = confidence
        }
        return RealtimeEvent(
            type: .transcriptionComplete,
            payload: payload,
            timestamp: timestamp ?? Date()
        )
    }

    /// Creates a function call event for testing
    private func createFunctionCallEvent(
        name: String,
        arguments: [String: Any],
        timestamp: Date? = nil
    ) -> RealtimeEvent {
        var payload: [String: Any] = [
            "name": name,
            "arguments": arguments,
            "call_id": UUID().uuidString
        ]
        return RealtimeEvent(
            type: .functionCall,
            payload: payload,
            timestamp: timestamp ?? Date()
        )
    }

    // MARK: - Test: Parse Partial Transcription

    func testParsePartialTranscription_validDelta() {
        // Given: A delta event with partial text
        let event = createDeltaEvent(delta: "Hello, how are ")

        // When: Parsing the delta
        let result = eventHandler.parseDelta(event)

        // Then: Should return a partial transcription event
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.text, "Hello, how are ")
        XCTAssertFalse(result?.isFinal ?? true)
    }

    func testParsePartialTranscription_multipleDeltasAccumulate() {
        // Given: Multiple consecutive delta events
        let delta1 = createDeltaEvent(delta: "Hello, ")
        let delta2 = createDeltaEvent(delta: "how ")
        let delta3 = createDeltaEvent(delta: "are you?")

        // When: Parsing each delta
        let result1 = eventHandler.parseDelta(delta1)
        let result2 = eventHandler.parseDelta(delta2)
        let result3 = eventHandler.parseDelta(delta3)

        // Then: Each should return the individual delta text
        XCTAssertEqual(result1?.text, "Hello, ")
        XCTAssertEqual(result2?.text, "how ")
        XCTAssertEqual(result3?.text, "are you?")
    }

    func testParsePartialTranscription_wrongEventType() {
        // Given: A complete event (not delta)
        let event = createCompleteEvent(transcript: "Final text")

        // When: Trying to parse as delta
        let result = eventHandler.parseDelta(event)

        // Then: Should return nil
        XCTAssertNil(result)
    }

    func testParsePartialTranscription_missingDelta() {
        // Given: An event without delta field
        let event = RealtimeEvent(
            type: .transcriptionDelta,
            payload: ["other": "data"],
            timestamp: Date()
        )

        // When: Parsing
        let result = eventHandler.parseDelta(event)

        // Then: Should return nil and increment parse errors
        XCTAssertNil(result)
        XCTAssertEqual(eventHandler.statistics.parseErrors, 1)
    }

    // MARK: - Test: Parse Final Transcription

    func testParseFinalTranscription_valid() {
        // Given: A complete event
        let event = createCompleteEvent(transcript: "This is the final transcription.")

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Should return a final transcription event
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.text, "This is the final transcription.")
        XCTAssertTrue(result?.isFinal ?? false)
    }

    func testParseFinalTranscription_wrongEventType() {
        // Given: A delta event
        let event = createDeltaEvent(delta: "Partial text")

        // When: Trying to parse as complete
        let result = eventHandler.parseComplete(event)

        // Then: Should return nil
        XCTAssertNil(result)
    }

    func testParseFinalTranscription_missingTranscript() {
        // Given: A complete event without transcript field
        let event = RealtimeEvent(
            type: .transcriptionComplete,
            payload: ["other": "data"],
            timestamp: Date()
        )

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Should return nil and increment parse errors
        XCTAssertNil(result)
        XCTAssertEqual(eventHandler.statistics.parseErrors, 1)
    }

    func testParseFinalTranscription_clearsPartial() {
        // Given: A partial transcription in progress
        _ = eventHandler.parseDelta(createDeltaEvent(delta: "Partial "))
        _ = eventHandler.parseDelta(createDeltaEvent(delta: "text "))

        // When: Receiving a complete event
        let completeEvent = createCompleteEvent(transcript: "Partial text complete.")
        let result = eventHandler.parseComplete(completeEvent)

        // Then: Should have the final text
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.isFinal ?? false)
    }

    // MARK: - Test: Parse Speaker Change

    func testParseSpeakerChange_interviewer() {
        // Given: An event with interviewer speaker
        let event = createCompleteEvent(transcript: "Test", speaker: "interviewer")

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Should identify speaker as interviewer
        XCTAssertEqual(result?.speaker, .interviewer)
    }

    func testParseSpeakerChange_participant() {
        // Given: An event with participant speaker
        let event = createCompleteEvent(transcript: "Test", speaker: "participant")

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Should identify speaker as participant
        XCTAssertEqual(result?.speaker, .participant)
    }

    func testParseSpeakerChange_fromRole() {
        // Given: An event with role field instead of speaker
        let event = RealtimeEvent(
            type: .transcriptionComplete,
            payload: [
                "transcript": "Test",
                "role": "user"  // Should map to interviewer
            ],
            timestamp: Date()
        )

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Should infer speaker from role
        XCTAssertEqual(result?.speaker, .interviewer)
    }

    func testParseSpeakerChange_inferredFromContext() {
        // Given: Events that establish speaker pattern
        let event1 = createCompleteEvent(transcript: "Question?", speaker: "interviewer")
        _ = eventHandler.parseComplete(event1)

        // When: A subsequent event without explicit speaker
        let event2 = RealtimeEvent(
            type: .transcriptionComplete,
            payload: ["transcript": "Answer"],
            timestamp: Date().addingTimeInterval(2.0)  // After speaker turn threshold
        )
        let result = eventHandler.parseComplete(event2)

        // Then: Should infer speaker turn
        XCTAssertNotNil(result?.speaker)
    }

    // MARK: - Test: Parse Timestamp

    func testParseTimestamp_calculatedFromSessionStart() {
        // Given: Session started at a known time
        let laterTimestamp = sessionStartTime.addingTimeInterval(10.5)
        let event = RealtimeEvent(
            type: .transcriptionComplete,
            payload: ["transcript": "Test"],
            timestamp: laterTimestamp
        )

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Timestamp should be relative to session start
        XCTAssertEqual(result?.timestamp ?? 0, 10.5, accuracy: 0.1)
    }

    func testParseTimestamp_deltaEvent() {
        // Given: A delta event at a specific time
        let laterTimestamp = sessionStartTime.addingTimeInterval(5.0)
        let event = RealtimeEvent(
            type: .transcriptionDelta,
            payload: ["delta": "Text"],
            timestamp: laterTimestamp
        )

        // When: Parsing
        let result = eventHandler.parseDelta(event)

        // Then: Timestamp should be calculated correctly
        XCTAssertEqual(result?.timestamp ?? 0, 5.0, accuracy: 0.1)
    }

    // MARK: - Test: Parse Confidence

    func testParseConfidence_fromPayload() {
        // Given: An event with explicit confidence
        let event = createCompleteEvent(transcript: "Test", confidence: 0.95)

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Should have the specified confidence
        XCTAssertEqual(result?.confidence ?? 0, 0.95, accuracy: 0.01)
    }

    func testParseConfidence_defaultForDelta() {
        // Given: A delta event without confidence
        let event = createDeltaEvent(delta: "Test")

        // When: Parsing
        let result = eventHandler.parseDelta(event)

        // Then: Should have default confidence (0.8)
        XCTAssertEqual(result?.confidence ?? 0, 0.8, accuracy: 0.01)
    }

    func testParseConfidence_defaultForComplete() {
        // Given: A complete event without confidence
        let event = RealtimeEvent(
            type: .transcriptionComplete,
            payload: ["transcript": "Test"],
            timestamp: Date()
        )

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Should have default confidence (0.9)
        XCTAssertEqual(result?.confidence ?? 0, 0.9, accuracy: 0.01)
    }

    // MARK: - Test: Parse Function Call

    func testParseFunctionCall_showNudge() {
        // Given: A show_nudge function call event
        let event = createFunctionCallEvent(
            name: "show_nudge",
            arguments: [
                "text": "Consider asking about their experience",
                "reason": "Participant mentioned frustration"
            ]
        )

        // When: Parsing (handler doesn't parse function calls, but we test the event structure)
        XCTAssertEqual(event.type, .functionCall)
        XCTAssertEqual(event.payload["name"] as? String, "show_nudge")
    }

    func testParseFunctionCall_flagInsight() {
        // Given: A flag_insight function call event
        let event = createFunctionCallEvent(
            name: "flag_insight",
            arguments: [
                "quote": "I almost quit because of this issue",
                "theme": "Frustration with onboarding"
            ]
        )

        // Then: Event should have correct structure
        XCTAssertEqual(event.type, .functionCall)
        if let args = event.payload["arguments"] as? [String: Any] {
            XCTAssertEqual(args["quote"] as? String, "I almost quit because of this issue")
        }
    }

    // MARK: - Test: Parse Error

    func testParseError_invalidPayload() {
        // Given: An event with invalid payload
        let event = RealtimeEvent(
            type: .transcriptionDelta,
            payload: ["invalid": 12345],  // delta should be a string
            timestamp: Date()
        )

        // When: Parsing
        let result = eventHandler.parseDelta(event)

        // Then: Should return nil and track error
        XCTAssertNil(result)
        XCTAssertGreaterThan(eventHandler.statistics.parseErrors, 0)
    }

    func testParseError_emptyPayload() {
        // Given: An event with empty payload
        let event = RealtimeEvent(
            type: .transcriptionComplete,
            payload: [:],
            timestamp: Date()
        )

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Should return nil and track error
        XCTAssertNil(result)
        XCTAssertEqual(eventHandler.statistics.parseErrors, 1)
    }

    // MARK: - Test: Event Stream

    func testEventStream_multipleEvents() {
        // Given: Multiple events in sequence
        let events = [
            createDeltaEvent(delta: "Hello "),
            createDeltaEvent(delta: "world"),
            createCompleteEvent(transcript: "Hello world", speaker: "interviewer"),
            createCompleteEvent(transcript: "Response here", speaker: "participant")
        ]

        // When: Processing all events
        var deltaResults: [TranscriptionEvent] = []
        var completeResults: [TranscriptionEvent] = []

        for event in events {
            if let result = eventHandler.parseDelta(event) {
                deltaResults.append(result)
            }
            if let result = eventHandler.parseComplete(event) {
                completeResults.append(result)
            }
        }

        // Then: Should have correct counts
        XCTAssertEqual(deltaResults.count, 2)
        XCTAssertEqual(completeResults.count, 2)
    }

    // MARK: - Test: Malformed Event

    func testMalformedEvent_nullValues() {
        // Given: An event with null-like values
        let event = RealtimeEvent(
            type: .transcriptionComplete,
            payload: ["transcript": NSNull()],
            timestamp: Date()
        )

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Should return nil
        XCTAssertNil(result)
    }

    func testMalformedEvent_wrongTypes() {
        // Given: An event with wrong types
        let event = RealtimeEvent(
            type: .transcriptionComplete,
            payload: [
                "transcript": 12345,  // Should be string
                "confidence": "high"  // Should be double
            ],
            timestamp: Date()
        )

        // When: Parsing
        let result = eventHandler.parseComplete(event)

        // Then: Should return nil
        XCTAssertNil(result)
    }

    // MARK: - Test: Event Ordering

    func testEventOrdering_timestampsPreserved() {
        // Given: Events with specific timestamps
        let time1 = sessionStartTime.addingTimeInterval(1.0)
        let time2 = sessionStartTime.addingTimeInterval(2.0)
        let time3 = sessionStartTime.addingTimeInterval(3.0)

        let event1 = RealtimeEvent(type: .transcriptionComplete, payload: ["transcript": "First"], timestamp: time1)
        let event2 = RealtimeEvent(type: .transcriptionComplete, payload: ["transcript": "Second"], timestamp: time2)
        let event3 = RealtimeEvent(type: .transcriptionComplete, payload: ["transcript": "Third"], timestamp: time3)

        // When: Parsing in order
        let result1 = eventHandler.parseComplete(event1)
        let result2 = eventHandler.parseComplete(event2)
        let result3 = eventHandler.parseComplete(event3)

        // Then: Timestamps should be in order
        XCTAssertLessThan(result1?.timestamp ?? 0, result2?.timestamp ?? 0)
        XCTAssertLessThan(result2?.timestamp ?? 0, result3?.timestamp ?? 0)
    }

    // MARK: - Test: Reset

    func testReset_clearsState() {
        // Given: Handler with accumulated state
        _ = eventHandler.parseDelta(createDeltaEvent(delta: "Partial"))
        _ = eventHandler.parseComplete(createCompleteEvent(transcript: "Complete"))

        XCTAssertGreaterThan(eventHandler.statistics.deltaEventsProcessed, 0)
        XCTAssertGreaterThan(eventHandler.statistics.completeEventsProcessed, 0)

        // When: Resetting
        eventHandler.reset()

        // Then: State should be cleared
        XCTAssertEqual(eventHandler.statistics.deltaEventsProcessed, 0)
        XCTAssertEqual(eventHandler.statistics.completeEventsProcessed, 0)
        XCTAssertEqual(eventHandler.statistics.parseErrors, 0)
    }

    // MARK: - Test: Statistics

    func testStatistics_deltaEventsProcessed() {
        // Given: Processing delta events
        _ = eventHandler.parseDelta(createDeltaEvent(delta: "One"))
        _ = eventHandler.parseDelta(createDeltaEvent(delta: "Two"))
        _ = eventHandler.parseDelta(createDeltaEvent(delta: "Three"))

        // Then: Statistics should reflect processed deltas
        XCTAssertEqual(eventHandler.statistics.deltaEventsProcessed, 3)
    }

    func testStatistics_completeEventsProcessed() {
        // Given: Processing complete events
        _ = eventHandler.parseComplete(createCompleteEvent(transcript: "First"))
        _ = eventHandler.parseComplete(createCompleteEvent(transcript: "Second"))

        // Then: Statistics should reflect processed completes
        XCTAssertEqual(eventHandler.statistics.completeEventsProcessed, 2)
    }

    func testStatistics_totalWordsTranscribed() {
        // Given: Processing events with known word counts
        _ = eventHandler.parseComplete(createCompleteEvent(transcript: "Hello world"))  // 2 words
        _ = eventHandler.parseComplete(createCompleteEvent(transcript: "This is a test sentence"))  // 5 words

        // Then: Total words should be counted
        XCTAssertEqual(eventHandler.statistics.totalWordsTranscribed, 7)
    }

    func testStatistics_averageWordsPerUtterance() {
        // Given: Processing events with varying word counts
        _ = eventHandler.parseComplete(createCompleteEvent(transcript: "One two"))
        _ = eventHandler.parseComplete(createCompleteEvent(transcript: "Three four five six"))
        _ = eventHandler.parseComplete(createCompleteEvent(transcript: "Seven eight nine"))

        // Then: Average should be calculated correctly
        let average = eventHandler.statistics.averageWordsPerUtterance
        XCTAssertEqual(average, 3.0, accuracy: 0.1)  // (2 + 4 + 3) / 3 = 3
    }

    func testStatistics_parseSuccessRate() {
        // Given: Some successful and some failed parses
        _ = eventHandler.parseComplete(createCompleteEvent(transcript: "Success"))
        _ = eventHandler.parseComplete(RealtimeEvent(type: .transcriptionComplete, payload: [:], timestamp: Date()))  // Fail

        // Then: Success rate should reflect both
        let successRate = eventHandler.statistics.parseSuccessRate
        XCTAssertGreaterThan(successRate, 0)
        XCTAssertLessThan(successRate, 1.0)
    }
}

// MARK: - TranscriptionQualityAnalyzer Tests

final class TranscriptionQualityAnalyzerTests: XCTestCase {

    func testHasAcceptableConfidence_aboveThreshold() {
        // Given: An event with high confidence
        let event = TranscriptionEvent(
            text: "Test",
            isFinal: true,
            speaker: nil,
            timestamp: 0,
            confidence: 0.9
        )

        // Then: Should be acceptable
        XCTAssertTrue(TranscriptionQualityAnalyzer.hasAcceptableConfidence(event))
    }

    func testHasAcceptableConfidence_belowThreshold() {
        // Given: An event with low confidence
        let event = TranscriptionEvent(
            text: "Test",
            isFinal: true,
            speaker: nil,
            timestamp: 0,
            confidence: 0.5
        )

        // Then: Should not be acceptable
        XCTAssertFalse(TranscriptionQualityAnalyzer.hasAcceptableConfidence(event))
    }

    func testLooksValid_normalText() {
        // Given: Normal text
        let text = "Hello, how are you today?"

        // Then: Should look valid
        XCTAssertTrue(TranscriptionQualityAnalyzer.looksValid(text))
    }

    func testLooksValid_tooShort() {
        // Given: Very short text
        let text = "a"

        // Then: Should not look valid
        XCTAssertFalse(TranscriptionQualityAnalyzer.looksValid(text))
    }

    func testLooksValid_tooManyNumbers() {
        // Given: Text with too few letters
        let text = "123456789"

        // Then: Should not look valid
        XCTAssertFalse(TranscriptionQualityAnalyzer.looksValid(text))
    }

    func testHasCrosstalk_withIndicators() {
        // Given: Text with crosstalk indicators
        let texts = [
            "Something [overlapping] here",
            "Text with [crosstalk] marker",
            "Some [inaudible] speech",
            "With [multiple speakers] talking"
        ]

        // Then: Should detect crosstalk
        for text in texts {
            XCTAssertTrue(TranscriptionQualityAnalyzer.hasCrosstalk(text), "Should detect crosstalk in: \(text)")
        }
    }

    func testHasCrosstalk_withoutIndicators() {
        // Given: Normal text
        let text = "This is normal speech without any issues."

        // Then: Should not detect crosstalk
        XCTAssertFalse(TranscriptionQualityAnalyzer.hasCrosstalk(text))
    }

    func testCleanText_normalizesWhitespace() {
        // Given: Text with extra whitespace
        let text = "Hello    world   with   spaces"

        // When: Cleaning
        let cleaned = TranscriptionQualityAnalyzer.cleanText(text)

        // Then: Should normalize whitespace
        XCTAssertEqual(cleaned, "Hello world with spaces")
    }

    func testCleanText_trimsWhitespace() {
        // Given: Text with leading/trailing whitespace
        let text = "   Hello world   "

        // When: Cleaning
        let cleaned = TranscriptionQualityAnalyzer.cleanText(text)

        // Then: Should trim
        XCTAssertEqual(cleaned, "Hello world")
    }
}

// MARK: - TranscriptionBuffer Tests

final class TranscriptionBufferTests: XCTestCase {

    var buffer: TranscriptionBuffer!

    override func setUp() {
        super.setUp()
        buffer = TranscriptionBuffer()
    }

    override func tearDown() {
        buffer = nil
        super.tearDown()
    }

    private func createEvent(text: String, timestamp: TimeInterval) -> TranscriptionEvent {
        TranscriptionEvent(text: text, isFinal: true, timestamp: timestamp)
    }

    func testAdd_storesEvents() {
        // Given: An empty buffer
        // When: Adding events
        buffer.add(createEvent(text: "First", timestamp: 0))
        buffer.add(createEvent(text: "Second", timestamp: 1))

        // Then: Should contain events
        XCTAssertEqual(buffer.events.count, 2)
    }

    func testRecent_returnsLastN() {
        // Given: A buffer with events
        for i in 0..<10 {
            buffer.add(createEvent(text: "Event \(i)", timestamp: TimeInterval(i)))
        }

        // When: Getting recent events
        let recent = buffer.recent(count: 3)

        // Then: Should return last 3
        XCTAssertEqual(recent.count, 3)
        XCTAssertEqual(recent[0].text, "Event 7")
        XCTAssertEqual(recent[2].text, "Event 9")
    }

    func testClear_removesAllEvents() {
        // Given: A buffer with events
        buffer.add(createEvent(text: "Test", timestamp: 0))
        buffer.add(createEvent(text: "Test", timestamp: 1))

        // When: Clearing
        buffer.clear()

        // Then: Should be empty
        XCTAssertTrue(buffer.events.isEmpty)
    }

    func testEventsInRange_filtersCorrectly() {
        // Given: Events at various timestamps
        buffer.add(createEvent(text: "Early", timestamp: 1))
        buffer.add(createEvent(text: "Middle", timestamp: 5))
        buffer.add(createEvent(text: "Late", timestamp: 10))

        // When: Getting events in range
        let inRange = buffer.events(from: 2, to: 8)

        // Then: Should only include middle
        XCTAssertEqual(inRange.count, 1)
        XCTAssertEqual(inRange[0].text, "Middle")
    }

    func testMergedText_combinesEvents() {
        // Given: Events in a time range
        buffer.add(createEvent(text: "Hello ", timestamp: 1))
        buffer.add(createEvent(text: "world", timestamp: 2))

        // When: Getting merged text
        let merged = buffer.mergedText(from: 0, to: 3)

        // Then: Should combine text
        XCTAssertEqual(merged, "Hello world")
    }

    func testBufferCapacity_trimsOldEvents() {
        // Given: Adding more than buffer size
        for i in 0..<150 {
            buffer.add(createEvent(text: "Event \(i)", timestamp: TimeInterval(i)))
        }

        // Then: Should be capped at max size
        XCTAssertLessThanOrEqual(buffer.events.count, 100)
    }
}
