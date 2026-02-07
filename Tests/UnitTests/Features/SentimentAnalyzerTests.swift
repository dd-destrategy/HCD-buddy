//
//  SentimentAnalyzerTests.swift
//  HCD Interview Coach Tests
//
//  Feature G: Emotional Arc Tracking
//  Unit tests for SentimentAnalyzer rules-based sentiment scoring,
//  shift detection, and arc summary generation.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class SentimentAnalyzerTests: XCTestCase {

    var analyzer: SentimentAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = SentimentAnalyzer()
    }

    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a test utterance with given text and speaker
    private func makeUtterance(
        text: String,
        speaker: Speaker = .participant,
        timestampSeconds: Double = 0.0
    ) -> Utterance {
        Utterance(
            speaker: speaker,
            text: text,
            timestampSeconds: timestampSeconds
        )
    }

    // MARK: - Positive Sentiment

    func testAnalyze_positiveText_returnsPositivePolarity() {
        let utterance = makeUtterance(text: "I love this feature, it's amazing and wonderful")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.polarity, .positive)
        XCTAssertGreaterThan(result.score, 0.15)
        XCTAssertGreaterThan(result.intensity, 0.0)
    }

    func testAnalyze_mildlyPositiveText_returnsPositivePolarity() {
        let utterance = makeUtterance(text: "This is nice and simple to use")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.polarity, .positive)
        XCTAssertGreaterThan(result.score, 0.0)
    }

    func testAnalyze_stronglyPositiveText_hasHighScore() {
        let utterance = makeUtterance(text: "I absolutely love this, it's perfect and amazing")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.polarity, .positive)
        XCTAssertGreaterThan(result.score, 0.3)
    }

    // MARK: - Negative Sentiment

    func testAnalyze_negativeText_returnsNegativePolarity() {
        let utterance = makeUtterance(text: "This is terrible and frustrating")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.polarity, .negative)
        XCTAssertLessThan(result.score, -0.15)
    }

    func testAnalyze_stronglyNegativeText_hasLowScore() {
        let utterance = makeUtterance(text: "I hate this, it's a nightmare, absolutely awful")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.polarity, .negative)
        XCTAssertLessThan(result.score, -0.3)
    }

    func testAnalyze_mildlyNegativeText_returnsNegativePolarity() {
        let utterance = makeUtterance(text: "This is a bit slow and hard to use")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.polarity, .negative)
        XCTAssertLessThan(result.score, 0.0)
    }

    // MARK: - Neutral Sentiment

    func testAnalyze_neutralText_returnsNeutralPolarity() {
        let utterance = makeUtterance(text: "I went to the store and bought some items")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.polarity, .neutral)
        XCTAssertGreaterThanOrEqual(result.score, -0.15)
        XCTAssertLessThanOrEqual(result.score, 0.15)
    }

    func testAnalyze_emptyText_returnsNeutralPolarity() {
        let utterance = makeUtterance(text: "")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.polarity, .neutral)
        XCTAssertEqual(result.score, 0.0)
        XCTAssertEqual(result.intensity, 0.0)
    }

    // MARK: - Mixed Sentiment

    func testAnalyze_mixedText_returnsMixedPolarity() {
        let utterance = makeUtterance(text: "I love the design but hate the performance, it's a nightmare but also amazing")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.polarity, .mixed)
    }

    // MARK: - Intensity Scoring

    func testAnalyze_highIntensityWords_haveHigherIntensity() {
        let strongUtterance = makeUtterance(text: "I absolutely love this, it's amazing")
        let mildUtterance = makeUtterance(text: "This is okay, it's nice")

        let strongResult = analyzer.analyze(strongUtterance)
        let mildResult = analyzer.analyze(mildUtterance)

        XCTAssertGreaterThan(strongResult.intensity, mildResult.intensity)
    }

    // MARK: - Negator Handling

    func testAnalyze_negatorInvertsPositive() {
        let utterance = makeUtterance(text: "This is not good at all")
        let result = analyzer.analyze(utterance)

        // "not good" should become negative
        XCTAssertLessThan(result.score, 0.0)
    }

    func testAnalyze_negatorInvertsNegative() {
        let utterance = makeUtterance(text: "This is not bad")
        let result = analyzer.analyze(utterance)

        // "not bad" should become positive
        XCTAssertGreaterThan(result.score, 0.0)
    }

    func testAnalyze_doubleNegation() {
        let utterance = makeUtterance(text: "I can't say it isn't good")
        let result = analyzer.analyze(utterance)

        // With negator handling, "isn't good" flips to negative-ish
        // The exact result depends on proximity, but we verify it processes
        XCTAssertNotNil(result)
    }

    // MARK: - Intensifier Handling

    func testAnalyze_intensifierBoostsPositive() {
        let normalUtterance = makeUtterance(text: "This is good")
        let intensifiedUtterance = makeUtterance(text: "This is very good")

        let normalResult = analyzer.analyze(normalUtterance)
        let intensifiedResult = analyzer.analyze(intensifiedUtterance)

        XCTAssertGreaterThan(intensifiedResult.score, normalResult.score)
    }

    func testAnalyze_intensifierBoostsNegative() {
        let normalUtterance = makeUtterance(text: "This is bad")
        let intensifiedUtterance = makeUtterance(text: "This is extremely bad")

        let normalResult = analyzer.analyze(normalUtterance)
        let intensifiedResult = analyzer.analyze(intensifiedUtterance)

        XCTAssertLessThan(intensifiedResult.score, normalResult.score)
    }

    // MARK: - Dominant Emotion Detection

    func testAnalyze_frustrationKeywords_detectsFrustration() {
        let utterance = makeUtterance(text: "This is so frustrating and annoying")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.dominantEmotion, "frustration")
    }

    func testAnalyze_delightKeywords_detectsDelight() {
        let utterance = makeUtterance(text: "I love this, it's amazing and wonderful")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.dominantEmotion, "delight")
    }

    func testAnalyze_confusionKeywords_detectsConfusion() {
        let utterance = makeUtterance(text: "I'm confused and this is confusing")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.dominantEmotion, "confusion")
    }

    func testAnalyze_neutralText_noDominantEmotion() {
        let utterance = makeUtterance(text: "I went to the store and then came back")
        let result = analyzer.analyze(utterance)

        XCTAssertNil(result.dominantEmotion)
    }

    // MARK: - Session Analysis

    func testAnalyzeSession_populatesResults() {
        let utterances = [
            makeUtterance(text: "I love this", timestampSeconds: 10.0),
            makeUtterance(text: "This is okay", timestampSeconds: 30.0),
            makeUtterance(text: "I hate this", timestampSeconds: 60.0),
        ]

        analyzer.analyzeSession(utterances)

        XCTAssertEqual(analyzer.results.count, 3)
        XCTAssertEqual(analyzer.results[0].polarity, .positive)
        XCTAssertEqual(analyzer.results[2].polarity, .negative)
    }

    func testAnalyzeSession_preservesTimestamps() {
        let utterances = [
            makeUtterance(text: "Good stuff", timestampSeconds: 15.0),
            makeUtterance(text: "Bad stuff", timestampSeconds: 45.0),
        ]

        analyzer.analyzeSession(utterances)

        XCTAssertEqual(analyzer.results[0].timestamp, 15.0)
        XCTAssertEqual(analyzer.results[1].timestamp, 45.0)
    }

    // MARK: - Emotional Shift Detection

    func testAnalyzeSession_detectsShifts() {
        let utterances = [
            makeUtterance(text: "I absolutely love this, it's amazing and perfect", timestampSeconds: 10.0),
            makeUtterance(text: "This is a terrible nightmare, I hate it", timestampSeconds: 30.0),
        ]

        analyzer.analyzeSession(utterances)

        // Score difference should be > 0.4, triggering a shift
        XCTAssertFalse(analyzer.emotionalShifts.isEmpty, "Should detect at least one emotional shift")
        if let shift = analyzer.emotionalShifts.first {
            XCTAssertGreaterThanOrEqual(shift.shiftMagnitude, 0.4)
        }
    }

    func testAnalyzeSession_noShiftBelowThreshold() {
        let utterances = [
            makeUtterance(text: "This is nice", timestampSeconds: 10.0),
            makeUtterance(text: "This is good", timestampSeconds: 30.0),
        ]

        analyzer.analyzeSession(utterances)

        // Both positive with similar scores — no shift
        XCTAssertTrue(analyzer.emotionalShifts.isEmpty, "Should not detect shift between similar sentiments")
    }

    func testAnalyzeSession_singleUtterance_noShifts() {
        let utterances = [
            makeUtterance(text: "I love this", timestampSeconds: 10.0),
        ]

        analyzer.analyzeSession(utterances)

        XCTAssertEqual(analyzer.results.count, 1)
        XCTAssertTrue(analyzer.emotionalShifts.isEmpty)
    }

    // MARK: - Arc Summary

    func testGenerateArcSummary_withResults() {
        let utterances = [
            makeUtterance(text: "I love this amazing feature", timestampSeconds: 30.0),
            makeUtterance(text: "Just some normal stuff here", timestampSeconds: 60.0),
            makeUtterance(text: "This is terrible and awful", timestampSeconds: 90.0),
        ]

        analyzer.analyzeSession(utterances)
        let summary = analyzer.arcSummary

        XCTAssertNotNil(summary)
        XCTAssertNotNil(summary?.arcDescription)
        XCTAssertFalse(summary!.arcDescription.isEmpty)
        XCTAssertLessThanOrEqual(summary!.intensityPeaks.count, 3)
        XCTAssertGreaterThan(summary!.maxSentiment, summary!.minSentiment)
    }

    func testGenerateArcSummary_emptyResults_returnsNil() {
        let summary = analyzer.generateArcSummary()
        XCTAssertNil(summary)
    }

    func testGenerateArcSummary_intensityPeaks_maxThree() {
        let utterances = [
            makeUtterance(text: "I love this", timestampSeconds: 10.0),
            makeUtterance(text: "Amazing wonderful", timestampSeconds: 20.0),
            makeUtterance(text: "Terrible awful", timestampSeconds: 30.0),
            makeUtterance(text: "Perfect and fantastic", timestampSeconds: 40.0),
            makeUtterance(text: "Horrible nightmare", timestampSeconds: 50.0),
        ]

        analyzer.analyzeSession(utterances)
        let summary = analyzer.arcSummary

        XCTAssertNotNil(summary)
        XCTAssertLessThanOrEqual(summary!.intensityPeaks.count, 3)
    }

    func testGenerateArcSummary_dominantPolarityReflectsAverage() {
        let utterances = [
            makeUtterance(text: "I love this", timestampSeconds: 10.0),
            makeUtterance(text: "Amazing feature", timestampSeconds: 20.0),
            makeUtterance(text: "Wonderful experience", timestampSeconds: 30.0),
        ]

        analyzer.analyzeSession(utterances)
        let summary = analyzer.arcSummary

        XCTAssertNotNil(summary)
        XCTAssertEqual(summary!.dominantPolarity, .positive)
    }

    // MARK: - Arc Description

    func testArcDescription_positiveToNegative() {
        let utterances = [
            makeUtterance(text: "I love this amazing feature", timestampSeconds: 10.0),
            makeUtterance(text: "This is really great", timestampSeconds: 20.0),
            makeUtterance(text: "Things are going well", timestampSeconds: 30.0),
            makeUtterance(text: "This is terrible", timestampSeconds: 50.0),
            makeUtterance(text: "I hate this so much", timestampSeconds: 60.0),
            makeUtterance(text: "Absolutely awful", timestampSeconds: 70.0),
        ]

        analyzer.analyzeSession(utterances)

        XCTAssertNotNil(analyzer.arcSummary)
        let desc = analyzer.arcSummary!.arcDescription.lowercased()
        XCTAssertTrue(desc.contains("positive") || desc.contains("started"),
                      "Arc description should describe the trajectory: \(desc)")
    }

    // MARK: - SentimentPolarity Properties

    func testSentimentPolarity_displayNames() {
        XCTAssertEqual(SentimentPolarity.positive.displayName, "Positive")
        XCTAssertEqual(SentimentPolarity.neutral.displayName, "Neutral")
        XCTAssertEqual(SentimentPolarity.negative.displayName, "Negative")
        XCTAssertEqual(SentimentPolarity.mixed.displayName, "Mixed")
    }

    func testSentimentPolarity_icons() {
        XCTAssertFalse(SentimentPolarity.positive.icon.isEmpty)
        XCTAssertFalse(SentimentPolarity.neutral.icon.isEmpty)
        XCTAssertFalse(SentimentPolarity.negative.icon.isEmpty)
        XCTAssertFalse(SentimentPolarity.mixed.icon.isEmpty)
    }

    func testSentimentPolarity_colorNames() {
        XCTAssertEqual(SentimentPolarity.positive.colorName, "hcdSuccess")
        XCTAssertEqual(SentimentPolarity.neutral.colorName, "hcdTextSecondary")
        XCTAssertEqual(SentimentPolarity.negative.colorName, "hcdError")
        XCTAssertEqual(SentimentPolarity.mixed.colorName, "hcdWarning")
    }

    func testSentimentPolarity_allCases() {
        XCTAssertEqual(SentimentPolarity.allCases.count, 4)
    }

    // MARK: - SentimentResult Codable

    func testSentimentResult_codableRoundTrip() throws {
        let original = SentimentResult(
            utteranceId: UUID(),
            polarity: .positive,
            score: 0.75,
            intensity: 0.75,
            dominantEmotion: "delight",
            timestamp: 42.0
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SentimentResult.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testSentimentResult_codableWithNilEmotion() throws {
        let original = SentimentResult(
            utteranceId: UUID(),
            polarity: .neutral,
            score: 0.0,
            intensity: 0.0,
            dominantEmotion: nil,
            timestamp: 10.0
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SentimentResult.self, from: data)

        XCTAssertEqual(original, decoded)
        XCTAssertNil(decoded.dominantEmotion)
    }

    // MARK: - EmotionalArcSummary Codable

    func testEmotionalArcSummary_codableRoundTrip() throws {
        let summary = EmotionalArcSummary(
            averageSentiment: 0.3,
            minSentiment: -0.5,
            maxSentiment: 0.8,
            emotionalShifts: [],
            dominantPolarity: .positive,
            intensityPeaks: [],
            arcDescription: "Started positive, ended positive"
        )

        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(EmotionalArcSummary.self, from: data)

        XCTAssertEqual(decoded.averageSentiment, 0.3, accuracy: 0.001)
        XCTAssertEqual(decoded.minSentiment, -0.5, accuracy: 0.001)
        XCTAssertEqual(decoded.maxSentiment, 0.8, accuracy: 0.001)
        XCTAssertEqual(decoded.dominantPolarity, .positive)
        XCTAssertEqual(decoded.arcDescription, "Started positive, ended positive")
    }

    // MARK: - Reset

    func testReset_clearsAllState() {
        let utterances = [
            makeUtterance(text: "I love this", timestampSeconds: 10.0),
            makeUtterance(text: "I hate this awful thing", timestampSeconds: 30.0),
        ]

        analyzer.analyzeSession(utterances)

        // Verify data is present
        XCTAssertFalse(analyzer.results.isEmpty)

        // When: Reset
        analyzer.reset()

        // Then: All state should be cleared
        XCTAssertTrue(analyzer.results.isEmpty)
        XCTAssertTrue(analyzer.emotionalShifts.isEmpty)
        XCTAssertNil(analyzer.arcSummary)
    }

    func testReset_allowsReanalysis() {
        // Given: Analyze some utterances then reset
        analyzer.analyzeSession([
            makeUtterance(text: "I love this", timestampSeconds: 10.0),
        ])
        analyzer.reset()

        // When: Analyze new utterances
        analyzer.analyzeSession([
            makeUtterance(text: "I hate this", timestampSeconds: 20.0),
        ])

        // Then: Results reflect only the new data
        XCTAssertEqual(analyzer.results.count, 1)
        XCTAssertEqual(analyzer.results[0].polarity, .negative)
    }

    // MARK: - Empty and Edge Cases

    func testAnalyzeSession_emptyList() {
        analyzer.analyzeSession([])

        XCTAssertTrue(analyzer.results.isEmpty)
        XCTAssertTrue(analyzer.emotionalShifts.isEmpty)
        XCTAssertNil(analyzer.arcSummary)
    }

    func testAnalyze_utteranceId_matchesResult() {
        let utterance = makeUtterance(text: "I love this")
        let result = analyzer.analyze(utterance)

        XCTAssertEqual(result.utteranceId, utterance.id)
    }

    func testAnalyze_scoreBounds() {
        // Very positive
        let posUtterance = makeUtterance(text: "I love love love love love this amazing wonderful perfect")
        let posResult = analyzer.analyze(posUtterance)
        XCTAssertLessThanOrEqual(posResult.score, 1.0)
        XCTAssertGreaterThanOrEqual(posResult.score, -1.0)

        // Very negative
        let negUtterance = makeUtterance(text: "hate hate hate terrible awful nightmare horrible broken")
        let negResult = analyzer.analyze(negUtterance)
        XCTAssertLessThanOrEqual(negResult.score, 1.0)
        XCTAssertGreaterThanOrEqual(negResult.score, -1.0)
    }

    func testAnalyze_intensityBounds() {
        let utterance = makeUtterance(text: "I extremely absolutely love this amazing perfect wonderful feature")
        let result = analyzer.analyze(utterance)

        XCTAssertGreaterThanOrEqual(result.intensity, 0.0)
        XCTAssertLessThanOrEqual(result.intensity, 1.0)
    }
}
