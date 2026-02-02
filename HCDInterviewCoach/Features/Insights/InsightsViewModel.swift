//
//  InsightsViewModel.swift
//  HCDInterviewCoach
//
//  EPIC E8: Insight Flagging
//  ViewModel for managing insight state and user interactions
//

import Foundation
import Combine
import SwiftData

// MARK: - Insights View Model

/// ViewModel for the InsightsPanel, managing insight display, selection, and editing.
/// Coordinates between the UI and the InsightFlaggingService.
///
/// Features:
/// - Filtered and sorted insight lists
/// - Selection management
/// - Edit mode handling
/// - Search functionality
/// - Keyboard shortcut support
@MainActor
final class InsightsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All insights for display
    @Published private(set) var insights: [Insight] = []

    /// Currently selected insight
    @Published var selectedInsight: Insight?

    /// Insight being edited
    @Published var editingInsight: Insight?

    /// Whether the detail sheet is showing
    @Published var isShowingDetailSheet: Bool = false

    /// Search query for filtering insights
    @Published var searchQuery: String = ""

    /// Current filter mode
    @Published var filterMode: InsightFilterMode = .all

    /// Sort order
    @Published var sortOrder: InsightSortOrder = .chronological

    /// Whether the panel is collapsed
    @Published var isCollapsed: Bool = false

    /// Current flagging status (for UI feedback)
    @Published private(set) var flaggingStatus: FlaggingStatus = .idle

    /// Error message if any
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    /// Filtered and sorted insights based on current settings
    var filteredInsights: [Insight] {
        var result = insights

        // Apply filter
        switch filterMode {
        case .all:
            break
        case .manual:
            result = result.filter { $0.isUserAdded }
        case .automatic:
            result = result.filter { $0.isAIGenerated }
        }

        // Apply search
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter { insight in
                insight.quote.lowercased().contains(query) ||
                insight.theme.lowercased().contains(query) ||
                insight.tags.contains { $0.lowercased().contains(query) }
            }
        }

        // Apply sort
        switch sortOrder {
        case .chronological:
            result.sort { $0.timestampSeconds < $1.timestampSeconds }
        case .reverseChronological:
            result.sort { $0.timestampSeconds > $1.timestampSeconds }
        case .alphabetical:
            result.sort { $0.theme.localizedCompare($1.theme) == .orderedAscending }
        }

        return result
    }

    /// Total insight count (for accessibility)
    var totalCount: Int {
        insights.count
    }

    /// Manual insight count
    var manualCount: Int {
        insights.filter { $0.isUserAdded }.count
    }

    /// Automatic insight count
    var automaticCount: Int {
        insights.filter { $0.isAIGenerated }.count
    }

    /// Whether there are any insights
    var hasInsights: Bool {
        !insights.isEmpty
    }

    /// Index of currently selected insight
    var selectedIndex: Int? {
        guard let selected = selectedInsight else { return nil }
        return filteredInsights.firstIndex { $0.id == selected.id }
    }

    // MARK: - Dependencies

    private let flaggingService: InsightFlaggingService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Callbacks

    /// Called when an insight is tapped to navigate to transcript location
    var onNavigateToUtterance: ((Utterance) -> Void)?

    /// Called when requesting to flag the current moment
    var onFlagCurrentMoment: (() -> Void)?

    // MARK: - Initialization

    /// Creates a new InsightsViewModel
    /// - Parameter flaggingService: The flagging service to use
    init(flaggingService: InsightFlaggingService) {
        self.flaggingService = flaggingService
        setupBindings()
    }

    // MARK: - Public Methods

    /// Selects an insight
    /// - Parameter insight: The insight to select
    func select(_ insight: Insight) {
        selectedInsight = insight
    }

    /// Clears selection
    func clearSelection() {
        selectedInsight = nil
    }

    /// Selects the next insight in the list
    func selectNext() {
        let filtered = filteredInsights
        guard !filtered.isEmpty else { return }

        if let current = selectedInsight,
           let index = filtered.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = (index + 1) % filtered.count
            selectedInsight = filtered[nextIndex]
        } else {
            selectedInsight = filtered.first
        }
    }

    /// Selects the previous insight in the list
    func selectPrevious() {
        let filtered = filteredInsights
        guard !filtered.isEmpty else { return }

        if let current = selectedInsight,
           let index = filtered.firstIndex(where: { $0.id == current.id }) {
            let previousIndex = index > 0 ? index - 1 : filtered.count - 1
            selectedInsight = filtered[previousIndex]
        } else {
            selectedInsight = filtered.last
        }
    }

    /// Opens the detail sheet for editing the selected insight
    func editSelectedInsight() {
        guard let insight = selectedInsight else { return }
        editingInsight = insight
        isShowingDetailSheet = true
    }

    /// Opens the detail sheet for a specific insight
    /// - Parameter insight: The insight to edit
    func edit(_ insight: Insight) {
        editingInsight = insight
        isShowingDetailSheet = true
    }

    /// Closes the detail sheet
    func dismissDetailSheet() {
        isShowingDetailSheet = false
        editingInsight = nil
    }

    /// Saves changes to the editing insight
    /// - Parameters:
    ///   - title: New title
    ///   - tags: New tags
    func saveInsightChanges(title: String, tags: [String]) {
        guard let insight = editingInsight else { return }
        flaggingService.updateInsight(insight, title: title, tags: tags)
        dismissDetailSheet()
    }

    /// Deletes an insight
    /// - Parameter insight: The insight to delete
    func delete(_ insight: Insight) {
        // Clear selection if deleting selected insight
        if selectedInsight?.id == insight.id {
            selectNext()
            if selectedInsight?.id == insight.id {
                selectedInsight = nil
            }
        }

        flaggingService.removeInsight(insight)
    }

    /// Deletes the selected insight
    func deleteSelectedInsight() {
        guard let insight = selectedInsight else { return }
        delete(insight)
    }

    /// Navigates to the transcript location for an insight
    /// - Parameter insight: The insight to navigate to
    func navigateToTranscript(for insight: Insight) {
        // Create a synthetic utterance for navigation
        let utterance = Utterance(
            speaker: .participant,
            text: insight.quote,
            timestampSeconds: insight.timestampSeconds
        )
        onNavigateToUtterance?(utterance)
    }

    /// Navigates to the selected insight's transcript location
    func navigateToSelectedInsight() {
        guard let insight = selectedInsight else { return }
        navigateToTranscript(for: insight)
    }

    /// Toggles the panel collapsed state
    func toggleCollapsed() {
        isCollapsed.toggle()
    }

    /// Refreshes insights from the data store
    func refresh() {
        flaggingService.refresh()
    }

    /// Flags the current moment (triggered by keyboard shortcut)
    func flagCurrentMoment() {
        onFlagCurrentMoment?()
    }

    /// Undoes the last flag operation
    func undoLastFlag() {
        _ = flaggingService.undoLastFlag()
    }

    /// Clears all automatic insights
    func clearAutomaticInsights() {
        flaggingService.clearAutoGeneratedInsights()
    }

    /// Cycles through filter modes
    func cycleFilterMode() {
        switch filterMode {
        case .all:
            filterMode = .manual
        case .manual:
            filterMode = .automatic
        case .automatic:
            filterMode = .all
        }
    }

    /// Cycles through sort orders
    func cycleSortOrder() {
        switch sortOrder {
        case .chronological:
            sortOrder = .reverseChronological
        case .reverseChronological:
            sortOrder = .alphabetical
        case .alphabetical:
            sortOrder = .chronological
        }
    }

    // MARK: - Accessibility

    /// Accessibility label for the insights panel
    var accessibilityLabel: String {
        if insights.isEmpty {
            return "Insights panel, empty"
        }
        return "Insights panel, \(insights.count) insights"
    }

    /// Accessibility announcement for selection changes
    func announceSelection() -> String? {
        guard let insight = selectedInsight else { return nil }
        return "\(insight.theme), at \(insight.formattedTimestamp)"
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Bind to flagging service insights
        flaggingService.$insights
            .receive(on: DispatchQueue.main)
            .sink { [weak self] insights in
                self?.insights = insights
            }
            .store(in: &cancellables)

        // Bind to flagging status
        flaggingService.$flaggingStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.flaggingStatus = status

                // Auto-select newly flagged insights
                if case .flagged(let insight) = status {
                    self?.selectedInsight = insight
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types

/// Filter modes for insights
enum InsightFilterMode: String, CaseIterable, Identifiable {
    case all = "All"
    case manual = "Manual"
    case automatic = "Auto"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:
            return "tray.full"
        case .manual:
            return "hand.tap"
        case .automatic:
            return "sparkles"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .all:
            return "Show all insights"
        case .manual:
            return "Show manually flagged insights only"
        case .automatic:
            return "Show automatically flagged insights only"
        }
    }
}

/// Sort orders for insights
enum InsightSortOrder: String, CaseIterable, Identifiable {
    case chronological = "Oldest First"
    case reverseChronological = "Newest First"
    case alphabetical = "Alphabetical"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chronological:
            return "arrow.up"
        case .reverseChronological:
            return "arrow.down"
        case .alphabetical:
            return "textformat.abc"
        }
    }
}

// MARK: - Insights ViewModel Factory

/// Factory for creating InsightsViewModel instances
@MainActor
struct InsightsViewModelFactory {

    /// Creates a view model for the given session
    static func create(
        for session: Session?,
        dataManager: DataManager = .shared
    ) -> InsightsViewModel {
        let flaggingService = InsightFlaggingService(session: session, dataManager: dataManager)
        return InsightsViewModel(flaggingService: flaggingService)
    }

    /// Creates a view model with an existing flagging service
    static func create(with flaggingService: InsightFlaggingService) -> InsightsViewModel {
        InsightsViewModel(flaggingService: flaggingService)
    }
}
