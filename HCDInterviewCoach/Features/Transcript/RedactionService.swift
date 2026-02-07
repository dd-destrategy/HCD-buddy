//
//  RedactionService.swift
//  HCDInterviewCoach
//
//  FEATURE C: Consent & PII Redaction Engine
//  Manages PII redaction state and consent tracking with JSON persistence.
//

import Foundation

// MARK: - Consent Status

/// Status of consent for a session
enum ConsentStatus: String, CaseIterable, Codable {
    case notObtained = "not_obtained"
    case verbalConsent = "verbal"
    case writtenConsent = "written"
    case declined = "declined"

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .notObtained: return "Not Obtained"
        case .verbalConsent: return "Verbal Consent"
        case .writtenConsent: return "Written Consent"
        case .declined: return "Declined"
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .notObtained: return "questionmark.circle"
        case .verbalConsent: return "mic.fill"
        case .writtenConsent: return "doc.text.fill"
        case .declined: return "xmark.circle.fill"
        }
    }

    /// Semantic color token name for this consent status
    var color: String {
        switch self {
        case .notObtained: return "hcdWarning"
        case .verbalConsent: return "hcdSuccess"
        case .writtenConsent: return "hcdSuccess"
        case .declined: return "hcdError"
        }
    }
}

// MARK: - Redaction Decision

/// The decision made for a detected PII instance
enum RedactionDecision: String, Codable {
    /// Replace with the PII type label (e.g., [EMAIL])
    case redact = "redact"
    /// Keep the original text unchanged
    case keep = "keep"
    /// Replace with custom user-provided text
    case replace = "replace"
}

// MARK: - Redaction Action

/// A redaction action taken on a detected PII instance
struct RedactionAction: Identifiable, Codable {
    let id: UUID
    let detectionId: UUID
    let action: RedactionDecision
    let replacement: String
    let performedAt: Date
    let performedBy: String

    init(
        id: UUID = UUID(),
        detectionId: UUID,
        action: RedactionDecision,
        replacement: String,
        performedAt: Date = Date(),
        performedBy: String = "user"
    ) {
        self.id = id
        self.detectionId = detectionId
        self.action = action
        self.replacement = replacement
        self.performedAt = performedAt
        self.performedBy = performedBy
    }
}

// MARK: - Consent Record

/// Record of consent status for a specific session
struct ConsentRecord: Identifiable, Codable {
    let id: UUID
    let sessionId: UUID
    let status: ConsentStatus
    let obtainedAt: Date?
    let notes: String?

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        status: ConsentStatus,
        obtainedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.status = status
        self.obtainedAt = obtainedAt
        self.notes = notes
    }
}

// MARK: - Redaction Service

/// Manages PII redaction state and consent tracking.
///
/// Detections, redaction actions, and consent records are persisted as JSON files in
/// `~/Library/Application Support/HCDInterviewCoach/` to avoid SwiftData schema migration.
@MainActor
final class RedactionService: ObservableObject {

    // MARK: - Published Properties

    /// All PII detections from the most recent scan
    @Published var detections: [PIIDetection] = []

    /// All redaction actions taken by the user or auto-redaction
    @Published var actions: [RedactionAction] = []

    /// All consent records across sessions
    @Published var consentRecords: [ConsentRecord] = []

    /// Whether a scan is currently in progress
    @Published var isScanning: Bool = false

    // MARK: - Private Properties

    private let detector: PIIDetector
    private let actionsStorageURL: URL
    private let consentStorageURL: URL

    // MARK: - Initialization

    /// Creates a RedactionService with default storage locations.
    /// - Parameter detector: The PII detector to use. Defaults to a new instance detecting all types.
    init(detector: PIIDetector = PIIDetector()) {
        let directory = Self.defaultStorageDirectory()
        self.detector = detector
        self.actionsStorageURL = directory.appendingPathComponent("redaction_actions.json")
        self.consentStorageURL = directory.appendingPathComponent("consent_records.json")
        load()
    }

    /// Creates a RedactionService with custom storage paths for testing.
    /// - Parameters:
    ///   - detector: The PII detector to use
    ///   - actionsURL: The file URL for persisting redaction actions
    ///   - consentURL: The file URL for persisting consent records
    init(detector: PIIDetector, actionsURL: URL, consentURL: URL) {
        self.detector = detector
        self.actionsStorageURL = actionsURL
        self.consentStorageURL = consentURL
        load()
    }

    // MARK: - Scanning

    /// Scan a session's utterances for PII.
    /// - Parameters:
    ///   - utterances: The utterances to scan
    ///   - sessionId: The session ID to associate with detections
    func scanSession(utterances: [Utterance], sessionId: UUID) async {
        isScanning = true
        let scannedDetections = detector.scanSession(utterances: utterances, sessionId: sessionId)
        detections = scannedDetections
        isScanning = false
        AppLogger.shared.info("PII scan complete: found \(scannedDetections.count) detections in \(utterances.count) utterances")
    }

    // MARK: - Redaction Actions

    /// Apply a redaction decision to a specific detection.
    /// - Parameters:
    ///   - decision: The redaction decision (redact, keep, or replace)
    ///   - detection: The PII detection to act on
    ///   - replacement: Optional custom replacement text (used when decision is `.replace`)
    func applyRedaction(_ decision: RedactionDecision, for detection: PIIDetection, replacement: String? = nil) {
        let replacementText: String
        switch decision {
        case .redact:
            replacementText = detection.type.redactionLabel
        case .keep:
            replacementText = detection.matchedText
        case .replace:
            replacementText = replacement ?? detection.type.redactionLabel
        }

        let action = RedactionAction(
            detectionId: detection.id,
            action: decision,
            replacement: replacementText
        )

        // Remove any existing action for this detection before adding the new one
        actions.removeAll { $0.detectionId == detection.id }
        actions.append(action)
        save()

        AppLogger.shared.debug("Applied \(decision.rawValue) redaction for \(detection.type.rawValue): \(detection.matchedText)")
    }

    /// Apply redactions to a text string for a given utterance (used during export).
    ///
    /// Processes all redaction actions for the utterance in reverse order (from end to start)
    /// to preserve character offsets while making replacements.
    /// - Parameters:
    ///   - text: The original text
    ///   - utteranceId: The utterance ID whose actions should be applied
    /// - Returns: The text with all redactions applied
    func applyRedactionsToText(_ text: String, utteranceId: UUID) -> String {
        // Find detections for this utterance
        let utteranceDetections = detections.filter { $0.utteranceId == utteranceId }

        // Build a map of detection ID to action
        let actionMap = Dictionary(uniqueKeysWithValues: actions.map { ($0.detectionId, $0) })

        // Collect applicable replacements, sorted by offset descending so we can apply from the end
        var replacements: [(startOffset: Int, endOffset: Int, replacement: String)] = []

        for detection in utteranceDetections {
            guard let action = actionMap[detection.id] else { continue }
            // Only apply redact and replace; keep leaves text unchanged
            if action.action == .keep { continue }
            replacements.append((
                startOffset: detection.startOffset,
                endOffset: detection.endOffset,
                replacement: action.replacement
            ))
        }

        // Sort descending by startOffset so we replace from end to start
        replacements.sort { $0.startOffset > $1.startOffset }

        var result = text
        for replacement in replacements {
            let startIndex = result.index(result.startIndex, offsetBy: replacement.startOffset, limitedBy: result.endIndex)
            let endIndex = result.index(result.startIndex, offsetBy: replacement.endOffset, limitedBy: result.endIndex)

            guard let start = startIndex, let end = endIndex, start <= end else { continue }
            result.replaceSubrange(start..<end, with: replacement.replacement)
        }

        return result
    }

    /// Batch-redact all detections of a given PII type.
    /// - Parameter type: The PII type to redact
    func batchRedact(type: PIIType) {
        let typeDetections = detections.filter { $0.type == type }
        for detection in typeDetections {
            // Only apply if no action has been taken yet
            let hasAction = actions.contains { $0.detectionId == detection.id }
            if !hasAction {
                applyRedaction(.redact, for: detection)
            }
        }
        AppLogger.shared.info("Batch-redacted \(typeDetections.count) \(type.displayName) detections")
    }

    // MARK: - Consent Tracking

    /// Get the consent record for a specific session.
    /// - Parameter sessionId: The session ID
    /// - Returns: The consent record, or nil if none exists
    func consentRecord(for sessionId: UUID) -> ConsentRecord? {
        consentRecords.first { $0.sessionId == sessionId }
    }

    /// Set the consent status for a session.
    /// - Parameters:
    ///   - status: The consent status
    ///   - sessionId: The session ID
    ///   - notes: Optional notes about the consent
    func setConsentStatus(_ status: ConsentStatus, for sessionId: UUID, notes: String?) {
        // Remove existing record for this session
        consentRecords.removeAll { $0.sessionId == sessionId }

        let record = ConsentRecord(
            sessionId: sessionId,
            status: status,
            obtainedAt: (status == .verbalConsent || status == .writtenConsent) ? Date() : nil,
            notes: notes
        )
        consentRecords.append(record)
        save()

        AppLogger.shared.info("Set consent status to \(status.rawValue) for session \(sessionId)")
    }

    // MARK: - Querying

    /// Get all detections that have no redaction action taken yet.
    /// - Returns: An array of unresolved detections
    func unresolvedDetections() -> [PIIDetection] {
        let resolvedIds = Set(actions.map { $0.detectionId })
        return detections.filter { !resolvedIds.contains($0.id) }
    }

    /// Get detection counts grouped by PII type.
    /// - Returns: A dictionary mapping each PII type to its detection count
    func detectionCounts() -> [PIIType: Int] {
        var counts: [PIIType: Int] = [:]
        for detection in detections {
            counts[detection.type, default: 0] += 1
        }
        return counts
    }

    // MARK: - Persistence

    /// Load redaction actions and consent records from disk.
    private func load() {
        loadActions()
        loadConsentRecords()
    }

    /// Save redaction actions and consent records to disk.
    func save() {
        saveActions()
        saveConsentRecords()
    }

    private func loadActions() {
        guard FileManager.default.fileExists(atPath: actionsStorageURL.path) else {
            AppLogger.shared.debug("No redaction actions file found at \(actionsStorageURL.path)")
            actions = []
            return
        }

        do {
            let data = try Data(contentsOf: actionsStorageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            actions = try decoder.decode([RedactionAction].self, from: data)
            AppLogger.shared.info("Loaded \(actions.count) redaction actions from disk")
        } catch {
            AppLogger.shared.error("Failed to load redaction actions: \(error.localizedDescription)")
            actions = []
        }
    }

    private func saveActions() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(actions)
            try data.write(to: actionsStorageURL, options: [.atomic])
            AppLogger.shared.debug("Redaction actions saved to \(actionsStorageURL.path)")
        } catch {
            AppLogger.shared.error("Failed to save redaction actions: \(error.localizedDescription)")
        }
    }

    private func loadConsentRecords() {
        guard FileManager.default.fileExists(atPath: consentStorageURL.path) else {
            AppLogger.shared.debug("No consent records file found at \(consentStorageURL.path)")
            consentRecords = []
            return
        }

        do {
            let data = try Data(contentsOf: consentStorageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            consentRecords = try decoder.decode([ConsentRecord].self, from: data)
            AppLogger.shared.info("Loaded \(consentRecords.count) consent records from disk")
        } catch {
            AppLogger.shared.error("Failed to load consent records: \(error.localizedDescription)")
            consentRecords = []
        }
    }

    private func saveConsentRecords() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(consentRecords)
            try data.write(to: consentStorageURL, options: [.atomic])
            AppLogger.shared.debug("Consent records saved to \(consentStorageURL.path)")
        } catch {
            AppLogger.shared.error("Failed to save consent records: \(error.localizedDescription)")
        }
    }

    // MARK: - Storage Location

    /// Returns the default directory for persistence files.
    /// Creates the directory if it does not exist.
    static func defaultStorageDirectory() -> URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            AppLogger.shared.warning("Application Support directory unavailable, using temporary directory for redaction data")
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("HCDInterviewCoach")
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            return tempDir
        }

        let appDirectory = appSupport.appendingPathComponent("HCDInterviewCoach", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: appDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        return appDirectory
    }
}
