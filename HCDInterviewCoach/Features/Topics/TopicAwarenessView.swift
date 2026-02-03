//
//  TopicAwarenessView.swift
//  HCD Interview Coach
//
//  EPIC E7: Topic Awareness
//  Main topic awareness panel for tracking research topic coverage
//

import SwiftUI

// MARK: - Topic Awareness View

/// Main panel for displaying and tracking research topic coverage during interviews.
/// Provides real-time updates based on AI analysis of conversation content.
///
/// Features:
/// - Live topic status tracking
/// - AI-driven status updates
/// - Manual status override via click
/// - Filter and sort options
/// - Collapsible panel design
/// - Full accessibility support (WCAG 2.1 AA)
struct TopicAwarenessView: View {

    // MARK: - Properties

    @ObservedObject var sessionManager: SessionManager
    var topics: [String]

    @StateObject private var viewModel: TopicAwarenessViewModel

    /// Whether to show in compact sidebar mode
    var isCompact: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initialization

    init(sessionManager: SessionManager, topics: [String], isCompact: Bool = false) {
        self.sessionManager = sessionManager
        self.topics = topics
        self.isCompact = isCompact
        self._viewModel = StateObject(wrappedValue: TopicAwarenessViewModel(sessionManager: sessionManager))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            panelHeader

            if viewModel.isPanelExpanded {
                // Content
                VStack(spacing: 0) {
                    // Overview section
                    overviewSection

                    Divider()
                        .padding(.horizontal, 12)

                    // Filter controls
                    if !isCompact {
                        filterControls
                    }

                    // Topic list
                    topicList
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            viewModel.configure(topics: topics)
            viewModel.startAnalysis()
        }
        .onDisappear {
            viewModel.stopAnalysis()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Topic Awareness Panel")
    }

    // MARK: - Panel Header

    private var panelHeader: some View {
        Button {
            if reduceMotion {
                viewModel.togglePanel()
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.togglePanel()
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Title
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    Text("Topics")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Progress indicator
                if viewModel.isPanelExpanded {
                    progressBadge
                } else {
                    compactProgressBadge
                }

                // Expand/collapse chevron
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(viewModel.isPanelExpanded ? 0 : -90))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Topics panel, \(viewModel.isPanelExpanded ? "expanded" : "collapsed")")
        .accessibilityHint("Double tap to \(viewModel.isPanelExpanded ? "collapse" : "expand")")
    }

    private var progressBadge: some View {
        HStack(spacing: 6) {
            Text(viewModel.coverageSummary.formattedPercentage)
                .font(.subheadline.monospacedDigit())
                .fontWeight(.medium)
                .foregroundColor(.blue)

            if viewModel.isAnalyzing {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Topic coverage \(viewModel.coverageSummary.formattedPercentage)\(viewModel.isAnalyzing ? ", analyzing" : "")")
    }

    private var compactProgressBadge: some View {
        HStack(spacing: 4) {
            Text("\(viewModel.coverageSummary.completedCount)/\(viewModel.coverageSummary.total)")
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)

            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.coverageSummary.completedCount) of \(viewModel.coverageSummary.total) topics completed")
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(spacing: 12) {
            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))

                        // Progress segments
                        HStack(spacing: 2) {
                            progressSegment(
                                width: segmentWidth(for: .deepDive, in: geometry),
                                color: TopicCoverageStatus.deepDive.color
                            )
                            progressSegment(
                                width: segmentWidth(for: .explored, in: geometry),
                                color: TopicCoverageStatus.explored.color
                            )
                            progressSegment(
                                width: segmentWidth(for: .mentioned, in: geometry),
                                color: TopicCoverageStatus.mentioned.color
                            )
                        }
                    }
                }
                .frame(height: 8)

                // Status counts
                if !isCompact {
                    HStack(spacing: 16) {
                        statusCount(
                            count: viewModel.statusCounts[.deepDive] ?? 0,
                            status: .deepDive,
                            label: "Deep Dive"
                        )
                        statusCount(
                            count: viewModel.statusCounts[.explored] ?? 0,
                            status: .explored,
                            label: "Explored"
                        )
                        statusCount(
                            count: viewModel.statusCounts[.mentioned] ?? 0,
                            status: .mentioned,
                            label: "Mentioned"
                        )
                        statusCount(
                            count: viewModel.statusCounts[.notStarted] ?? 0,
                            status: .notStarted,
                            label: "Not Started"
                        )
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Topic coverage: \(viewModel.coverageSummary.formattedPercentage)")
    }

    private func progressSegment(width: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: max(0, width))
    }

    private func segmentWidth(for status: TopicCoverageStatus, in geometry: GeometryProxy) -> CGFloat {
        let count = viewModel.statusCounts[status] ?? 0
        let total = viewModel.topicItems.count
        guard total > 0 else { return 0 }
        return (CGFloat(count) / CGFloat(total)) * geometry.size.width
    }

    private func statusCount(count: Int, status: TopicCoverageStatus, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            Text("\(count)")
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(label)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Filter Controls

    private var filterControls: some View {
        HStack(spacing: 12) {
            // Filter picker
            Menu {
                ForEach(TopicFilterOption.allCases) { option in
                    Button {
                        viewModel.filterOption = option
                    } label: {
                        Label(option.rawValue, systemImage: option.iconName)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.filterOption.iconName)
                    Text(viewModel.filterOption.rawValue)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                )
            }
            .menuStyle(.borderlessButton)

            // Sort picker
            Menu {
                ForEach(TopicSortOption.allCases) { option in
                    Button {
                        viewModel.sortOption = option
                    } label: {
                        Label(option.rawValue, systemImage: option.iconName)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.sortOption.iconName)
                    Text(viewModel.sortOption.rawValue)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                )
            }
            .menuStyle(.borderlessButton)

            Spacer()

            // Legend toggle
            if !isCompact {
                TopicStatusLegend(isHorizontal: true, showLabels: false)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Topic List

    private var topicList: some View {
        ScrollView {
            LazyVStack(spacing: isCompact ? 4 : 8) {
                ForEach(viewModel.filteredTopicItems) { topic in
                    TopicRowView(
                        topic: topic,
                        style: isCompact ? .compact : .standard,
                        isInteractive: true,
                        onStatusCycle: { id in
                            viewModel.cycleStatus(for: id)
                        },
                        onSelect: isCompact ? nil : { item in
                            viewModel.selectTopic(item)
                        }
                    )
                }

                // Empty state
                if viewModel.filteredTopicItems.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, isCompact ? 8 : 16)
            .padding(.vertical, 8)
        }
        .frame(maxHeight: isCompact ? 200 : 400)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No topics match your filter")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Show All") {
                viewModel.filterOption = .all
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Background

    private var panelBackground: some View {
        colorScheme == .dark
            ? Color.black.opacity(0.2)
            : Color.white
    }
}

// MARK: - Topic Awareness Sidebar

/// Compact sidebar version of the topic awareness panel
struct TopicAwarenessSidebar: View {

    @ObservedObject var sessionManager: SessionManager
    var topics: [String]

    var body: some View {
        TopicAwarenessView(
            sessionManager: sessionManager,
            topics: topics,
            isCompact: true
        )
    }
}

// MARK: - Topic Detail Sheet

/// Detail view for a selected topic
struct TopicDetailSheet: View {

    let topic: TopicItem
    var onStatusChange: ((TopicCoverageStatus) -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(topic.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                .accessibilityHint("Dismiss topic detail sheet")
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Current status
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Status")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        TopicStatusIndicator(
                            status: topic.status,
                            style: .badge
                        )

                        TopicStatusIndicator(
                            status: topic.status,
                            style: .progress,
                            showLabel: true
                        )
                    }

                    Divider()

                    // Status selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Change Status")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            ForEach(TopicCoverageStatus.allCases) { status in
                                Button {
                                    onStatusChange?(status)
                                } label: {
                                    VStack(spacing: 6) {
                                        TopicStatusRing(status: status, size: 40, lineWidth: 3)

                                        Text(status.shortLabel)
                                            .font(.caption2)
                                            .foregroundColor(status == topic.status ? .primary : .secondary)
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(status == topic.status ? status.backgroundColor : Color.clear)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    // Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            statRow(label: "Mentions", value: "\(topic.mentionCount)")
                            statRow(label: "Confidence", value: String(format: "%.0f%%", topic.confidence * 100))
                            if let lastUpdated = topic.lastUpdated {
                                statRow(label: "Last Updated", value: lastUpdated.formatted(.relative(presentation: .named)))
                            }
                            statRow(label: "Override", value: topic.isManualOverride ? "Manual" : "Automatic")
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 450)
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.08))
        )
    }
}

// MARK: - Previews

#Preview("Topic Awareness Panel") {
    let sessionManager = SessionManager(
        audioCapturerProvider: { MockAudioCapturer() },
        apiClientProvider: { MockRealtimeAPIClient() }
    )

    let topics = [
        "User Goals and Motivations",
        "Pain Points with Current Solutions",
        "Daily Workflow and Habits",
        "Future Feature Expectations",
        "Collaboration Patterns",
        "Tool Preferences"
    ]

    VStack {
        TopicAwarenessView(
            sessionManager: sessionManager,
            topics: topics
        )
        .frame(width: 400)
        .padding()
    }
    .frame(width: 500, height: 600)
    .background(Color.gray.opacity(0.1))
}

#Preview("Compact Sidebar") {
    let sessionManager = SessionManager(
        audioCapturerProvider: { MockAudioCapturer() },
        apiClientProvider: { MockRealtimeAPIClient() }
    )

    let topics = [
        "User Goals",
        "Pain Points",
        "Daily Workflow",
        "Future Features"
    ]

    TopicAwarenessSidebar(
        sessionManager: sessionManager,
        topics: topics
    )
    .frame(width: 250)
    .padding()
    .background(Color.gray.opacity(0.1))
}

// MARK: - Mock Types for Preview

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
