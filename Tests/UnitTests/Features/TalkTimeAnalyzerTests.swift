//
//  TalkTimeAnalyzerTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for TalkTimeAnalyzer talk-time ratio computation
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class TalkTimeAnalyzerTests: XCTestCase {

    var analyzer: TalkTimeAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = TalkTimeAnalyzer()
    }

    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a test utterance with the specified speaker and word count
    private func makeUtterance(
        speaker: Speaker,
        wordCount: Int,
        timestampSeconds: Double = 0.0
    ) -> Utterance {
        // Build a text string with the desired number of words
        let words = Array(repeating: "word", count: max(wordCount, 0))
        let text = words.joined(separator: " ")
        return Utterance(
            speaker: speaker,
            text: text,
            timestampSeconds: timestampSeconds
        )
    }

    // MARK: - Test: Initial State

    func testInitialState_allZeros() {
        // The analyzer should start in a clean state with 0% ratios
        XCTAssertEqual(analyzer.interviewerRatio, 0.0)
        XCTAssertEqual(analyzer.participantRatio, 0.0)
        XCTAssertEqual(analyzer.totalSpeakingTime, 0.0)
        XCTAssertEqual(analyzer.healthStatus, .good)
        XCTAssertEqual(analyzer.utteranceCount, 0)
    }

    func testInitialState_formattedRatio() {
        // With no data, formatted ratio should show 0% / 0%
        XCTAssertEqual(analyzer.formattedRatio, "0% / 0%")
    }

    // MARK: - Test: Single Interviewer Utterance

    func testSingleInterviewerUtterance() {
        // Given: A single interviewer utterance with 5 words
        let utterance = makeUtterance(speaker: .interviewer, wordCount: 5)

        // When: Process the utterance
        analyzer.processUtterance(utterance)

        // Then: Interviewer should have 100% of talk time
        XCTAssertEqual(analyzer.interviewerRatio, 1.0, accuracy: 0.001)
        XCTAssertEqual(analyzer.participantRatio, 0.0, accuracy: 0.001)
        XCTAssertEqual(analyzer.utteranceCount, 1)

        // Duration should be 5 words / 2.5 words-per-sec = 2.0 seconds
        XCTAssertEqual(analyzer.totalSpeakingTime, 2.0, accuracy: 0.001)
    }

    func testSingleParticipantUtterance() {
        // Given: A single participant utterance with 10 words
        let utterance = makeUtterance(speaker: .participant, wordCount: 10)

        // When: Process the utterance
        analyzer.processUtterance(utterance)

        // Then: Participant should have 100% of talk time
        XCTAssertEqual(analyzer.interviewerRatio, 0.0, accuracy: 0.001)
        XCTAssertEqual(analyzer.participantRatio, 1.0, accuracy: 0.001)
        XCTAssertEqual(analyzer.utteranceCount, 1)

        // Duration should be 10 words / 2.5 words-per-sec = 4.0 seconds
        XCTAssertEqual(analyzer.totalSpeakingTime, 4.0, accuracy: 0.001)
    }

    // MARK: - Test: Mixed Utterances Compute Correct Ratio

    func testMixedUtterances_equalWordCount() {
        // Given: Equal word counts for interviewer and participant
        let interviewerUtterance = makeUtterance(speaker: .interviewer, wordCount: 10)
        let participantUtterance = makeUtterance(speaker: .participant, wordCount: 10)

        // When: Process both
        analyzer.processUtterance(interviewerUtterance)
        analyzer.processUtterance(participantUtterance)

        // Then: 50/50 ratio
        XCTAssertEqual(analyzer.interviewerRatio, 0.5, accuracy: 0.001)
        XCTAssertEqual(analyzer.participantRatio, 0.5, accuracy: 0.001)
        XCTAssertEqual(analyzer.utteranceCount, 2)
    }

    func testMixedUtterances_25_75_ratio() {
        // Given: Interviewer 25 words, participant 75 words
        let interviewerUtterance = makeUtterance(speaker: .interviewer, wordCount: 25)
        let participantUtterance = makeUtterance(speaker: .participant, wordCount: 75)

        // When: Process both
        analyzer.processUtterance(interviewerUtterance)
        analyzer.processUtterance(participantUtterance)

        // Then: 25%/75% ratio
        XCTAssertEqual(analyzer.interviewerRatio, 0.25, accuracy: 0.001)
        XCTAssertEqual(analyzer.participantRatio, 0.75, accuracy: 0.001)
    }

    func testMixedUtterances_multipleUtterances() {
        // Given: Multiple utterances from both speakers
        // Interviewer: 5 + 5 = 10 words
        // Participant: 10 + 20 = 30 words
        // Total: 40 words => interviewer 25%, participant 75%
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 5))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 10))
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 5))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 20))

        // Then: 25%/75% ratio
        XCTAssertEqual(analyzer.interviewerRatio, 0.25, accuracy: 0.001)
        XCTAssertEqual(analyzer.participantRatio, 0.75, accuracy: 0.001)
        XCTAssertEqual(analyzer.utteranceCount, 4)

        // Total time: 40 words / 2.5 = 16.0 seconds
        XCTAssertEqual(analyzer.totalSpeakingTime, 16.0, accuracy: 0.001)
    }

    func testBatchProcessUtterances() {
        // Given: A batch of utterances
        let utterances = [
            makeUtterance(speaker: .interviewer, wordCount: 10),
            makeUtterance(speaker: .participant, wordCount: 30),
        ]

        // When: Process as batch
        analyzer.processUtterances(utterances)

        // Then: 25%/75% ratio
        XCTAssertEqual(analyzer.interviewerRatio, 0.25, accuracy: 0.001)
        XCTAssertEqual(analyzer.participantRatio, 0.75, accuracy: 0.001)
        XCTAssertEqual(analyzer.utteranceCount, 2)
    }

    // MARK: - Test: Unknown Speaker Ignored

    func testUnknownSpeaker_isIgnored() {
        // Given: An unknown speaker utterance
        let unknownUtterance = makeUtterance(speaker: .unknown, wordCount: 50)

        // When: Process the utterance
        analyzer.processUtterance(unknownUtterance)

        // Then: Should be ignored; ratios remain zero
        XCTAssertEqual(analyzer.interviewerRatio, 0.0)
        XCTAssertEqual(analyzer.participantRatio, 0.0)
        XCTAssertEqual(analyzer.totalSpeakingTime, 0.0)
        XCTAssertEqual(analyzer.utteranceCount, 0)
    }

    func testUnknownSpeaker_doesNotAffectRatio() {
        // Given: Mix of known and unknown speakers
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 10))
        analyzer.processUtterance(makeUtterance(speaker: .unknown, wordCount: 100))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 30))

        // Then: Unknown speaker should not affect ratio (10/40 = 25%)
        XCTAssertEqual(analyzer.interviewerRatio, 0.25, accuracy: 0.001)
        XCTAssertEqual(analyzer.participantRatio, 0.75, accuracy: 0.001)
        // Only 2 counted (unknown is skipped)
        XCTAssertEqual(analyzer.utteranceCount, 2)
    }

    // MARK: - Test: Health Status Thresholds

    func testHealthStatus_good() {
        // Given: Interviewer < 30% (20% interviewer, 80% participant)
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 20))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 80))

        // Then: Health should be good
        XCTAssertEqual(analyzer.healthStatus, .good)
    }

    func testHealthStatus_caution() {
        // Given: Interviewer 35% (35 words interviewer, 65 words participant)
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 35))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 65))

        // Then: Health should be caution (30-40% range)
        XCTAssertEqual(analyzer.healthStatus, .caution)
    }

    func testHealthStatus_warning() {
        // Given: Interviewer 50% (50 words each)
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 50))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 50))

        // Then: Health should be warning (>40%)
        XCTAssertEqual(analyzer.healthStatus, .warning)
    }

    func testHealthStatus_warningAtExactThreshold() {
        // Given: Interviewer at exactly 40%
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 40))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 60))

        // Then: 40% is the boundary; >= cautionThreshold (0.40) is warning
        XCTAssertEqual(analyzer.healthStatus, .warning)
    }

    func testHealthStatus_goodAtExactThreshold() {
        // Given: Interviewer at exactly 30%
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 30))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 70))

        // Then: 30% equals the goodThreshold boundary; >= 0.30 means caution
        XCTAssertEqual(analyzer.healthStatus, .caution)
    }

    func testHealthStatus_justBelowGoodThreshold() {
        // Given: Interviewer at 29%
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 29))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 71))

        // Then: < 30% is good
        XCTAssertEqual(analyzer.healthStatus, .good)
    }

    // MARK: - Test: Reset

    func testReset_clearsAllState() {
        // Given: Analyzer has processed some utterances
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 25))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 75))

        // Verify data is present
        XCTAssertGreaterThan(analyzer.totalSpeakingTime, 0)
        XCTAssertEqual(analyzer.utteranceCount, 2)

        // When: Reset
        analyzer.reset()

        // Then: All state should be cleared
        XCTAssertEqual(analyzer.interviewerRatio, 0.0)
        XCTAssertEqual(analyzer.participantRatio, 0.0)
        XCTAssertEqual(analyzer.totalSpeakingTime, 0.0)
        XCTAssertEqual(analyzer.healthStatus, .good)
        XCTAssertEqual(analyzer.utteranceCount, 0)
        XCTAssertEqual(analyzer.interviewerSpeakingTime, 0.0)
        XCTAssertEqual(analyzer.participantSpeakingTime, 0.0)
    }

    func testReset_allowsReprocessing() {
        // Given: Process some utterances then reset
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 50))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 50))
        analyzer.reset()

        // When: Process new utterances
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 10))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 90))

        // Then: Ratios reflect only the new data
        XCTAssertEqual(analyzer.interviewerRatio, 0.1, accuracy: 0.001)
        XCTAssertEqual(analyzer.participantRatio, 0.9, accuracy: 0.001)
    }

    // MARK: - Test: Formatted Ratio String

    func testFormattedRatio_noData() {
        XCTAssertEqual(analyzer.formattedRatio, "0% / 0%")
    }

    func testFormattedRatio_withData() {
        // 28% interviewer, 72% participant
        // Use 28 and 72 words so ratio is exactly 28/100 = 0.28
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 28))
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 72))

        XCTAssertEqual(analyzer.formattedRatio, "28% / 72%")
    }

    func testFormattedRatio_100Percent_interviewer() {
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 50))

        XCTAssertEqual(analyzer.formattedRatio, "100% / 0%")
    }

    func testFormattedRatio_100Percent_participant() {
        analyzer.processUtterance(makeUtterance(speaker: .participant, wordCount: 50))

        XCTAssertEqual(analyzer.formattedRatio, "0% / 100%")
    }

    // MARK: - Test: Duration Estimation

    func testDurationEstimation() {
        // Given: 25 words at 2.5 words/sec = 10.0 seconds
        analyzer.processUtterance(makeUtterance(speaker: .interviewer, wordCount: 25))

        XCTAssertEqual(analyzer.totalSpeakingTime, 10.0, accuracy: 0.001)
        XCTAssertEqual(analyzer.interviewerSpeakingTime, 10.0, accuracy: 0.001)
    }

    func testEmptyUtterance_zeroDuration() {
        // Given: An utterance with 0 words (empty text)
        let utterance = Utterance(speaker: .interviewer, text: "", timestampSeconds: 0.0)

        // When: Process the utterance
        analyzer.processUtterance(utterance)

        // Then: Zero words means zero duration; utterance was from a known speaker
        // but contributed 0 time, so ratios stay at 0/0 => 0%
        XCTAssertEqual(analyzer.totalSpeakingTime, 0.0)
    }

    // MARK: - Test: TalkTimeHealth Properties

    func testTalkTimeHealth_icons() {
        XCTAssertEqual(TalkTimeHealth.good.icon, "checkmark.circle.fill")
        XCTAssertEqual(TalkTimeHealth.caution.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(TalkTimeHealth.warning.icon, "xmark.octagon.fill")
    }

    func testTalkTimeHealth_descriptions() {
        XCTAssertFalse(TalkTimeHealth.good.description.isEmpty)
        XCTAssertFalse(TalkTimeHealth.caution.description.isEmpty)
        XCTAssertFalse(TalkTimeHealth.warning.description.isEmpty)
    }

    func testTalkTimeHealth_allCases() {
        // Verify all cases are represented
        XCTAssertEqual(TalkTimeHealth.allCases.count, 3)
        XCTAssertTrue(TalkTimeHealth.allCases.contains(.good))
        XCTAssertTrue(TalkTimeHealth.allCases.contains(.caution))
        XCTAssertTrue(TalkTimeHealth.allCases.contains(.warning))
    }
}
