//
//  ParticipantManager.swift
//  HCDInterviewCoach
//
//  FEATURE F: Participant Management System
//  Manages the lifecycle of Participant objects including CRUD operations,
//  search, session linking, GDPR export/deletion, and JSON persistence.
//

import Foundation

/// Manages research participants, providing CRUD operations, search,
/// session linking, and JSON-based persistence.
///
/// Participants are stored as JSON at
/// `~/Library/Application Support/HCDInterviewCoach/participants.json`
/// to avoid SwiftData schema migration complexity.
@MainActor
final class ParticipantManager: ObservableObject {

    // MARK: - Published Properties

    /// All participants managed by this instance
    @Published var participants: [Participant] = []

    /// Current search query for filtering participants
    @Published var searchQuery: String = ""

    // MARK: - Private Properties

    /// File URL for persisted participants JSON
    private let storageURL: URL

    // MARK: - Initialization

    /// Creates a new ParticipantManager with the default storage location.
    /// Immediately loads persisted participants from disk.
    init() {
        let dir = Self.defaultStorageDirectory()
        self.storageURL = dir.appendingPathComponent("participants.json")
        load()
    }

    /// Creates a ParticipantManager backed by a custom storage URL.
    /// Intended for testing with temporary directories.
    /// - Parameter storageURL: The file URL where participants JSON will be persisted
    init(storageURL: URL) {
        self.storageURL = storageURL
        load()
    }

    // MARK: - Storage Location

    /// Returns the default directory for participant persistence.
    /// Creates the directory if it does not exist.
    static func defaultStorageDirectory() -> URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            AppLogger.shared.warning("Application Support directory unavailable, using temporary directory for participants")
            let fallback = FileManager.default.temporaryDirectory
                .appendingPathComponent("HCDInterviewCoach")
            try? FileManager.default.createDirectory(
                at: fallback,
                withIntermediateDirectories: true,
                attributes: nil
            )
            return fallback
        }

        let appDirectory = appSupport.appendingPathComponent("HCDInterviewCoach", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: appDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        return appDirectory
    }

    // MARK: - CRUD Operations

    /// Creates a new participant and persists it to disk.
    /// - Parameters:
    ///   - name: Full name of the participant (required)
    ///   - email: Contact email address
    ///   - role: Job title or role
    ///   - department: Department within their organization
    ///   - organization: Organization or company name
    ///   - experienceLevel: Self-reported or assessed experience level
    ///   - notes: Free-form notes about the participant
    ///   - metadata: Custom screener fields as key-value pairs
    /// - Returns: The newly created participant
    @discardableResult
    func createParticipant(
        name: String,
        email: String? = nil,
        role: String? = nil,
        department: String? = nil,
        organization: String? = nil,
        experienceLevel: ExperienceLevel? = nil,
        notes: String = "",
        metadata: [String: String] = [:]
    ) -> Participant {
        let participant = Participant(
            name: name,
            email: email,
            role: role,
            department: department,
            organization: organization,
            experienceLevel: experienceLevel,
            notes: notes,
            metadata: metadata
        )
        participants.append(participant)
        save()
        AppLogger.shared.info("Created participant: \(participant.name) (\(participant.id))")
        return participant
    }

    /// Updates an existing participant's fields. Only non-nil parameters are applied.
    /// - Parameters:
    ///   - id: The UUID of the participant to update
    ///   - name: New name, or nil to keep existing
    ///   - email: New email, or nil to keep existing
    ///   - role: New role, or nil to keep existing
    ///   - department: New department, or nil to keep existing
    ///   - organization: New organization, or nil to keep existing
    ///   - experienceLevel: New experience level, or nil to keep existing
    ///   - notes: New notes, or nil to keep existing
    ///   - metadata: New metadata dictionary, or nil to keep existing
    func updateParticipant(
        _ id: UUID,
        name: String? = nil,
        email: String? = nil,
        role: String? = nil,
        department: String? = nil,
        organization: String? = nil,
        experienceLevel: ExperienceLevel? = nil,
        notes: String? = nil,
        metadata: [String: String]? = nil
    ) {
        guard let index = participants.firstIndex(where: { $0.id == id }) else {
            AppLogger.shared.warning("Attempted to update non-existent participant: \(id)")
            return
        }

        if let name = name {
            participants[index].name = name
        }
        if let email = email {
            participants[index].email = email
        }
        if let role = role {
            participants[index].role = role
        }
        if let department = department {
            participants[index].department = department
        }
        if let organization = organization {
            participants[index].organization = organization
        }
        if let experienceLevel = experienceLevel {
            participants[index].experienceLevel = experienceLevel
        }
        if let notes = notes {
            participants[index].notes = notes
        }
        if let metadata = metadata {
            participants[index].metadata = metadata
        }

        participants[index].updatedAt = Date()
        save()
        AppLogger.shared.info("Updated participant: \(participants[index].name) (\(id))")
    }

    /// Deletes a participant by its identifier.
    /// - Parameter id: The UUID of the participant to delete
    func deleteParticipant(_ id: UUID) {
        guard participants.contains(where: { $0.id == id }) else {
            AppLogger.shared.warning("Attempted to delete non-existent participant: \(id)")
            return
        }

        participants.removeAll { $0.id == id }
        save()
        AppLogger.shared.info("Deleted participant: \(id)")
    }

    // MARK: - Session Linking

    /// Links a session to a participant.
    /// Duplicate session IDs within a participant are ignored.
    /// - Parameters:
    ///   - sessionId: The UUID of the session to link
    ///   - participantId: The UUID of the participant to link to
    func linkSession(_ sessionId: UUID, to participantId: UUID) {
        guard let index = participants.firstIndex(where: { $0.id == participantId }) else {
            AppLogger.shared.warning("Cannot link session to non-existent participant: \(participantId)")
            return
        }

        guard !participants[index].sessionIds.contains(sessionId) else {
            AppLogger.shared.debug("Session \(sessionId) already linked to participant \(participantId)")
            return
        }

        participants[index].sessionIds.append(sessionId)
        participants[index].updatedAt = Date()
        save()
        AppLogger.shared.info("Linked session \(sessionId) to participant \(participantId)")
    }

    /// Unlinks a session from a participant.
    /// - Parameters:
    ///   - sessionId: The UUID of the session to unlink
    ///   - participantId: The UUID of the participant to unlink from
    func unlinkSession(_ sessionId: UUID, from participantId: UUID) {
        guard let index = participants.firstIndex(where: { $0.id == participantId }) else {
            AppLogger.shared.warning("Cannot unlink session from non-existent participant: \(participantId)")
            return
        }

        participants[index].sessionIds.removeAll { $0 == sessionId }
        participants[index].updatedAt = Date()
        save()
        AppLogger.shared.info("Unlinked session \(sessionId) from participant \(participantId)")
    }

    /// Returns the session IDs linked to a participant.
    /// - Parameter participantId: The UUID of the participant
    /// - Returns: Array of session UUIDs, or empty if participant not found
    func sessions(for participantId: UUID) -> [UUID] {
        guard let participant = participants.first(where: { $0.id == participantId }) else {
            return []
        }
        return participant.sessionIds
    }

    // MARK: - Lookup

    /// Finds the participant linked to a given session.
    /// - Parameter sessionId: The UUID of the session
    /// - Returns: The participant linked to the session, or nil
    func participant(for sessionId: UUID) -> Participant? {
        participants.first { $0.sessionIds.contains(sessionId) }
    }

    /// Finds a participant by its UUID.
    /// - Parameter id: The UUID of the participant
    /// - Returns: The matching participant, or nil
    func participant(byId id: UUID) -> Participant? {
        participants.first { $0.id == id }
    }

    /// Finds a participant by name (case-insensitive).
    /// - Parameter name: The name to match
    /// - Returns: The first matching participant, or nil
    func participant(byName name: String) -> Participant? {
        let lowered = name.lowercased().trimmingCharacters(in: .whitespaces)
        return participants.first {
            $0.name.lowercased().trimmingCharacters(in: .whitespaces) == lowered
        }
    }

    // MARK: - Search

    /// Searches participants by name, email, role, and organization.
    /// Returns all participants if the query is empty.
    /// - Parameter query: The search query string
    /// - Returns: Array of matching participants
    func searchParticipants(query: String) -> [Participant] {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()

        guard !trimmed.isEmpty else {
            return participants
        }

        return participants.filter { participant in
            participant.name.lowercased().contains(trimmed)
                || (participant.email?.lowercased().contains(trimmed) ?? false)
                || (participant.role?.lowercased().contains(trimmed) ?? false)
                || (participant.organization?.lowercased().contains(trimmed) ?? false)
                || (participant.department?.lowercased().contains(trimmed) ?? false)
        }
    }

    /// Participants filtered by the current `searchQuery`.
    /// Returns all participants when the search query is empty.
    var filteredParticipants: [Participant] {
        searchParticipants(query: searchQuery)
    }

    // MARK: - Calendar Integration

    /// Finds an existing participant matching the calendar event,
    /// or returns nil if no match is found.
    ///
    /// Matches by participant name from `UpcomingInterview.participantName`
    /// using case-insensitive comparison.
    ///
    /// - Parameter interview: The upcoming interview from the calendar
    /// - Returns: A matching participant, or nil
    func findOrSuggest(from interview: UpcomingInterview) -> Participant? {
        guard let participantName = interview.participantName else {
            return nil
        }
        return participant(byName: participantName)
    }

    // MARK: - GDPR Export & Deletion

    /// Exports all participant data in Markdown format for GDPR compliance.
    /// - Parameter id: The UUID of the participant to export
    /// - Returns: A Markdown-formatted string with all participant information
    func exportParticipantData(_ id: UUID) -> String {
        guard let participant = participant(byId: id) else {
            return "# Participant Data Export\n\nNo participant found with ID: \(id)"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium

        var lines: [String] = []
        lines.append("# Participant Data Export")
        lines.append("")
        lines.append("**Export Date:** \(dateFormatter.string(from: Date()))")
        lines.append("")
        lines.append("## Personal Information")
        lines.append("")
        lines.append("- **Name:** \(participant.name)")
        lines.append("- **Email:** \(participant.email ?? "Not provided")")
        lines.append("- **Role:** \(participant.role ?? "Not provided")")
        lines.append("- **Department:** \(participant.department ?? "Not provided")")
        lines.append("- **Organization:** \(participant.organization ?? "Not provided")")
        lines.append("- **Experience Level:** \(participant.experienceLevel?.displayName ?? "Not provided")")
        lines.append("")
        lines.append("## Notes")
        lines.append("")
        lines.append(participant.notes.isEmpty ? "No notes." : participant.notes)
        lines.append("")
        lines.append("## Custom Metadata")
        lines.append("")
        if participant.metadata.isEmpty {
            lines.append("No custom metadata.")
        } else {
            for (key, value) in participant.metadata.sorted(by: { $0.key < $1.key }) {
                lines.append("- **\(key):** \(value)")
            }
        }
        lines.append("")
        lines.append("## Session History")
        lines.append("")
        if participant.sessionIds.isEmpty {
            lines.append("No linked sessions.")
        } else {
            for sessionId in participant.sessionIds {
                lines.append("- Session ID: `\(sessionId.uuidString)`")
            }
        }
        lines.append("")
        lines.append("## Record Metadata")
        lines.append("")
        lines.append("- **Participant ID:** `\(participant.id.uuidString)`")
        lines.append("- **Created:** \(dateFormatter.string(from: participant.createdAt))")
        lines.append("- **Last Updated:** \(dateFormatter.string(from: participant.updatedAt))")

        return lines.joined(separator: "\n")
    }

    /// Deletes a participant and unlinks all associated session references.
    /// This is a hard delete intended for GDPR right-to-erasure requests.
    /// - Parameter id: The UUID of the participant to delete
    func deleteParticipantAndData(_ id: UUID) {
        guard participants.contains(where: { $0.id == id }) else {
            AppLogger.shared.warning("Attempted GDPR deletion of non-existent participant: \(id)")
            return
        }

        participants.removeAll { $0.id == id }
        save()
        AppLogger.shared.info("GDPR deletion completed for participant: \(id)")
    }

    // MARK: - Statistics

    /// Total number of participants
    var totalCount: Int {
        participants.count
    }

    /// Returns participants who have been linked to more than one session.
    func participantsWithMultipleSessions() -> [Participant] {
        participants.filter { $0.sessionIds.count > 1 }
    }

    // MARK: - Persistence

    /// Loads participants from the JSON file on disk.
    /// If the file does not exist or is corrupted, starts with an empty array.
    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            AppLogger.shared.debug("No participants file found at \(storageURL.path), starting fresh")
            participants = []
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            participants = try decoder.decode([Participant].self, from: data)
            AppLogger.shared.info("Loaded \(participants.count) participants from disk")
        } catch {
            AppLogger.shared.error("Failed to load participants: \(error.localizedDescription)")
            participants = []
        }
    }

    /// Persists the current participants array to the JSON file on disk.
    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(participants)
            try data.write(to: storageURL, options: [.atomic])
            AppLogger.shared.debug("Participants saved to \(storageURL.path)")
        } catch {
            AppLogger.shared.error("Failed to save participants: \(error.localizedDescription)")
        }
    }
}
