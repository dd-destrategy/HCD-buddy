//
//  RedactionServiceTests.swift
//  HCD Interview Coach Tests
//
//  FEATURE C: Consent & PII Redaction Engine
//  Unit tests for RedactionService redaction actions, consent tracking, and persistence.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class RedactionServiceTests: XCTestCase {

    // MARK: - Properties

    var service: RedactionService!
    var tempDirectory: URL!
    var actionsURL: URL!
    var consentURL: URL!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RedactionServiceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        actionsURL = tempDirectory.appendingPathComponent("redaction_actions.json")
        consentURL = tempDirectory.appendingPathComponent("consent_records.json")
        service = RedactionService(detector: PIIDetector(), actionsURL: actionsURL, consentURL: consentURL)
    }

    override func tearDown() {
        service = nil
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        actionsURL = nil
        consentURL = nil
        super.tearDown()
    }

    // MARK: - Test: Apply Redaction with .redact

    func testApplyRedaction_redact_createsActionWithTypeLabel() {
        let detection = makeSampleDetection(type: .email, matchedText: "user@example.com")

        service.detections = [detection]
        service.applyRedaction(.redact, for: detection)

        XCTAssertEqual(service.actions.count, 1)
        let action = service.actions.first!
        XCTAssertEqual(action.detectionId, detection.id)
        XCTAssertEqual(action.action, .redact)
        XCTAssertEqual(action.replacement, "[EMAIL]")
        XCTAssertEqual(action.performedBy, "user")
    }

    // MARK: - Test: Apply Redaction with .keep

    func testApplyRedaction_keep_preservesOriginalText() {
        let detection = makeSampleDetection(type: .phone, matchedText: "555-123-4567")

        service.detections = [detection]
        service.applyRedaction(.keep, for: detection)

        XCTAssertEqual(service.actions.count, 1)
        let action = service.actions.first!
        XCTAssertEqual(action.action, .keep)
        XCTAssertEqual(action.replacement, "555-123-4567")
    }

    // MARK: - Test: Apply Redaction with .replace

    func testApplyRedaction_replace_usesCustomText() {
        let detection = makeSampleDetection(type: .name, matchedText: "John Smith")

        service.detections = [detection]
        service.applyRedaction(.replace, for: detection, replacement: "Participant A")

        XCTAssertEqual(service.actions.count, 1)
        let action = service.actions.first!
        XCTAssertEqual(action.action, .replace)
        XCTAssertEqual(action.replacement, "Participant A")
    }

    func testApplyRedaction_replace_withoutCustomText_usesLabel() {
        let detection = makeSampleDetection(type: .name, matchedText: "John Smith")

        service.detections = [detection]
        service.applyRedaction(.replace, for: detection)

        XCTAssertEqual(service.actions.count, 1)
        XCTAssertEqual(service.actions.first?.replacement, "[NAME]")
    }

    // MARK: - Test: Apply Redaction Replaces Existing

    func testApplyRedaction_replacesExistingAction() {
        let detection = makeSampleDetection(type: .email, matchedText: "user@example.com")

        service.detections = [detection]

        // First action: redact
        service.applyRedaction(.redact, for: detection)
        XCTAssertEqual(service.actions.count, 1)
        XCTAssertEqual(service.actions.first?.action, .redact)

        // Second action: keep (should replace the first)
        service.applyRedaction(.keep, for: detection)
        XCTAssertEqual(service.actions.count, 1)
        XCTAssertEqual(service.actions.first?.action, .keep)
    }

    // MARK: - Test: Apply Redactions to Text

    func testApplyRedactionsToText_redactsEmail() {
        let utteranceId = UUID()
        let detection = makeSampleDetection(
            type: .email,
            matchedText: "user@example.com",
            startOffset: 12,
            endOffset: 28,
            utteranceId: utteranceId
        )

        service.detections = [detection]
        service.applyRedaction(.redact, for: detection)

        let originalText = "My email is user@example.com thanks"
        let result = service.applyRedactionsToText(originalText, utteranceId: utteranceId)

        XCTAssertEqual(result, "My email is [EMAIL] thanks")
    }

    func testApplyRedactionsToText_keepLeavesUnchanged() {
        let utteranceId = UUID()
        let detection = makeSampleDetection(
            type: .email,
            matchedText: "user@example.com",
            startOffset: 12,
            endOffset: 28,
            utteranceId: utteranceId
        )

        service.detections = [detection]
        service.applyRedaction(.keep, for: detection)

        let originalText = "My email is user@example.com thanks"
        let result = service.applyRedactionsToText(originalText, utteranceId: utteranceId)

        XCTAssertEqual(result, originalText)
    }

    func testApplyRedactionsToText_multipleRedactions() {
        let utteranceId = UUID()
        let detection1 = makeSampleDetection(
            type: .email,
            matchedText: "a@b.com",
            startOffset: 0,
            endOffset: 7,
            utteranceId: utteranceId
        )
        let detection2 = makeSampleDetection(
            type: .phone,
            matchedText: "555-1234",
            startOffset: 12,
            endOffset: 20,
            utteranceId: utteranceId
        )

        service.detections = [detection1, detection2]
        service.applyRedaction(.redact, for: detection1)
        service.applyRedaction(.redact, for: detection2)

        let originalText = "a@b.com and 555-1234"
        let result = service.applyRedactionsToText(originalText, utteranceId: utteranceId)

        XCTAssertEqual(result, "[EMAIL] and [PHONE]")
    }

    func testApplyRedactionsToText_noActionsForUtterance_returnsOriginal() {
        let utteranceId = UUID()
        let otherUtteranceId = UUID()
        let detection = makeSampleDetection(
            type: .email,
            matchedText: "user@example.com",
            startOffset: 0,
            endOffset: 16,
            utteranceId: otherUtteranceId
        )

        service.detections = [detection]
        service.applyRedaction(.redact, for: detection)

        let originalText = "user@example.com"
        let result = service.applyRedactionsToText(originalText, utteranceId: utteranceId)

        // No detections for this utteranceId, so text should be unchanged
        XCTAssertEqual(result, originalText)
    }

    // MARK: - Test: Batch Redact

    func testBatchRedact_redactsAllOfType() {
        let detection1 = makeSampleDetection(type: .email, matchedText: "a@b.com")
        let detection2 = makeSampleDetection(type: .email, matchedText: "c@d.com")
        let detection3 = makeSampleDetection(type: .phone, matchedText: "555-1234")

        service.detections = [detection1, detection2, detection3]
        service.batchRedact(type: .email)

        // Both emails should be redacted, phone untouched
        let emailActions = service.actions.filter { action in
            [detection1.id, detection2.id].contains(action.detectionId)
        }
        XCTAssertEqual(emailActions.count, 2)
        XCTAssertTrue(emailActions.allSatisfy { $0.action == .redact })

        let phoneActions = service.actions.filter { $0.detectionId == detection3.id }
        XCTAssertEqual(phoneActions.count, 0)
    }

    func testBatchRedact_skipsAlreadyActioned() {
        let detection1 = makeSampleDetection(type: .email, matchedText: "a@b.com")
        let detection2 = makeSampleDetection(type: .email, matchedText: "c@d.com")

        service.detections = [detection1, detection2]

        // Manually keep detection1
        service.applyRedaction(.keep, for: detection1)

        // Batch redact emails
        service.batchRedact(type: .email)

        // detection1 should still be "keep", detection2 should be "redact"
        let action1 = service.actions.first { $0.detectionId == detection1.id }
        XCTAssertEqual(action1?.action, .keep)

        let action2 = service.actions.first { $0.detectionId == detection2.id }
        XCTAssertEqual(action2?.action, .redact)
    }

    // MARK: - Test: Consent Tracking

    func testSetConsentStatus_setsRecord() {
        let sessionId = UUID()

        service.setConsentStatus(.verbalConsent, for: sessionId, notes: "Verbal at start")

        let record = service.consentRecord(for: sessionId)
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.status, .verbalConsent)
        XCTAssertEqual(record?.notes, "Verbal at start")
        XCTAssertNotNil(record?.obtainedAt)
    }

    func testSetConsentStatus_updatesExisting() {
        let sessionId = UUID()

        service.setConsentStatus(.verbalConsent, for: sessionId, notes: "First")
        service.setConsentStatus(.writtenConsent, for: sessionId, notes: "Updated")

        // Should have only one record for this session
        let matchingRecords = service.consentRecords.filter { $0.sessionId == sessionId }
        XCTAssertEqual(matchingRecords.count, 1)
        XCTAssertEqual(matchingRecords.first?.status, .writtenConsent)
        XCTAssertEqual(matchingRecords.first?.notes, "Updated")
    }

    func testSetConsentStatus_declined_noObtainedAt() {
        let sessionId = UUID()

        service.setConsentStatus(.declined, for: sessionId, notes: nil)

        let record = service.consentRecord(for: sessionId)
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.status, .declined)
        XCTAssertNil(record?.obtainedAt)
    }

    func testSetConsentStatus_notObtained_noObtainedAt() {
        let sessionId = UUID()

        service.setConsentStatus(.notObtained, for: sessionId, notes: nil)

        let record = service.consentRecord(for: sessionId)
        XCTAssertNotNil(record)
        XCTAssertNil(record?.obtainedAt)
    }

    func testConsentRecord_nonExistentSession_returnsNil() {
        let record = service.consentRecord(for: UUID())

        XCTAssertNil(record)
    }

    // MARK: - Test: Unresolved Detections

    func testUnresolvedDetections_allUnresolved() {
        let detection1 = makeSampleDetection(type: .email, matchedText: "a@b.com")
        let detection2 = makeSampleDetection(type: .phone, matchedText: "555-1234")

        service.detections = [detection1, detection2]

        XCTAssertEqual(service.unresolvedDetections().count, 2)
    }

    func testUnresolvedDetections_someResolved() {
        let detection1 = makeSampleDetection(type: .email, matchedText: "a@b.com")
        let detection2 = makeSampleDetection(type: .phone, matchedText: "555-1234")

        service.detections = [detection1, detection2]
        service.applyRedaction(.redact, for: detection1)

        let unresolved = service.unresolvedDetections()
        XCTAssertEqual(unresolved.count, 1)
        XCTAssertEqual(unresolved.first?.id, detection2.id)
    }

    func testUnresolvedDetections_allResolved() {
        let detection = makeSampleDetection(type: .email, matchedText: "a@b.com")

        service.detections = [detection]
        service.applyRedaction(.keep, for: detection)

        XCTAssertEqual(service.unresolvedDetections().count, 0)
    }

    // MARK: - Test: Detection Counts

    func testDetectionCounts_groupsByType() {
        let d1 = makeSampleDetection(type: .email, matchedText: "a@b.com")
        let d2 = makeSampleDetection(type: .email, matchedText: "c@d.com")
        let d3 = makeSampleDetection(type: .phone, matchedText: "555-1234")
        let d4 = makeSampleDetection(type: .ssn, matchedText: "123-45-6789")

        service.detections = [d1, d2, d3, d4]

        let counts = service.detectionCounts()
        XCTAssertEqual(counts[.email], 2)
        XCTAssertEqual(counts[.phone], 1)
        XCTAssertEqual(counts[.ssn], 1)
        XCTAssertNil(counts[.name])
    }

    func testDetectionCounts_empty() {
        let counts = service.detectionCounts()

        XCTAssertTrue(counts.isEmpty)
    }

    // MARK: - Test: Persistence

    func testPersistence_saveAndLoadActions() {
        let detection = makeSampleDetection(type: .email, matchedText: "a@b.com")
        service.detections = [detection]
        service.applyRedaction(.redact, for: detection)

        // Create new service from same files
        let reloaded = RedactionService(detector: PIIDetector(), actionsURL: actionsURL, consentURL: consentURL)

        XCTAssertEqual(reloaded.actions.count, 1)
        let action = reloaded.actions.first!
        XCTAssertEqual(action.action, .redact)
        XCTAssertEqual(action.replacement, "[EMAIL]")
    }

    func testPersistence_saveAndLoadConsent() {
        let sessionId = UUID()
        service.setConsentStatus(.writtenConsent, for: sessionId, notes: "Signed form")

        // Create new service from same files
        let reloaded = RedactionService(detector: PIIDetector(), actionsURL: actionsURL, consentURL: consentURL)

        let record = reloaded.consentRecords.first { $0.sessionId == sessionId }
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.status, .writtenConsent)
        XCTAssertEqual(record?.notes, "Signed form")
    }

    func testPersistence_corruptedActionsFile_loadsEmpty() throws {
        let corruptData = "not json".data(using: .utf8)!
        try corruptData.write(to: actionsURL)

        let reloaded = RedactionService(detector: PIIDetector(), actionsURL: actionsURL, consentURL: consentURL)

        XCTAssertEqual(reloaded.actions.count, 0)
    }

    func testPersistence_corruptedConsentFile_loadsEmpty() throws {
        let corruptData = "not json".data(using: .utf8)!
        try corruptData.write(to: consentURL)

        let reloaded = RedactionService(detector: PIIDetector(), actionsURL: actionsURL, consentURL: consentURL)

        XCTAssertEqual(reloaded.consentRecords.count, 0)
    }

    // MARK: - Test: ConsentStatus Properties

    func testConsentStatus_displayNames() {
        XCTAssertEqual(ConsentStatus.notObtained.displayName, "Not Obtained")
        XCTAssertEqual(ConsentStatus.verbalConsent.displayName, "Verbal Consent")
        XCTAssertEqual(ConsentStatus.writtenConsent.displayName, "Written Consent")
        XCTAssertEqual(ConsentStatus.declined.displayName, "Declined")
    }

    func testConsentStatus_icons_areNonEmpty() {
        for status in ConsentStatus.allCases {
            XCTAssertFalse(status.icon.isEmpty, "\(status.rawValue) should have an icon")
        }
    }

    func testConsentStatus_colors_areNonEmpty() {
        for status in ConsentStatus.allCases {
            XCTAssertFalse(status.color.isEmpty, "\(status.rawValue) should have a color")
        }
    }

    // MARK: - Test: RedactionAction Codable

    func testRedactionAction_codable_roundTrip() throws {
        let action = RedactionAction(
            detectionId: UUID(),
            action: .redact,
            replacement: "[EMAIL]",
            performedBy: "auto"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(action)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RedactionAction.self, from: data)

        XCTAssertEqual(decoded.id, action.id)
        XCTAssertEqual(decoded.detectionId, action.detectionId)
        XCTAssertEqual(decoded.action, action.action)
        XCTAssertEqual(decoded.replacement, action.replacement)
        XCTAssertEqual(decoded.performedBy, action.performedBy)
    }

    // MARK: - Test: ConsentRecord Codable

    func testConsentRecord_codable_roundTrip() throws {
        let record = ConsentRecord(
            sessionId: UUID(),
            status: .verbalConsent,
            obtainedAt: Date(),
            notes: "Test note"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ConsentRecord.self, from: data)

        XCTAssertEqual(decoded.id, record.id)
        XCTAssertEqual(decoded.sessionId, record.sessionId)
        XCTAssertEqual(decoded.status, record.status)
        XCTAssertEqual(decoded.notes, record.notes)
    }

    // MARK: - Helpers

    /// Creates a sample PIIDetection for use in tests.
    private func makeSampleDetection(
        type: PIIType,
        matchedText: String,
        startOffset: Int = 0,
        endOffset: Int = 10,
        utteranceId: UUID? = nil,
        sessionId: UUID? = nil
    ) -> PIIDetection {
        PIIDetection(
            type: type,
            matchedText: matchedText,
            startOffset: startOffset,
            endOffset: endOffset,
            confidence: 0.9,
            utteranceId: utteranceId,
            sessionId: sessionId
        )
    }
}
