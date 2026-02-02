//
//  CoachingViewModel.swift
//  HCD Interview Coach
//
//  EPIC E6: Coaching Engine
//  State management and UI coordination for coaching prompts
//

import Foundation
import Combine
import SwiftUI

// MARK: - Coaching View State

/// Represents the current state of the coaching UI
enum CoachingViewState: Equatable {
    /// No coaching active
    case inactive

    /// Coaching enabled but no prompt showing
    case idle

    /// Prompt is appearing (fade in animation)
    case appearing

    /// Prompt is fully visible
    case visible

    /// Prompt is disappearing (fade out animation)
    case disappearing

    /// In cooldown period between prompts
    case cooldown

    var isVisible: Bool {
        switch self {
        case .appearing, .visible:
            return true
        default:
            return false
        }
    }
}

// MARK: - Coaching View Model

/// View model for coaching UI components.
/// Coordinates between CoachingService and SwiftUI views.
@MainActor
final class CoachingViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current view state
    @Published private(set) var viewState: CoachingViewState = .inactive

    /// Current prompt to display
    @Published private(set) var currentPrompt: CoachingPrompt?

    /// Opacity for fade animations
    @Published private(set) var promptOpacity: Double = 0

    /// Scale for spring animations
    @Published private(set) var promptScale: CGFloat = 0.9

    /// Whether to show the prompt count badge
    @Published var showPromptCount: Bool = true

    /// Remaining time for auto-dismiss (for progress indicator)
    @Published private(set) var autoDismissProgress: Double = 0

    /// Whether keyboard shortcut hints should be visible
    @Published var showKeyboardHints: Bool = true

    // MARK: - Computed Properties

    /// Number of prompts shown in this session
    var promptCount: Int {
        coachingService.promptCount
    }

    /// Maximum prompts allowed per session
    var maxPrompts: Int {
        preferences.effectiveThresholds.maxPromptsPerSession
    }

    /// Whether coaching is enabled
    var isEnabled: Bool {
        coachingService.isEnabled
    }

    /// Current coaching level
    var coachingLevel: CoachingLevel {
        preferences.coachingLevel
    }

    /// Overlay position preference
    var overlayPosition: OverlayPosition {
        preferences.overlayPosition
    }

    /// Whether we're at max prompts
    var hasReachedMaxPrompts: Bool {
        coachingService.hasReachedMaxPrompts
    }

    /// Cooldown remaining in seconds
    var cooldownRemaining: TimeInterval {
        coachingService.cooldownRemaining
    }

    // MARK: - Dependencies

    private let coachingService: CoachingService
    private let preferences: CoachingPreferences

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()
    private var animationTask: Task<Void, Never>?
    private var autoDismissTimerTask: Task<Void, Never>?
    private var autoDismissDuration: TimeInterval = 8.0

    // MARK: - Initialization

    init(
        coachingService: CoachingService,
        preferences: CoachingPreferences? = nil
    ) {
        self.coachingService = coachingService
        self.preferences = preferences ?? .shared

        setupBindings()
    }

    // MARK: - Public Methods

    /// Toggle coaching on/off
    func toggleCoaching() {
        if coachingService.isEnabled {
            coachingService.disable()
            transitionTo(.inactive)
        } else {
            coachingService.enable()
            transitionTo(.idle)
        }
    }

    /// Enable coaching
    func enableCoaching() {
        guard !coachingService.isEnabled else { return }
        coachingService.enable()
        transitionTo(.idle)
    }

    /// Disable coaching
    func disableCoaching() {
        guard coachingService.isEnabled else { return }
        coachingService.disable()
        transitionTo(.inactive)
    }

    /// Dismiss the current prompt
    func dismissPrompt() {
        coachingService.dismiss()
    }

    /// Accept the current prompt
    func acceptPrompt() {
        coachingService.accept()
    }

    /// Snooze the current prompt
    func snoozePrompt() {
        coachingService.snooze()
    }

    /// Handle keyboard escape
    func handleEscape() {
        if currentPrompt != nil {
            dismissPrompt()
        }
    }

    /// Handle keyboard return/enter
    func handleReturn() {
        if currentPrompt != nil {
            acceptPrompt()
        }
    }

    /// Handle keyboard space
    func handleSpace() {
        if currentPrompt != nil {
            snoozePrompt()
        }
    }

    /// Update the current timestamp (called from session timer)
    func updateTimestamp(_ timestamp: TimeInterval) {
        coachingService.updateTimestamp(timestamp)
    }

    /// Notify that speech was detected
    func notifySpeechDetected() {
        coachingService.notifySpeechDetected()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Observe coaching service enabled state
        coachingService.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                if enabled {
                    self?.transitionTo(.idle)
                } else {
                    self?.transitionTo(.inactive)
                }
            }
            .store(in: &cancellables)

        // Observe current prompt changes
        coachingService.$currentPrompt
            .receive(on: DispatchQueue.main)
            .sink { [weak self] prompt in
                self?.handlePromptChange(prompt)
            }
            .store(in: &cancellables)

        // Observe preferences
        preferences.$overlayPosition
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        preferences.$showNotificationBadge
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                self?.showPromptCount = show
            }
            .store(in: &cancellables)
    }

    private func handlePromptChange(_ prompt: CoachingPrompt?) {
        if let prompt = prompt {
            // New prompt appearing
            currentPrompt = prompt
            autoDismissDuration = preferences.customAutoDismissDuration ?? preferences.effectiveThresholds.autoDismissDuration
            animateIn()
        } else if currentPrompt != nil {
            // Prompt disappearing
            animateOut()
        }
    }

    private func animateIn() {
        animationTask?.cancel()

        transitionTo(.appearing)

        // Animate opacity and scale
        animationTask = Task { [weak self] in
            guard let self = self else { return }

            // Quick animation
            let duration = self.preferences.effectiveThresholds.fadeInDuration

            await MainActor.run {
                withAnimation(.spring(response: duration, dampingFraction: 0.7)) {
                    self.promptOpacity = 1.0
                    self.promptScale = 1.0
                }
            }

            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

            await MainActor.run {
                self.transitionTo(.visible)
                self.startAutoDismissTimer()
            }
        }
    }

    private func animateOut() {
        animationTask?.cancel()
        autoDismissTimerTask?.cancel()

        transitionTo(.disappearing)

        animationTask = Task { [weak self] in
            guard let self = self else { return }

            let duration = self.preferences.effectiveThresholds.fadeOutDuration

            await MainActor.run {
                withAnimation(.easeOut(duration: duration)) {
                    self.promptOpacity = 0
                    self.promptScale = 0.9
                }
            }

            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

            await MainActor.run {
                self.currentPrompt = nil
                self.autoDismissProgress = 0

                if self.coachingService.isEnabled {
                    if self.coachingService.isInCooldown {
                        self.transitionTo(.cooldown)
                    } else {
                        self.transitionTo(.idle)
                    }
                } else {
                    self.transitionTo(.inactive)
                }
            }
        }
    }

    private func startAutoDismissTimer() {
        autoDismissTimerTask?.cancel()

        autoDismissTimerTask = Task { [weak self] in
            guard let self = self else { return }

            let startTime = Date()
            let duration = self.autoDismissDuration

            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(1.0, elapsed / duration)

                await MainActor.run {
                    self.autoDismissProgress = progress
                }

                if progress >= 1.0 {
                    break
                }

                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms updates
            }
        }
    }

    private func transitionTo(_ state: CoachingViewState) {
        guard viewState != state else { return }

        AppLogger.shared.debug("CoachingViewModel state: \(viewState) -> \(state)")
        viewState = state
    }
}

// MARK: - Keyboard Monitor

/// Monitors keyboard events for coaching shortcuts
final class CoachingKeyboardMonitor {

    private var eventMonitor: Any?
    private weak var viewModel: CoachingViewModel?

    init(viewModel: CoachingViewModel) {
        self.viewModel = viewModel
    }

    /// Start monitoring keyboard events
    func start() {
        #if os(macOS)
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
        #endif
    }

    /// Stop monitoring keyboard events
    func stop() {
        #if os(macOS)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        #endif
    }

    #if os(macOS)
    private func handleKeyEvent(_ event: NSEvent) {
        guard let viewModel = viewModel else { return }

        Task { @MainActor in
            switch event.keyCode {
            case 53: // Escape
                viewModel.handleEscape()
            case 36: // Return
                viewModel.handleReturn()
            case 49: // Space
                viewModel.handleSpace()
            default:
                break
            }
        }
    }
    #endif

    deinit {
        stop()
    }
}

// MARK: - Coaching View Model Factory

/// Factory for creating coaching view models
struct CoachingViewModelFactory {

    /// Creates a production view model
    @MainActor
    static func createProduction(coachingService: CoachingService) -> CoachingViewModel {
        return CoachingViewModel(coachingService: coachingService)
    }
}

// MARK: - Environment Key

/// Environment key for accessing the coaching view model
struct CoachingViewModelKey: EnvironmentKey {
    static let defaultValue: CoachingViewModel? = nil
}

extension EnvironmentValues {
    var coachingViewModel: CoachingViewModel? {
        get { self[CoachingViewModelKey.self] }
        set { self[CoachingViewModelKey.self] = newValue }
    }
}
