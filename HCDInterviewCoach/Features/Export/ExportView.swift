//
//  ExportView.swift
//  HCD Interview Coach
//
//  EPIC E9: Export System
//  Main export UI with format selection and actions
//

import SwiftUI

/// Main export view presenting format selection and export actions
struct ExportView: View {
    // MARK: - Properties

    let session: Session
    @StateObject private var exportService = ExportService()

    @State private var selectedFormat: ExportFormat = .markdown
    @State private var isExporting = false
    @State private var showProgress = false
    @State private var exportResult: ExportResult?
    @State private var showPreview = false
    @State private var previewContent = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCopiedFeedback = false

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Session info
                    sessionInfoSection

                    // Format selection
                    formatSelectionSection

                    // Preview section
                    if showPreview {
                        previewSection
                    }
                }
                .padding(20)
            }

            Divider()

            // Actions
            actionSection
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(Color(.windowBackgroundColor))
        .sheet(isPresented: $showProgress) {
            ExportProgressView(
                progress: exportService.currentProgress,
                onCancel: {
                    showProgress = false
                }
            )
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .overlay(alignment: .bottom) {
            if showCopiedFeedback {
                copiedFeedbackBanner
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Export Session")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Export your session data for documentation or analysis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color(.controlBackgroundColor))
    }

    // MARK: - Session Info Section

    private var sessionInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Details")
                .font(.headline)

            HStack(spacing: 20) {
                sessionInfoItem(
                    icon: "person.fill",
                    label: "Participant",
                    value: session.participantName
                )

                sessionInfoItem(
                    icon: "folder.fill",
                    label: "Project",
                    value: session.projectName
                )

                sessionInfoItem(
                    icon: "clock.fill",
                    label: "Duration",
                    value: formatDuration(session.totalDurationSeconds)
                )
            }

            HStack(spacing: 20) {
                sessionInfoItem(
                    icon: "text.bubble.fill",
                    label: "Utterances",
                    value: "\(session.utterances.count)"
                )

                sessionInfoItem(
                    icon: "lightbulb.fill",
                    label: "Insights",
                    value: "\(session.insights.count)"
                )

                sessionInfoItem(
                    icon: "list.bullet",
                    label: "Topics",
                    value: "\(session.topicStatuses.count)"
                )
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func sessionInfoItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Format Selection Section

    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Format")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(ExportFormat.allCases) { format in
                    formatOptionRow(format)
                }
            }
        }
    }

    private func formatOptionRow(_ format: ExportFormat) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFormat = format
                updatePreview()
            }
        }) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: selectedFormat == format ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedFormat == format ? .accentColor : .secondary)
                    .font(.title3)

                // Format icon
                Image(systemName: format.icon)
                    .foregroundColor(.primary)
                    .frame(width: 24)

                // Format info
                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(format.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // File extension badge
                Text(".\(format.fileExtension)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(4)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedFormat == format
                          ? Color.accentColor.opacity(0.1)
                          : Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedFormat == format ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Preview")
                    .font(.headline)

                Spacer()

                Button(action: { showPreview = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                Text(previewContent)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(height: 200)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        HStack(spacing: 12) {
            // Preview toggle
            Button(action: {
                withAnimation {
                    showPreview.toggle()
                    if showPreview {
                        updatePreview()
                    }
                }
            }) {
                Label(
                    showPreview ? "Hide Preview" : "Show Preview",
                    systemImage: showPreview ? "eye.slash" : "eye"
                )
            }
            .buttonStyle(.bordered)

            Spacer()

            // Copy to clipboard
            Button(action: copyToClipboard) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .disabled(isExporting)

            // Save to file
            Button(action: saveToFile) {
                Label("Save File", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)
        }
        .padding(20)
        .background(Color(.controlBackgroundColor))
    }

    // MARK: - Copied Feedback Banner

    private var copiedFeedbackBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            Text("Copied to clipboard")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding(.bottom, 80)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func updatePreview() {
        Task {
            do {
                switch selectedFormat {
                case .markdown:
                    let exporter = MarkdownExporter()
                    previewContent = exporter.preview(session)
                case .json:
                    let exporter = JSONExporter()
                    let fullContent = try exporter.exportToString(session)
                    // Show first 1000 characters for preview
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
    }

    private func copyToClipboard() {
        Task {
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

                withAnimation {
                    showCopiedFeedback = true
                }

                // Hide feedback after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showCopiedFeedback = false
                    }
                }
            } catch let error as ExportError {
                errorMessage = error.localizedDescription ?? "Export failed"
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

            isExporting = false
        }
    }

    private func saveToFile() {
        Task {
            isExporting = true
            showProgress = true

            do {
                let result = try await exportService.exportWithProgress(
                    session,
                    format: selectedFormat
                ) { progress in
                    // Progress is handled by the sheet
                }

                let filename = exportService.suggestedFilename(for: session, format: selectedFormat)

                switch selectedFormat {
                case .markdown:
                    _ = try await exportService.saveToFile(result.content, filename: filename, format: selectedFormat)
                case .json:
                    if let data = result.content.data(using: .utf8) {
                        _ = try await exportService.saveToFile(data, filename: filename, format: selectedFormat)
                    }
                }

                showProgress = false
                dismiss()
            } catch ExportError.cancelled {
                // User cancelled, just close progress
                showProgress = false
            } catch let error as ExportError {
                showProgress = false
                errorMessage = error.localizedDescription ?? "Export failed"
                showError = true
            } catch {
                showProgress = false
                errorMessage = error.localizedDescription
                showError = true
            }

            isExporting = false
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Double) -> String {
        TimeFormatting.formatDuration(seconds)
    }
}

// MARK: - Export Button

/// A button that triggers the export sheet
struct ExportButton: View {
    let session: Session
    @State private var showExportSheet = false

    var body: some View {
        Button(action: { showExportSheet = true }) {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .sheet(isPresented: $showExportSheet) {
            ExportView(session: session)
        }
    }
}

// MARK: - Export Menu Button

/// A menu button with export format options
struct ExportMenuButton: View {
    let session: Session
    @StateObject private var exportService = ExportService()

    @State private var showExportSheet = false
    @State private var showCopiedFeedback = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Menu {
            Button(action: { showExportSheet = true }) {
                Label("Export...", systemImage: "square.and.arrow.up")
            }

            Divider()

            Menu {
                Button(action: { copyToClipboard(.markdown) }) {
                    Label("Copy as Markdown", systemImage: "doc.richtext")
                }

                Button(action: { copyToClipboard(.json) }) {
                    Label("Copy as JSON", systemImage: "curlybraces")
                }
            } label: {
                Label("Copy to Clipboard", systemImage: "doc.on.doc")
            }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .sheet(isPresented: $showExportSheet) {
            ExportView(session: session)
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func copyToClipboard(_ format: ExportFormat) {
        Task {
            do {
                let content: String
                switch format {
                case .markdown:
                    content = try exportService.exportToMarkdown(session)
                case .json:
                    let data = try exportService.exportToJSON(session)
                    content = String(data: data, encoding: .utf8) ?? ""
                }

                exportService.copyToClipboard(content)
            } catch let error as ExportError {
                errorMessage = error.localizedDescription ?? "Export failed"
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Export View") {
    let session = Session(
        participantName: "John Doe",
        projectName: "User Research Study",
        sessionMode: .full,
        startedAt: Date().addingTimeInterval(-3600),
        endedAt: Date(),
        totalDurationSeconds: 3600
    )

    return ExportView(session: session)
        .frame(width: 550, height: 700)
}
