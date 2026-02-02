//
//  TopicAwarenessViewModel.swift
//  HCD Interview Coach
//
//  EPIC E7: Topic Awareness
//  State management for topic awareness panel
//

import Foundation
import Combine
import SwiftData
import SwiftUI

// MARK: - Topic Awareness ViewModel

/// Manages state for the topic awareness panel.
/// Coordinates between UI, topic analyzer, and session data.
///
/// Responsibilities:
/// - Topic list display and filtering
/// - Status updates (AI-driven and manual)
/// - Session data persistence
/// - Real-time transcription integration
@MainActor
final class TopicAwarenessViewModel: ObservableObject {

    // MARK: - Published State

    /// Topic items for display
    @Published private(set) var topicItems: [TopicItem] = []

    /// Currently selected topic (for detail view)
    @Published var selectedTopic: TopicItem?

    /// Current filter for topic display
    @Published var filterOption: TopicFilterOption = .all

    /// Current sort option for topic display
    @Published var sortOption: TopicSortOption = .order

    /// Whether the view is in compact mode
    @Published var isCompactMode: Bool = false

    /// Whether the panel is expanded
    @Published var isPanelExpanded: Bool = true

    /// Overall coverage percentage
    @Published private(set) var overallCoverage: Double = 0.0

    /// Number of topics in each status
    @Published private(set) var statusCounts: [TopicCoverageStatus: Int] = [:]

    /// Error message for display
    @Published private(set) var errorMessage: String?

    /// Whether analysis is currently running
    @Published private(set) var isAnalyzing: Bool = false

    // MARK: - Dependencies

    private let analyzer: TopicAnalyzer
    private weak var sessionManager: SessionManager?

    // MARK: - Private Properties

    private var topics: [String] = []
    private var cancellables = Set<AnyCancellable>()
    private var transcriptionTask: Task<Void, Never>?

    // MARK: - Initialization

    init(sessionManager: SessionManager? = nil, analyzer: TopicAnalyzer? = nil) {
        self.sessionManager = sessionManager
        self.analyzer = analyzer ?? TopicAnalyzer()

        setupBindings()
    }

    deinit {
        transcriptionTask?.cancel()
    }

    // MARK: - Configuration

    /// Configures the view model with research topics
    /// - Parameters:
    ///   - topics: List of research topic names
    ///   - keywords: Optional keyword mappings for better detection
    func configure(topics: [String], keywords: [String: [String]]? = nil) {
        self.topics = topics
        analyzer.configure(topics: topics, keywords: keywords)
        updateTopicItems()
    }

    /// Starts listening to transcription stream for real-time analysis
    func startAnalysis() {
        guard let sessionManager = sessionManager else { return }

        transcriptionTask?.cancel()
        transcriptionTask = Task { [weak self] in
            for await event in sessionManager.transcriptionStream {
                guard !Task.isCancelled else { break }
                await self?.handleTranscription(event)
            }
        }
    }

    /// Stops the analysis
    func stopAnalysis() {
        transcriptionTask?.cancel()
        transcriptionTask = nil
    }

    /// Resets all topic statuses
    func reset() {
        analyzer.reset()
        updateTopicItems()
    }

    // MARK: - Topic Actions

    /// Cycles the status of a topic (manual override)
    /// - Parameter topicId: The topic identifier
    func cycleStatus(for topicId: String) {
        guard let newStatus = analyzer.cycleStatus(for: topicId) else { return }

        // Persist to session if available
        persistStatusChange(topicId: topicId, status: newStatus)

        updateTopicItems()

        // Haptic feedback would go here on iOS
        // For macOS, we could play a subtle sound
    }

    /// Sets a specific status for a topic
    /// - Parameters:
    ///   - topicId: The topic identifier
    ///   - status: The new status
    func setStatus(for topicId: String, to status: TopicCoverageStatus) {
        analyzer.setStatus(for: topicId, to: status)
        persistStatusChange(topicId: topicId, status: status)
        updateTopicItems()
    }

    /// Toggles panel expansion
    func togglePanel() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPanelExpanded.toggle()
        }
    }

    /// Selects a topic for detail view
    /// - Parameter topic: The topic to select
    func selectTopic(_ topic: TopicItem?) {
        selectedTopic = topic
    }

    // MARK: - Filtering and Sorting

    /// Filtered and sorted topic items based on current options
    var filteredTopicItems: [TopicItem] {
        var items = topicItems

        // Apply filter
        switch filterOption {
        case .all:
            break
        case .notStarted:
            items = items.filter { $0.status == .notStarted }
        case .inProgress:
            items = items.filter { $0.status == .mentioned || $0.status == .explored }
        case .completed:
            items = items.filter { $0.status == .deepDive }
        }

        // Apply sort
        switch sortOption {
        case .order:
            // Keep original order
            break
        case .status:
            items.sort { $0.status > $1.status }
        case .alphabetical:
            items.sort { $0.name < $1.name }
        case .recentActivity:
            items.sort { ($0.lastUpdated ?? .distantPast) > ($1.lastUpdated ?? .distantPast) }
        }

        return items
    }

    // MARK: - Statistics

    /// Returns a summary of topic coverage
    var coverageSummary: TopicCoverageSummary {
        TopicCoverageSummary(
            total: topicItems.count,
            notStarted: statusCounts[.notStarted] ?? 0,
            mentioned: statusCounts[.mentioned] ?? 0,
            explored: statusCounts[.explored] ?? 0,
            deepDive: statusCounts[.deepDive] ?? 0,
            overallPercentage: overallCoverage
        )
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Observe analyzer state
        analyzer.$topicCoverages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTopicItems()
            }
            .store(in: &cancellables)

        analyzer.$isAnalyzing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAnalyzing)

        analyzer.$lastError
            .receive(on: DispatchQueue.main)
            .map { $0?.localizedDescription }
            .assign(to: &$errorMessage)
    }

    private func updateTopicItems() {
        var items: [TopicItem] = []
        var counts: [TopicCoverageStatus: Int] = [
            .notStarted: 0,
            .mentioned: 0,
            .explored: 0,
            .deepDive: 0
        ]

        for (index, topic) in topics.enumerated() {
            let coverage = analyzer.topicCoverages[topic]
            let status = coverage?.status ?? .notStarted

            items.append(TopicItem(
                id: topic,
                name: topic,
                status: status,
                order: index,
                confidence: coverage?.confidence ?? 0.0,
                mentionCount: coverage?.mentionCount ?? 0,
                lastUpdated: coverage?.lastUpdatedAt,
                isManualOverride: coverage?.isManualOverride ?? false
            ))

            counts[status, default: 0] += 1
        }

        topicItems = items
        statusCounts = counts
        overallCoverage = analyzer.overallCoverage
    }

    private func handleTranscription(_ event: TranscriptionEvent) async {
        guard event.isFinal else { return }

        analyzer.analyze(
            text: event.text,
            speaker: event.speaker ?? .unknown,
            timestamp: event.timestamp
        )
    }

    private func persistStatusChange(topicId: String, status: TopicCoverageStatus) {
        guard let session = sessionManager?.currentSession else { return }

        // Find or create TopicStatus
        if let existingStatus = session.topicStatuses.first(where: { $0.topicId == topicId }) {
            existingStatus.updateStatus(mapToTopicAwareness(status))
        } else {
            let newStatus = TopicStatus(
                topicId: topicId,
                topicName: topicId,
                status: mapToTopicAwareness(status)
            )
            newStatus.session = session
            session.topicStatuses.append(newStatus)
        }
    }

    /// Maps TopicCoverageStatus to TopicAwareness (existing model)
    private func mapToTopicAwareness(_ status: TopicCoverageStatus) -> TopicAwareness {
        switch status {
        case .notStarted:
            return .notCovered
        case .mentioned:
            return .partialCoverage
        case .explored:
            return .partialCoverage
        case .deepDive:
            return .fullyCovered
        }
    }
}

// MARK: - Supporting Types

/// Represents a topic item for display
struct TopicItem: Identifiable, Equatable {
    let id: String
    let name: String
    let status: TopicCoverageStatus
    let order: Int
    let confidence: Double
    let mentionCount: Int
    let lastUpdated: Date?
    let isManualOverride: Bool

    /// Accessibility description for the topic
    var accessibilityDescription: String {
        var description = "\(name), \(status.displayName)"
        if mentionCount > 0 {
            description += ", mentioned \(mentionCount) times"
        }
        if isManualOverride {
            description += ", manually set"
        }
        return description
    }
}

/// Filter options for topic display
enum TopicFilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .all:
            return "list.bullet"
        case .notStarted:
            return "circle.dashed"
        case .inProgress:
            return "circle.lefthalf.filled"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
}

/// Sort options for topic display
enum TopicSortOption: String, CaseIterable, Identifiable {
    case order = "Original Order"
    case status = "Status"
    case alphabetical = "Alphabetical"
    case recentActivity = "Recent Activity"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .order:
            return "list.number"
        case .status:
            return "arrow.up.arrow.down"
        case .alphabetical:
            return "textformat.abc"
        case .recentActivity:
            return "clock"
        }
    }
}

/// Summary of topic coverage for display
struct TopicCoverageSummary {
    let total: Int
    let notStarted: Int
    let mentioned: Int
    let explored: Int
    let deepDive: Int
    let overallPercentage: Double

    var completedCount: Int {
        deepDive
    }

    var inProgressCount: Int {
        mentioned + explored
    }

    var formattedPercentage: String {
        String(format: "%.0f%%", overallPercentage * 100)
    }
}
