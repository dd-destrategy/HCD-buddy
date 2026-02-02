//
//  PostSessionSummaryView.swift
//  HCD Interview Coach
//
//  EPIC E10: Post-Session Summary
//  Main summary view displayed after ending an interview session
//

import SwiftUI

// MARK: - Post-Session Summary View

/// Main summary view shown after ending an interview session
/// Displays statistics, AI reflection, topic coverage, insights, and export options
struct PostSessionSummaryView: View {
    let session: Session
    var onExport: (ExportFormat) -> Void
    var onDismiss: () -> Void

    @StateObject private var viewModel: PostSessionViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showExportSheet = false
    @State private var showUnsavedAlert = false
    @State private var exportedURL: URL?
    @State private var showExportSuccess = false

    @FocusState private var focusedSection: SummarySection?

    enum SummarySection: Hashable {
        case statistics
        case reflection
        case topics
        case insights
        case notes
        case export
    }

    init(
        session: Session,
        onExport: @escaping (ExportFormat) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.session = session
        self.onExport = onExport
        self.onDismiss = onDismiss
        self._viewModel = StateObject(wrappedValue: PostSessionViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with session info
                    headerSection

                    // Statistics
                    SessionStatisticsView(statistics: viewModel.statistics)
                        .focused($focusedSection, equals: .statistics)

                    // AI Reflection
                    AIReflectionView(viewModel: viewModel)
                        .focused($focusedSection, equals: .reflection)

                    // Topic Coverage
                    TopicCoverageChart(topicStatuses: Array(session.topicStatuses))
                        .focused($focusedSection, equals: .topics)

                    // Insights
                    InsightsListView(viewModel: viewModel)
                        .focused($focusedSection, equals: .insights)

                    // Researcher Notes
                    ResearcherNotesEditor(notes: $viewModel.researcherNotes)
                        .focused($focusedSection, equals: .notes)

                    // Export section
                    exportSection
                        .focused($focusedSection, equals: .export)

                    // Bottom spacing
                    Spacer()
                        .frame(height: 40)
                }
                .padding(24)
            }
            .navigationTitle("Session Summary")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if viewModel.hasUnsavedChanges {
                        Button(action: saveChanges) {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        .keyboardShortcut("s", modifiers: .command)
                    }

                    Button(action: handleDismiss) {
                        Text("Done")
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportOptionsSheet(
                    viewModel: viewModel,
                    onExport: handleExport
                )
            }
            .alert("Unsaved Changes", isPresented: $showUnsavedAlert) {
                Button("Discard", role: .destructive) {
                    viewModel.discardChanges()
                    onDismiss()
                }
                Button("Save and Close") {
                    saveChanges()
                    onDismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have unsaved changes to your notes and insights. Would you like to save them before closing?")
            }
            .overlay(alignment: .bottom) {
                if showExportSuccess, let url = exportedURL {
                    ExportSuccessBanner(url: url) {
                        showExportSuccess = false
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            setupKeyboardNavigation()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.participantName)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(session.projectName)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Session mode badge
                sessionModeBadge
            }

            HStack(spacing: 16) {
                Label(formattedDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Label(viewModel.statistics.formattedDuration, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var sessionModeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: modeIcon)
            Text(session.sessionMode.displayName)
        }
        .font(.caption)
        .foregroundColor(modeColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(modeColor.opacity(0.15))
        .cornerRadius(6)
    }

    private var modeIcon: String {
        switch session.sessionMode {
        case .full:
            return "waveform.and.mic"
        case .transcriptionOnly:
            return "text.bubble"
        case .observerOnly:
            return "eye"
        }
    }

    private var modeColor: Color {
        switch session.sessionMode {
        case .full:
            return .green
        case .transcriptionOnly:
            return .blue
        case .observerOnly:
            return .orange
        }
    }

    private var formattedDate: String {
        session.startedAt.formattedDateTime
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(.green)

                Text("Export Session")
                    .font(.headline)

                Spacer()
            }

            Text("Export your session data for further analysis or sharing.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(ExportFormat.allCases) { format in
                    ExportFormatButton(
                        format: format,
                        isExporting: viewModel.isExporting,
                        action: { showExportSheet = true }
                    )
                }

                Spacer()

                Button(action: { showExportSheet = true }) {
                    Label("More Options", systemImage: "ellipsis.circle")
                }
                .buttonStyle(.bordered)
            }

            if let error = viewModel.exportError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func handleDismiss() {
        if viewModel.hasUnsavedChanges {
            showUnsavedAlert = true
        } else {
            onDismiss()
        }
    }

    private func saveChanges() {
        Task {
            try? await viewModel.saveChanges()
        }
    }

    private func handleExport(format: ExportFormat, includeReflection: Bool) {
        Task {
            do {
                let url = try await viewModel.exportSession(format: format, includeReflection: includeReflection)
                exportedURL = url
                onExport(format)

                if reduceMotion {
                    showExportSuccess = true
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showExportSuccess = true
                    }
                }

                // Auto-hide after delay
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    withAnimation {
                        showExportSuccess = false
                    }
                }
            } catch {
                // Error is handled by viewModel
            }
        }
    }

    private func setupKeyboardNavigation() {
        // Focus first section for keyboard navigation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            focusedSection = .statistics
        }
    }
}

// MARK: - Export Format Button

/// Button for quick export in a specific format
private struct ExportFormatButton: View {
    let format: ExportFormat
    let isExporting: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isExporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: format.icon)
                }

                Text(format.displayName)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(format == .markdown ? .blue : .purple)
        .disabled(isExporting)
    }
}

// MARK: - Export Options Sheet

/// Sheet for detailed export options
private struct ExportOptionsSheet: View {
    @ObservedObject var viewModel: PostSessionViewModel
    var onExport: (ExportFormat, Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat = .markdown
    @State private var includeReflection: Bool = true
    @State private var includeTranscript: Bool = true
    @State private var includeInsights: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Export Options")
                    .font(.headline)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Options
            Form {
                Section("Format") {
                    Picker("Export Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Label(format.displayName, systemImage: format.icon)
                                .tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Include") {
                    Toggle("AI Reflection", isOn: $includeReflection)
                        .disabled(viewModel.reflectionState.reflection == nil)

                    Toggle("Transcript", isOn: $includeTranscript)

                    Toggle("Insights", isOn: $includeInsights)
                }

                Section {
                    Text("The export will be saved to your Documents folder.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)

            Divider()

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(action: exportSession) {
                    HStack {
                        if viewModel.isExporting {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Export")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isExporting)
            }
            .padding()
        }
        .frame(width: 400, height: 400)
    }

    private func exportSession() {
        onExport(selectedFormat, includeReflection)
        dismiss()
    }
}

// MARK: - Export Success Banner

/// Banner shown after successful export
private struct ExportSuccessBanner: View {
    let url: URL
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Export Successful")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(url.lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: revealInFinder) {
                Text("Show in Finder")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([url])
        onDismiss()
    }
}

// Note: KeyboardNavigationHelper is defined in Core/Accessibility/KeyboardNavigationModifiers.swift
// Note: accessibilityAudioLevel is defined in DesignSystem/Accessibility/ColorIndependence.swift

// MARK: - Preview

#Preview("Post-Session Summary") {
    let session = Session(
        participantName: "Jane Smith",
        projectName: "User Research Q1",
        sessionMode: .full,
        startedAt: Date().addingTimeInterval(-3600),
        endedAt: Date(),
        totalDurationSeconds: 3600
    )

    // Add sample data
    session.utterances = [
        Utterance(speaker: .interviewer, text: "Can you tell me about your experience with the product?", timestampSeconds: 0),
        Utterance(speaker: .participant, text: "Sure, I've been using it for about 3 months now.", timestampSeconds: 5),
        Utterance(speaker: .participant, text: "The main challenge I face is during the onboarding process.", timestampSeconds: 15)
    ]

    session.insights = [
        Insight(timestampSeconds: 15, quote: "The main challenge I face is during the onboarding process", theme: "User Frustration", source: .aiGenerated, tags: ["pain-point", "onboarding"]),
        Insight(timestampSeconds: 45, quote: "I wish there was better integration with my existing tools", theme: "Feature Request", source: .aiGenerated, tags: ["integration"])
    ]

    session.topicStatuses = [
        TopicStatus(topicId: "1", topicName: "User Goals", status: .fullyCovered),
        TopicStatus(topicId: "2", topicName: "Pain Points", status: .fullyCovered),
        TopicStatus(topicId: "3", topicName: "Current Workflow", status: .partialCoverage),
        TopicStatus(topicId: "4", topicName: "Feature Requests", status: .partialCoverage),
        TopicStatus(topicId: "5", topicName: "Integration Needs", status: .notCovered)
    ]

    PostSessionSummaryView(
        session: session,
        onExport: { format in print("Exported as \(format.displayName)") },
        onDismiss: { print("Dismissed") }
    )
    .frame(width: 700, height: 900)
    .environmentObject(KeyboardNavigationHelper())
}
