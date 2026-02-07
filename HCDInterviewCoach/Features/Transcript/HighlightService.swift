//
//  HighlightService.swift
//  HCDInterviewCoach
//
//  FEATURE E: Highlight Reel & Quote Library
//  Manages the creation, storage, search, and export of highlights across sessions.
//

import Foundation

/// Sort options for the highlight list
enum HighlightSortOrder: String, CaseIterable {
    case newestFirst = "newest_first"
    case oldestFirst = "oldest_first"
    case alphabetical = "alphabetical"
    case byCategory = "by_category"

    var displayName: String {
        switch self {
        case .newestFirst: return "Newest First"
        case .oldestFirst: return "Oldest First"
        case .alphabetical: return "Alphabetical"
        case .byCategory: return "By Category"
        }
    }
}

/// Manages the creation, storage, search, and export of highlights across sessions.
///
/// Highlights and their metadata are stored as a JSON file in
/// `~/Library/Application Support/HCDInterviewCoach/` to avoid SwiftData schema migration.
///
/// Supports CRUD operations, multi-field search, category/star filtering, and Markdown export.
@MainActor
final class HighlightService: ObservableObject {

    // MARK: - Published Properties

    /// All highlights across all sessions
    @Published var highlights: [Highlight] = []

    /// Current search query for filtering highlights
    @Published var searchQuery: String = ""

    /// Currently selected category filter (nil = all categories)
    @Published var selectedCategory: HighlightCategory?

    /// Whether to show only starred highlights
    @Published var showStarredOnly: Bool = false

    /// Current sort order
    @Published var sortOrder: HighlightSortOrder = .newestFirst

    // MARK: - Private Properties

    /// File URL for persisted highlights JSON
    private let storageURL: URL

    // MARK: - Initialization

    /// Creates a HighlightService with the default storage location.
    /// Loads persisted data from disk.
    init() {
        let directory = Self.defaultStorageDirectory()
        self.storageURL = directory.appendingPathComponent("highlights.json")
        load()
    }

    /// Creates a HighlightService backed by a custom storage URL.
    /// Intended for testing with temporary directories.
    /// - Parameter storageURL: The file URL where highlights JSON will be persisted
    init(storageURL: URL) {
        self.storageURL = storageURL
        load()
    }

    // MARK: - Storage Location

    /// Returns the default directory for highlight persistence files.
    /// Creates the directory if it does not exist.
    static func defaultStorageDirectory() -> URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            AppLogger.shared.warning("Application Support directory unavailable, using temporary directory for highlights")
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

    // MARK: - CRUD Operations

    /// Creates a new highlight and persists it.
    /// - Parameters:
    ///   - title: Short descriptive title
    ///   - quoteText: The quoted text from the transcript
    ///   - speaker: Display name of the speaker
    ///   - category: Category for organizing
    ///   - notes: Researcher notes
    ///   - utteranceId: ID of the source utterance
    ///   - sessionId: ID of the source session
    ///   - timestampSeconds: Timestamp in seconds from session start
    /// - Returns: The newly created highlight
    @discardableResult
    func createHighlight(
        title: String,
        quoteText: String,
        speaker: String,
        category: HighlightCategory = .uncategorized,
        notes: String = "",
        utteranceId: UUID,
        sessionId: UUID,
        timestampSeconds: Double
    ) -> Highlight {
        let highlight = Highlight(
            title: title,
            quoteText: quoteText,
            speaker: speaker,
            category: category,
            notes: notes,
            utteranceId: utteranceId,
            sessionId: sessionId,
            timestampSeconds: timestampSeconds
        )
        highlights.append(highlight)
        save()
        AppLogger.shared.info("Created highlight: \(highlight.title) (\(highlight.id))")
        return highlight
    }

    /// Updates properties of an existing highlight.
    /// Only non-nil parameters are applied.
    /// - Parameters:
    ///   - id: The UUID of the highlight to update
    ///   - title: New title, or nil to keep current
    ///   - category: New category, or nil to keep current
    ///   - notes: New notes, or nil to keep current
    ///   - isStarred: New starred state, or nil to keep current
    func updateHighlight(
        _ id: UUID,
        title: String? = nil,
        category: HighlightCategory? = nil,
        notes: String? = nil,
        isStarred: Bool? = nil
    ) {
        guard let index = highlights.firstIndex(where: { $0.id == id }) else {
            AppLogger.shared.warning("Attempted to update non-existent highlight: \(id)")
            return
        }

        if let title = title {
            highlights[index].title = title
        }
        if let category = category {
            highlights[index].category = category
        }
        if let notes = notes {
            highlights[index].notes = notes
        }
        if let isStarred = isStarred {
            highlights[index].isStarred = isStarred
        }

        highlights[index].updatedAt = Date()
        save()
        AppLogger.shared.debug("Updated highlight \(id)")
    }

    /// Deletes a highlight by its ID.
    /// - Parameter id: The UUID of the highlight to delete
    func deleteHighlight(_ id: UUID) {
        guard highlights.contains(where: { $0.id == id }) else {
            AppLogger.shared.warning("Attempted to delete non-existent highlight: \(id)")
            return
        }

        highlights.removeAll { $0.id == id }
        save()
        AppLogger.shared.info("Deleted highlight \(id)")
    }

    // MARK: - Query Operations

    /// Returns all highlights for a specific session.
    /// - Parameter sessionId: The UUID of the session
    /// - Returns: An array of highlights from that session, sorted by timestamp
    func highlights(for sessionId: UUID) -> [Highlight] {
        highlights
            .filter { $0.sessionId == sessionId }
            .sorted { $0.timestampSeconds < $1.timestampSeconds }
    }

    /// Returns all starred highlights across all sessions.
    /// - Returns: An array of starred highlights, sorted by creation date (newest first)
    func starredHighlights() -> [Highlight] {
        highlights
            .filter { $0.isStarred }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Returns all highlights in a specific category.
    /// - Parameter category: The category to filter by
    /// - Returns: An array of highlights in that category
    func highlights(in category: HighlightCategory) -> [Highlight] {
        highlights
            .filter { $0.category == category }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Searches highlights with a case-insensitive query across title, quoteText, notes, and speaker.
    /// - Parameter query: The search string
    /// - Returns: An array of matching highlights
    func searchHighlights(query: String) -> [Highlight] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return highlights }

        let lowered = trimmed.lowercased()
        return highlights.filter { highlight in
            highlight.title.lowercased().contains(lowered) ||
            highlight.quoteText.lowercased().contains(lowered) ||
            highlight.notes.lowercased().contains(lowered) ||
            highlight.speaker.lowercased().contains(lowered)
        }
    }

    /// Filtered highlights based on current search, category, star, and sort state.
    ///
    /// Combines `searchQuery`, `selectedCategory`, `showStarredOnly`, and `sortOrder`
    /// to produce a fully filtered and sorted result set.
    var filteredHighlights: [Highlight] {
        var result = highlights

        // Apply search filter
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            let lowered = trimmedQuery.lowercased()
            result = result.filter { highlight in
                highlight.title.lowercased().contains(lowered) ||
                highlight.quoteText.lowercased().contains(lowered) ||
                highlight.notes.lowercased().contains(lowered) ||
                highlight.speaker.lowercased().contains(lowered)
            }
        }

        // Apply category filter
        if let selectedCategory = selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }

        // Apply star filter
        if showStarredOnly {
            result = result.filter { $0.isStarred }
        }

        // Apply sort order
        switch sortOrder {
        case .newestFirst:
            result.sort { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            result.sort { $0.createdAt < $1.createdAt }
        case .alphabetical:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .byCategory:
            result.sort { $0.category.displayName < $1.category.displayName }
        }

        return result
    }

    // MARK: - Star Management

    /// Toggles the starred state of a highlight.
    /// - Parameter id: The UUID of the highlight to toggle
    func toggleStar(_ id: UUID) {
        guard let index = highlights.firstIndex(where: { $0.id == id }) else {
            AppLogger.shared.warning("Attempted to toggle star on non-existent highlight: \(id)")
            return
        }

        highlights[index].isStarred.toggle()
        highlights[index].updatedAt = Date()
        save()
        AppLogger.shared.debug("Toggled star for highlight \(id): \(highlights[index].isStarred)")
    }

    // MARK: - Export

    /// Exports highlights as a Markdown document, optionally filtered by session.
    ///
    /// Groups highlights by category with headers. Starred items are marked
    /// with a star indicator. Includes timestamps, speaker names, and notes.
    ///
    /// - Parameter sessionId: Optional session ID to filter by; nil exports all highlights
    /// - Returns: A Markdown-formatted string
    func exportAsMarkdown(sessionId: UUID? = nil) -> String {
        var source = highlights
        if let sessionId = sessionId {
            source = highlights.filter { $0.sessionId == sessionId }
        }

        guard !source.isEmpty else {
            return "# Highlight Reel\n\nNo highlights found.\n"
        }

        // Group by category
        var categoryGroups: [HighlightCategory: [Highlight]] = [:]
        for highlight in source {
            categoryGroups[highlight.category, default: []].append(highlight)
        }

        var markdown = "# Highlight Reel\n\n"
        markdown += "Total: \(source.count) highlight(s)\n\n"

        // Sort categories by display name for consistent output
        let sortedCategories = categoryGroups.keys.sorted { $0.displayName < $1.displayName }

        for category in sortedCategories {
            guard let categoryHighlights = categoryGroups[category] else { continue }

            markdown += "## \(category.displayName)\n\n"
            markdown += "\(categoryHighlights.count) highlight(s)\n\n"

            // Sort highlights within category by timestamp
            let sorted = categoryHighlights.sorted { $0.timestampSeconds < $1.timestampSeconds }

            for highlight in sorted {
                let starMarker = highlight.isStarred ? " \u{2B50}" : ""
                markdown += "### \(highlight.title)\(starMarker)\n\n"
                markdown += "> \"\(highlight.quoteText)\"\n\n"
                markdown += "**Speaker:** \(highlight.speaker) | **Timestamp:** \(highlight.formattedTimestamp)\n\n"

                if !highlight.notes.isEmpty {
                    markdown += "_Notes: \(highlight.notes)_\n\n"
                }

                markdown += "---\n\n"
            }
        }

        return markdown
    }

    /// Exports only starred highlights as a Markdown document.
    /// - Returns: A Markdown-formatted string containing starred highlights
    func exportStarredAsMarkdown() -> String {
        let starred = highlights.filter { $0.isStarred }

        guard !starred.isEmpty else {
            return "# Starred Highlights\n\nNo starred highlights found.\n"
        }

        // Group by category
        var categoryGroups: [HighlightCategory: [Highlight]] = [:]
        for highlight in starred {
            categoryGroups[highlight.category, default: []].append(highlight)
        }

        var markdown = "# Starred Highlights\n\n"
        markdown += "Total: \(starred.count) starred highlight(s)\n\n"

        let sortedCategories = categoryGroups.keys.sorted { $0.displayName < $1.displayName }

        for category in sortedCategories {
            guard let categoryHighlights = categoryGroups[category] else { continue }

            markdown += "## \(category.displayName)\n\n"

            let sorted = categoryHighlights.sorted { $0.timestampSeconds < $1.timestampSeconds }

            for highlight in sorted {
                markdown += "### \(highlight.title) \u{2B50}\n\n"
                markdown += "> \"\(highlight.quoteText)\"\n\n"
                markdown += "**Speaker:** \(highlight.speaker) | **Timestamp:** \(highlight.formattedTimestamp)\n\n"

                if !highlight.notes.isEmpty {
                    markdown += "_Notes: \(highlight.notes)_\n\n"
                }

                markdown += "---\n\n"
            }
        }

        return markdown
    }

    // MARK: - Statistics

    /// Total number of highlights
    var totalCount: Int {
        highlights.count
    }

    /// Number of starred highlights
    var starredCount: Int {
        highlights.filter { $0.isStarred }.count
    }

    /// Returns the count of highlights grouped by category.
    /// - Returns: A dictionary mapping each category to its highlight count
    func countByCategory() -> [HighlightCategory: Int] {
        var counts: [HighlightCategory: Int] = [:]
        for highlight in highlights {
            counts[highlight.category, default: 0] += 1
        }
        return counts
    }

    // MARK: - Persistence

    /// Loads highlights from the JSON file on disk.
    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            AppLogger.shared.debug("No highlights file found at \(storageURL.path)")
            highlights = []
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            highlights = try decoder.decode([Highlight].self, from: data)
            AppLogger.shared.info("Loaded \(highlights.count) highlights from disk")
        } catch {
            AppLogger.shared.error("Failed to load highlights: \(error.localizedDescription)")
            highlights = []
        }
    }

    /// Persists highlights to the JSON file on disk.
    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(highlights)
            try data.write(to: storageURL, options: [.atomic])
            AppLogger.shared.debug("Highlights saved to \(storageURL.path)")
        } catch {
            AppLogger.shared.error("Failed to save highlights: \(error.localizedDescription)")
        }
    }
}
