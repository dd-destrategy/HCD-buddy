//
//  PostSessionViewModel.swift
//  HCD Interview Coach
//
//  EPIC E10: Post-Session Summary
//  State management for the post-session summary view
//

import Foundation
import Combine
import SwiftUI

// MARK: - AI Reflection State

/// State of the AI reflection generation process
enum AIReflectionState: Equatable {
    case idle
    case generating
    case completed(String)
    case failed(String)

    var isLoading: Bool {
        if case .generating = self { return true }
        return false
    }

    var reflection: String? {
        if case .completed(let text) = self { return text }
        return nil
    }

    var error: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}

// MARK: - Post-Session Statistics

/// Computed statistics for a completed session
struct PostSessionStatistics {
    let duration: TimeInterval
    let utteranceCount: Int
    let insightCount: Int
    let participantUtterances: Int
    let interviewerUtterances: Int
    let topicsCovered: Int
    let totalTopics: Int
    let averageUtteranceLength: Double
    let wordsPerMinute: Double

    init(session: Session) {
        self.duration = session.totalDurationSeconds
        self.utteranceCount = session.utterances.count
        self.insightCount = session.insights.count

        self.participantUtterances = session.utterances.filter { $0.speaker == .participant }.count
        self.interviewerUtterances = session.utterances.filter { $0.speaker == .interviewer }.count

        let coveredTopics = session.topicStatuses.filter { $0.isCovered }
        self.topicsCovered = coveredTopics.count
        self.totalTopics = session.topicStatuses.count

        let totalWords = session.utterances.reduce(0) { $0 + $1.wordCount }
        self.averageUtteranceLength = utteranceCount > 0 ? Double(totalWords) / Double(utteranceCount) : 0

        let durationMinutes = duration / 60.0
        self.wordsPerMinute = durationMinutes > 0 ? Double(totalWords) / durationMinutes : 0
    }

    /// Formatted duration string
    var formattedDuration: String {
        TimeFormatting.formatDuration(duration)
    }

    /// Topic coverage percentage
    var topicCoveragePercent: Double {
        guard totalTopics > 0 else { return 0 }
        return Double(topicsCovered) / Double(totalTopics) * 100
    }

    /// Participation ratio (participant vs interviewer)
    var participationRatio: Double {
        guard interviewerUtterances > 0 else { return 0 }
        return Double(participantUtterances) / Double(interviewerUtterances)
    }
}

// MARK: - Editable Insight

/// Wrapper for insights that can be edited
struct EditableInsight: Identifiable {
    let id: UUID
    var quote: String
    var theme: String
    var tags: [String]
    var isModified: Bool = false

    init(from insight: Insight) {
        self.id = insight.id
        self.quote = insight.quote
        self.theme = insight.theme
        self.tags = insight.tags
    }
}

// MARK: - Post-Session View Model

/// View model managing the post-session summary state
@MainActor
final class PostSessionViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The session being summarized
    @Published private(set) var session: Session

    /// Computed statistics for the session
    @Published private(set) var statistics: PostSessionStatistics

    /// Current state of AI reflection generation
    @Published private(set) var reflectionState: AIReflectionState = .idle

    /// Editable insights from the session
    @Published var editableInsights: [EditableInsight]

    /// Researcher notes
    @Published var researcherNotes: String

    /// Whether export is in progress
    @Published private(set) var isExporting: Bool = false

    /// Last export error, if any
    @Published var exportError: String?

    /// Currently selected insight for editing
    @Published var selectedInsightId: UUID?

    /// Whether the summary has unsaved changes
    @Published private(set) var hasUnsavedChanges: Bool = false

    // MARK: - Private Properties

    private let exportService: PostSessionExportService
    private let aiReflectionService: AIReflectionService
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        session: Session,
        exportService: PostSessionExportService = PostSessionExportService(),
        aiReflectionService: AIReflectionService = AIReflectionService(),
        dataManager: DataManager = .shared
    ) {
        self.session = session
        self.statistics = PostSessionStatistics(session: session)
        self.editableInsights = session.insights.map { EditableInsight(from: $0) }
        self.researcherNotes = session.notes ?? ""
        self.exportService = exportService
        self.aiReflectionService = aiReflectionService
        self.dataManager = dataManager

        setupChangeTracking()
    }

    // MARK: - Public Methods

    /// Generate AI reflection for the session
    func generateReflection() async {
        guard reflectionState != .generating else { return }

        reflectionState = .generating

        do {
            let reflection = try await aiReflectionService.generateReflection(for: session)
            reflectionState = .completed(reflection)
        } catch {
            reflectionState = .failed(error.localizedDescription)
        }
    }

    /// Retry generating the AI reflection
    func retryReflection() async {
        reflectionState = .idle
        await generateReflection()
    }

    /// Export session data in the specified format
    /// - Parameters:
    ///   - format: Export format (markdown or JSON)
    ///   - includeReflection: Whether to include AI reflection
    /// - Returns: URL of the exported file
    func exportSession(format: ExportFormat, includeReflection: Bool = true) async throws -> URL {
        isExporting = true
        exportError = nil

        defer { isExporting = false }

        do {
            // Save any pending changes first
            try await saveChanges()

            let reflection = includeReflection ? reflectionState.reflection : nil
            let url = try await exportService.export(
                session: session,
                format: format,
                reflection: reflection,
                notes: researcherNotes
            )

            return url
        } catch {
            exportError = error.localizedDescription
            throw error
        }
    }

    /// Update an insight's content
    /// - Parameters:
    ///   - id: Insight ID
    ///   - quote: New quote text
    ///   - theme: New theme
    ///   - tags: New tags
    func updateInsight(id: UUID, quote: String, theme: String, tags: [String]) {
        guard let index = editableInsights.firstIndex(where: { $0.id == id }) else { return }

        editableInsights[index].quote = quote
        editableInsights[index].theme = theme
        editableInsights[index].tags = tags
        editableInsights[index].isModified = true
        hasUnsavedChanges = true
    }

    /// Delete an insight
    /// - Parameter id: Insight ID to delete
    func deleteInsight(id: UUID) {
        editableInsights.removeAll { $0.id == id }
        hasUnsavedChanges = true
    }

    /// Save all pending changes
    func saveChanges() async throws {
        // Update session notes
        session.notes = researcherNotes.isEmpty ? nil : researcherNotes

        // Update modified insights
        for editableInsight in editableInsights where editableInsight.isModified {
            if let insight = session.insights.first(where: { $0.id == editableInsight.id }) {
                insight.quote = editableInsight.quote
                insight.theme = editableInsight.theme
                insight.tags = editableInsight.tags
            }
        }

        // Remove deleted insights
        let editableIds = Set(editableInsights.map { $0.id })
        session.insights.removeAll { !editableIds.contains($0.id) }

        try dataManager.save()
        hasUnsavedChanges = false

        // Reset modified flags
        for index in editableInsights.indices {
            editableInsights[index].isModified = false
        }
    }

    /// Discard all unsaved changes
    func discardChanges() {
        editableInsights = session.insights.map { EditableInsight(from: $0) }
        researcherNotes = session.notes ?? ""
        hasUnsavedChanges = false
    }

    // MARK: - Topic Coverage Helpers

    /// Get topic statuses grouped by coverage level
    var topicsByStatus: [TopicAwareness: [TopicStatus]] {
        Dictionary(grouping: session.topicStatuses) { $0.status }
    }

    /// Get the top themes from insights
    var topThemes: [(theme: String, count: Int)] {
        let themeCounts = Dictionary(grouping: session.insights) { $0.theme }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        return themeCounts.prefix(5).map { (theme: $0.key, count: $0.value) }
    }

    // MARK: - Private Methods

    private func setupChangeTracking() {
        // Track notes changes
        $researcherNotes
            .dropFirst()
            .sink { [weak self] _ in
                self?.hasUnsavedChanges = true
            }
            .store(in: &cancellables)
    }
}

// MARK: - AI Reflection Service

/// Service for generating AI reflections on sessions
final class AIReflectionService {

    /// Generate an AI reflection for the given session
    /// - Parameter session: The session to reflect on
    /// - Returns: AI-generated reflection text
    func generateReflection(for session: Session) async throws -> String {
        // Build context from session data
        let context = buildReflectionContext(for: session)

        // In production, this would call the OpenAI API
        // For now, generate a structured reflection based on session data
        return generateLocalReflection(session: session, context: context)
    }

    private func buildReflectionContext(for session: Session) -> String {
        var context = "Interview Session Analysis\n\n"

        // Add participant info
        context += "Participant: \(session.participantName)\n"
        context += "Project: \(session.projectName)\n"
        context += "Duration: \(TimeFormatting.formatDurationVerbose(session.totalDurationSeconds))\n\n"

        // Add key utterances
        context += "Key Conversation Points:\n"
        for utterance in session.utterances.prefix(20) {
            context += "[\(utterance.speaker.displayName)]: \(utterance.text)\n"
        }

        // Add insights
        if !session.insights.isEmpty {
            context += "\nIdentified Insights:\n"
            for insight in session.insights {
                context += "- \(insight.theme): \"\(insight.quote)\"\n"
            }
        }

        // Add topic coverage
        if !session.topicStatuses.isEmpty {
            context += "\nTopic Coverage:\n"
            for topic in session.topicStatuses {
                context += "- \(topic.topicName): \(topic.status.displayName)\n"
            }
        }

        return context
    }

    private func generateLocalReflection(session: Session, context: String) -> String {
        // Generate a meaningful reflection based on session data
        var reflection = ""

        // First paragraph: Overview
        let duration = TimeFormatting.formatDurationVerbose(session.totalDurationSeconds)
        let participantName = session.participantName

        reflection += "This \(duration) interview with \(participantName) "

        if !session.insights.isEmpty {
            reflection += "yielded \(session.insights.count) notable insights. "
        } else {
            reflection += "focused on gathering initial perspectives. "
        }

        // Identify key themes
        let themes = Dictionary(grouping: session.insights) { $0.theme }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        if let topTheme = themes.first {
            reflection += "The predominant theme that emerged was '\(topTheme.key)'"
            if themes.count > 1 {
                let otherThemes = themes.dropFirst().prefix(2).map { "'\($0.key)'" }.joined(separator: " and ")
                reflection += ", followed by \(otherThemes)"
            }
            reflection += ".\n\n"
        } else {
            reflection += "\n\n"
        }

        // Second paragraph: Notable moments
        reflection += "Key moments worth revisiting include "

        let notableInsights = session.insights.prefix(3)
        if notableInsights.isEmpty {
            reflection += "the natural flow of conversation that established rapport with the participant. "
        } else {
            let quotes = notableInsights.map { "\"\($0.quote.prefix(50))...\"" }.joined(separator: ", ")
            reflection += "when the participant shared: \(quotes). "
        }

        // Add participation balance
        let participantCount = session.utterances.filter { $0.speaker == .participant }.count
        let interviewerCount = session.utterances.filter { $0.speaker == .interviewer }.count

        if participantCount > 0 && interviewerCount > 0 {
            let ratio = Double(participantCount) / Double(interviewerCount)
            if ratio > 2 {
                reflection += "The participant spoke significantly more than the interviewer, suggesting good open-ended questioning."
            } else if ratio > 1 {
                reflection += "There was a healthy balance of speaking time with the participant leading the conversation."
            } else {
                reflection += "The interviewer spoke more than the participant, which may indicate opportunities for more open-ended questions."
            }
        }
        reflection += "\n\n"

        // Third paragraph: Suggestions
        reflection += "For follow-up, consider exploring "

        // Find uncovered topics
        let uncoveredTopics = session.topicStatuses.filter { !$0.isCovered }
        if !uncoveredTopics.isEmpty {
            let topicNames = uncoveredTopics.prefix(3).map { $0.topicName }.joined(separator: ", ")
            reflection += "the following topics that weren't fully addressed: \(topicNames). "
        } else if !session.topicStatuses.isEmpty {
            reflection += "deepening the conversation around topics that showed partial coverage. "
        } else {
            reflection += "themes that the participant seemed most engaged with. "
        }

        // Add insight-based suggestions
        if let firstInsight = session.insights.first {
            reflection += "The insight about '\(firstInsight.theme)' particularly warrants deeper investigation in future sessions."
        }

        return reflection
    }

}

// MARK: - Post Session Export Service

/// Service for exporting session data to various formats (post-session specific)
final class PostSessionExportService {

    private let fileManager = FileManager.default

    /// Export session data to the specified format
    /// - Parameters:
    ///   - session: Session to export
    ///   - format: Export format
    ///   - reflection: Optional AI reflection to include
    ///   - notes: Optional researcher notes to include
    /// - Returns: URL of the exported file
    func export(
        session: Session,
        format: ExportFormat,
        reflection: String?,
        notes: String?
    ) async throws -> URL {
        let content: String

        switch format {
        case .markdown:
            content = generateMarkdown(session: session, reflection: reflection, notes: notes)
        case .json:
            content = try generateJSON(session: session, reflection: reflection, notes: notes)
        }

        let fileName = sanitizeFileName("\(session.projectName)_\(session.participantName)_\(formatDate(session.startedAt))")
        let fileURL = try getExportDirectory().appendingPathComponent("\(fileName).\(format.fileExtension)")

        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    // MARK: - Markdown Generation

    private func generateMarkdown(session: Session, reflection: String?, notes: String?) -> String {
        var md = ""

        // Header
        md += "# Interview Session: \(session.participantName)\n\n"
        md += "**Project:** \(session.projectName)\n"
        md += "**Date:** \(formatDate(session.startedAt))\n"
        md += "**Duration:** \(formatDuration(session.totalDurationSeconds))\n"
        md += "**Mode:** \(session.sessionMode.displayName)\n\n"

        // Statistics
        md += "## Session Statistics\n\n"
        md += "| Metric | Value |\n"
        md += "|--------|-------|\n"
        md += "| Total Utterances | \(session.utterances.count) |\n"
        md += "| Insights Captured | \(session.insights.count) |\n"
        md += "| Topics Covered | \(session.topicStatuses.filter { $0.isCovered }.count)/\(session.topicStatuses.count) |\n\n"

        // AI Reflection
        if let reflection = reflection, !reflection.isEmpty {
            md += "## AI Reflection\n\n"
            md += "\(reflection)\n\n"
        }

        // Researcher Notes
        if let notes = notes, !notes.isEmpty {
            md += "## Researcher Notes\n\n"
            md += "\(notes)\n\n"
        }

        // Topic Coverage
        if !session.topicStatuses.isEmpty {
            md += "## Topic Coverage\n\n"

            let grouped = Dictionary(grouping: session.topicStatuses) { $0.status }

            for status in TopicAwareness.allCases {
                if let topics = grouped[status], !topics.isEmpty {
                    md += "### \(status.displayName)\n\n"
                    for topic in topics {
                        md += "- \(topic.topicName)"
                        if let topicNotes = topic.notes, !topicNotes.isEmpty {
                            md += ": \(topicNotes)"
                        }
                        md += "\n"
                    }
                    md += "\n"
                }
            }
        }

        // Insights
        if !session.insights.isEmpty {
            md += "## Insights\n\n"

            for insight in session.insights.sorted(by: { $0.timestampSeconds < $1.timestampSeconds }) {
                md += "### \(insight.theme)\n\n"
                md += "> \"\(insight.quote)\"\n\n"
                md += "- **Timestamp:** \(insight.formattedTimestamp)\n"
                md += "- **Source:** \(insight.source.displayName)\n"
                if !insight.tags.isEmpty {
                    md += "- **Tags:** \(insight.tags.joined(separator: ", "))\n"
                }
                md += "\n"
            }
        }

        // Transcript
        if !session.utterances.isEmpty {
            md += "## Transcript\n\n"

            for utterance in session.utterances.sorted(by: { $0.timestampSeconds < $1.timestampSeconds }) {
                md += "**[\(utterance.formattedTimestamp)] \(utterance.speaker.displayName):** \(utterance.text)\n\n"
            }
        }

        return md
    }

    // MARK: - JSON Generation

    private func generateJSON(session: Session, reflection: String?, notes: String?) throws -> String {
        let exportData = SessionExportData(
            session: session,
            reflection: reflection,
            notes: notes
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(exportData)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - Helpers

    private func getExportDirectory() throws -> URL {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        let exportPath = documentsPath.appendingPathComponent("HCD Interview Coach/Exports", isDirectory: true)

        if !fileManager.fileExists(atPath: exportPath.path) {
            try fileManager.createDirectory(at: exportPath, withIntermediateDirectories: true)
        }

        return exportPath
    }

    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }

    private func formatDate(_ date: Date) -> String {
        String(TimeFormatting.fileNameFormatter.string(from: date).prefix(10))
    }

    private func formatDuration(_ seconds: Double) -> String {
        TimeFormatting.formatDuration(seconds)
    }
}

// MARK: - Export Data Structure

/// Codable structure for JSON export
private struct SessionExportData: Codable {
    let sessionId: String
    let participantName: String
    let projectName: String
    let sessionMode: String
    let startedAt: Date
    let endedAt: Date?
    let durationSeconds: Double
    let reflection: String?
    let researcherNotes: String?
    let statistics: ExportStatistics
    let topicCoverage: [ExportTopicStatus]
    let insights: [ExportInsight]
    let transcript: [ExportUtterance]

    init(session: Session, reflection: String?, notes: String?) {
        self.sessionId = session.id.uuidString
        self.participantName = session.participantName
        self.projectName = session.projectName
        self.sessionMode = session.sessionMode.rawValue
        self.startedAt = session.startedAt
        self.endedAt = session.endedAt
        self.durationSeconds = session.totalDurationSeconds
        self.reflection = reflection
        self.researcherNotes = notes

        self.statistics = ExportStatistics(
            utteranceCount: session.utterances.count,
            insightCount: session.insights.count,
            topicsCovered: session.topicStatuses.filter { $0.isCovered }.count,
            totalTopics: session.topicStatuses.count
        )

        self.topicCoverage = session.topicStatuses.map { ExportTopicStatus(from: $0) }
        self.insights = session.insights.map { ExportInsight(from: $0) }
        self.transcript = session.utterances.sorted { $0.timestampSeconds < $1.timestampSeconds }
            .map { ExportUtterance(from: $0) }
    }
}

private struct ExportStatistics: Codable {
    let utteranceCount: Int
    let insightCount: Int
    let topicsCovered: Int
    let totalTopics: Int
}

private struct ExportTopicStatus: Codable {
    let topicId: String
    let topicName: String
    let status: String
    let notes: String?

    init(from topic: TopicStatus) {
        self.topicId = topic.topicId
        self.topicName = topic.topicName
        self.status = topic.status.rawValue
        self.notes = topic.notes
    }
}

private struct ExportInsight: Codable {
    let id: String
    let timestampSeconds: Double
    let quote: String
    let theme: String
    let source: String
    let tags: [String]

    init(from insight: Insight) {
        self.id = insight.id.uuidString
        self.timestampSeconds = insight.timestampSeconds
        self.quote = insight.quote
        self.theme = insight.theme
        self.source = insight.source.rawValue
        self.tags = insight.tags
    }
}

private struct ExportUtterance: Codable {
    let id: String
    let speaker: String
    let text: String
    let timestampSeconds: Double
    let confidence: Double?

    init(from utterance: Utterance) {
        self.id = utterance.id.uuidString
        self.speaker = utterance.speaker.rawValue
        self.text = utterance.text
        self.timestampSeconds = utterance.timestampSeconds
        self.confidence = utterance.confidence
    }
}

// MARK: - Session Mode Extension

extension SessionMode {
    var displayName: String {
        switch self {
        case .full:
            return "Full Session"
        case .transcriptionOnly:
            return "Transcription Only"
        case .observerOnly:
            return "Observer Mode"
        }
    }
}
