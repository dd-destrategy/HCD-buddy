//
//  Batch2IntegrationTests.swift
//  HCDInterviewCoach
//
//  Integration tests verifying that Batch 2 features (A-H) work together
//  and integrate properly with Batch 1 features and the existing codebase.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class Batch2IntegrationTests: XCTestCase {

    // MARK: - Feature A + D: Coaching Timing with Cultural Context

    func testCulturalContextAdjustsCoachingThresholds() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cultural_\(UUID().uuidString).json")
        let manager = CulturalContextManager(storageURL: tempURL)

        let baseThresholds = CoachingThresholds.balanced
        let westernAdjusted = manager.adjustedThresholds(base: baseThresholds)

        // Western defaults should not significantly change thresholds
        XCTAssertEqual(westernAdjusted.speechCooldown, baseThresholds.speechCooldown, accuracy: 0.01)

        // East Asian preset should increase speech cooldown (longer silence tolerance)
        manager.updatePreset(.eastAsian)
        let eastAsianAdjusted = manager.adjustedThresholds(base: baseThresholds)
        XCTAssertGreaterThan(eastAsianAdjusted.speechCooldown, baseThresholds.speechCooldown)
        XCTAssertGreaterThan(eastAsianAdjusted.cooldownDuration, baseThresholds.cooldownDuration)

        // Latin American should decrease cooldowns (faster pacing)
        manager.updatePreset(.latinAmerican)
        let latinAdjusted = manager.adjustedThresholds(base: baseThresholds)
        XCTAssertLessThan(latinAdjusted.cooldownDuration, baseThresholds.cooldownDuration)

        try? FileManager.default.removeItem(at: tempURL)
    }

    func testCoachingTimingSettingsDeliveryModes() {
        let testDefaults = UserDefaults(suiteName: "com.hcd.batch2.timing.\(UUID().uuidString)")!
        let settings = CoachingTimingSettings(defaults: testDefaults)

        // Default: realtime mode, standard preset
        XCTAssertEqual(settings.deliveryMode, .realtime)
        XCTAssertEqual(settings.autoDismissPreset, .standard)
        XCTAssertEqual(settings.effectiveAutoDismissDuration, 8.0)

        // Pull mode: queue prompts
        settings.deliveryMode = .pull
        XCTAssertTrue(settings.pullModeQueue.isEmpty)

        // Manual preset: no auto-dismiss
        settings.autoDismissPreset = .manual
        XCTAssertNil(settings.effectiveAutoDismissDuration)
    }

    // MARK: - Feature B + F: Calendar to Participant Linking

    func testCalendarSuggestsExistingParticipant() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("participants_\(UUID().uuidString).json")
        let manager = ParticipantManager(storageURL: tempURL)

        // Create a participant
        let participant = manager.createParticipant(
            name: "Jane Doe",
            email: "jane@example.com",
            role: "Product Manager",
            department: nil,
            organization: "Acme Corp",
            experienceLevel: .intermediate,
            notes: "",
            metadata: [:]
        )

        // Create a mock upcoming interview
        let interview = UpcomingInterview(
            id: "event-123",
            title: "User Research - Jane Doe",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            notes: nil,
            participantName: "Jane Doe",
            projectName: "Project Alpha",
            calendarName: "Work"
        )

        // findOrSuggest should match by name
        let suggested = manager.findOrSuggest(from: interview)
        XCTAssertNotNil(suggested)
        XCTAssertEqual(suggested?.id, participant.id)
        XCTAssertEqual(suggested?.name, "Jane Doe")

        try? FileManager.default.removeItem(at: tempURL)
    }

    func testParticipantSessionLinking() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("participants_\(UUID().uuidString).json")
        let manager = ParticipantManager(storageURL: tempURL)

        let participant = manager.createParticipant(
            name: "Test User",
            email: nil,
            role: nil,
            department: nil,
            organization: nil,
            experienceLevel: nil,
            notes: "",
            metadata: [:]
        )

        let sessionId = UUID()
        manager.linkSession(sessionId, to: participant.id)

        // Verify link
        let linkedSessions = manager.sessions(for: participant.id)
        XCTAssertEqual(linkedSessions.count, 1)
        XCTAssertEqual(linkedSessions.first, sessionId)

        // Find participant by session
        let found = manager.participant(for: sessionId)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Test User")

        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Feature C + H: PII Detection with Consent Tracking

    func testPIIDetectionAndConsentWorkflow() {
        let detector = PIIDetector()

        // Detect PII in text
        let text = "My name is John Smith and my email is john@example.com, call me at 555-123-4567"
        let detections = detector.detect(in: text)

        // Should detect email and phone at minimum
        let emailDetections = detections.filter { $0.type == .email }
        let phoneDetections = detections.filter { $0.type == .phone }
        XCTAssertFalse(emailDetections.isEmpty, "Should detect email address")
        XCTAssertFalse(phoneDetections.isEmpty, "Should detect phone number")

        // ContainsPII should return true
        XCTAssertTrue(detector.containsPII(text))
        XCTAssertFalse(detector.containsPII("This is clean text with no personal data"))
    }

    func testConsentTrackerPersistence() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("consent_\(UUID().uuidString).json")
        let tracker = ConsentTracker(storageURL: tempURL)

        let sessionId = UUID()
        tracker.setConsent(.verbalConsent, for: sessionId, notes: "Verbal consent obtained via phone")

        let record = tracker.getConsent(for: sessionId)
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.status, .verbalConsent)
        XCTAssertNotNil(record?.obtainedAt)

        // Reload from disk
        let tracker2 = ConsentTracker(storageURL: tempURL)
        let reloaded = tracker2.getConsent(for: sessionId)
        XCTAssertNotNil(reloaded)
        XCTAssertEqual(reloaded?.status, .verbalConsent)

        try? FileManager.default.removeItem(at: tempURL)
    }

    func testRedactionServiceAppliesRedactions() {
        let tempActionsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("actions_\(UUID().uuidString).json")
        let tempConsentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("consent_\(UUID().uuidString).json")
        let service = RedactionService(
            detector: PIIDetector(),
            actionsURL: tempActionsURL,
            consentURL: tempConsentURL
        )

        let utteranceId = UUID()
        let detection = PIIDetection(
            id: UUID(),
            type: .email,
            matchedText: "john@example.com",
            startOffset: 20,
            endOffset: 36,
            confidence: 0.95,
            utteranceId: utteranceId,
            sessionId: nil
        )

        service.detections = [detection]
        service.applyRedaction(.redact, for: detection)

        // Verify action was recorded
        XCTAssertEqual(service.actions.count, 1)
        XCTAssertEqual(service.actions.first?.action, .redact)

        // Verify text redaction
        let original = "Contact me at john@example.com please"
        let redacted = service.applyRedactionsToText(original, utteranceId: utteranceId)
        XCTAssertTrue(redacted.contains("[EMAIL]") || redacted != original,
                       "Text should be redacted")

        try? FileManager.default.removeItem(at: tempActionsURL)
        try? FileManager.default.removeItem(at: tempConsentURL)
    }

    // MARK: - Feature D: Bias Detection

    func testBiasDetectorIdentifiesPatterns() {
        let detector = BiasDetector()

        // Create classifications with leading question bias
        let classifications: [(utteranceId: UUID, text: String, type: String)] = [
            (UUID(), "Don't you think the design is good?", "leading"),
            (UUID(), "Wouldn't you agree this is better?", "leading"),
            (UUID(), "You like this feature, right?", "leading"),
            (UUID(), "Isn't it obvious that this works?", "leading"),
            (UUID(), "Tell me about your experience", "open_ended"),
        ]

        detector.analyze(classifications: classifications)

        // Should detect leading pattern bias (>30% are leading)
        let leadingAlerts = detector.alerts.filter { $0.type == .leadingPatternBias }
        XCTAssertFalse(leadingAlerts.isEmpty, "Should detect leading question pattern bias")

        // Should detect confirmation bias (3+ confirmatory phrases)
        let confirmationAlerts = detector.alerts.filter { $0.type == .confirmationBias }
        XCTAssertFalse(confirmationAlerts.isEmpty, "Should detect confirmation bias")
    }

    // MARK: - Feature E: Highlights with Cross-Session Search

    func testHighlightCRUDAndSearch() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("highlights_\(UUID().uuidString).json")
        let service = HighlightService(storageURL: tempURL)

        let sessionId1 = UUID()
        let sessionId2 = UUID()

        // Create highlights across sessions
        let h1 = service.createHighlight(
            title: "Login Frustration",
            quoteText: "I always forget my password and the reset process is terrible",
            speaker: "Participant",
            category: .painPoint,
            notes: "Critical finding",
            utteranceId: UUID(),
            sessionId: sessionId1,
            timestampSeconds: 120.0
        )

        let h2 = service.createHighlight(
            title: "Quick Onboarding",
            quoteText: "I loved how easy it was to get started",
            speaker: "Participant",
            category: .delight,
            notes: "",
            utteranceId: UUID(),
            sessionId: sessionId2,
            timestampSeconds: 45.0
        )

        XCTAssertEqual(service.totalCount, 2)

        // Search across sessions
        let results = service.searchHighlights(query: "password")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Login Frustration")

        // Filter by category
        let painPoints = service.highlights(in: .painPoint)
        XCTAssertEqual(painPoints.count, 1)

        // Star and filter
        service.toggleStar(h2.id)
        XCTAssertEqual(service.starredCount, 1)

        // Session-specific query
        let session1Highlights = service.highlights(for: sessionId1)
        XCTAssertEqual(session1Highlights.count, 1)

        // Export
        let markdown = service.exportAsMarkdown()
        XCTAssertTrue(markdown.contains("Login Frustration"))
        XCTAssertTrue(markdown.contains("Quick Onboarding"))

        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Feature G: Sentiment Analysis

    func testSentimentAnalyzerDetectsEmotionalShifts() {
        let analyzer = SentimentAnalyzer()

        let positive = Utterance(
            speaker: .participant,
            text: "I absolutely love this feature, it's amazing and wonderful",
            timestampSeconds: 30.0
        )
        let negative = Utterance(
            speaker: .participant,
            text: "But this other part is terrible and frustrating, I hate it",
            timestampSeconds: 60.0
        )

        analyzer.analyzeSession([positive, negative])

        // Should have 2 results
        XCTAssertEqual(analyzer.results.count, 2)

        // First should be positive
        XCTAssertEqual(analyzer.results.first?.polarity, .positive)

        // Second should be negative
        XCTAssertEqual(analyzer.results.last?.polarity, .negative)

        // Should detect an emotional shift
        XCTAssertFalse(analyzer.emotionalShifts.isEmpty, "Should detect emotional shift")
    }

    func testSentimentAnalyzerHandlesNegation() {
        let analyzer = SentimentAnalyzer()

        let negated = Utterance(
            speaker: .participant,
            text: "It's not good at all",
            timestampSeconds: 10.0
        )

        let result = analyzer.analyze(negated)

        // "not good" should flip to negative
        XCTAssertTrue(result.score < 0, "Negated positive should be negative, got \(result.score)")
    }

    func testSentimentArcSummaryGeneration() {
        let analyzer = SentimentAnalyzer()

        let utterances = [
            Utterance(speaker: .participant, text: "I love this product, it's great", timestampSeconds: 10),
            Utterance(speaker: .participant, text: "This part is okay I guess", timestampSeconds: 30),
            Utterance(speaker: .participant, text: "But this is really frustrating and terrible", timestampSeconds: 50),
        ]

        analyzer.analyzeSession(utterances)
        let summary = analyzer.generateArcSummary()

        XCTAssertNotNil(summary)
        XCTAssertFalse(summary!.arcDescription.isEmpty)
        XCTAssertLessThanOrEqual(summary!.intensityPeaks.count, 3)
    }

    // MARK: - Feature H: Consent Templates

    func testDefaultConsentTemplatesHaveCorrectStructure() {
        let english = ConsentTemplate.defaultEnglish()
        let spanish = ConsentTemplate.defaultSpanish()
        let french = ConsentTemplate.defaultFrench()

        // All should have 5 permissions
        XCTAssertEqual(english.permissionCount, 5)
        XCTAssertEqual(spanish.permissionCount, 5)
        XCTAssertEqual(french.permissionCount, 5)

        // Same required/optional structure
        for i in 0..<5 {
            XCTAssertEqual(english.permissions[i].isRequired, spanish.permissions[i].isRequired)
            XCTAssertEqual(english.permissions[i].isRequired, french.permissions[i].isRequired)
        }

        // Not all accepted by default
        XCTAssertFalse(english.allRequiredAccepted)
        XCTAssertEqual(english.acceptedCount, 0)
    }

    func testConsentTemplateAcceptanceLogic() {
        var template = ConsentTemplate.defaultEnglish()

        // Accept only required permissions
        for i in 0..<template.permissions.count {
            if template.permissions[i].isRequired {
                template.permissions[i].isAccepted = true
            }
        }

        // allRequiredAccepted should be true even with optional declined
        XCTAssertTrue(template.allRequiredAccepted)
        XCTAssertEqual(template.acceptedCount, 3) // 3 required
    }

    // MARK: - Cross-Feature: Participant + Consent + PII Flow

    func testFullParticipantConsentFlow() {
        let participantURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("participants_\(UUID().uuidString).json")
        let consentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("consent_\(UUID().uuidString).json")

        let participantManager = ParticipantManager(storageURL: participantURL)
        let consentTracker = ConsentTracker(storageURL: consentURL)

        // 1. Create participant
        let participant = participantManager.createParticipant(
            name: "Sarah Johnson",
            email: "sarah@company.com",
            role: "Designer",
            department: "UX",
            organization: "TechCo",
            experienceLevel: .advanced,
            notes: "",
            metadata: ["Recruited via": "UserTesting.com"]
        )

        // 2. Link to session
        let sessionId = UUID()
        participantManager.linkSession(sessionId, to: participant.id)

        // 3. Track consent
        consentTracker.setConsent(.writtenConsent, for: sessionId, notes: "Signed digital consent form v1.0.0")

        // 4. Verify complete chain
        let linkedParticipant = participantManager.participant(for: sessionId)
        XCTAssertEqual(linkedParticipant?.name, "Sarah Johnson")

        let consent = consentTracker.getConsent(for: sessionId)
        XCTAssertEqual(consent?.status, .writtenConsent)

        // 5. GDPR export
        let export = participantManager.exportParticipantData(participant.id)
        XCTAssertTrue(export.contains("Sarah Johnson"))
        XCTAssertTrue(export.contains("sarah@company.com"))

        try? FileManager.default.removeItem(at: participantURL)
        try? FileManager.default.removeItem(at: consentURL)
    }

    // MARK: - Cross-Feature: Sentiment + Highlights Integration

    func testEmotionalPeaksCanBecomeHighlights() {
        let analyzer = SentimentAnalyzer()
        let highlightURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("highlights_\(UUID().uuidString).json")
        let highlightService = HighlightService(storageURL: highlightURL)
        let sessionId = UUID()

        // Analyze utterances
        let utterances = [
            Utterance(speaker: .participant, text: "This is absolutely amazing, I love it", timestampSeconds: 30),
            Utterance(speaker: .participant, text: "Just okay here", timestampSeconds: 60),
            Utterance(speaker: .participant, text: "This is the worst experience ever, I hate it", timestampSeconds: 90),
        ]

        analyzer.analyzeSession(utterances)

        // Take the most intense moments and create highlights
        let peaks = analyzer.results.sorted { $0.intensity > $1.intensity }
        for peak in peaks.prefix(2) {
            let utterance = utterances.first { $0.id == peak.utteranceId }
            if let utterance = utterance {
                let category: HighlightCategory = peak.polarity == .positive ? .delight : .painPoint
                _ = highlightService.createHighlight(
                    title: peak.dominantEmotion?.capitalized ?? "Emotional Moment",
                    quoteText: utterance.text,
                    speaker: utterance.speaker.displayName,
                    category: category,
                    notes: "Auto-flagged: intensity \(String(format: "%.2f", peak.intensity))",
                    utteranceId: peak.utteranceId,
                    sessionId: sessionId,
                    timestampSeconds: peak.timestamp
                )
            }
        }

        XCTAssertGreaterThanOrEqual(highlightService.totalCount, 1)

        try? FileManager.default.removeItem(at: highlightURL)
    }

    // MARK: - Cross-Feature: Cultural Context + Bias Detection

    func testCulturalContextEnablesBiasDetection() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cultural_\(UUID().uuidString).json")
        let manager = CulturalContextManager(storageURL: tempURL)
        let biasDetector = BiasDetector()

        // Enable bias alerts
        var context = manager.context
        context.enableBiasAlerts = true
        manager.updateContext(context)
        XCTAssertTrue(manager.context.enableBiasAlerts)

        // Run bias detection with gendered language
        let classifications: [(utteranceId: UUID, text: String, type: String)] = [
            (UUID(), "How do the guys on your team handle this?", "open_ended"),
            (UUID(), "What about the girls in marketing?", "open_ended"),
            (UUID(), "Tell me about your workflow", "open_ended"),
        ]

        biasDetector.analyze(classifications: classifications)

        // Should detect gender bias
        let genderAlerts = biasDetector.alerts.filter { $0.type == .genderBias }
        XCTAssertFalse(genderAlerts.isEmpty, "Should detect gender bias in questions")

        try? FileManager.default.removeItem(at: tempURL)
    }
}
