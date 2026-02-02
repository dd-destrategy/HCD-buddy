//
//  InsightNavigator.swift
//  HCDInterviewCoach
//
//  EPIC E8: Insight Flagging
//  Service for navigating to transcript locations from insights
//

import Foundation
import Combine
import SwiftUI

// MARK: - Insight Navigator

/// Service responsible for navigating to transcript locations when an insight is selected.
/// Coordinates between the insights panel and the transcript view.
///
/// Features:
/// - Find nearest utterance to insight timestamp
/// - Scroll transcript to utterance location
/// - Highlight the relevant utterance
/// - Support for audio playback seeking (future)
@MainActor
final class InsightNavigator: ObservableObject {

    // MARK: - Published Properties

    /// The currently highlighted utterance (after navigation)
    @Published private(set) var highlightedUtterance: Utterance?

    /// The target timestamp being navigated to
    @Published private(set) var targetTimestamp: Double?

    /// Whether navigation is in progress
    @Published private(set) var isNavigating: Bool = false

    /// Navigation result for UI feedback
    @Published private(set) var lastNavigationResult: NavigationResult?

    // MARK: - Dependencies

    private weak var session: Session?
    private var cancellables = Set<AnyCancellable>()

    /// Callback invoked when navigation should scroll to an utterance
    var onScrollToUtterance: ((Utterance, Bool) -> Void)?

    /// Callback invoked when a timestamp should be seeked to in audio
    var onSeekToTimestamp: ((Double) -> Void)?

    // MARK: - Configuration

    /// Maximum time difference (in seconds) to consider an utterance as matching
    private let maxTimeDifferenceForMatch: Double = 5.0

    /// Duration to highlight the utterance after navigation
    private let highlightDuration: TimeInterval = 3.0

    // MARK: - Initialization

    /// Creates a new InsightNavigator
    /// - Parameter session: The current session containing utterances
    init(session: Session?) {
        self.session = session
    }

    // MARK: - Public Methods

    /// Navigates to the transcript location for an insight
    /// - Parameters:
    ///   - insight: The insight to navigate to
    ///   - animated: Whether to animate the scroll
    /// - Returns: The result of the navigation attempt
    @discardableResult
    func navigate(to insight: Insight, animated: Bool = true) -> NavigationResult {
        isNavigating = true
        targetTimestamp = insight.timestampSeconds

        defer {
            isNavigating = false
            targetTimestamp = nil
        }

        // Find the utterance closest to the insight timestamp
        guard let utterance = findNearestUtterance(to: insight.timestampSeconds) else {
            let result = NavigationResult.utteranceNotFound(timestamp: insight.timestampSeconds)
            lastNavigationResult = result
            AppLogger.shared.warning("No utterance found near timestamp \(insight.formattedTimestamp)")
            return result
        }

        // Calculate the time difference
        let timeDifference = abs(utterance.timestampSeconds - insight.timestampSeconds)

        // Check if the match is close enough
        if timeDifference > maxTimeDifferenceForMatch {
            let result = NavigationResult.approximateMatch(utterance: utterance, timeDifference: timeDifference)
            performNavigation(to: utterance, animated: animated)
            lastNavigationResult = result
            return result
        }

        // Exact or close match
        performNavigation(to: utterance, animated: animated)
        let result = NavigationResult.success(utterance: utterance)
        lastNavigationResult = result

        AppLogger.shared.info("Navigated to utterance at \(utterance.formattedTimestamp)")
        return result
    }

    /// Navigates to a specific timestamp
    /// - Parameters:
    ///   - timestamp: The timestamp in seconds
    ///   - animated: Whether to animate the scroll
    /// - Returns: The result of the navigation attempt
    @discardableResult
    func navigate(to timestamp: Double, animated: Bool = true) -> NavigationResult {
        isNavigating = true
        targetTimestamp = timestamp

        defer {
            isNavigating = false
            targetTimestamp = nil
        }

        guard let utterance = findNearestUtterance(to: timestamp) else {
            let result = NavigationResult.utteranceNotFound(timestamp: timestamp)
            lastNavigationResult = result
            return result
        }

        performNavigation(to: utterance, animated: animated)
        let result = NavigationResult.success(utterance: utterance)
        lastNavigationResult = result
        return result
    }

    /// Navigates to a specific utterance
    /// - Parameters:
    ///   - utterance: The utterance to navigate to
    ///   - animated: Whether to animate the scroll
    func navigate(to utterance: Utterance, animated: Bool = true) {
        performNavigation(to: utterance, animated: animated)
        lastNavigationResult = .success(utterance: utterance)
    }

    /// Clears the current highlight
    func clearHighlight() {
        highlightedUtterance = nil
    }

    /// Finds the nearest insight to a given timestamp
    /// - Parameter timestamp: The timestamp to search near
    /// - Returns: The nearest insight, if any
    func findNearestInsight(to timestamp: Double) -> Insight? {
        guard let session = session else { return nil }
        return session.insights.min { abs($0.timestampSeconds - timestamp) < abs($1.timestampSeconds - timestamp) }
    }

    /// Checks if there are insights near a given timestamp
    /// - Parameters:
    ///   - timestamp: The timestamp to check
    ///   - tolerance: The maximum time difference to consider "near"
    /// - Returns: True if there are insights within the tolerance
    func hasInsightsNear(_ timestamp: Double, tolerance: Double = 10.0) -> Bool {
        guard let session = session else { return false }
        return session.insights.contains { abs($0.timestampSeconds - timestamp) <= tolerance }
    }

    // MARK: - Private Methods

    private func findNearestUtterance(to timestamp: Double) -> Utterance? {
        guard let session = session, !session.utterances.isEmpty else { return nil }

        // Find the utterance with the closest timestamp
        return session.utterances.min { abs($0.timestampSeconds - timestamp) < abs($1.timestampSeconds - timestamp) }
    }

    private func performNavigation(to utterance: Utterance, animated: Bool) {
        // Set the highlight
        highlightedUtterance = utterance

        // Trigger scroll callback
        onScrollToUtterance?(utterance, animated)

        // Optionally seek audio
        onSeekToTimestamp?(utterance.timestampSeconds)

        // Clear highlight after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + highlightDuration) { [weak self] in
            if self?.highlightedUtterance?.id == utterance.id {
                self?.highlightedUtterance = nil
            }
        }
    }
}

// MARK: - Navigation Result

/// Result of a navigation attempt
enum NavigationResult: Equatable {
    /// Successfully navigated to the exact or near utterance
    case success(utterance: Utterance)

    /// Found an utterance but it's not a close match
    case approximateMatch(utterance: Utterance, timeDifference: Double)

    /// No utterance found near the target timestamp
    case utteranceNotFound(timestamp: Double)

    /// Whether the navigation was successful (found an utterance to navigate to)
    var isSuccess: Bool {
        switch self {
        case .success, .approximateMatch:
            return true
        case .utteranceNotFound:
            return false
        }
    }

    /// The utterance that was navigated to (if any)
    var utterance: Utterance? {
        switch self {
        case .success(let utterance), .approximateMatch(let utterance, _):
            return utterance
        case .utteranceNotFound:
            return nil
        }
    }

    /// Human-readable description of the result
    var description: String {
        switch self {
        case .success(let utterance):
            return "Navigated to utterance at \(utterance.formattedTimestamp)"
        case .approximateMatch(let utterance, let difference):
            let formatted = String(format: "%.1f", difference)
            return "Found approximate match at \(utterance.formattedTimestamp) (\(formatted)s away)"
        case .utteranceNotFound(let timestamp):
            let minutes = Int(timestamp) / 60
            let seconds = Int(timestamp) % 60
            let formatted = String(format: "%02d:%02d", minutes, seconds)
            return "No utterance found near \(formatted)"
        }
    }

    // Equatable
    static func == (lhs: NavigationResult, rhs: NavigationResult) -> Bool {
        switch (lhs, rhs) {
        case (.success(let u1), .success(let u2)):
            return u1.id == u2.id
        case (.approximateMatch(let u1, let d1), .approximateMatch(let u2, let d2)):
            return u1.id == u2.id && d1 == d2
        case (.utteranceNotFound(let t1), .utteranceNotFound(let t2)):
            return t1 == t2
        default:
            return false
        }
    }
}

// MARK: - Transcript Scroll Request

/// Represents a request to scroll the transcript to a specific location
struct TranscriptScrollRequest: Identifiable {
    let id = UUID()
    let utterance: Utterance
    let animated: Bool
    let highlight: Bool
    let highlightDuration: TimeInterval

    init(
        utterance: Utterance,
        animated: Bool = true,
        highlight: Bool = true,
        highlightDuration: TimeInterval = 3.0
    ) {
        self.utterance = utterance
        self.animated = animated
        self.highlight = highlight
        self.highlightDuration = highlightDuration
    }
}

// MARK: - Navigation Coordinator

/// Coordinates navigation between different parts of the UI
/// Acts as a central hub for navigation requests
@MainActor
final class InsightNavigationCoordinator: ObservableObject {

    // MARK: - Published Properties

    /// Current scroll request for the transcript
    @Published var transcriptScrollRequest: TranscriptScrollRequest?

    /// Currently highlighted insight in the insights panel
    @Published var highlightedInsightId: UUID?

    /// Currently highlighted utterance in the transcript
    @Published var highlightedUtteranceId: UUID?

    // MARK: - Singleton

    static let shared = InsightNavigationCoordinator()

    private init() {}

    // MARK: - Public Methods

    /// Requests navigation to an insight's transcript location
    /// - Parameters:
    ///   - insight: The insight to navigate to
    ///   - utterances: Available utterances to search
    ///   - animated: Whether to animate
    func navigateToInsight(_ insight: Insight, utterances: [Utterance], animated: Bool = true) {
        // Find nearest utterance
        guard let utterance = utterances.min(by: {
            abs($0.timestampSeconds - insight.timestampSeconds) < abs($1.timestampSeconds - insight.timestampSeconds)
        }) else { return }

        transcriptScrollRequest = TranscriptScrollRequest(
            utterance: utterance,
            animated: animated,
            highlight: true
        )

        highlightedUtteranceId = utterance.id

        // Clear highlight after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            if self?.highlightedUtteranceId == utterance.id {
                self?.highlightedUtteranceId = nil
            }
        }
    }

    /// Requests navigation to a specific utterance
    /// - Parameters:
    ///   - utterance: The utterance to navigate to
    ///   - animated: Whether to animate
    func navigateToUtterance(_ utterance: Utterance, animated: Bool = true) {
        transcriptScrollRequest = TranscriptScrollRequest(
            utterance: utterance,
            animated: animated,
            highlight: true
        )

        highlightedUtteranceId = utterance.id

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            if self?.highlightedUtteranceId == utterance.id {
                self?.highlightedUtteranceId = nil
            }
        }
    }

    /// Highlights an insight in the insights panel
    /// - Parameter insight: The insight to highlight
    func highlightInsight(_ insight: Insight) {
        highlightedInsightId = insight.id

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            if self?.highlightedInsightId == insight.id {
                self?.highlightedInsightId = nil
            }
        }
    }

    /// Clears all navigation highlights
    func clearHighlights() {
        transcriptScrollRequest = nil
        highlightedInsightId = nil
        highlightedUtteranceId = nil
    }
}

// MARK: - View Extension for Navigation

extension View {

    /// Applies highlight styling when the utterance is being navigated to
    func insightNavigationHighlight(
        utteranceId: UUID,
        highlightedId: UUID?,
        highlightColor: Color = Color.hcdInsightHighlight
    ) -> some View {
        self
            .background(
                utteranceId == highlightedId ? highlightColor : Color.clear
            )
            .animation(.easeInOut(duration: 0.3), value: utteranceId == highlightedId)
    }
}

// MARK: - Insight Navigator Factory

/// Factory for creating InsightNavigator instances
@MainActor
struct InsightNavigatorFactory {

    /// Creates a navigator for the given session
    static func create(for session: Session?) -> InsightNavigator {
        InsightNavigator(session: session)
    }
}
