//
//  MarkdownExporter.swift
//  HCD Interview Coach
//
//  EPIC E9: Export System
//  Generates Markdown export of session data
//

import Foundation

/// Generates Markdown exports from session data
/// Optimized for researcher readability and documentation
final class MarkdownExporter {

    // MARK: - Configuration

    /// Configuration options for Markdown export
    struct Configuration {
        /// Include session metadata header
        var includeMetadata: Bool = true

        /// Include full transcript
        var includeTranscript: Bool = true

        /// Include insights section
        var includeInsights: Bool = true

        /// Include topic coverage summary
        var includeTopicCoverage: Bool = true

        /// Include session notes
        var includeNotes: Bool = true

        /// Include timestamps in transcript
        var includeTimestamps: Bool = true

        /// Use relative timestamps (from session start) vs absolute
        var useRelativeTimestamps: Bool = true

        /// Maximum quote length in insights before truncation
        var maxQuoteLength: Int = 200

        static let `default` = Configuration()
    }

    // MARK: - Properties

    private let configuration: Configuration

    // MARK: - Initialization

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Public Interface

    /// Exports a session to Markdown format
    /// - Parameter session: The session to export
    /// - Returns: The generated Markdown string
    /// - Throws: An error if export fails
    func export(_ session: Session) throws -> String {
        var sections: [String] = []

        // Add metadata header
        if configuration.includeMetadata {
            sections.append(generateMetadataSection(session))
        }

        // Add transcript
        if configuration.includeTranscript && !session.utterances.isEmpty {
            sections.append(generateTranscriptSection(session))
        }

        // Add insights
        if configuration.includeInsights && !session.insights.isEmpty {
            sections.append(generateInsightsSection(session))
        }

        // Add topic coverage
        if configuration.includeTopicCoverage && !session.topicStatuses.isEmpty {
            sections.append(generateTopicCoverageSection(session))
        }

        // Add notes
        if configuration.includeNotes, let notes = session.notes, !notes.isEmpty {
            sections.append(generateNotesSection(notes))
        }

        // Add footer
        sections.append(generateFooter(session))

        return sections.joined(separator: "\n\n---\n\n")
    }

    // MARK: - Section Generators

    /// Generates the metadata header section
    private func generateMetadataSection(_ session: Session) -> String {
        var lines: [String] = []

        // Title
        lines.append("# Interview Session: \(session.projectName)")
        lines.append("")

        // Metadata table
        lines.append("| Property | Value |")
        lines.append("|----------|-------|")
        lines.append("| **Participant** | \(session.participantName) |")
        lines.append("| **Date** | \(formatDate(session.startedAt)) |")
        lines.append("| **Duration** | \(formatDuration(session.totalDurationSeconds)) |")
        lines.append("| **Mode** | \(session.sessionMode.displayName) |")

        if session.utterances.count > 0 {
            lines.append("| **Utterances** | \(session.utterances.count) |")
        }

        if session.insights.count > 0 {
            lines.append("| **Insights** | \(session.insights.count) |")
        }

        return lines.joined(separator: "\n")
    }

    /// Generates the transcript section
    private func generateTranscriptSection(_ session: Session) -> String {
        var lines: [String] = []

        lines.append("## Transcript")
        lines.append("")

        // Sort utterances by timestamp
        let sortedUtterances = session.utterances.sorted { $0.timestampSeconds < $1.timestampSeconds }

        for utterance in sortedUtterances {
            let timestamp = configuration.includeTimestamps
                ? "[\(utterance.formattedTimestamp)] "
                : ""

            let speaker = "**\(utterance.speaker.displayName):**"
            let text = utterance.text

            lines.append("\(timestamp)\(speaker) \(text)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// Generates the insights section
    private func generateInsightsSection(_ session: Session) -> String {
        var lines: [String] = []

        lines.append("## Key Insights")
        lines.append("")

        // Sort insights by timestamp
        let sortedInsights = session.insights.sorted { $0.timestampSeconds < $1.timestampSeconds }

        for (index, insight) in sortedInsights.enumerated() {
            let number = index + 1
            let timestamp = configuration.includeTimestamps
                ? " (at \(insight.formattedTimestamp))"
                : ""

            lines.append("\(number). **\(insight.theme)**\(timestamp)")

            // Add quote
            let quote = truncateQuote(insight.quote)
            lines.append("   > \(quote)")
            lines.append("")

            // Add tags if present
            if !insight.tags.isEmpty {
                let tagsString = insight.tags.map { "`\($0)`" }.joined(separator: " ")
                lines.append("   Tags: \(tagsString)")
                lines.append("")
            }

            // Add source indicator
            let sourceIcon = insight.isAIGenerated ? "AI" : "Manual"
            lines.append("   *Source: \(sourceIcon)*")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// Generates the topic coverage section
    private func generateTopicCoverageSection(_ session: Session) -> String {
        var lines: [String] = []

        lines.append("## Topic Coverage")
        lines.append("")

        // Sort topics by name
        let sortedTopics = session.topicStatuses.sorted { $0.topicName < $1.topicName }

        for topic in sortedTopics {
            let progressBar = generateProgressBar(for: topic.status)
            let statusEmoji = statusEmoji(for: topic.status)

            lines.append("- \(statusEmoji) **\(topic.topicName):** \(progressBar) *\(topic.status.displayName)*")

            // Add notes if present
            if let notes = topic.notes, !notes.isEmpty {
                lines.append("  - Notes: \(notes)")
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Generates the notes section
    private func generateNotesSection(_ notes: String) -> String {
        var lines: [String] = []

        lines.append("## Session Notes")
        lines.append("")
        lines.append(notes)

        return lines.joined(separator: "\n")
    }

    /// Generates the footer with export metadata
    private func generateFooter(_ session: Session) -> String {
        var lines: [String] = []

        lines.append("---")
        lines.append("")
        lines.append("*Exported from HCD Interview Coach*")
        lines.append("*Session ID: \(session.id.uuidString)*")
        lines.append("*Export Date: \(formatDate(Date()))*")

        return lines.joined(separator: "\n")
    }

    // MARK: - Formatting Helpers

    /// Formats a date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Formats duration in seconds to HH:MM:SS format
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    /// Truncates a quote if it exceeds the maximum length
    private func truncateQuote(_ quote: String) -> String {
        if quote.count <= configuration.maxQuoteLength {
            return quote
        }

        let truncated = String(quote.prefix(configuration.maxQuoteLength))
        // Try to truncate at a word boundary
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        return truncated + "..."
    }

    /// Generates a visual progress bar for topic coverage
    private func generateProgressBar(for status: TopicAwareness) -> String {
        let totalBlocks = 10
        let filledBlocks: Int

        switch status {
        case .notCovered:
            filledBlocks = 0
        case .partialCoverage:
            filledBlocks = 5
        case .fullyCovered:
            filledBlocks = 10
        case .skipped:
            filledBlocks = 0
        }

        let filled = String(repeating: "\u{2588}", count: filledBlocks)
        let empty = String(repeating: "\u{2591}", count: totalBlocks - filledBlocks)

        return filled + empty
    }

    /// Returns an appropriate status emoji for topic coverage
    private func statusEmoji(for status: TopicAwareness) -> String {
        switch status {
        case .notCovered:
            return ""
        case .partialCoverage:
            return ""
        case .fullyCovered:
            return ""
        case .skipped:
            return ""
        }
    }
}

// MARK: - Markdown Export Extensions

extension MarkdownExporter {
    /// Creates a preview of the Markdown export (first 500 characters)
    func preview(_ session: Session) -> String {
        do {
            let fullExport = try export(session)
            let previewLength = min(fullExport.count, 500)
            let preview = String(fullExport.prefix(previewLength))

            if fullExport.count > 500 {
                return preview + "\n\n*[Preview truncated...]*"
            }
            return preview
        } catch {
            return "Preview unavailable"
        }
    }

    /// Calculates the estimated word count for the export
    func estimatedWordCount(_ session: Session) -> Int {
        var count = 0

        // Count words in utterances
        for utterance in session.utterances {
            count += utterance.wordCount
        }

        // Add estimate for metadata and formatting
        count += 50 // Approximate overhead

        // Add insight quotes
        for insight in session.insights {
            count += insight.quote.split(separator: " ").count
        }

        return count
    }
}
