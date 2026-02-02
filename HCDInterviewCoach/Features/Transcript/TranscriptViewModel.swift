//
//  TranscriptViewModel.swift
//  HCDInterviewCoach
//
//  EPIC E5: Transcript Display
//  View model that consumes transcriptionStream and manages transcript state
//

import Foundation
import Combine
import SwiftData

// MARK: - Transcript View Model

/// Main view model for the transcript display.
/// Consumes transcriptionStream from SessionManager and coordinates with virtualization manager.
@MainActor
final class TranscriptViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current filter for speaker (nil = show all)
    @Published var speakerFilter: Speaker?

    /// Current search query
    @Published var searchQuery: String = ""

    /// Search results
    @Published private(set) var searchResults: [SearchResult] = []

    /// Currently highlighted search result index
    @Published var currentSearchResultIndex: Int = 0

    /// Whether search is active
    @Published var isSearchActive: Bool = false

    /// Whether auto-scroll is enabled
    @Published var isAutoScrollEnabled: Bool = true

    /// Currently selected utterance (for details/editing)
    @Published var selectedUtteranceId: UUID?

    /// Whether transcript is empty
    @Published private(set) var isEmpty: Bool = true

    /// Connection status message
    @Published private(set) var statusMessage: String = "Waiting for session..."

    /// Whether currently processing transcription events
    @Published private(set) var isProcessing: Bool = false

    /// Error message if any
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    /// Virtualization manager for memory-efficient display
    let virtualizationManager: TranscriptVirtualizationManager

    /// Reference to session manager
    private weak var sessionManager: SessionManager?

    /// Data manager for persistence
    private let dataManager: DataManager

    // MARK: - Private Properties

    private var transcriptionTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    /// Pending utterance being built from partial transcriptions
    private var pendingUtterance: PendingUtterance?

    // MARK: - Callbacks

    /// Called when an utterance is flagged as an insight
    var onInsightFlagged: ((UtteranceViewModel) -> Void)?

    // MARK: - Initialization

    init(
        sessionManager: SessionManager? = nil,
        virtualizationManager: TranscriptVirtualizationManager = TranscriptVirtualizationManager(),
        dataManager: DataManager = .shared
    ) {
        self.sessionManager = sessionManager
        self.virtualizationManager = virtualizationManager
        self.dataManager = dataManager

        setupBindings()
    }

    deinit {
        transcriptionTask?.cancel()
        searchTask?.cancel()
    }

    // MARK: - Setup

    /// Connect to a session manager and start consuming transcription events
    /// - Parameter sessionManager: The session manager to observe
    func connect(to sessionManager: SessionManager) {
        self.sessionManager = sessionManager

        // Load existing utterances from session
        if let session = sessionManager.currentSession {
            virtualizationManager.setup(with: session)
            isEmpty = session.utterances.isEmpty
            statusMessage = isEmpty ? "No transcription yet" : "Loaded \(session.utterances.count) utterances"
        }

        // Start consuming transcription stream
        startTranscriptionConsumer()
    }

    /// Disconnect from the session manager
    func disconnect() {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        sessionManager = nil
        statusMessage = "Disconnected"
    }

    // MARK: - Transcription Handling

    private func startTranscriptionConsumer() {
        guard let sessionManager = sessionManager else { return }

        transcriptionTask?.cancel()

        transcriptionTask = Task { [weak self] in
            for await event in sessionManager.transcriptionStream {
                guard let self = self else { return }
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.handleTranscriptionEvent(event)
                }
            }
        }

        statusMessage = "Listening for transcription..."
    }

    private func handleTranscriptionEvent(_ event: TranscriptionEvent) {
        isProcessing = true
        defer { isProcessing = false }

        if event.isFinal {
            // Final transcription - create utterance
            finalizePendingUtterance()

            let viewModel = UtteranceViewModel(from: event)
            addUtterance(viewModel)

            // Persist to SwiftData
            if let session = sessionManager?.currentSession {
                persistUtterance(viewModel, to: session)
            }

            statusMessage = "Transcribing..."
        } else {
            // Partial transcription - update pending
            updatePendingUtterance(with: event)
        }
    }

    private func updatePendingUtterance(with event: TranscriptionEvent) {
        if pendingUtterance == nil {
            pendingUtterance = PendingUtterance(
                speaker: event.speaker ?? .unknown,
                timestamp: event.timestamp
            )
        }
        pendingUtterance?.text = event.text
    }

    private func finalizePendingUtterance() {
        pendingUtterance = nil
    }

    // MARK: - Utterance Management

    private func addUtterance(_ utterance: UtteranceViewModel) {
        virtualizationManager.addUtterance(utterance)
        isEmpty = false

        // Auto-scroll if enabled
        if isAutoScrollEnabled {
            virtualizationManager.scrollToEnd()
        }
    }

    /// Update speaker for an utterance (manual correction)
    /// - Parameters:
    ///   - id: Utterance ID
    ///   - speaker: New speaker value
    func updateSpeaker(for id: UUID, to speaker: Speaker) {
        guard var utterance = virtualizationManager.getUtterance(id) else { return }

        utterance = utterance.withSpeaker(speaker)
        virtualizationManager.updateUtterance(utterance)

        // Persist the change
        updateUtteranceInDatabase(id: id, speaker: speaker)
    }

    /// Toggle speaker between interviewer and participant
    /// - Parameter id: Utterance ID
    func toggleSpeaker(for id: UUID) {
        guard let utterance = virtualizationManager.getUtterance(id) else { return }

        let newSpeaker: Speaker = switch utterance.speaker {
        case .interviewer: .participant
        case .participant: .interviewer
        case .unknown: .interviewer
        }

        updateSpeaker(for: id, to: newSpeaker)
    }

    /// Flag an utterance as an insight
    /// - Parameter id: Utterance ID to flag
    func flagAsInsight(_ id: UUID) {
        guard let utterance = virtualizationManager.getUtterance(id) else { return }
        onInsightFlagged?(utterance)
    }

    // MARK: - Search

    /// Perform search with current query
    func performSearch() {
        guard !searchQuery.isEmpty else {
            clearSearch()
            return
        }

        isSearchActive = true
        searchTask?.cancel()

        searchTask = Task { [weak self] in
            guard let self = self else { return }

            let results = await self.virtualizationManager.search(for: self.searchQuery)

            await MainActor.run {
                self.searchResults = results
                self.currentSearchResultIndex = 0

                if !results.isEmpty {
                    // Navigate to first result
                    self.navigateToSearchResult(at: 0)
                }
            }
        }
    }

    /// Clear search and reset state
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        currentSearchResultIndex = 0
        isSearchActive = false
        selectedUtteranceId = nil
    }

    /// Navigate to next search result
    func nextSearchResult() {
        guard !searchResults.isEmpty else { return }

        currentSearchResultIndex = (currentSearchResultIndex + 1) % searchResults.count
        navigateToSearchResult(at: currentSearchResultIndex)
    }

    /// Navigate to previous search result
    func previousSearchResult() {
        guard !searchResults.isEmpty else { return }

        currentSearchResultIndex = currentSearchResultIndex > 0
            ? currentSearchResultIndex - 1
            : searchResults.count - 1
        navigateToSearchResult(at: currentSearchResultIndex)
    }

    /// Navigate to a specific search result
    /// - Parameter index: Result index
    func navigateToSearchResult(at index: Int) {
        guard index >= 0 && index < searchResults.count else { return }

        let result = searchResults[index]
        selectedUtteranceId = result.utteranceId

        // Scroll to the utterance
        _ = virtualizationManager.scrollToUtterance(result.utteranceId)
    }

    // MARK: - Filtering

    /// Filter utterances by speaker
    /// - Parameter speaker: Speaker to filter by (nil for all)
    func filterBySpeaker(_ speaker: Speaker?) {
        speakerFilter = speaker
    }

    /// Get filtered utterances
    var filteredUtterances: [UtteranceViewModel] {
        let utterances = virtualizationManager.visibleUtterances

        guard let filter = speakerFilter else {
            return utterances
        }

        return utterances.filter { $0.speaker == filter }
    }

    // MARK: - Navigation

    /// Scroll to a specific timestamp
    /// - Parameter timestamp: Time in seconds from session start
    func scrollToTimestamp(_ timestamp: TimeInterval) {
        // Find the utterance closest to this timestamp
        let utterances = virtualizationManager.visibleUtterances
        let closest = utterances.min { abs($0.timestampSeconds - timestamp) < abs($1.timestampSeconds - timestamp) }

        if let closest = closest {
            selectedUtteranceId = closest.id
            _ = virtualizationManager.scrollToUtterance(closest.id)
        }
    }

    /// Jump to the end of the transcript
    func jumpToEnd() {
        virtualizationManager.scrollToEnd()
        isAutoScrollEnabled = true
    }

    /// Jump to the beginning of the transcript
    func jumpToStart() {
        if let firstId = virtualizationManager.visibleUtterances.first?.id {
            _ = virtualizationManager.scrollToUtterance(firstId)
        }
        isAutoScrollEnabled = false
    }

    // MARK: - Persistence

    private func persistUtterance(_ viewModel: UtteranceViewModel, to session: Session) {
        let utterance = Utterance(
            id: viewModel.id,
            speaker: viewModel.speaker,
            text: viewModel.text,
            timestampSeconds: viewModel.timestampSeconds,
            confidence: viewModel.confidence,
            createdAt: viewModel.createdAt
        )
        utterance.session = session

        dataManager.mainContext.insert(utterance)

        do {
            try dataManager.save()
        } catch {
            errorMessage = "Failed to save utterance: \(error.localizedDescription)"
        }
    }

    private func updateUtteranceInDatabase(id: UUID, speaker: Speaker) {
        let predicate = #Predicate<Utterance> { $0.id == id }
        let descriptor = FetchDescriptor<Utterance>(predicate: predicate)

        do {
            let results = try dataManager.mainContext.fetch(descriptor)
            if let utterance = results.first {
                utterance.speaker = speaker
                try dataManager.save()
            }
        } catch {
            errorMessage = "Failed to update speaker: \(error.localizedDescription)"
        }
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Debounced search
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.performSearch()
                } else {
                    self?.clearSearch()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Export

    /// Export transcript as plain text
    /// - Returns: Plain text transcript
    func exportAsText() -> String {
        var output = ""

        for utterance in virtualizationManager.visibleUtterances {
            output += "[\(utterance.formattedTimestamp)] \(utterance.speaker.displayName): \(utterance.text)\n\n"
        }

        return output
    }

    /// Get transcript statistics
    var statistics: TranscriptStatistics {
        let utterances = virtualizationManager.visibleUtterances

        let interviewerCount = utterances.filter { $0.speaker == .interviewer }.count
        let participantCount = utterances.filter { $0.speaker == .participant }.count
        let totalWords = utterances.reduce(0) { $0 + $1.wordCount }

        let duration = utterances.last?.timestampSeconds ?? 0

        return TranscriptStatistics(
            totalUtterances: utterances.count,
            interviewerUtterances: interviewerCount,
            participantUtterances: participantCount,
            totalWords: totalWords,
            durationSeconds: duration
        )
    }
}

// MARK: - Supporting Types

/// Pending partial utterance being built
private struct PendingUtterance {
    var speaker: Speaker
    var text: String = ""
    let timestamp: TimeInterval
}

/// Transcript statistics for display
struct TranscriptStatistics {
    let totalUtterances: Int
    let interviewerUtterances: Int
    let participantUtterances: Int
    let totalWords: Int
    let durationSeconds: TimeInterval

    var participationRatio: String {
        guard totalUtterances > 0 else { return "N/A" }

        let interviewerPct = Double(interviewerUtterances) / Double(totalUtterances) * 100
        let participantPct = Double(participantUtterances) / Double(totalUtterances) * 100

        return String(format: "%.0f%% / %.0f%%", interviewerPct, participantPct)
    }

    var formattedDuration: String {
        TimeFormatting.formatDuration(durationSeconds)
    }
}
