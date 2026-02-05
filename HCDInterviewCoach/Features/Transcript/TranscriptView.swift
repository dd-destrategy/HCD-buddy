//
//  TranscriptView.swift
//  HCDInterviewCoach
//
//  EPIC E5: Transcript Display
//  Main transcript container with real-time display and full accessibility
//

import SwiftUI
// Note: SwiftData import removed - view accesses data only through ViewModel

// MARK: - Transcript View

/// Main transcript container that displays conversation as it happens.
/// Consumes `sessionManager.transcriptionStream` and displays utterances in real-time.
///
/// Features:
/// - Real-time transcript display with auto-scroll
/// - Speaker labels with color coding and manual toggle
/// - Inline timestamps
/// - Search within transcript
/// - Full keyboard navigation and VoiceOver support
/// - Memory-efficient virtualization for 60+ minute sessions
struct TranscriptView: View {

    // MARK: - Properties

    /// Session manager to consume transcription events from
    @ObservedObject var sessionManager: SessionManager

    /// Callback when an utterance is flagged as an insight
    var onInsightFlagged: (Utterance) -> Void

    // MARK: - State

    @StateObject private var viewModel = TranscriptViewModel()

    @State private var isSearchVisible: Bool = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var focusedUtteranceIndex: Int?

    @FocusState private var focusedArea: FocusArea?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var focusManager: FocusManager

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            transcriptHeader

            // Search bar (when active)
            if isSearchVisible {
                TranscriptSearchView(
                    searchQuery: $viewModel.searchQuery,
                    results: viewModel.searchResults,
                    currentResultIndex: $viewModel.currentSearchResultIndex,
                    isLoading: viewModel.isProcessing,
                    onPrevious: { viewModel.previousSearchResult() },
                    onNext: { viewModel.nextSearchResult() },
                    onClose: { closeSearch() }
                )
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .liquidGlass(
                    material: .thin,
                    cornerRadius: CornerRadius.medium,
                    borderStyle: .subtle,
                    enableHover: false
                )
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.xs)
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }

            // Main transcript content
            transcriptContent
                .focused($focusedArea, equals: .transcript)

            // Footer with stats and auto-scroll toggle
            transcriptFooter
        }
        .glassPanel(edge: .leading)
        .onAppear {
            viewModel.connect(to: sessionManager)
            setupInsightCallback()
        }
        .onDisappear {
            viewModel.disconnect()
        }
        .onChange(of: focusManager.currentFocus) { _, newFocus in
            if newFocus == .transcript {
                focusedArea = .transcript
            }
        }
        // Keyboard shortcuts
        .keyboardNavigable(
            onEscape: { closeSearch() }
        )
        .onKeyPress(KeyboardShortcuts.searchTranscript) {
            toggleSearch()
            return .handled
        }
        .onKeyPress(KeyboardShortcuts.toggleSpeaker) {
            toggleSelectedSpeaker()
            return .handled
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Transcript panel")
        .accessibilityHint("Shows real-time conversation transcript")
    }

    // MARK: - Header

    private var transcriptHeader: some View {
        HStack(spacing: Spacing.md) {
            // Title
            Label("Transcript", systemImage: "text.quote")
                .font(Typography.heading3)
                .foregroundColor(.primary)

            Spacer()

            // Filter buttons
            filterButtons

            // Search toggle
            Button(action: toggleSearch) {
                Image(systemName: isSearchVisible ? "magnifyingglass.circle.fill" : "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(isSearchVisible ? .accentColor : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .glassButton(isActive: isSearchVisible, style: .ghost)
            .keyboardShortcut("f", modifiers: .command)
            .help("Search transcript (Cmd+F)")
            .accessibilityLabel(isSearchVisible ? "Close search" : "Search transcript")

            // Export menu
            Menu {
                Button(action: exportAsText) {
                    Label("Export as Text", systemImage: "doc.text")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 28)
            .help("Export transcript")
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassToolbar()
    }

    private var filterButtons: some View {
        HStack(spacing: Spacing.xs) {
            FilterButton(
                label: "All",
                isSelected: viewModel.speakerFilter == nil,
                action: { viewModel.filterBySpeaker(nil) }
            )

            FilterButton(
                label: "INT",
                color: .blue,
                isSelected: viewModel.speakerFilter == .interviewer,
                action: { viewModel.filterBySpeaker(.interviewer) }
            )

            FilterButton(
                label: "PAR",
                color: .green,
                isSelected: viewModel.speakerFilter == .participant,
                action: { viewModel.filterBySpeaker(.participant) }
            )
        }
        .padding(Spacing.xs)
        .liquidGlass(
            material: .ultraThin,
            cornerRadius: CornerRadius.medium,
            borderStyle: .subtle,
            enableHover: false
        )
    }

    // MARK: - Content

    @ViewBuilder
    private var transcriptContent: some View {
        if viewModel.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.filteredUtterances.enumerated()), id: \.element.id) { index, utterance in
                            UtteranceRowView(
                                utterance: utterance,
                                isSelected: viewModel.selectedUtteranceId == utterance.id,
                                isFocused: focusedUtteranceIndex == index,
                                searchQuery: viewModel.isSearchActive ? viewModel.searchQuery : nil,
                                onSpeakerToggle: { newSpeaker in
                                    viewModel.updateSpeaker(for: utterance.id, to: newSpeaker)
                                },
                                onFlagInsight: {
                                    viewModel.flagAsInsight(utterance.id)
                                },
                                onTimestampTap: {
                                    viewModel.selectedUtteranceId = utterance.id
                                },
                                onSelect: {
                                    viewModel.selectedUtteranceId = utterance.id
                                }
                            )
                            .id(utterance.id)

                            if index < viewModel.filteredUtterances.count - 1 {
                                Divider()
                                    .padding(.leading, 74) // Align with text
                                    .opacity(0.5)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }
                .onAppear { scrollProxy = proxy }
                .onChange(of: viewModel.virtualizationManager.totalUtteranceCount) { _, _ in
                    if viewModel.isAutoScrollEnabled {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: viewModel.selectedUtteranceId) { _, newId in
                    if let id = newId {
                        if reduceMotion {
                            proxy.scrollTo(id, anchor: .center)
                        } else {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
                // Keyboard navigation
                .listNavigable(
                    onNext: { navigateDown() },
                    onPrevious: { navigateUp() },
                    onSelect: { selectCurrentUtterance() }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "text.quote")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No transcript yet")
                .font(Typography.heading2)
                .foregroundColor(.secondary)

            Text(viewModel.statusMessage)
                .font(Typography.body)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(Spacing.xl)
        .glassCard(isSelected: false)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Empty transcript")
        .accessibilityValue(viewModel.statusMessage)
    }

    // MARK: - Footer

    private var transcriptFooter: some View {
        HStack {
            // Statistics
            if !viewModel.isEmpty {
                statisticsView
            }

            Spacer()

            // Memory usage (in debug builds)
            #if DEBUG
            memoryIndicator
            #endif

            // Auto-scroll toggle
            autoScrollToggle
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassToolbar()
    }

    private var statisticsView: some View {
        let stats = viewModel.statistics

        return HStack(spacing: Spacing.md) {
            StatisticBadge(value: "\(stats.totalUtterances)", icon: "text.bubble", help: "Total utterances")

            StatisticBadge(value: "\(stats.totalWords)", icon: "character.cursor.ibeam", help: "Total words")

            if stats.durationSeconds > 0 {
                StatisticBadge(value: stats.formattedDuration, icon: "clock", help: "Duration")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statisticsAccessibilityLabel(stats))
    }

    private func statisticsAccessibilityLabel(_ stats: TranscriptStatistics) -> String {
        var parts: [String] = []
        parts.append("\(stats.totalUtterances) utterances")
        parts.append("\(stats.totalWords) words")
        if stats.durationSeconds > 0 {
            parts.append("duration \(stats.formattedDuration)")
        }
        return "Transcript statistics: " + parts.joined(separator: ", ")
    }

    #if DEBUG
    private var memoryIndicator: some View {
        let stats = viewModel.virtualizationManager.memoryStats

        return Text("\(stats.loadedCount)/\(stats.totalCount) loaded")
            .font(Typography.small)
            .foregroundColor(.secondary.opacity(0.6))
            .help("Memory: \(stats.formattedMemory)")
    }
    #endif

    private var autoScrollToggle: some View {
        Toggle(isOn: $viewModel.isAutoScrollEnabled) {
            Label("Auto-scroll", systemImage: "arrow.down.to.line")
                .font(Typography.caption)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .help("Automatically scroll to new utterances")
        .accessibilityLabel("Auto-scroll")
        .accessibilityValue(viewModel.isAutoScrollEnabled ? "On" : "Off")
        .accessibilityHint("Toggle automatic scrolling to new content")
    }

    // MARK: - Actions

    private func toggleSearch() {
        if reduceMotion {
            isSearchVisible.toggle()
            if !isSearchVisible {
                viewModel.clearSearch()
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearchVisible.toggle()
                if !isSearchVisible {
                    viewModel.clearSearch()
                }
            }
        }
    }

    private func closeSearch() {
        if reduceMotion {
            isSearchVisible = false
            viewModel.clearSearch()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearchVisible = false
                viewModel.clearSearch()
            }
        }
    }

    private func toggleSelectedSpeaker() {
        if let selectedId = viewModel.selectedUtteranceId {
            viewModel.toggleSpeaker(for: selectedId)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.filteredUtterances.last?.id {
            if reduceMotion {
                proxy.scrollTo(lastId, anchor: .bottom)
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }

    private func navigateUp() {
        let utterances = viewModel.filteredUtterances
        guard !utterances.isEmpty else { return }

        if let currentIndex = focusedUtteranceIndex {
            focusedUtteranceIndex = max(0, currentIndex - 1)
        } else if let selectedId = viewModel.selectedUtteranceId,
                  let index = utterances.firstIndex(where: { $0.id == selectedId }) {
            focusedUtteranceIndex = max(0, index - 1)
        } else {
            focusedUtteranceIndex = utterances.count - 1
        }

        if let index = focusedUtteranceIndex {
            viewModel.selectedUtteranceId = utterances[index].id
        }
    }

    private func navigateDown() {
        let utterances = viewModel.filteredUtterances
        guard !utterances.isEmpty else { return }

        if let currentIndex = focusedUtteranceIndex {
            focusedUtteranceIndex = min(utterances.count - 1, currentIndex + 1)
        } else if let selectedId = viewModel.selectedUtteranceId,
                  let index = utterances.firstIndex(where: { $0.id == selectedId }) {
            focusedUtteranceIndex = min(utterances.count - 1, index + 1)
        } else {
            focusedUtteranceIndex = 0
        }

        if let index = focusedUtteranceIndex {
            viewModel.selectedUtteranceId = utterances[index].id
        }
    }

    private func selectCurrentUtterance() {
        // Select current focused utterance for editing or flagging
        if let index = focusedUtteranceIndex {
            let utterances = viewModel.filteredUtterances
            if index < utterances.count {
                viewModel.selectedUtteranceId = utterances[index].id
            }
        }
    }

    private func exportAsText() {
        let text = viewModel.exportAsText()

        // Use save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "transcript.txt"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try text.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    AppLogger.shared.logUI("Failed to save transcript: \(error)", level: .error)
                }
            }
        }
    }

    private func setupInsightCallback() {
        viewModel.onInsightFlagged = { utteranceVM in
            // Convert view model back to model for callback
            // In production, this would use proper data manager integration
            let utterance = Utterance(
                id: utteranceVM.id,
                speaker: utteranceVM.speaker,
                text: utteranceVM.text,
                timestampSeconds: utteranceVM.timestampSeconds,
                confidence: utteranceVM.confidence,
                createdAt: utteranceVM.createdAt
            )
            onInsightFlagged(utterance)
        }
    }
}

// MARK: - Filter Button

/// Small filter button for speaker filtering with glass styling
private struct FilterButton: View {
    let label: String
    var color: Color = .secondary
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.small)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? (label == "All" ? .accentColor : color) : .secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(buttonBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .stroke(
                            isSelected ? selectedBorderColor.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel("Filter: \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var buttonBackground: Color {
        if isSelected {
            return selectedBackground
        } else if isHovered {
            return colorScheme == .dark
                ? Color.white.opacity(0.05)
                : Color.black.opacity(0.03)
        }
        return Color.clear
    }

    private var selectedBackground: Color {
        if label == "All" {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.2 : 0.1)
        }
        return color.opacity(colorScheme == .dark ? 0.2 : 0.1)
    }

    private var selectedBorderColor: Color {
        label == "All" ? .accentColor : color
    }
}

// MARK: - Statistic Badge

/// Badge for displaying statistics with subtle glass background
private struct StatisticBadge: View {
    let value: String
    let icon: String
    let help: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Label(value, systemImage: icon)
            .font(Typography.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.05)
                        : Color.black.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .stroke(
                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                        lineWidth: 0.5
                    )
            )
            .help(help)
    }
}

// MARK: - Focus Area

/// Focus areas within the transcript view
private enum FocusArea: Hashable {
    case transcript
    case search
}

// MARK: - Preview

#if DEBUG
struct TranscriptView_Previews: PreviewProvider {
    static var previews: some View {
        TranscriptView(
            sessionManager: SessionManager(
                audioCapturerProvider: { MockAudioCapturer() },
                apiClientProvider: { MockRealtimeAPIClient() }
            ),
            onInsightFlagged: { _ in }
        )
        .environmentObject(FocusManager())
        .frame(width: 500, height: 600)
    }
}

// Mock types for preview
private class MockAudioCapturer: AudioCapturing {
    var audioStream: AsyncStream<AudioChunk> {
        AsyncStream { _ in }
    }
    var audioLevels: AudioLevels = .silence
    func start() throws {}
    func stop() {}
    func pause() {}
    func resume() {}
}

private class MockRealtimeAPIClient: RealtimeAPIConnecting {
    var connectionState: ConnectionState = .disconnected
    var transcriptionStream: AsyncStream<TranscriptionEvent> {
        AsyncStream { _ in }
    }
    var functionCallStream: AsyncStream<FunctionCallEvent> {
        AsyncStream { _ in }
    }
    func connect(with config: SessionConfig) async throws {}
    func send(audio: AudioChunk) async throws {}
    func disconnect() async {}
}
#endif
