//
//  InsightsPanel.swift
//  HCDInterviewCoach
//
//  EPIC E8: Insight Flagging
//  Main panel view for displaying and managing insights
//

import SwiftUI
import Combine

// MARK: - Insights Panel

/// Main panel for displaying all flagged insights during a session.
/// Supports manual flagging via keyboard shortcuts and automatic AI flagging.
///
/// Features:
/// - List of all insights with filtering and sorting
/// - Command+I global shortcut for quick flagging
/// - Click insight to navigate to transcript location
/// - Edit/delete insight capabilities
/// - Accessibility: Full VoiceOver and keyboard navigation support
struct InsightsPanel: View {

    // MARK: - Properties

    @ObservedObject var viewModel: InsightsViewModel
    @ObservedObject var sessionManager: SessionManager

    /// Callback when user wants to navigate to an utterance in the transcript
    var onNavigateToUtterance: (Utterance) -> Void

    /// Current timestamp for flagging
    var currentTimestamp: Double

    /// Current transcript text for flagging context
    var currentTranscriptText: String

    @State private var showQuickFlagSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var insightToDelete: Insight?

    @FocusState private var isPanelFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            panelHeader

            Divider()

            // Content
            if viewModel.isCollapsed {
                collapsedContent
            } else {
                expandedContent
            }
        }
        .glassPanel(edge: .trailing)
        .focusable()
        .focused($isPanelFocused)
        // Global keyboard shortcut for flagging
        .keyboardShortcut("i", modifiers: .command)
        // Navigation keyboard shortcuts
        .onKeyPress(.downArrow) {
            viewModel.selectNext()
            return .handled
        }
        .onKeyPress(.upArrow) {
            viewModel.selectPrevious()
            return .handled
        }
        .onKeyPress(.return) {
            viewModel.navigateToSelectedInsight()
            return .handled
        }
        .onKeyPress(.delete) {
            if viewModel.selectedInsight != nil {
                insightToDelete = viewModel.selectedInsight
                showDeleteConfirmation = true
            }
            return .handled
        }
        .onKeyPress("e") {
            viewModel.editSelectedInsight()
            return .handled
        }
        .onKeyPress("z") {
            viewModel.undoLastFlag()
            return .handled
        }
        .sheet(isPresented: $viewModel.isShowingDetailSheet) {
            if let insight = viewModel.editingInsight {
                InsightDetailSheet(
                    insight: insight,
                    onSave: { title, tags in
                        viewModel.saveInsightChanges(title: title, tags: tags)
                    },
                    onDelete: {
                        viewModel.delete(insight)
                        viewModel.dismissDetailSheet()
                    },
                    onNavigate: {
                        viewModel.navigateToTranscript(for: insight)
                    },
                    onDismiss: {
                        viewModel.dismissDetailSheet()
                    }
                )
            }
        }
        .sheet(isPresented: $showQuickFlagSheet) {
            QuickFlagSheet(
                timestamp: currentTimestamp,
                quote: currentTranscriptText,
                onFlag: { title in
                    flagCurrentMoment(with: title)
                    showQuickFlagSheet = false
                },
                onDismiss: {
                    showQuickFlagSheet = false
                }
            )
        }
        .alert("Delete Insight?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                insightToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let insight = insightToDelete {
                    viewModel.delete(insight)
                }
                insightToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            setupNavigationCallback()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(viewModel.accessibilityLabel)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.container)
    }

    // MARK: - Subviews

    private var panelHeader: some View {
        HStack(spacing: 12) {
            // Title and count
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color.hcdInsight)

                Text("Insights")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.hcdTextPrimary)

                if viewModel.totalCount > 0 {
                    Text("\(viewModel.totalCount)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.hcdTextSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.hcdBackgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Spacer()

            // Flagging status indicator
            if case .flagged = viewModel.flaggingStatus {
                FlaggingStatusBadge(status: viewModel.flaggingStatus)
                    .transition(.scale.combined(with: .opacity))
            }

            // Filter button
            if !viewModel.isCollapsed {
                filterMenu
            }

            // Flag button
            Button(action: { handleQuickFlag() }) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.hcdInsight)
            }
            .buttonStyle(.plain)
            .help("Flag current moment (Cmd+I)")
            .accessibilityLabel("Flag current moment")
            .accessibilityHint("Press Command I")
            .accessibilityIdentifier(AccessibilityIdentifiers.Insights.flagButton)

            // Collapse button
            Button(action: { viewModel.toggleCollapsed() }) {
                Image(systemName: viewModel.isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.hcdTextSecondary)
            }
            .buttonStyle(.plain)
            .help(viewModel.isCollapsed ? "Expand panel" : "Collapse panel")
            .accessibilityLabel(viewModel.isCollapsed ? "Expand insights panel" : "Collapse insights panel")
            .accessibilityIdentifier(AccessibilityIdentifiers.Insights.collapseButton)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var filterMenu: some View {
        Menu {
            // Filter options
            Section("Filter") {
                ForEach(InsightFilterMode.allCases) { mode in
                    Button(action: { viewModel.filterMode = mode }) {
                        HStack {
                            Image(systemName: mode.icon)
                            Text(mode.rawValue)
                            if viewModel.filterMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Section("Sort") {
                ForEach(InsightSortOrder.allCases) { order in
                    Button(action: { viewModel.sortOrder = order }) {
                        HStack {
                            Image(systemName: order.icon)
                            Text(order.rawValue)
                            if viewModel.sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            // Clear auto insights
            if viewModel.automaticCount > 0 {
                Button(role: .destructive, action: { viewModel.clearAutomaticInsights() }) {
                    Label("Clear Auto Insights", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 14))
                .foregroundColor(viewModel.filterMode != .all ? Color.hcdPrimary : Color.hcdTextSecondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var collapsedContent: some View {
        HStack(spacing: 12) {
            // Compact insight pills
            if viewModel.hasInsights {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.filteredInsights.prefix(5)) { insight in
                            CompactInsightPill(insight: insight) {
                                viewModel.select(insight)
                                viewModel.navigateToTranscript(for: insight)
                            }
                        }

                        if viewModel.filteredInsights.count > 5 {
                            Text("+\(viewModel.filteredInsights.count - 5)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.hcdTextTertiary)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            } else {
                Text("No insights flagged")
                    .font(.system(size: 12))
                    .foregroundColor(Color.hcdTextTertiary)
                    .padding(.horizontal, 12)
            }

            Spacer()
        }
        .frame(height: 36)
        .animation(reduceMotion ? nil : .easeInOut(duration: AnimationTiming.normal), value: viewModel.isCollapsed)
    }

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Search bar (when there are insights)
            if viewModel.hasInsights {
                searchBar
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }

            // Insights list or empty state
            if viewModel.filteredInsights.isEmpty {
                if viewModel.hasInsights {
                    // Has insights but filtered to none
                    noMatchesView
                } else {
                    // No insights at all
                    InsightsEmptyStateView(onFlagCurrentMoment: { handleQuickFlag() })
                }
            } else {
                insightsList
            }
        }
        .frame(minHeight: 200, maxHeight: 400)
        .animation(reduceMotion ? nil : .easeInOut(duration: AnimationTiming.normal), value: viewModel.isCollapsed)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.hcdTextTertiary)

            TextField("Search insights", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))

            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.hcdTextTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.hcdBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var insightsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.filteredInsights) { insight in
                        InsightRowView(
                            insight: insight,
                            isSelected: viewModel.selectedInsight?.id == insight.id,
                            onTap: {
                                viewModel.select(insight)
                            },
                            onDoubleTap: {
                                viewModel.navigateToTranscript(for: insight)
                            },
                            onEdit: {
                                viewModel.edit(insight)
                            },
                            onDelete: {
                                insightToDelete = insight
                                showDeleteConfirmation = true
                            }
                        )
                        .id(insight.id)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .onChange(of: viewModel.selectedInsight) { newSelection in
                if let id = newSelection?.id {
                    if reduceMotion {
                        proxy.scrollTo(id, anchor: .center)
                    } else {
                        withAnimation(.easeInOut(duration: AnimationTiming.normal)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.list)
    }

    private var noMatchesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Color.hcdTextTertiary)

            Text("No matching insights")
                .font(.system(size: 13))
                .foregroundColor(Color.hcdTextSecondary)

            Button("Clear Search") {
                viewModel.searchQuery = ""
                viewModel.filterMode = .all
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.hcdPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Actions

    private func handleQuickFlag() {
        showQuickFlagSheet = true
    }

    private func flagCurrentMoment(with title: String) {
        // Create a temporary utterance for flagging
        let utterance = Utterance(
            speaker: .participant,
            text: currentTranscriptText,
            timestampSeconds: currentTimestamp
        )

        // Get the flagging service from view model and flag
        viewModel.onFlagCurrentMoment?()

        AppLogger.shared.info("Flagged insight: \(title) at \(currentTimestamp)")
    }

    private func setupNavigationCallback() {
        viewModel.onNavigateToUtterance = { [onNavigateToUtterance] utterance in
            onNavigateToUtterance(utterance)
        }
    }
}

// MARK: - Compact Insight Pill

/// Small pill for displaying insight in collapsed mode
struct CompactInsightPill: View {

    let insight: Insight
    let onTap: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(insight.isUserAdded ? Color.hcdPrimary : Color.hcdInsight)
                .frame(width: 6, height: 6)

            Text(insight.theme)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.hcdTextPrimary)
                .lineLimit(1)

            Text(insight.formattedTimestamp)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Color.hcdTextTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isHovered ? Color.hcdBackgroundSecondary : Color.hcdBackgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.theme) at \(insight.formattedTimestamp)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Flagging Status Badge

/// Badge showing the current flagging status
struct FlaggingStatusBadge: View {

    let status: FlaggingStatus

    var body: some View {
        HStack(spacing: 4) {
            if case .flagging = status {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Flagging...")
            } else if case .flagged(let insight) = status {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.hcdSuccess)
                Text("Flagged")
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(Color.hcdTextSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.hcdBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch status {
        case .idle:
            return "Flagging idle"
        case .flagging:
            return "Flagging in progress"
        case .flagged:
            return "Successfully flagged"
        case .error:
            return "Flagging error"
        }
    }
}

// MARK: - Insights Panel Factory

/// Convenience factory for creating InsightsPanel
@MainActor
struct InsightsPanelFactory {

    /// Creates an InsightsPanel with all dependencies configured
    static func create(
        sessionManager: SessionManager,
        session: Session?,
        currentTimestamp: Double,
        currentTranscriptText: String,
        onNavigateToUtterance: @escaping (Utterance) -> Void
    ) -> some View {
        let flaggingService = InsightFlaggingService(session: session)
        let viewModel = InsightsViewModel(flaggingService: flaggingService)

        return InsightsPanel(
            viewModel: viewModel,
            sessionManager: sessionManager,
            onNavigateToUtterance: onNavigateToUtterance,
            currentTimestamp: currentTimestamp,
            currentTranscriptText: currentTranscriptText
        )
    }
}

// MARK: - Keyboard Shortcut Handler

/// View modifier for handling global insight keyboard shortcuts
struct InsightKeyboardShortcuts: ViewModifier {

    let onFlagInsight: () -> Void
    let onEditInsight: () -> Void
    let onDeleteInsight: () -> Void
    let onNavigateToInsight: () -> Void

    func body(content: Content) -> some View {
        content
            .keyboardShortcut("i", modifiers: .command)
    }
}

extension View {

    /// Adds insight-related keyboard shortcuts to a view
    func insightKeyboardShortcuts(
        onFlag: @escaping () -> Void,
        onEdit: @escaping () -> Void = {},
        onDelete: @escaping () -> Void = {},
        onNavigate: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(InsightKeyboardShortcuts(
            onFlagInsight: onFlag,
            onEditInsight: onEdit,
            onDeleteInsight: onDelete,
            onNavigateToInsight: onNavigate
        ))
    }
}

// MARK: - Preview Provider

#if DEBUG
struct InsightsPanel_Previews: PreviewProvider {
    static var previews: some View {
        let flaggingService = InsightFlaggingService(session: nil)
        let viewModel = InsightsViewModel(flaggingService: flaggingService)

        // Create mock session manager
        let sessionManager = SessionManager(
            audioCapturerProvider: { MockAudioCapturer() },
            apiClientProvider: { MockRealtimeAPIClient() }
        )

        InsightsPanel(
            viewModel: viewModel,
            sessionManager: sessionManager,
            onNavigateToUtterance: { _ in },
            currentTimestamp: 125.0,
            currentTranscriptText: "This is the current transcript text being captured."
        )
        .frame(width: 350, height: 400)
        .padding()
    }
}

// Mock types for preview
private class MockAudioCapturer: AudioCapturing {
    var audioStream: AsyncStream<AudioChunk> {
        AsyncStream { _ in }
    }
    var audioLevels: AudioLevels { .silence }
    func start() throws {}
    func stop() {}
    func pause() {}
    func resume() {}
}

private class MockRealtimeAPIClient: RealtimeAPIConnecting {
    var connectionState: ConnectionState { .disconnected }
    var transcriptionStream: AsyncStream<TranscriptionEvent> {
        AsyncStream { _ in }
    }
    var functionCallStream: AsyncStream<FunctionCallEvent> {
        AsyncStream { _ in }
    }
    func connect(with config: SessionConfig) async throws {}
    func disconnect() async {}
    func send(audio: AudioChunk) async throws {}
}
#endif
