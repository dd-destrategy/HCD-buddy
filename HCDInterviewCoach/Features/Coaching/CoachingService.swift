//
//  CoachingService.swift
//  HCD Interview Coach
//
//  EPIC E6: Coaching Engine
//  Main coaching logic implementing silence-first philosophy
//

import Foundation
import Combine

// MARK: - Coaching Prompt

/// Represents a coaching prompt to be displayed to the user
struct CoachingPrompt: Identifiable, Equatable {
    let id: UUID
    let type: CoachingFunctionType
    let text: String
    let reason: String
    let confidence: Double
    let timestamp: TimeInterval
    let createdAt: Date

    init(
        id: UUID = UUID(),
        type: CoachingFunctionType,
        text: String,
        reason: String,
        confidence: Double,
        timestamp: TimeInterval,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.reason = reason
        self.confidence = confidence
        self.timestamp = timestamp
        self.createdAt = createdAt
    }
}

// MARK: - Coaching Service

/// Main coaching service implementing silence-first philosophy.
///
/// Core Rules:
/// - DEFAULT OFF for first session - user must explicitly enable
/// - Minimum 85% confidence before showing prompt
/// - 2-minute cooldown between prompts
/// - Wait 5 seconds after any speech before showing
/// - Maximum 3 prompts per session
/// - Auto-dismiss after 8 seconds
@MainActor
final class CoachingService: ObservableObject {

    // MARK: - Published Properties

    /// Currently displayed coaching prompt (nil if none)
    @Published private(set) var currentPrompt: CoachingPrompt?

    /// Whether coaching is enabled for this session
    @Published var isEnabled: Bool = false

    /// Queue of pending prompts (processed in order)
    @Published private(set) var pendingPrompts: [CoachingPrompt] = []

    /// Current session timestamp (updated externally)
    @Published var currentTimestamp: TimeInterval = 0

    // MARK: - Public Properties

    /// Number of prompts shown in the current session
    var promptCount: Int {
        eventTracker.sessionStats.promptsShown
    }

    /// Whether we've reached the maximum prompts for this session
    var hasReachedMaxPrompts: Bool {
        promptCount >= thresholds.maxPromptsPerSession
    }

    /// Whether a prompt is currently being displayed
    var isShowingPrompt: Bool {
        currentPrompt != nil
    }

    /// Time until cooldown expires (0 if not in cooldown)
    var cooldownRemaining: TimeInterval {
        guard let lastPromptTime = lastPromptTime else { return 0 }
        let elapsed = Date().timeIntervalSince(lastPromptTime)
        return max(0, thresholds.effectiveCooldown - elapsed)
    }

    /// Whether we're currently in cooldown period
    var isInCooldown: Bool {
        cooldownRemaining > 0
    }

    // MARK: - Dependencies

    private let preferences: CoachingPreferences
    private let eventTracker: CoachingEventTracker
    private weak var session: Session?

    // MARK: - Private State

    private var thresholds: CoachingThresholds
    private var lastPromptTime: Date?
    private var lastSpeechTime: Date?
    private var autoDismissTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        preferences: CoachingPreferences = .shared,
        eventTracker: CoachingEventTracker = CoachingEventTracker()
    ) {
        self.preferences = preferences
        self.eventTracker = eventTracker
        self.thresholds = preferences.effectiveThresholds

        setupPreferencesBinding()
    }

    // MARK: - Session Lifecycle

    /// Start coaching for a new session
    /// - Parameter session: The session to track
    func startSession(_ session: Session) {
        self.session = session
        eventTracker.startSession(session)

        // Reset state
        currentPrompt = nil
        pendingPrompts.removeAll()
        lastPromptTime = nil
        lastSpeechTime = nil
        currentTimestamp = 0

        // SILENCE-FIRST: Check if coaching should be active
        isEnabled = preferences.shouldShowCoaching

        // Get adaptive thresholds based on user history
        thresholds = eventTracker.getAdaptiveThresholds()

        AppLogger.shared.info(
            """
            CoachingService started:
            - Enabled: \(isEnabled)
            - Level: \(preferences.coachingLevel.displayName)
            - Max prompts: \(thresholds.maxPromptsPerSession)
            - Confidence threshold: \(String(format: "%.0f%%", thresholds.minimumConfidence * 100))
            """
        )
    }

    /// End the current coaching session
    func endSession() {
        // Cancel any pending auto-dismiss
        autoDismissTask?.cancel()
        autoDismissTask = nil

        // Dismiss current prompt without recording (session ending)
        currentPrompt = nil

        // End tracking
        eventTracker.endSession()

        // Reset state
        pendingPrompts.removeAll()
        session = nil

        AppLogger.shared.info("CoachingService ended session")
    }

    // MARK: - Public Interface

    /// Enable coaching for the current session
    func enable() {
        guard !isEnabled else { return }

        isEnabled = true
        preferences.isCoachingEnabled = true
        AppLogger.shared.info("Coaching enabled")

        // Process any pending prompts
        processNextPendingPrompt()
    }

    /// Disable coaching for the current session
    func disable() {
        guard isEnabled else { return }

        isEnabled = false
        preferences.isCoachingEnabled = false

        // Clear current prompt
        if currentPrompt != nil {
            dismiss()
        }

        // Clear pending prompts
        pendingPrompts.removeAll()

        AppLogger.shared.info("Coaching disabled")
    }

    /// Dismiss the current prompt
    /// - Parameter response: The user's response (default: dismissed)
    func dismiss(response: CoachingResponse = .dismissed) {
        guard let prompt = currentPrompt else { return }

        // Cancel auto-dismiss timer
        autoDismissTask?.cancel()
        autoDismissTask = nil

        // Record response
        eventTracker.recordResponse(response, for: prompt.id)

        // Clear prompt with animation delay
        currentPrompt = nil

        AppLogger.shared.info("Prompt dismissed with response: \(response.displayName)")

        // Process next pending prompt after brief delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await processNextPendingPrompt()
        }
    }

    /// Accept the current prompt
    func accept() {
        dismiss(response: .accepted)
    }

    /// Snooze the current prompt (extends cooldown)
    func snooze() {
        // Extend the cooldown period
        lastPromptTime = Date()
        dismiss(response: .snoozed)
    }

    /// Process a function call event from the AI
    /// - Parameter event: The function call event containing coaching data
    func processFunctionCall(_ event: FunctionCallEvent) {
        // SILENCE-FIRST: Check if coaching is active
        guard isEnabled else {
            AppLogger.shared.debug("Coaching disabled, ignoring function call: \(event.name)")
            return
        }

        // Parse the function call
        guard let prompt = parsePromptFromFunctionCall(event) else {
            AppLogger.shared.warning("Could not parse coaching prompt from function call: \(event.name)")
            return
        }

        // Validate and potentially queue the prompt
        queuePrompt(prompt)
    }

    /// Notify the service that speech was detected
    func notifySpeechDetected() {
        lastSpeechTime = Date()
    }

    /// Update the current session timestamp
    func updateTimestamp(_ timestamp: TimeInterval) {
        currentTimestamp = timestamp
    }

    // MARK: - Private Methods

    private func setupPreferencesBinding() {
        preferences.$coachingLevel
            .sink { [weak self] _ in
                self?.thresholds = self?.preferences.effectiveThresholds ?? .default
            }
            .store(in: &cancellables)

        preferences.$customSensitivity
            .sink { [weak self] _ in
                self?.thresholds = self?.preferences.effectiveThresholds ?? .default
            }
            .store(in: &cancellables)
    }

    private func parsePromptFromFunctionCall(_ event: FunctionCallEvent) -> CoachingPrompt? {
        // Determine prompt type from function name
        guard let type = CoachingFunctionType(rawValue: event.name) else {
            // Try to infer type from name
            let inferredType = inferPromptType(from: event.name)
            guard inferredType != nil else {
                AppLogger.shared.debug("Unknown function type: \(event.name)")
                return nil
            }
            return createPrompt(
                type: inferredType!,
                arguments: event.arguments,
                timestamp: event.timestamp
            )
        }

        return createPrompt(type: type, arguments: event.arguments, timestamp: event.timestamp)
    }

    private func inferPromptType(from name: String) -> CoachingFunctionType? {
        let lowercased = name.lowercased()

        if lowercased.contains("follow") || lowercased.contains("question") {
            return .suggestFollowUp
        } else if lowercased.contains("deep") || lowercased.contains("explore") {
            return .exploreDeeper
        } else if lowercased.contains("topic") || lowercased.contains("uncovered") {
            return .uncoveredTopic
        } else if lowercased.contains("pivot") || lowercased.contains("redirect") {
            return .suggestPivot
        } else if lowercased.contains("encourage") || lowercased.contains("good") {
            return .encouragement
        } else if lowercased.contains("tip") || lowercased.contains("hint") {
            return .generalTip
        }

        return nil
    }

    private func createPrompt(
        type: CoachingFunctionType,
        arguments: [String: String],
        timestamp: TimeInterval
    ) -> CoachingPrompt {
        let text = arguments["text"] ?? arguments["prompt"] ?? arguments["message"] ?? "Consider this approach..."
        let reason = arguments["reason"] ?? arguments["context"] ?? ""
        let confidenceString = arguments["confidence"] ?? "0.85"
        let confidence = Double(confidenceString) ?? 0.85

        return CoachingPrompt(
            type: type,
            text: text,
            reason: reason,
            confidence: confidence,
            timestamp: timestamp
        )
    }

    private func queuePrompt(_ prompt: CoachingPrompt) {
        // Validate against thresholds
        guard validatePrompt(prompt) else {
            AppLogger.shared.debug("Prompt failed validation: \(prompt.type.displayName)")
            return
        }

        // Check if we can show immediately
        if canShowPromptNow() {
            showPrompt(prompt)
        } else {
            // Queue for later
            pendingPrompts.append(prompt)
            sortPendingPrompts()
            AppLogger.shared.debug("Prompt queued: \(prompt.type.displayName), queue size: \(pendingPrompts.count)")
        }
    }

    private func validatePrompt(_ prompt: CoachingPrompt) -> Bool {
        // RULE: Maximum prompts per session
        if hasReachedMaxPrompts {
            AppLogger.shared.debug("Max prompts reached (\(thresholds.maxPromptsPerSession))")
            return false
        }

        // RULE: Minimum confidence threshold
        if prompt.confidence < thresholds.effectiveConfidenceThreshold {
            AppLogger.shared.debug(
                "Confidence too low: \(String(format: "%.0f%%", prompt.confidence * 100)) < \(String(format: "%.0f%%", thresholds.effectiveConfidenceThreshold * 100))"
            )
            return false
        }

        return true
    }

    private func canShowPromptNow() -> Bool {
        // Already showing a prompt
        if currentPrompt != nil {
            return false
        }

        // RULE: 2-minute cooldown between prompts
        if isInCooldown {
            AppLogger.shared.debug("In cooldown: \(String(format: "%.0f", cooldownRemaining))s remaining")
            return false
        }

        // RULE: Wait 5 seconds after speech
        if let lastSpeech = lastSpeechTime {
            let timeSinceSpeech = Date().timeIntervalSince(lastSpeech)
            if timeSinceSpeech < thresholds.speechCooldown {
                AppLogger.shared.debug(
                    "Speech cooldown: \(String(format: "%.1f", thresholds.speechCooldown - timeSinceSpeech))s remaining"
                )
                return false
            }
        }

        return true
    }

    private func showPrompt(_ prompt: CoachingPrompt) {
        // Record the prompt
        eventTracker.recordPromptShown(prompt, at: currentTimestamp)

        // Update state
        lastPromptTime = Date()
        currentPrompt = prompt

        AppLogger.shared.info(
            """
            Showing prompt:
            - Type: \(prompt.type.displayName)
            - Confidence: \(String(format: "%.0f%%", prompt.confidence * 100))
            - Text: \(prompt.text.prefix(50))...
            """
        )

        // Start auto-dismiss timer
        startAutoDismissTimer()
    }

    private func startAutoDismissTimer() {
        autoDismissTask?.cancel()

        let duration = preferences.customAutoDismissDuration ?? thresholds.autoDismissDuration

        autoDismissTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

                await MainActor.run {
                    guard let self = self, self.currentPrompt != nil else { return }

                    // Auto-dismiss
                    if let prompt = self.currentPrompt {
                        self.eventTracker.recordAutoDismiss(for: prompt.id)
                    }
                    self.currentPrompt = nil

                    AppLogger.shared.info("Prompt auto-dismissed after \(duration)s")

                    // Process next pending prompt
                    self.processNextPendingPrompt()
                }
            } catch {
                // Task was cancelled, no action needed
            }
        }
    }

    private func processNextPendingPrompt() {
        guard isEnabled else { return }
        guard !pendingPrompts.isEmpty else { return }
        guard canShowPromptNow() else {
            // Schedule retry
            scheduleRetry()
            return
        }

        // Get highest priority prompt
        let prompt = pendingPrompts.removeFirst()

        // Re-validate (conditions may have changed)
        if validatePrompt(prompt) {
            showPrompt(prompt)
        } else {
            // Try next prompt
            processNextPendingPrompt()
        }
    }

    private func sortPendingPrompts() {
        // Sort by priority (lower = higher priority), then by timestamp
        pendingPrompts.sort { a, b in
            if a.type.priority != b.type.priority {
                return a.type.priority < b.type.priority
            }
            return a.timestamp < b.timestamp
        }
    }

    private func scheduleRetry() {
        // Calculate when we can next show a prompt
        var delay: TimeInterval = 1.0

        if isInCooldown {
            delay = max(delay, cooldownRemaining + 0.5)
        }

        if let lastSpeech = lastSpeechTime {
            let speechDelay = thresholds.speechCooldown - Date().timeIntervalSince(lastSpeech)
            if speechDelay > 0 {
                delay = max(delay, speechDelay + 0.5)
            }
        }

        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await processNextPendingPrompt()
        }
    }
}

// MARK: - Coaching Service Factory

/// Factory for creating coaching service instances
struct CoachingServiceFactory {

    /// Creates a production coaching service
    static func createProduction() -> CoachingService {
        return CoachingService()
    }

    /// Creates a coaching service for testing with custom dependencies
    static func createForTesting(
        preferences: CoachingPreferences,
        eventTracker: CoachingEventTracker
    ) -> CoachingService {
        return CoachingService(
            preferences: preferences,
            eventTracker: eventTracker
        )
    }
}
