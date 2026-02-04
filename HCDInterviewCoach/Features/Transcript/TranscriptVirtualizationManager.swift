//
//  TranscriptVirtualizationManager.swift
//  HCDInterviewCoach
//
//  EPIC E5: Transcript Display
//  Memory-efficient virtualization for long interview sessions (60+ minutes)
//

import Foundation
import Combine
import SwiftData

// MARK: - Virtualization Manager

/// Manages memory-efficient display of utterances for long sessions.
/// Implements windowing/virtualization to prevent memory issues with 60+ minute sessions.
///
/// Strategy:
/// - Maintains a sliding window of utterances in memory
/// - Pre-fetches utterances as user scrolls
/// - Unloads utterances outside the visible window
/// - Supports search within full transcript (loads on-demand)
@MainActor
class TranscriptVirtualizationManager: ObservableObject {

    // MARK: - Configuration

    /// Configuration for virtualization behavior
    struct Configuration {
        /// Number of utterances to keep in the visible window
        let windowSize: Int

        /// Number of utterances to pre-fetch ahead of scroll direction
        let prefetchBuffer: Int

        /// Threshold for unloading utterances (when window moves this far)
        let unloadThreshold: Int

        /// Maximum utterances to load during search
        let searchBatchSize: Int

        /// Estimated row height for scroll calculations
        let estimatedRowHeight: CGFloat

        static let `default` = Configuration(
            windowSize: 100,
            prefetchBuffer: 25,
            unloadThreshold: 50,
            searchBatchSize: 500,
            estimatedRowHeight: 80
        )

        /// Configuration for testing with smaller windows
        static let testing = Configuration(
            windowSize: 20,
            prefetchBuffer: 5,
            unloadThreshold: 10,
            searchBatchSize: 50,
            estimatedRowHeight: 80
        )
    }

    // MARK: - Published Properties

    /// Currently loaded utterances in the visible window
    @Published private(set) var visibleUtterances: [UtteranceViewModel] = []

    /// Total count of all utterances (for scroll bar sizing)
    @Published private(set) var totalUtteranceCount: Int = 0

    /// Current scroll position (0.0 - 1.0)
    @Published private(set) var scrollPosition: CGFloat = 1.0

    /// Whether more data is being loaded
    @Published private(set) var isLoading: Bool = false

    /// Index range of currently visible items
    @Published private(set) var visibleRange: Range<Int> = 0..<0

    /// Memory usage statistics for monitoring
    @Published private(set) var memoryStats: MemoryStatistics = .zero

    // MARK: - Private Properties

    private let configuration: Configuration
    private var allUtteranceIds: [UUID] = []
    private var loadedUtterances: [UUID: UtteranceViewModel] = [:]
    private var centerIndex: Int = 0
    private var scrollDirection: ScrollDirection = .down
    private var lastScrollOffset: CGFloat = 0
    private var modelContext: ModelContext?

    private var prefetchTask: Task<Void, Never>?
    private var unloadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Setup

    /// Initialize the manager with a model context for fetching utterances
    /// - Parameter context: SwiftData model context
    func setup(with context: ModelContext) {
        self.modelContext = context
        refreshUtteranceIndex()
    }

    /// Initialize with a session's utterances
    /// - Parameter session: The session to display utterances from
    func setup(with session: Session) {
        allUtteranceIds = session.utterances
            .sorted { $0.timestampSeconds < $1.timestampSeconds }
            .map { $0.id }
        totalUtteranceCount = allUtteranceIds.count

        // Pre-populate with session utterances
        for utterance in session.utterances {
            let viewModel = UtteranceViewModel(from: utterance)
            loadedUtterances[utterance.id] = viewModel
        }

        updateVisibleWindow()
        updateMemoryStats()
    }

    // MARK: - Scroll Handling

    /// Update visible window based on scroll offset
    /// - Parameters:
    ///   - offset: Current scroll offset
    ///   - viewportHeight: Height of the visible viewport
    func handleScroll(offset: CGFloat, viewportHeight: CGFloat) {
        guard totalUtteranceCount > 0 else { return }

        // Determine scroll direction
        scrollDirection = offset > lastScrollOffset ? .down : .up
        lastScrollOffset = offset

        // Calculate which utterances should be visible
        let estimatedFirstVisible = max(0, Int(offset / configuration.estimatedRowHeight))
        let estimatedLastVisible = min(
            totalUtteranceCount - 1,
            estimatedFirstVisible + Int(viewportHeight / configuration.estimatedRowHeight)
        )

        // Update center index
        centerIndex = (estimatedFirstVisible + estimatedLastVisible) / 2

        // Update scroll position for UI
        let maxOffset = max(1, CGFloat(totalUtteranceCount) * configuration.estimatedRowHeight - viewportHeight)
        scrollPosition = min(1.0, offset / maxOffset)

        // Update visible window
        updateVisibleWindow()

        // Trigger prefetch if needed
        schedulePrefetch()
    }

    /// Scroll to a specific utterance by ID
    /// - Parameter id: Utterance ID to scroll to
    /// - Returns: Estimated scroll offset for the utterance
    func scrollToUtterance(_ id: UUID) -> CGFloat? {
        guard let index = allUtteranceIds.firstIndex(of: id) else { return nil }

        centerIndex = index
        updateVisibleWindow()

        // Ensure the utterance is loaded
        if loadedUtterances[id] == nil {
            loadUtterance(at: index)
        }

        return CGFloat(index) * configuration.estimatedRowHeight
    }

    /// Scroll to the end of the transcript (auto-scroll behavior)
    func scrollToEnd() {
        guard totalUtteranceCount > 0 else { return }

        centerIndex = totalUtteranceCount - 1
        scrollPosition = 1.0
        updateVisibleWindow()
    }

    // MARK: - Utterance Management

    /// Add a new utterance to the transcript
    /// - Parameter utterance: The utterance to add
    func addUtterance(_ utterance: UtteranceViewModel) {
        allUtteranceIds.append(utterance.id)
        loadedUtterances[utterance.id] = utterance
        totalUtteranceCount = allUtteranceIds.count

        updateVisibleWindow()
        updateMemoryStats()
    }

    /// Update an existing utterance (e.g., speaker correction)
    /// - Parameter utterance: Updated utterance view model
    func updateUtterance(_ utterance: UtteranceViewModel) {
        loadedUtterances[utterance.id] = utterance

        // Update visible array if present
        if let index = visibleUtterances.firstIndex(where: { $0.id == utterance.id }) {
            visibleUtterances[index] = utterance
        }
    }

    /// Remove an utterance from the transcript
    /// - Parameter id: ID of utterance to remove
    func removeUtterance(_ id: UUID) {
        allUtteranceIds.removeAll { $0 == id }
        loadedUtterances.removeValue(forKey: id)
        totalUtteranceCount = allUtteranceIds.count

        updateVisibleWindow()
        updateMemoryStats()
    }

    /// Get a specific utterance by ID
    /// - Parameter id: Utterance ID
    /// - Returns: The utterance view model if loaded
    func getUtterance(_ id: UUID) -> UtteranceViewModel? {
        return loadedUtterances[id]
    }

    // MARK: - Search Support

    /// Search for utterances containing the query
    /// - Parameter query: Search query string
    /// - Returns: Array of matching utterance IDs with context
    func search(for query: String) async -> [SearchResult] {
        guard !query.isEmpty else { return [] }

        isLoading = true
        defer { isLoading = false }

        var results: [SearchResult] = []
        let lowercaseQuery = query.lowercased()

        // Search through loaded utterances first
        for (id, utterance) in loadedUtterances {
            if let range = utterance.text.lowercased().range(of: lowercaseQuery) {
                let result = SearchResult(
                    utteranceId: id,
                    matchRange: range,
                    context: utterance.text,
                    timestamp: utterance.timestampSeconds
                )
                results.append(result)
            }
        }

        // If we have a model context, search unloaded utterances
        if let context = modelContext {
            let unloadedIds = Set(allUtteranceIds).subtracting(loadedUtterances.keys)

            for id in unloadedIds {
                guard let utterance = await fetchUtterance(id: id, context: context) else { continue }

                if let range = utterance.text.lowercased().range(of: lowercaseQuery) {
                    let result = SearchResult(
                        utteranceId: id,
                        matchRange: range,
                        context: utterance.text,
                        timestamp: utterance.timestampSeconds
                    )
                    results.append(result)
                }
            }
        }

        return results.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - Memory Management

    /// Force unload of utterances outside the current window
    func compactMemory() {
        let windowStart = max(0, centerIndex - configuration.windowSize / 2)
        let windowEnd = min(totalUtteranceCount, centerIndex + configuration.windowSize / 2)
        let windowIds = Set(allUtteranceIds[windowStart..<windowEnd])

        // Remove utterances outside the window
        let keysToRemove = loadedUtterances.keys.filter { !windowIds.contains($0) }
        for key in keysToRemove {
            loadedUtterances.removeValue(forKey: key)
        }

        updateMemoryStats()
    }

    /// Clear all loaded utterances (for session end/reset)
    func reset() {
        prefetchTask?.cancel()
        unloadTask?.cancel()

        allUtteranceIds.removeAll()
        loadedUtterances.removeAll()
        visibleUtterances.removeAll()
        totalUtteranceCount = 0
        centerIndex = 0
        scrollPosition = 1.0
        memoryStats = .zero
    }

    // MARK: - Private Methods

    private func updateVisibleWindow() {
        let halfWindow = configuration.windowSize / 2
        let windowStart = max(0, centerIndex - halfWindow)
        let windowEnd = min(totalUtteranceCount, centerIndex + halfWindow)

        visibleRange = windowStart..<windowEnd

        // Build visible utterances array
        var newVisible: [UtteranceViewModel] = []
        for index in windowStart..<windowEnd {
            let id = allUtteranceIds[index]
            if let utterance = loadedUtterances[id] {
                newVisible.append(utterance)
            } else {
                // Create placeholder or load
                loadUtterance(at: index)
            }
        }

        visibleUtterances = newVisible
    }

    private func loadUtterance(at index: Int) {
        guard index >= 0 && index < allUtteranceIds.count else { return }

        let id = allUtteranceIds[index]
        guard loadedUtterances[id] == nil else { return }

        // If we have model context, fetch from database
        if let context = modelContext {
            Task {
                if let utterance = await fetchUtterance(id: id, context: context) {
                    await MainActor.run {
                        loadedUtterances[id] = utterance
                        updateVisibleWindow()
                    }
                }
            }
        }
    }

    private func fetchUtterance(id: UUID, context: ModelContext) async -> UtteranceViewModel? {
        let predicate = #Predicate<Utterance> { $0.id == id }
        let descriptor = FetchDescriptor<Utterance>(predicate: predicate)

        do {
            let results = try context.fetch(descriptor)
            if let utterance = results.first {
                return UtteranceViewModel(from: utterance)
            }
        } catch {
            // Log error but don't crash
            AppLogger.shared.logData("Failed to fetch utterance: \(error)", level: .error)
        }

        return nil
    }

    private func schedulePrefetch() {
        prefetchTask?.cancel()

        prefetchTask = Task {
            // Small delay to batch rapid scroll events
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

            guard !Task.isCancelled else { return }

            await prefetchAhead()
            await scheduleUnload()
        }
    }

    private func prefetchAhead() async {
        let prefetchStart: Int
        let prefetchEnd: Int

        switch scrollDirection {
        case .down:
            prefetchStart = min(totalUtteranceCount - 1, visibleRange.upperBound)
            prefetchEnd = min(totalUtteranceCount, prefetchStart + configuration.prefetchBuffer)
        case .up:
            prefetchEnd = max(0, visibleRange.lowerBound)
            prefetchStart = max(0, prefetchEnd - configuration.prefetchBuffer)
        }

        for index in prefetchStart..<prefetchEnd {
            guard !Task.isCancelled else { return }
            loadUtterance(at: index)
        }
    }

    private func scheduleUnload() async {
        unloadTask?.cancel()

        unloadTask = Task {
            // Delay unloading to avoid thrashing during rapid scrolling
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms

            guard !Task.isCancelled else { return }

            await MainActor.run {
                compactMemory()
            }
        }
    }

    private func refreshUtteranceIndex() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<Utterance>(
            sortBy: [SortDescriptor(\.timestampSeconds)]
        )

        do {
            let utterances = try context.fetch(descriptor)
            allUtteranceIds = utterances.map { $0.id }
            totalUtteranceCount = allUtteranceIds.count
        } catch {
            AppLogger.shared.logData("Failed to refresh utterance index: \(error)", level: .error)
        }
    }

    private func updateMemoryStats() {
        memoryStats = MemoryStatistics(
            loadedCount: loadedUtterances.count,
            totalCount: totalUtteranceCount,
            estimatedMemoryBytes: loadedUtterances.count * MemoryStatistics.estimatedBytesPerUtterance
        )
    }
}

// MARK: - Supporting Types

/// Scroll direction for prefetch optimization
enum ScrollDirection {
    case up
    case down
}

/// Memory usage statistics
struct MemoryStatistics: Equatable {
    let loadedCount: Int
    let totalCount: Int
    let estimatedMemoryBytes: Int

    static let zero = MemoryStatistics(loadedCount: 0, totalCount: 0, estimatedMemoryBytes: 0)
    static let estimatedBytesPerUtterance = 1024 // ~1KB per utterance estimate

    var loadedPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(loadedCount) / Double(totalCount) * 100
    }

    var formattedMemory: String {
        let kb = estimatedMemoryBytes / 1024
        if kb > 1024 {
            return String(format: "%.1f MB", Double(kb) / 1024.0)
        }
        return "\(kb) KB"
    }
}

/// Search result with match context
struct SearchResult: Identifiable {
    let id = UUID()
    let utteranceId: UUID
    let matchRange: Range<String.Index>
    let context: String
    let timestamp: TimeInterval

    var formattedTimestamp: String {
        TimeFormatting.formatDuration(timestamp)
    }
}

// MARK: - Utterance View Model

/// Lightweight view model for utterances in the transcript
struct UtteranceViewModel: Identifiable, Equatable {
    let id: UUID
    var speaker: Speaker
    let text: String
    let timestampSeconds: TimeInterval
    let confidence: Double?
    let createdAt: Date

    /// Whether speaker was manually corrected
    var wasManuallyEdited: Bool = false

    /// Initialize from SwiftData model
    init(from utterance: Utterance) {
        self.id = utterance.id
        self.speaker = utterance.speaker
        self.text = utterance.text
        self.timestampSeconds = utterance.timestampSeconds
        self.confidence = utterance.confidence
        self.createdAt = utterance.createdAt
    }

    /// Initialize from TranscriptionEvent
    init(from event: TranscriptionEvent, id: UUID = UUID()) {
        self.id = id
        self.speaker = event.speaker ?? .unknown
        self.text = event.text
        self.timestampSeconds = event.timestamp
        self.confidence = event.confidence
        self.createdAt = Date()
    }

    /// Formatted timestamp string (MM:SS or HH:MM:SS for long sessions)
    var formattedTimestamp: String {
        TimeFormatting.formatDuration(timestampSeconds)
    }

    /// Long formatted timestamp string (HH:MM:SS)
    var formattedTimestampLong: String {
        TimeFormatting.formatDuration(timestampSeconds)
    }

    /// Whether this utterance has high confidence
    var hasHighConfidence: Bool {
        guard let confidence = confidence else { return true }
        return confidence >= 0.8
    }

    /// Word count in the utterance
    var wordCount: Int {
        text.split(separator: " ").count
    }

    /// Create a copy with updated speaker
    func withSpeaker(_ newSpeaker: Speaker) -> UtteranceViewModel {
        var copy = self
        copy.speaker = newSpeaker
        copy.wasManuallyEdited = true
        return copy
    }
}
