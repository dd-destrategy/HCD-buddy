//
//  TaggingService.swift
//  HCDInterviewCoach
//
//  FEATURE 5: Post-Session Tagging & Coding
//  Manages tags and tag-to-utterance assignments with JSON persistence.
//

import Foundation

/// Manages the creation, assignment, and persistence of tags for coding transcript segments.
///
/// Tags and their assignments are stored as JSON files in
/// `~/Library/Application Support/HCDInterviewCoach/` to avoid SwiftData schema migration.
///
/// On first run (when no tags file exists), a set of default tags is created.
@MainActor
final class TaggingService: ObservableObject {

    // MARK: - Published Properties

    /// All available tags
    @Published var tags: [Tag] = []

    /// All tag-to-utterance assignments across all sessions
    @Published var assignments: [UtteranceTagAssignment] = []

    /// The currently selected tag ID for applying to utterances
    @Published var selectedTagId: UUID?

    // MARK: - Private Properties

    /// File URL for persisted tags JSON
    private let tagsStorageURL: URL

    /// File URL for persisted tag assignments JSON
    private let assignmentsStorageURL: URL

    // MARK: - Initialization

    /// Creates a TaggingService with the default storage locations.
    /// Loads persisted data and creates default tags on first run.
    init() {
        let directory = Self.defaultStorageDirectory()
        self.tagsStorageURL = directory.appendingPathComponent("tags.json")
        self.assignmentsStorageURL = directory.appendingPathComponent("tag_assignments.json")
        load()
    }

    /// Creates a TaggingService backed by custom storage URLs.
    /// Intended for testing with temporary directories.
    /// - Parameters:
    ///   - tagsURL: The file URL where tags JSON will be persisted
    ///   - assignmentsURL: The file URL where assignments JSON will be persisted
    init(tagsURL: URL, assignmentsURL: URL) {
        self.tagsStorageURL = tagsURL
        self.assignmentsStorageURL = assignmentsURL
        load()
    }

    // MARK: - Storage Location

    /// Returns the default directory for tag persistence files.
    /// Creates the directory if it does not exist.
    private static func defaultStorageDirectory() -> URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            AppLogger.shared.warning("Application Support directory unavailable, using temporary directory for tags")
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

    // MARK: - Default Tags

    /// Creates the default set of tags for first-time users.
    private func createDefaultTags() {
        let defaults: [(name: String, colorHex: String)] = [
            ("Pain Point", "#E74C3C"),
            ("User Need", "#3498DB"),
            ("Positive Moment", "#2ECC71"),
            ("Confusion", "#F39C12"),
            ("Suggestion", "#9B59B6")
        ]

        for entry in defaults {
            let tag = Tag(name: entry.name, colorHex: entry.colorHex)
            tags.append(tag)
        }

        save()
        AppLogger.shared.info("Created \(defaults.count) default tags")
    }

    // MARK: - Tag CRUD

    /// Creates a new tag with the given properties.
    /// - Parameters:
    ///   - name: The display name for the tag
    ///   - colorHex: The hex color string (e.g., "#FF5733")
    ///   - parentId: Optional parent tag ID for hierarchy
    /// - Returns: The newly created tag
    @discardableResult
    func createTag(name: String, colorHex: String, parentId: UUID? = nil) -> Tag {
        let tag = Tag(name: name, colorHex: colorHex, parentId: parentId)
        tags.append(tag)
        save()
        AppLogger.shared.info("Created tag: \(tag.name) (\(tag.id))")
        return tag
    }

    /// Deletes a tag and all of its assignments.
    /// Also removes any child tags that reference this tag as a parent.
    /// - Parameter id: The UUID of the tag to delete
    func deleteTag(_ id: UUID) {
        guard tags.contains(where: { $0.id == id }) else {
            AppLogger.shared.warning("Attempted to delete non-existent tag: \(id)")
            return
        }

        // Remove all assignments referencing this tag
        assignments.removeAll { $0.tagId == id }

        // Remove child tags that reference this tag as parent
        let childIds = tags.filter { $0.parentId == id }.map { $0.id }
        for childId in childIds {
            assignments.removeAll { $0.tagId == childId }
        }
        tags.removeAll { $0.parentId == id }

        // Remove the tag itself
        tags.removeAll { $0.id == id }

        // Clear selection if needed
        if selectedTagId == id {
            selectedTagId = nil
        }

        save()
        AppLogger.shared.info("Deleted tag \(id) and its \(childIds.count) children")
    }

    /// Updates properties of an existing tag.
    /// Only non-nil parameters are applied.
    /// - Parameters:
    ///   - id: The UUID of the tag to update
    ///   - name: New name, or nil to keep current
    ///   - colorHex: New color hex, or nil to keep current
    func updateTag(_ id: UUID, name: String? = nil, colorHex: String? = nil) {
        guard let index = tags.firstIndex(where: { $0.id == id }) else {
            AppLogger.shared.warning("Attempted to update non-existent tag: \(id)")
            return
        }

        if let name = name {
            tags[index].name = name
        }
        if let colorHex = colorHex {
            tags[index].colorHex = colorHex
        }

        save()
        AppLogger.shared.debug("Updated tag \(id)")
    }

    // MARK: - Tag Assignment

    /// Assigns a tag to an utterance within a session.
    /// Duplicate assignments (same tag + same utterance) are prevented.
    /// - Parameters:
    ///   - tagId: The UUID of the tag to assign
    ///   - utteranceId: The UUID of the utterance to tag
    ///   - sessionId: The UUID of the session containing the utterance
    ///   - note: Optional researcher note for this assignment
    @discardableResult
    func assignTag(_ tagId: UUID, to utteranceId: UUID, sessionId: UUID, note: String? = nil) -> UtteranceTagAssignment {
        // Prevent duplicate assignments of the same tag to the same utterance
        if let existing = assignments.first(where: { $0.tagId == tagId && $0.utteranceId == utteranceId }) {
            AppLogger.shared.debug("Tag \(tagId) already assigned to utterance \(utteranceId)")
            return existing
        }

        let assignment = UtteranceTagAssignment(
            utteranceId: utteranceId,
            tagId: tagId,
            sessionId: sessionId,
            note: note
        )
        assignments.append(assignment)
        save()
        AppLogger.shared.debug("Assigned tag \(tagId) to utterance \(utteranceId)")
        return assignment
    }

    /// Removes a specific tag assignment by its ID.
    /// - Parameter assignmentId: The UUID of the assignment to remove
    func removeAssignment(_ assignmentId: UUID) {
        guard assignments.contains(where: { $0.id == assignmentId }) else {
            AppLogger.shared.warning("Attempted to remove non-existent assignment: \(assignmentId)")
            return
        }

        assignments.removeAll { $0.id == assignmentId }
        save()
        AppLogger.shared.debug("Removed assignment \(assignmentId)")
    }

    // MARK: - Querying Assignments

    /// Returns all assignments for a specific utterance.
    /// - Parameter utteranceId: The UUID of the utterance
    /// - Returns: An array of assignments for the utterance
    func getAssignments(forUtterance utteranceId: UUID) -> [UtteranceTagAssignment] {
        assignments.filter { $0.utteranceId == utteranceId }
    }

    /// Returns all assignments using a specific tag.
    /// - Parameter tagId: The UUID of the tag
    /// - Returns: An array of assignments using the tag
    func getAssignments(forTag tagId: UUID) -> [UtteranceTagAssignment] {
        assignments.filter { $0.tagId == tagId }
    }

    /// Returns all assignments within a specific session.
    /// - Parameter sessionId: The UUID of the session
    /// - Returns: An array of assignments in the session
    func getAssignments(forSession sessionId: UUID) -> [UtteranceTagAssignment] {
        assignments.filter { $0.sessionId == sessionId }
    }

    /// Returns the set of utterance IDs that have at least one tag in a session.
    /// - Parameter sessionId: The UUID of the session
    /// - Returns: A set of tagged utterance IDs
    func getTaggedUtteranceIds(for sessionId: UUID) -> Set<UUID> {
        Set(assignments.filter { $0.sessionId == sessionId }.map { $0.utteranceId })
    }

    // MARK: - Export

    /// Exports all tagged segments for a session as a Markdown document.
    ///
    /// The output groups utterances by tag and includes timestamps, speaker labels,
    /// the utterance text, and any researcher notes.
    ///
    /// - Parameters:
    ///   - sessionId: The UUID of the session to export
    ///   - utterances: The full list of utterances in the session
    /// - Returns: A Markdown-formatted string
    func exportTaggedSegments(sessionId: UUID, utterances: [Utterance]) -> String {
        let sessionAssignments = getAssignments(forSession: sessionId)
        guard !sessionAssignments.isEmpty else {
            return "# Tagged Segments\n\nNo tagged segments found for this session.\n"
        }

        // Build a lookup from utterance ID to utterance
        let utteranceLookup = Dictionary(uniqueKeysWithValues: utterances.map { ($0.id, $0) })

        // Group assignments by tag
        var tagGroups: [UUID: [UtteranceTagAssignment]] = [:]
        for assignment in sessionAssignments {
            tagGroups[assignment.tagId, default: []].append(assignment)
        }

        var markdown = "# Tagged Segments\n\n"

        // Build tag lookup for names
        let tagLookup = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0) })

        for (tagId, tagAssignments) in tagGroups.sorted(by: { ($0.value.count) > ($1.value.count) }) {
            let tagName = tagLookup[tagId]?.name ?? "Unknown Tag"
            let tagColor = tagLookup[tagId]?.colorHex ?? ""

            markdown += "## \(tagName)"
            if !tagColor.isEmpty {
                markdown += " (\(tagColor))"
            }
            markdown += "\n\n"
            markdown += "\(tagAssignments.count) tagged segment(s)\n\n"

            // Sort assignments by utterance timestamp
            let sortedAssignments = tagAssignments.sorted { a, b in
                let utteranceA = utteranceLookup[a.utteranceId]
                let utteranceB = utteranceLookup[b.utteranceId]
                return (utteranceA?.timestampSeconds ?? 0) < (utteranceB?.timestampSeconds ?? 0)
            }

            for assignment in sortedAssignments {
                guard let utterance = utteranceLookup[assignment.utteranceId] else {
                    continue
                }

                let timestamp = utterance.formattedTimestamp
                let speaker = utterance.speaker.displayName
                markdown += "- **[\(timestamp)] \(speaker):** \(utterance.text)\n"

                if let note = assignment.note, !note.isEmpty {
                    markdown += "  - _Note: \(note)_\n"
                }
            }

            markdown += "\n"
        }

        return markdown
    }

    // MARK: - Persistence

    /// Persists both tags and assignments to their respective JSON files.
    func save() {
        saveTags()
        saveAssignments()
    }

    /// Loads both tags and assignments from their respective JSON files.
    /// Creates default tags if the tags file does not exist.
    func load() {
        loadTags()
        loadAssignments()

        // Create default tags on first run
        if tags.isEmpty && !FileManager.default.fileExists(atPath: tagsStorageURL.path) {
            createDefaultTags()
        }
    }

    // MARK: - Private Persistence Helpers

    private func saveTags() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(tags)
            try data.write(to: tagsStorageURL, options: [.atomic])
            AppLogger.shared.debug("Tags saved to \(tagsStorageURL.path)")
        } catch {
            AppLogger.shared.error("Failed to save tags: \(error.localizedDescription)")
        }
    }

    private func saveAssignments() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(assignments)
            try data.write(to: assignmentsStorageURL, options: [.atomic])
            AppLogger.shared.debug("Tag assignments saved to \(assignmentsStorageURL.path)")
        } catch {
            AppLogger.shared.error("Failed to save tag assignments: \(error.localizedDescription)")
        }
    }

    private func loadTags() {
        guard FileManager.default.fileExists(atPath: tagsStorageURL.path) else {
            AppLogger.shared.debug("No tags file found at \(tagsStorageURL.path)")
            tags = []
            return
        }

        do {
            let data = try Data(contentsOf: tagsStorageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            tags = try decoder.decode([Tag].self, from: data)
            AppLogger.shared.info("Loaded \(tags.count) tags from disk")
        } catch {
            AppLogger.shared.error("Failed to load tags: \(error.localizedDescription)")
            tags = []
        }
    }

    private func loadAssignments() {
        guard FileManager.default.fileExists(atPath: assignmentsStorageURL.path) else {
            AppLogger.shared.debug("No tag assignments file found at \(assignmentsStorageURL.path)")
            assignments = []
            return
        }

        do {
            let data = try Data(contentsOf: assignmentsStorageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            assignments = try decoder.decode([UtteranceTagAssignment].self, from: data)
            AppLogger.shared.info("Loaded \(assignments.count) tag assignments from disk")
        } catch {
            AppLogger.shared.error("Failed to load tag assignments: \(error.localizedDescription)")
            assignments = []
        }
    }
}
