//
//  BiasDetectorTests.swift
//  HCD Interview Coach Tests
//
//  Unit tests for BiasDetector, BiasType, BiasSeverity, and BiasAlert
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class BiasDetectorTests: XCTestCase {

    // MARK: - Properties

    var detector: BiasDetector!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        detector = BiasDetector()
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeClassifications(
        _ items: [(text: String, type: String)]
    ) -> [(utteranceId: UUID, text: String, type: String)] {
        return items.map { (UUID(), $0.text, $0.type) }
    }

    // MARK: - BiasType Properties

    func testBiasType_allCasesHaveDisplayNames() {
        for biasType in BiasType.allCases {
            XCTAssertFalse(biasType.displayName.isEmpty, "\(biasType.rawValue) should have a display name")
        }
    }

    func testBiasType_allCasesHaveDescriptions() {
        for biasType in BiasType.allCases {
            XCTAssertFalse(biasType.description.isEmpty, "\(biasType.rawValue) should have a description")
        }
    }

    func testBiasType_allCasesHaveIcons() {
        for biasType in BiasType.allCases {
            XCTAssertFalse(biasType.icon.isEmpty, "\(biasType.rawValue) should have an icon")
        }
    }

    func testBiasType_severityLevels() {
        XCTAssertEqual(BiasType.genderBias.severity, .high)
        XCTAssertEqual(BiasType.ageBias.severity, .medium)
        XCTAssertEqual(BiasType.confirmationBias.severity, .high)
        XCTAssertEqual(BiasType.leadingPatternBias.severity, .medium)
        XCTAssertEqual(BiasType.closedQuestionOveruse.severity, .low)
        XCTAssertEqual(BiasType.assumptiveLanguage.severity, .medium)
    }

    // MARK: - BiasSeverity Properties

    func testBiasSeverity_displayNames() {
        XCTAssertEqual(BiasSeverity.low.displayName, "Low")
        XCTAssertEqual(BiasSeverity.medium.displayName, "Medium")
        XCTAssertEqual(BiasSeverity.high.displayName, "High")
    }

    func testBiasSeverity_colorsNotEmpty() {
        for severity in [BiasSeverity.low, .medium, .high] {
            XCTAssertFalse(severity.color.isEmpty, "\(severity.rawValue) should have a color")
        }
    }

    // MARK: - Gender Bias Detection

    func testDetectGenderBias_positive() {
        let classifications = makeClassifications([
            (text: "How do guys typically handle this?", type: "open_ended"),
            (text: "What does she think about this workflow?", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let genderAlerts = detector.alerts.filter { $0.type == .genderBias }
        XCTAssertEqual(genderAlerts.count, 1, "Should detect gender bias")
        XCTAssertEqual(genderAlerts.first?.utteranceIds.count, 2)
        XCTAssertFalse(genderAlerts.first?.suggestion.isEmpty ?? true)
    }

    func testDetectGenderBias_negative() {
        let classifications = makeClassifications([
            (text: "How do users typically handle this?", type: "open_ended"),
            (text: "What does the participant think about this workflow?", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let genderAlerts = detector.alerts.filter { $0.type == .genderBias }
        XCTAssertEqual(genderAlerts.count, 0, "Should not detect gender bias in neutral language")
    }

    // MARK: - Age Bias Detection

    func testDetectAgeBias_positive() {
        let classifications = makeClassifications([
            (text: "How do millennials in your team use this?", type: "open_ended"),
            (text: "Do older users struggle with this feature?", type: "closed")
        ])

        detector.analyze(classifications: classifications)

        let ageAlerts = detector.alerts.filter { $0.type == .ageBias }
        XCTAssertEqual(ageAlerts.count, 1, "Should detect age bias")
        XCTAssertEqual(ageAlerts.first?.utteranceIds.count, 2)
    }

    func testDetectAgeBias_negative() {
        let classifications = makeClassifications([
            (text: "How do team members use this?", type: "open_ended"),
            (text: "Tell me about your experience with the feature.", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let ageAlerts = detector.alerts.filter { $0.type == .ageBias }
        XCTAssertEqual(ageAlerts.count, 0, "Should not detect age bias in neutral language")
    }

    // MARK: - Confirmation Bias Detection

    func testDetectConfirmationBias_positive_meetsThreshold() {
        let classifications = makeClassifications([
            (text: "This is easier to use, right?", type: "leading"),
            (text: "The new design is better, isn't it?", type: "leading"),
            (text: "You prefer this version, don't you think?", type: "leading"),
            (text: "How do you feel about the navigation?", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let confirmationAlerts = detector.alerts.filter { $0.type == .confirmationBias }
        XCTAssertEqual(confirmationAlerts.count, 1, "Should detect confirmation bias at threshold of 3+")
        XCTAssertEqual(confirmationAlerts.first?.utteranceIds.count, 3)
    }

    func testDetectConfirmationBias_negative_belowThreshold() {
        let classifications = makeClassifications([
            (text: "This is easier to use, right?", type: "leading"),
            (text: "The design looks clean, isn't it?", type: "leading"),
            (text: "How do you feel about the navigation?", type: "open_ended"),
            (text: "Tell me about your workflow.", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let confirmationAlerts = detector.alerts.filter { $0.type == .confirmationBias }
        XCTAssertEqual(confirmationAlerts.count, 0, "Should not detect confirmation bias below threshold of 3")
    }

    // MARK: - Leading Pattern Detection

    func testDetectLeadingPattern_positive() {
        let classifications = makeClassifications([
            (text: "Don't you think this is better?", type: "leading"),
            (text: "Wouldn't you agree this is improved?", type: "leading"),
            (text: "How do you use the feature?", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let leadingAlerts = detector.alerts.filter { $0.type == .leadingPatternBias }
        XCTAssertEqual(leadingAlerts.count, 1, "Should detect leading pattern when >30% are leading")
    }

    func testDetectLeadingPattern_negative_belowRatio() {
        let classifications = makeClassifications([
            (text: "Don't you think this is better?", type: "leading"),
            (text: "How do you use the feature?", type: "open_ended"),
            (text: "Tell me about your experience.", type: "open_ended"),
            (text: "What was your workflow?", type: "open_ended"),
            (text: "Describe your process.", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let leadingAlerts = detector.alerts.filter { $0.type == .leadingPatternBias }
        XCTAssertEqual(leadingAlerts.count, 0, "Should not detect leading pattern when <=30% are leading")
    }

    // MARK: - Closed Question Overuse Detection

    func testDetectClosedOveruse_positive() {
        let classifications = makeClassifications([
            (text: "Do you use this?", type: "closed"),
            (text: "Is it helpful?", type: "closed"),
            (text: "Have you tried the update?", type: "closed"),
            (text: "Did you complete setup?", type: "closed"),
            (text: "How do you feel about it?", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let closedAlerts = detector.alerts.filter { $0.type == .closedQuestionOveruse }
        XCTAssertEqual(closedAlerts.count, 1, "Should detect closed overuse when >60% are closed")
        XCTAssertEqual(closedAlerts.first?.utteranceIds.count, 4)
    }

    func testDetectClosedOveruse_negative_belowThreshold() {
        let classifications = makeClassifications([
            (text: "Do you use this?", type: "closed"),
            (text: "How do you feel about it?", type: "open_ended"),
            (text: "Tell me about your experience.", type: "open_ended"),
            (text: "What was your workflow?", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let closedAlerts = detector.alerts.filter { $0.type == .closedQuestionOveruse }
        XCTAssertEqual(closedAlerts.count, 0, "Should not detect closed overuse when <=60% are closed")
    }

    // MARK: - Assumptive Language Detection

    func testDetectAssumptiveLanguage_positive() {
        let classifications = makeClassifications([
            (text: "Obviously this feature is confusing, so how do you cope?", type: "open_ended"),
            (text: "Everyone knows this is a problem, what's your take?", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let assumptiveAlerts = detector.alerts.filter { $0.type == .assumptiveLanguage }
        XCTAssertEqual(assumptiveAlerts.count, 1, "Should detect assumptive language")
        XCTAssertEqual(assumptiveAlerts.first?.utteranceIds.count, 2)
    }

    func testDetectAssumptiveLanguage_negative() {
        let classifications = makeClassifications([
            (text: "How do you feel about this feature?", type: "open_ended"),
            (text: "What has your experience been?", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        let assumptiveAlerts = detector.alerts.filter { $0.type == .assumptiveLanguage }
        XCTAssertEqual(assumptiveAlerts.count, 0, "Should not detect assumptive language in neutral questions")
    }

    // MARK: - Combined Analysis

    func testAnalyze_multiplebiasTypes() {
        let classifications = makeClassifications([
            (text: "Obviously guys struggle with this, right?", type: "leading"),
            (text: "Millennials use this differently, don't you think?", type: "leading"),
            (text: "Everyone knows this is hard, isn't it?", type: "leading"),
            (text: "How do you feel?", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        // Should detect multiple bias types simultaneously
        let types = Set(detector.alerts.map { $0.type })
        XCTAssertTrue(types.contains(.genderBias), "Should detect gender bias")
        XCTAssertTrue(types.contains(.ageBias), "Should detect age bias")
        XCTAssertTrue(types.contains(.confirmationBias), "Should detect confirmation bias")
        XCTAssertTrue(types.contains(.assumptiveLanguage), "Should detect assumptive language")
    }

    // MARK: - Empty Input

    func testAnalyze_emptyInput() {
        let classifications: [(utteranceId: UUID, text: String, type: String)] = []

        detector.analyze(classifications: classifications)

        XCTAssertTrue(detector.alerts.isEmpty, "Should produce no alerts for empty input")
    }

    // MARK: - Clear Alerts

    func testClearAlerts_removesAll() {
        let classifications = makeClassifications([
            (text: "Obviously guys struggle with this.", type: "open_ended")
        ])
        detector.analyze(classifications: classifications)
        XCTAssertFalse(detector.alerts.isEmpty, "Should have alerts before clearing")

        detector.clearAlerts()

        XCTAssertTrue(detector.alerts.isEmpty, "Should have no alerts after clearing")
    }

    // MARK: - Analyzing State

    func testAnalyze_setsIsAnalyzingBackToFalse() {
        let classifications = makeClassifications([
            (text: "How do you use this?", type: "open_ended")
        ])

        detector.analyze(classifications: classifications)

        XCTAssertFalse(detector.isAnalyzing, "isAnalyzing should be false after analysis completes")
    }

    // MARK: - Minimum Sample Size

    func testDetectLeadingPattern_requiresMinimumSampleSize() {
        // Only 2 items, below the minimum of 3
        let classifications = makeClassifications([
            (text: "Don't you think?", type: "leading"),
            (text: "Isn't it obvious?", type: "leading")
        ])

        detector.analyze(classifications: classifications)

        let leadingAlerts = detector.alerts.filter { $0.type == .leadingPatternBias }
        XCTAssertEqual(leadingAlerts.count, 0, "Should not detect patterns with fewer than 3 classifications")
    }

    func testDetectClosedOveruse_requiresMinimumSampleSize() {
        // Only 2 items, below the minimum of 3
        let classifications = makeClassifications([
            (text: "Do you use this?", type: "closed"),
            (text: "Is it helpful?", type: "closed")
        ])

        detector.analyze(classifications: classifications)

        let closedAlerts = detector.alerts.filter { $0.type == .closedQuestionOveruse }
        XCTAssertEqual(closedAlerts.count, 0, "Should not detect overuse with fewer than 3 classifications")
    }
}
