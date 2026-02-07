//
//  CoachingTimingSettings.swift
//  HCD Interview Coach
//
//  Feature A: Customizable Coaching Timing & Predictable Mode
//  Advanced timing configuration and delivery mode management
//

import Foundation

// MARK: - Auto-Dismiss Preset

/// Preset options for how long a coaching prompt remains visible before auto-dismissing.
/// Provides a range from quick dismissal to fully manual control.
enum AutoDismissPreset: String, CaseIterable, Codable {
    /// 5-second auto-dismiss for experienced researchers who glance quickly
    case quick = "quick"
    /// 8-second auto-dismiss matching the system default
    case standard = "standard"
    /// 15-second auto-dismiss for those who prefer more reading time
    case relaxed = "relaxed"
    /// 30-second auto-dismiss for thorough review of suggestions
    case extended = "extended"
    /// No auto-dismiss; user must manually dismiss each prompt
    case manual = "manual"

    /// The auto-dismiss duration in seconds, or nil for manual mode
    var duration: TimeInterval? {
        switch self {
        case .quick:
            return 5.0
        case .standard:
            return 8.0
        case .relaxed:
            return 15.0
        case .extended:
            return 30.0
        case .manual:
            return nil
        }
    }

    /// Human-readable name for display in UI
    var displayName: String {
        switch self {
        case .quick:
            return "Quick"
        case .standard:
            return "Standard"
        case .relaxed:
            return "Relaxed"
        case .extended:
            return "Extended"
        case .manual:
            return "Manual"
        }
    }

    /// Descriptive text explaining the preset behavior
    var description: String {
        switch self {
        case .quick:
            return "Dismiss after 5 seconds"
        case .standard:
            return "Dismiss after 8 seconds (default)"
        case .relaxed:
            return "Dismiss after 15 seconds"
        case .extended:
            return "Dismiss after 30 seconds"
        case .manual:
            return "You dismiss prompts manually"
        }
    }
}

// MARK: - Coaching Delivery Mode

/// Controls how coaching prompts are delivered to the researcher.
/// Supports real-time, pull-based, and preview modes.
enum CoachingDeliveryMode: String, CaseIterable, Codable {
    /// Prompts appear immediately when triggered (default behavior)
    case realtime = "realtime"
    /// Prompts are queued silently; user pulls them via shortcut when ready
    case pull = "pull"
    /// Prompts are logged but never displayed; useful for reviewing what would trigger
    case preview = "preview"

    /// Human-readable name for display in UI
    var displayName: String {
        switch self {
        case .realtime:
            return "Real-time"
        case .pull:
            return "Pull"
        case .preview:
            return "Preview"
        }
    }

    /// Descriptive text explaining the delivery mode behavior
    var description: String {
        switch self {
        case .realtime:
            return "Prompts appear automatically when triggered"
        case .pull:
            return "Prompts queue silently; pull them when you're ready"
        case .preview:
            return "See what would trigger without interruptions"
        }
    }

    /// SF Symbol icon name for the delivery mode
    var icon: String {
        switch self {
        case .realtime:
            return "bolt.fill"
        case .pull:
            return "tray.and.arrow.down"
        case .preview:
            return "eye"
        }
    }
}

// MARK: - Coaching Timing Settings

/// Manages advanced coaching timing preferences including auto-dismiss presets
/// and delivery modes (real-time, pull, preview).
///
/// Persists settings via UserDefaults and provides queue management for
/// pull mode and logging for preview mode.
@MainActor
final class CoachingTimingSettings: ObservableObject {

    // MARK: - Published Properties

    /// The selected auto-dismiss preset controlling how long prompts stay visible
    @Published var autoDismissPreset: AutoDismissPreset {
        didSet {
            defaults.set(autoDismissPreset.rawValue, forKey: Keys.autoDismissPreset)
            AppLogger.shared.info("Auto-dismiss preset changed to: \(autoDismissPreset.displayName)")
        }
    }

    /// The coaching delivery mode controlling how prompts are presented
    @Published var deliveryMode: CoachingDeliveryMode {
        didSet {
            defaults.set(deliveryMode.rawValue, forKey: Keys.deliveryMode)
            AppLogger.shared.info("Delivery mode changed to: \(deliveryMode.displayName)")
        }
    }

    /// Queue of prompts waiting to be pulled by the user (pull mode only)
    @Published private(set) var pullModeQueue: [CoachingPrompt] = []

    /// Log of prompts that would have been shown (preview mode only)
    @Published private(set) var previewLog: [CoachingPrompt] = []

    // MARK: - Private Properties

    private let defaults: UserDefaults

    // MARK: - Keys

    private enum Keys {
        static let autoDismissPreset = "coaching.timing.autoDismissPreset"
        static let deliveryMode = "coaching.timing.deliveryMode"
    }

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load persisted auto-dismiss preset
        if let presetString = defaults.string(forKey: Keys.autoDismissPreset),
           let preset = AutoDismissPreset(rawValue: presetString) {
            self.autoDismissPreset = preset
        } else {
            self.autoDismissPreset = .standard
        }

        // Load persisted delivery mode
        if let modeString = defaults.string(forKey: Keys.deliveryMode),
           let mode = CoachingDeliveryMode(rawValue: modeString) {
            self.deliveryMode = mode
        } else {
            self.deliveryMode = .realtime
        }
    }

    // MARK: - Computed Properties

    /// The effective auto-dismiss duration based on the current preset.
    /// Returns nil when in manual mode (no auto-dismiss).
    var effectiveAutoDismissDuration: TimeInterval? {
        return autoDismissPreset.duration
    }

    /// The number of prompts currently queued in pull mode
    var pullQueueCount: Int {
        return pullModeQueue.count
    }

    /// The number of prompts logged in preview mode
    var previewLogCount: Int {
        return previewLog.count
    }

    /// Whether there are prompts available to pull
    var hasPendingPullPrompts: Bool {
        return !pullModeQueue.isEmpty
    }

    // MARK: - Pull Mode Methods

    /// Retrieve and remove the next queued prompt in pull mode.
    /// Returns the highest-priority prompt from the queue, or nil if the queue is empty.
    func pullNextPrompt() -> CoachingPrompt? {
        guard !pullModeQueue.isEmpty else { return nil }
        let prompt = pullModeQueue.removeFirst()
        AppLogger.shared.info("Pulled prompt from queue: \(prompt.type.displayName), \(pullModeQueue.count) remaining")
        return prompt
    }

    /// Add a prompt to the pull queue. Called by CoachingService when in pull mode.
    /// Prompts are sorted by priority (type priority ascending, then timestamp ascending).
    /// - Parameter prompt: The coaching prompt to enqueue
    func enqueueForPull(_ prompt: CoachingPrompt) {
        pullModeQueue.append(prompt)
        sortPullQueue()
        AppLogger.shared.info("Enqueued prompt for pull: \(prompt.type.displayName), queue size: \(pullModeQueue.count)")
    }

    /// Clear all prompts from the pull queue.
    func clearPullQueue() {
        let count = pullModeQueue.count
        pullModeQueue.removeAll()
        AppLogger.shared.info("Pull queue cleared (\(count) prompts removed)")
    }

    // MARK: - Preview Mode Methods

    /// Log a prompt that would have been shown in real-time mode.
    /// Called by CoachingService when in preview mode.
    /// - Parameter prompt: The coaching prompt to log
    func logPreview(_ prompt: CoachingPrompt) {
        previewLog.append(prompt)
        AppLogger.shared.info("Preview logged: \(prompt.type.displayName), log size: \(previewLog.count)")
    }

    /// Clear the preview log.
    func clearPreviewLog() {
        let count = previewLog.count
        previewLog.removeAll()
        AppLogger.shared.info("Preview log cleared (\(count) entries removed)")
    }

    // MARK: - Reset

    /// Reset all timing settings to defaults and clear queues.
    func resetToDefaults() {
        autoDismissPreset = .standard
        deliveryMode = .realtime
        clearPullQueue()
        clearPreviewLog()
        AppLogger.shared.info("Coaching timing settings reset to defaults")
    }

    // MARK: - Private Methods

    /// Sort the pull queue by prompt type priority (lower = higher priority),
    /// then by timestamp for prompts of the same priority.
    private func sortPullQueue() {
        pullModeQueue.sort { a, b in
            if a.type.priority != b.type.priority {
                return a.type.priority < b.type.priority
            }
            return a.timestamp < b.timestamp
        }
    }
}
