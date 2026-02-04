//
//  ExportService.swift
//  HCD Interview Coach
//
//  EPIC E9: Export System
//  Main orchestrator for session export functionality
//

import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - Export Format

/// Supported export formats
enum ExportFormat: String, CaseIterable, Identifiable {
    case markdown = "Markdown"
    case json = "JSON"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .json: return "json"
        }
    }

    var utType: UTType {
        switch self {
        case .markdown: return UTType.plainText
        case .json: return UTType.json
        }
    }

    var description: String {
        switch self {
        case .markdown:
            return "Human-readable format ideal for researchers and documentation"
        case .json:
            return "Machine-readable format for integration with other tools"
        }
    }

    var icon: String {
        switch self {
        case .markdown: return "doc.richtext"
        case .json: return "curlybraces"
        }
    }
}

// MARK: - Export Error

/// Errors that can occur during export
enum ExportError: LocalizedError, Equatable {
    case emptySession
    case invalidData
    case encodingFailed(String)
    case fileWriteFailed(String)
    case cancelled
    case unknown(Error)

    static func == (lhs: ExportError, rhs: ExportError) -> Bool {
        switch (lhs, rhs) {
        case (.emptySession, .emptySession),
             (.invalidData, .invalidData),
             (.cancelled, .cancelled):
            return true
        case (.encodingFailed(let l), .encodingFailed(let r)):
            return l == r
        case (.fileWriteFailed(let l), .fileWriteFailed(let r)):
            return l == r
        case (.unknown(let l), .unknown(let r)):
            return l.localizedDescription == r.localizedDescription
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .emptySession:
            return "Cannot export an empty session"
        case .invalidData:
            return "Session data is invalid or corrupted"
        case .encodingFailed(let detail):
            return "Failed to encode data: \(detail)"
        case .fileWriteFailed(let detail):
            return "Failed to write file: \(detail)"
        case .cancelled:
            return "Export was cancelled"
        case .unknown(let error):
            return "Export failed: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptySession:
            return "Record some content before exporting"
        case .invalidData:
            return "Try restarting the app and loading the session again"
        case .encodingFailed:
            return "Check that the session data doesn't contain invalid characters"
        case .fileWriteFailed:
            return "Check that you have write permissions to the selected location"
        case .cancelled:
            return nil
        case .unknown:
            return "Please try again or contact support if the issue persists"
        }
    }
}

// MARK: - Export Progress

/// Represents the progress of an export operation
struct ExportProgress: Sendable {
    let phase: Phase
    let progress: Double
    let message: String

    enum Phase: Sendable {
        case preparing
        case generatingTranscript
        case generatingInsights
        case encodingData
        case writingFile
        case completed
        case failed
    }

    static let preparing = ExportProgress(phase: .preparing, progress: 0.0, message: "Preparing export...")
    static let completed = ExportProgress(phase: .completed, progress: 1.0, message: "Export completed")

    static func generatingTranscript(progress: Double) -> ExportProgress {
        ExportProgress(phase: .generatingTranscript, progress: progress, message: "Generating transcript...")
    }

    static func generatingInsights(progress: Double) -> ExportProgress {
        ExportProgress(phase: .generatingInsights, progress: progress, message: "Generating insights...")
    }

    static func encodingData(progress: Double) -> ExportProgress {
        ExportProgress(phase: .encodingData, progress: progress, message: "Encoding data...")
    }

    static func writingFile(progress: Double) -> ExportProgress {
        ExportProgress(phase: .writingFile, progress: progress, message: "Writing file...")
    }

    static func failed(_ message: String) -> ExportProgress {
        ExportProgress(phase: .failed, progress: 0.0, message: message)
    }
}

// MARK: - Export Result

/// Result of an export operation
struct ExportResult {
    let format: ExportFormat
    let fileURL: URL?
    let content: String
    let duration: TimeInterval
    let statistics: ExportStatistics
}

/// Statistics about the exported content
struct ExportStatistics {
    let utteranceCount: Int
    let insightCount: Int
    let topicCount: Int
    let wordCount: Int
    let characterCount: Int
}

// MARK: - Export Service

/// Main service for exporting session data to various formats
@MainActor
final class ExportService: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isExporting = false
    @Published private(set) var currentProgress: ExportProgress = .preparing
    @Published private(set) var lastError: ExportError?

    // MARK: - Dependencies

    private let markdownExporter: MarkdownExporter
    private let jsonExporter: JSONExporter

    // MARK: - Initialization

    init(
        markdownExporter: MarkdownExporter = MarkdownExporter(),
        jsonExporter: JSONExporter = JSONExporter()
    ) {
        self.markdownExporter = markdownExporter
        self.jsonExporter = jsonExporter
    }

    // MARK: - Public Interface

    /// Exports a session to Markdown format
    /// - Parameter session: The session to export
    /// - Returns: The generated Markdown string
    /// - Throws: ExportError if export fails
    func exportToMarkdown(_ session: Session) throws -> String {
        guard !session.utterances.isEmpty || !session.insights.isEmpty else {
            throw ExportError.emptySession
        }

        do {
            return try markdownExporter.export(session)
        } catch {
            throw ExportError.encodingFailed(error.localizedDescription)
        }
    }

    /// Exports a session to JSON format
    /// - Parameter session: The session to export
    /// - Returns: The generated JSON data
    /// - Throws: ExportError if export fails
    func exportToJSON(_ session: Session) throws -> Data {
        guard !session.utterances.isEmpty || !session.insights.isEmpty else {
            throw ExportError.emptySession
        }

        do {
            return try jsonExporter.export(session)
        } catch {
            throw ExportError.encodingFailed(error.localizedDescription)
        }
    }

    /// Saves content to a file at user-selected location
    /// - Parameters:
    ///   - content: The content to save
    ///   - filename: The suggested filename
    ///   - format: The export format (determines file extension)
    /// - Returns: The URL where the file was saved
    /// - Throws: ExportError if save fails
    func saveToFile(_ content: String, filename: String, format: ExportFormat) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [format.utType]
            savePanel.nameFieldStringValue = "\(filename).\(format.fileExtension)"
            savePanel.title = "Export Session"
            savePanel.message = "Choose a location to save your \(format.rawValue) export"
            savePanel.canCreateDirectories = true

            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try content.write(to: url, atomically: true, encoding: .utf8)
                        continuation.resume(returning: url)
                    } catch {
                        continuation.resume(throwing: ExportError.fileWriteFailed(error.localizedDescription))
                    }
                } else {
                    continuation.resume(throwing: ExportError.cancelled)
                }
            }
        }
    }

    /// Saves data to a file at user-selected location
    /// - Parameters:
    ///   - data: The data to save
    ///   - filename: The suggested filename
    ///   - format: The export format (determines file extension)
    /// - Returns: The URL where the file was saved
    /// - Throws: ExportError if save fails
    func saveToFile(_ data: Data, filename: String, format: ExportFormat) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [format.utType]
            savePanel.nameFieldStringValue = "\(filename).\(format.fileExtension)"
            savePanel.title = "Export Session"
            savePanel.message = "Choose a location to save your \(format.rawValue) export"
            savePanel.canCreateDirectories = true

            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try data.write(to: url)
                        continuation.resume(returning: url)
                    } catch {
                        continuation.resume(throwing: ExportError.fileWriteFailed(error.localizedDescription))
                    }
                } else {
                    continuation.resume(throwing: ExportError.cancelled)
                }
            }
        }
    }

    /// Copies content to the system clipboard
    /// - Parameter content: The content to copy
    func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }

    /// Exports a session with progress tracking
    /// - Parameters:
    ///   - session: The session to export
    ///   - format: The desired export format
    ///   - progressHandler: Called with export progress updates
    /// - Returns: The export result
    /// - Throws: ExportError if export fails
    func exportWithProgress(
        _ session: Session,
        format: ExportFormat,
        progressHandler: @escaping (ExportProgress) -> Void
    ) async throws -> ExportResult {
        isExporting = true
        lastError = nil
        let startTime = Date()

        defer { isExporting = false }

        do {
            // Phase 1: Preparing
            currentProgress = .preparing
            progressHandler(currentProgress)
            try await Task.sleep(nanoseconds: 100_000_000) // Brief delay for UI

            // Phase 2: Generate content based on format
            let content: String
            switch format {
            case .markdown:
                currentProgress = .generatingTranscript(progress: 0.2)
                progressHandler(currentProgress)

                // Simulate progress for larger sessions
                let utteranceCount = session.utterances.count
                if utteranceCount > 50 {
                    for i in stride(from: 0, to: utteranceCount, by: 10) {
                        let progress = 0.2 + (0.4 * Double(i) / Double(utteranceCount))
                        currentProgress = .generatingTranscript(progress: progress)
                        progressHandler(currentProgress)
                        try await Task.sleep(nanoseconds: 10_000_000)
                    }
                }

                currentProgress = .generatingInsights(progress: 0.6)
                progressHandler(currentProgress)

                content = try exportToMarkdown(session)

            case .json:
                currentProgress = .encodingData(progress: 0.3)
                progressHandler(currentProgress)

                let data = try exportToJSON(session)
                content = String(data: data, encoding: .utf8) ?? ""
            }

            // Phase 3: Calculate statistics
            currentProgress = .encodingData(progress: 0.9)
            progressHandler(currentProgress)

            let statistics = calculateStatistics(session: session, content: content)

            // Phase 4: Complete
            currentProgress = .completed
            progressHandler(currentProgress)

            let duration = Date().timeIntervalSince(startTime)

            return ExportResult(
                format: format,
                fileURL: nil,
                content: content,
                duration: duration,
                statistics: statistics
            )

        } catch let error as ExportError {
            lastError = error
            currentProgress = .failed(error.localizedDescription ?? "Export failed")
            progressHandler(currentProgress)
            throw error
        } catch {
            let exportError = ExportError.unknown(error)
            lastError = exportError
            currentProgress = .failed(exportError.localizedDescription ?? "Export failed")
            progressHandler(currentProgress)
            throw exportError
        }
    }

    // MARK: - Private Helpers

    private func calculateStatistics(session: Session, content: String) -> ExportStatistics {
        let wordCount = content.split(whereSeparator: { $0.isWhitespace }).count
        let characterCount = content.count

        return ExportStatistics(
            utteranceCount: session.utterances.count,
            insightCount: session.insights.count,
            topicCount: session.topicStatuses.count,
            wordCount: wordCount,
            characterCount: characterCount
        )
    }

    /// Generates a suggested filename for the export
    /// - Parameters:
    ///   - session: The session being exported
    ///   - format: The export format
    /// - Returns: A suggested filename (without extension)
    func suggestedFilename(for session: Session, format: ExportFormat) -> String {
        let dateString = String(TimeFormatting.fileNameFormatter.string(from: session.startedAt).prefix(10))

        let sanitizedProjectName = session.projectName
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .lowercased()

        let sanitizedParticipant = session.participantName
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()

        return "\(dateString)-\(sanitizedProjectName)-\(sanitizedParticipant)"
    }
}
