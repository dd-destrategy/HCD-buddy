//
//  ExportViewModel.swift
//  HCD Interview Coach
//
//  EPIC E9: Export System
//  ViewModel for export functionality with state management
//

import Foundation
import Combine

/// ViewModel managing export operations and state
@MainActor
final class ExportViewModel: ObservableObject {

    // MARK: - Published State

    /// Currently selected export format
    @Published var selectedFormat: ExportFormat = .markdown

    /// Whether an export operation is in progress
    @Published private(set) var isExporting = false

    /// Current export progress
    @Published private(set) var progress: ExportProgress = .preparing

    /// Whether to show preview
    @Published var showPreview = false

    /// Preview content
    @Published private(set) var previewContent = ""

    /// Last error message
    @Published var errorMessage: String?

    /// Whether to show error alert
    @Published var showError = false

    /// Whether copy was successful (for feedback)
    @Published var showCopiedFeedback = false

    /// Last export result
    @Published private(set) var lastExportResult: ExportResult?

    // MARK: - Properties

    let session: Session
    private let exportService: ExportService
    private let markdownExporter: MarkdownExporter
    private let jsonExporter: JSONExporter

    // MARK: - Initialization

    init(
        session: Session,
        exportService: ExportService = ExportService(),
        markdownExporter: MarkdownExporter = MarkdownExporter(),
        jsonExporter: JSONExporter = JSONExporter()
    ) {
        self.session = session
        self.exportService = exportService
        self.markdownExporter = markdownExporter
        self.jsonExporter = jsonExporter
    }

    // MARK: - Computed Properties

    /// Suggested filename for the export
    var suggestedFilename: String {
        exportService.suggestedFilename(for: session, format: selectedFormat)
    }

    /// Whether the session has exportable content
    var hasExportableContent: Bool {
        !session.utterances.isEmpty || !session.insights.isEmpty
    }

    /// Session statistics for display
    var sessionStatistics: SessionExportInfo {
        SessionExportInfo(
            participantName: session.participantName,
            projectName: session.projectName,
            duration: session.totalDurationSeconds,
            utteranceCount: session.utterances.count,
            insightCount: session.insights.count,
            topicCount: session.topicStatuses.count
        )
    }

    /// Estimated word count for the export
    var estimatedWordCount: Int {
        markdownExporter.estimatedWordCount(session)
    }

    // MARK: - Actions

    /// Updates the preview content based on selected format
    func updatePreview() {
        guard showPreview else { return }

        do {
            switch selectedFormat {
            case .markdown:
                previewContent = markdownExporter.preview(session)

            case .json:
                let fullContent = try jsonExporter.exportToString(session)
                if fullContent.count > 1000 {
                    previewContent = String(fullContent.prefix(1000)) + "\n\n[Preview truncated...]"
                } else {
                    previewContent = fullContent
                }
            }
        } catch {
            previewContent = "Preview unavailable: \(error.localizedDescription)"
        }
    }

    /// Copies the export content to clipboard
    func copyToClipboard() async {
        isExporting = true

        do {
            let content: String
            switch selectedFormat {
            case .markdown:
                content = try exportService.exportToMarkdown(session)
            case .json:
                let data = try exportService.exportToJSON(session)
                content = String(data: data, encoding: .utf8) ?? ""
            }

            exportService.copyToClipboard(content)

            showCopiedFeedback = true

            // Hide feedback after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showCopiedFeedback = false

        } catch let error as ExportError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isExporting = false
    }

    /// Exports and saves to a file
    func saveToFile() async -> URL? {
        isExporting = true

        do {
            let result = try await exportService.exportWithProgress(
                session,
                format: selectedFormat
            ) { [weak self] progress in
                self?.progress = progress
            }

            lastExportResult = result
            let filename = suggestedFilename

            let url: URL
            switch selectedFormat {
            case .markdown:
                url = try await exportService.saveToFile(result.content, filename: filename, format: selectedFormat)
            case .json:
                if let data = result.content.data(using: .utf8) {
                    url = try await exportService.saveToFile(data, filename: filename, format: selectedFormat)
                } else {
                    throw ExportError.encodingFailed("Failed to encode JSON content")
                }
            }

            isExporting = false
            return url

        } catch ExportError.cancelled {
            // User cancelled, no error needed
            isExporting = false
            return nil

        } catch let error as ExportError {
            errorMessage = error.localizedDescription
            showError = true
            isExporting = false
            return nil

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isExporting = false
            return nil
        }
    }

    /// Generates the full export content without saving
    func generateExportContent() async throws -> String {
        switch selectedFormat {
        case .markdown:
            return try exportService.exportToMarkdown(session)
        case .json:
            let data = try exportService.exportToJSON(session)
            return String(data: data, encoding: .utf8) ?? ""
        }
    }

    /// Resets the view model state
    func reset() {
        selectedFormat = .markdown
        isExporting = false
        progress = .preparing
        showPreview = false
        previewContent = ""
        errorMessage = nil
        showError = false
        showCopiedFeedback = false
        lastExportResult = nil
    }
}

// MARK: - Session Export Info

/// Information about the session for export display
struct SessionExportInfo {
    let participantName: String
    let projectName: String
    let duration: Double
    let utteranceCount: Int
    let insightCount: Int
    let topicCount: Int

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var totalItemCount: Int {
        utteranceCount + insightCount + topicCount
    }
}

// MARK: - Export History Item

/// Represents a completed export for history tracking
struct ExportHistoryItem: Identifiable {
    let id: UUID
    let sessionId: UUID
    let format: ExportFormat
    let exportedAt: Date
    let fileURL: URL?
    let statistics: ExportStatistics

    init(result: ExportResult, sessionId: UUID) {
        self.id = UUID()
        self.sessionId = sessionId
        self.format = result.format
        self.exportedAt = Date()
        self.fileURL = result.fileURL
        self.statistics = result.statistics
    }
}

// MARK: - Export Preferences

/// User preferences for export operations
struct ExportPreferences: Codable {
    var defaultFormat: ExportFormat = .markdown
    var includeTimestamps: Bool = true
    var includeTopicCoverage: Bool = true
    var prettyPrintJSON: Bool = true
    var autoOpenAfterExport: Bool = false

    static let `default` = ExportPreferences()
}

extension ExportFormat: Codable { }
