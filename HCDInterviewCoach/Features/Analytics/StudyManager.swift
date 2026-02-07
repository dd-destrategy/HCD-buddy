//
//  StudyManager.swift
//  HCDInterviewCoach
//
//  FEATURE 3: Cross-Session Analytics & Study Organization
//  Manages the lifecycle of Study objects including CRUD operations and JSON persistence.
//

import Foundation
import SwiftData

/// Manages research studies, providing CRUD operations and JSON-based persistence.
///
/// Studies are stored as JSON at `~/Library/Application Support/HCDInterviewCoach/studies.json`
/// to avoid SwiftData schema migration complexity. The manager coordinates with `DataManager`
/// to resolve session references when needed.
@MainActor
final class StudyManager: ObservableObject {

    // MARK: - Published Properties

    /// All studies managed by this instance
    @Published var studies: [Study] = []

    /// The currently selected study for analytics and detail views
    @Published var selectedStudy: Study?

    // MARK: - Private Properties

    /// File URL for persisted studies JSON
    private let storageURL: URL

    // MARK: - Initialization

    /// Creates a new StudyManager with the default storage location.
    /// Immediately loads persisted studies from disk.
    init() {
        self.storageURL = Self.defaultStorageURL()
        load()
    }

    /// Creates a StudyManager backed by a custom storage URL.
    /// Intended for testing with temporary directories.
    /// - Parameter storageURL: The file URL where studies JSON will be persisted
    init(storageURL: URL) {
        self.storageURL = storageURL
        load()
    }

    // MARK: - Storage Location

    /// Returns the default file URL for studies persistence.
    /// Creates the parent directory if it does not exist.
    private static func defaultStorageURL() -> URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            AppLogger.shared.warning("Application Support directory unavailable, using temporary directory for studies")
            return FileManager.default.temporaryDirectory
                .appendingPathComponent("HCDInterviewCoach")
                .appendingPathComponent("studies.json")
        }

        let appDirectory = appSupport.appendingPathComponent("HCDInterviewCoach", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: appDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        return appDirectory.appendingPathComponent("studies.json")
    }

    // MARK: - CRUD Operations

    /// Creates a new study with the given name and description.
    /// The study is immediately persisted to disk.
    /// - Parameters:
    ///   - name: The human-readable name for the study
    ///   - description: An optional longer description of the study's purpose
    /// - Returns: The newly created study
    @discardableResult
    func createStudy(name: String, description: String = "") -> Study {
        let study = Study(
            name: name,
            description: description
        )
        studies.append(study)
        save()
        AppLogger.shared.info("Created study: \(study.name) (\(study.id))")
        return study
    }

    /// Deletes a study by its identifier.
    /// If the deleted study is the currently selected study, the selection is cleared.
    /// - Parameter id: The UUID of the study to delete
    func deleteStudy(id: UUID) {
        guard studies.contains(where: { $0.id == id }) else {
            AppLogger.shared.warning("Attempted to delete non-existent study: \(id)")
            return
        }

        studies.removeAll { $0.id == id }

        if selectedStudy?.id == id {
            selectedStudy = nil
        }

        save()
        AppLogger.shared.info("Deleted study: \(id)")
    }

    /// Adds a session reference to a study.
    /// Duplicate session IDs within a study are ignored.
    /// - Parameters:
    ///   - sessionId: The UUID of the session to add
    ///   - studyId: The UUID of the study to add the session to
    func addSession(_ sessionId: UUID, to studyId: UUID) {
        guard let index = studies.firstIndex(where: { $0.id == studyId }) else {
            AppLogger.shared.warning("Cannot add session to non-existent study: \(studyId)")
            return
        }

        guard !studies[index].sessionIds.contains(sessionId) else {
            AppLogger.shared.debug("Session \(sessionId) already in study \(studyId)")
            return
        }

        studies[index].sessionIds.append(sessionId)
        studies[index].updatedAt = Date()
        save()
        AppLogger.shared.info("Added session \(sessionId) to study \(studyId)")
    }

    /// Removes a session reference from a study.
    /// - Parameters:
    ///   - sessionId: The UUID of the session to remove
    ///   - studyId: The UUID of the study to remove the session from
    func removeSession(_ sessionId: UUID, from studyId: UUID) {
        guard let index = studies.firstIndex(where: { $0.id == studyId }) else {
            AppLogger.shared.warning("Cannot remove session from non-existent study: \(studyId)")
            return
        }

        studies[index].sessionIds.removeAll { $0 == sessionId }
        studies[index].updatedAt = Date()
        save()
        AppLogger.shared.info("Removed session \(sessionId) from study \(studyId)")
    }

    // MARK: - Session Resolution

    /// Fetches the full `Session` objects for all session IDs in a study.
    /// Sessions that no longer exist in the database are silently skipped.
    /// - Parameter study: The study whose sessions should be resolved
    /// - Returns: An array of `Session` objects found in the database
    func getSessionsForStudy(_ study: Study) async -> [Session] {
        guard !study.sessionIds.isEmpty else {
            return []
        }

        do {
            let context = try DataManager.shared.requireMainContext()
            var sessions: [Session] = []

            for sessionId in study.sessionIds {
                let predicate = #Predicate<Session> { session in
                    session.id == sessionId
                }
                let descriptor = FetchDescriptor<Session>(predicate: predicate)

                if let found = try context.fetch(descriptor).first {
                    sessions.append(found)
                }
            }

            return sessions
        } catch {
            AppLogger.shared.error("Failed to fetch sessions for study \(study.id): \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Persistence

    /// Persists the current studies array to the JSON file on disk.
    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(studies)
            try data.write(to: storageURL, options: [.atomic])
            AppLogger.shared.debug("Studies saved to \(storageURL.path)")
        } catch {
            AppLogger.shared.error("Failed to save studies: \(error.localizedDescription)")
        }
    }

    /// Loads studies from the JSON file on disk.
    /// If the file does not exist or is corrupted, starts with an empty array.
    func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            AppLogger.shared.debug("No studies file found at \(storageURL.path), starting fresh")
            studies = []
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            studies = try decoder.decode([Study].self, from: data)
            AppLogger.shared.info("Loaded \(studies.count) studies from disk")
        } catch {
            AppLogger.shared.error("Failed to load studies: \(error.localizedDescription)")
            studies = []
        }
    }
}
