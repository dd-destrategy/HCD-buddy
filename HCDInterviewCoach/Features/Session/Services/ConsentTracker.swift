//
//  ConsentTracker.swift
//  HCDInterviewCoach
//
//  FEATURE C: Consent & PII Redaction Engine
//  Lightweight service for tracking consent status per session with JSON persistence.
//

import Foundation

/// Tracks consent status for interview sessions.
///
/// Consent records are stored as a JSON file in
/// `~/Library/Application Support/HCDInterviewCoach/` to avoid SwiftData schema migration.
@MainActor
final class ConsentTracker: ObservableObject {

    // MARK: - Published Properties

    /// The consent status for the currently active session
    @Published var currentSessionConsent: ConsentStatus = .notObtained

    /// Complete history of consent records across all sessions
    @Published var consentHistory: [ConsentRecord] = []

    // MARK: - Private Properties

    /// File URL for persisted consent records JSON
    private let storageURL: URL

    // MARK: - Initialization

    /// Creates a ConsentTracker with the default storage location.
    /// Loads persisted consent records from disk.
    init() {
        let directory = Self.defaultStorageDirectory()
        self.storageURL = directory.appendingPathComponent("consent_tracker.json")
        load()
    }

    /// Creates a ConsentTracker backed by a custom storage URL.
    /// Intended for testing with temporary directories.
    /// - Parameter storageURL: The file URL where consent records JSON will be persisted
    init(storageURL: URL) {
        self.storageURL = storageURL
        load()
    }

    // MARK: - Public API

    /// Sets the consent status for a specific session.
    /// If a record already exists for the session, it is replaced.
    /// - Parameters:
    ///   - status: The consent status to set
    ///   - sessionId: The UUID of the session
    ///   - notes: Optional notes about the consent (e.g., how it was obtained)
    func setConsent(_ status: ConsentStatus, for sessionId: UUID, notes: String?) {
        // Remove any existing record for this session
        consentHistory.removeAll { $0.sessionId == sessionId }

        let record = ConsentRecord(
            sessionId: sessionId,
            status: status,
            obtainedAt: (status == .verbalConsent || status == .writtenConsent) ? Date() : nil,
            notes: notes
        )
        consentHistory.append(record)
        currentSessionConsent = status
        save()

        AppLogger.shared.info("ConsentTracker: set consent to \(status.rawValue) for session \(sessionId)")
    }

    /// Retrieves the consent record for a specific session.
    /// - Parameter sessionId: The UUID of the session
    /// - Returns: The consent record, or nil if none exists
    func getConsent(for sessionId: UUID) -> ConsentRecord? {
        consentHistory.first { $0.sessionId == sessionId }
    }

    /// Returns all consent records across all sessions.
    /// - Returns: An array of all consent records, ordered by insertion
    func allConsents() -> [ConsentRecord] {
        consentHistory
    }

    // MARK: - Persistence

    /// Loads consent records from the JSON file on disk.
    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            AppLogger.shared.debug("No consent tracker file found at \(storageURL.path)")
            consentHistory = []
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            consentHistory = try decoder.decode([ConsentRecord].self, from: data)
            AppLogger.shared.info("Loaded \(consentHistory.count) consent records from disk")
        } catch {
            AppLogger.shared.error("Failed to load consent records: \(error.localizedDescription)")
            consentHistory = []
        }
    }

    /// Persists consent records to the JSON file on disk.
    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(consentHistory)
            try data.write(to: storageURL, options: [.atomic])
            AppLogger.shared.debug("Consent records saved to \(storageURL.path)")
        } catch {
            AppLogger.shared.error("Failed to save consent records: \(error.localizedDescription)")
        }
    }

    // MARK: - Storage Location

    /// Returns the default directory for persistence files.
    /// Creates the directory if it does not exist.
    private static func defaultStorageDirectory() -> URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            AppLogger.shared.warning("Application Support directory unavailable, using temporary directory for consent data")
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
