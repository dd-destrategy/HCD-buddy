//
//  CulturalContext.swift
//  HCD Interview Coach
//
//  Feature D: Cultural Sensitivity & AI Bias Controls
//  Cultural context configuration affecting coaching behavior
//

import Foundation

// MARK: - Cultural Preset

/// Predefined cultural communication style presets that adjust coaching behavior
/// to respect different cultural norms around silence, pacing, and formality.
enum CulturalPreset: String, CaseIterable, Codable {
    /// Direct, low-context communication style typical of Western cultures
    case western = "western"
    /// High-context, indirect communication style typical of East Asian cultures
    case eastAsian = "east_asian"
    /// Relational, warm communication style typical of Latin American cultures
    case latinAmerican = "latin_american"
    /// Formal, hierarchical communication style typical of Middle Eastern cultures
    case middleEastern = "middle_eastern"
    /// User-defined values for full manual control
    case custom = "custom"

    /// Human-readable name for display in UI
    var displayName: String {
        switch self {
        case .western:
            return "Western"
        case .eastAsian:
            return "East Asian"
        case .latinAmerican:
            return "Latin American"
        case .middleEastern:
            return "Middle Eastern"
        case .custom:
            return "Custom"
        }
    }

    /// Description of the communication style characteristics
    var description: String {
        switch self {
        case .western:
            return "Direct, low-context communication. Standard silence tolerance and question pacing."
        case .eastAsian:
            return "High-context, indirect communication. Extended silence tolerance and slower question pacing."
        case .latinAmerican:
            return "Relational, warm communication. Shorter silence tolerance and faster conversational pacing."
        case .middleEastern:
            return "Formal, hierarchical communication. Moderate silence tolerance with respectful pacing."
        case .custom:
            return "Fully customizable settings for unique research contexts."
        }
    }

    /// SF Symbol icon representing the cultural region
    var icon: String {
        switch self {
        case .western:
            return "globe.americas"
        case .eastAsian:
            return "globe.asia.australia"
        case .latinAmerican:
            return "globe.central.south.asia"
        case .middleEastern:
            return "globe.europe.africa"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}

// MARK: - Formality Level

/// Levels of formality that influence coaching prompt language and tone.
enum FormalityLevel: String, CaseIterable, Codable {
    /// Relaxed, conversational tone in coaching prompts
    case casual = "casual"
    /// Balanced tone appropriate for most contexts
    case neutral = "neutral"
    /// Respectful, professional tone for hierarchical settings
    case formal = "formal"

    /// Human-readable name for display in UI
    var displayName: String {
        switch self {
        case .casual:
            return "Casual"
        case .neutral:
            return "Neutral"
        case .formal:
            return "Formal"
        }
    }
}

// MARK: - Cultural Context

/// Cultural context configuration that affects coaching behavior.
///
/// Each property influences how the coaching engine adapts to different
/// cultural communication styles. Presets provide sensible defaults,
/// while custom mode allows full manual control.
struct CulturalContext: Codable, Equatable {

    /// The selected cultural preset
    var preset: CulturalPreset

    /// How long to wait (in seconds) before considering silence significant.
    /// Longer values respect cultures where silence is a natural part of conversation.
    var silenceToleranceSeconds: TimeInterval

    /// Multiplier for question cooldown timing (1.0 = default).
    /// Higher values slow down the pacing between coaching prompts.
    var questionPacingMultiplier: Double

    /// Sensitivity to interruptions on a scale of 0.0 (ignore) to 1.0 (very sensitive).
    /// Higher values make the system more cautious about showing prompts during speech.
    var interruptionSensitivity: Double

    /// The formality level for coaching prompt language
    var formalityLevel: FormalityLevel

    /// Whether to display explanations for why each coaching prompt was triggered
    var showCoachingExplanations: Bool

    /// Whether to alert the interviewer about detected bias patterns in questions
    var enableBiasAlerts: Bool

    // MARK: - Factory Method

    /// Creates a CulturalContext configured for the specified preset.
    ///
    /// - Parameter preset: The cultural preset to configure for
    /// - Returns: A fully configured CulturalContext
    static func preset(_ preset: CulturalPreset) -> CulturalContext {
        switch preset {
        case .western:
            return CulturalContext(
                preset: .western,
                silenceToleranceSeconds: 5.0,
                questionPacingMultiplier: 1.0,
                interruptionSensitivity: 0.5,
                formalityLevel: .casual,
                showCoachingExplanations: true,
                enableBiasAlerts: true
            )
        case .eastAsian:
            return CulturalContext(
                preset: .eastAsian,
                silenceToleranceSeconds: 12.0,
                questionPacingMultiplier: 1.5,
                interruptionSensitivity: 0.8,
                formalityLevel: .formal,
                showCoachingExplanations: true,
                enableBiasAlerts: true
            )
        case .latinAmerican:
            return CulturalContext(
                preset: .latinAmerican,
                silenceToleranceSeconds: 4.0,
                questionPacingMultiplier: 0.8,
                interruptionSensitivity: 0.3,
                formalityLevel: .casual,
                showCoachingExplanations: true,
                enableBiasAlerts: true
            )
        case .middleEastern:
            return CulturalContext(
                preset: .middleEastern,
                silenceToleranceSeconds: 8.0,
                questionPacingMultiplier: 1.3,
                interruptionSensitivity: 0.7,
                formalityLevel: .formal,
                showCoachingExplanations: true,
                enableBiasAlerts: true
            )
        case .custom:
            // Custom starts with Western defaults for a familiar baseline
            return CulturalContext(
                preset: .custom,
                silenceToleranceSeconds: 5.0,
                questionPacingMultiplier: 1.0,
                interruptionSensitivity: 0.5,
                formalityLevel: .casual,
                showCoachingExplanations: true,
                enableBiasAlerts: true
            )
        }
    }

    /// Default cultural context using Western preset
    static let `default` = CulturalContext.preset(.western)
}

// MARK: - Cultural Context Manager

/// Manages the active cultural context configuration with JSON file persistence.
///
/// Provides methods to update presets, apply custom configurations, and
/// compute adjusted coaching thresholds based on cultural settings.
@MainActor
final class CulturalContextManager: ObservableObject {

    // MARK: - Published Properties

    /// The current cultural context configuration
    @Published var context: CulturalContext

    // MARK: - Private Properties

    private let storageURL: URL

    // MARK: - Initialization

    /// Creates a manager using the default Application Support storage location.
    init() {
        let appSupport: URL
        if let appSupportDir = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            appSupport = appSupportDir.appendingPathComponent("HCDInterviewCoach")
        } else {
            AppLogger.shared.warning("Application Support directory unavailable, using temporary directory for cultural context")
            appSupport = FileManager.default.temporaryDirectory
                .appendingPathComponent("HCDInterviewCoach")
        }

        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: appSupport,
            withIntermediateDirectories: true
        )

        self.storageURL = appSupport.appendingPathComponent("cultural_context.json")
        self.context = .default
        load()
    }

    /// Creates a manager with a specific storage URL for testing.
    ///
    /// - Parameter storageURL: The file URL where context is persisted
    init(storageURL: URL) {
        self.storageURL = storageURL
        self.context = .default
        load()
    }

    // MARK: - Public Methods

    /// Update the cultural context to a specific preset, replacing all values.
    ///
    /// - Parameter preset: The cultural preset to apply
    func updatePreset(_ preset: CulturalPreset) {
        context = CulturalContext.preset(preset)
        save()
        AppLogger.shared.info("Cultural context updated to preset: \(preset.displayName)")
    }

    /// Update the cultural context with a fully custom configuration.
    ///
    /// - Parameter context: The new cultural context to apply
    func updateContext(_ context: CulturalContext) {
        self.context = context
        save()
        AppLogger.shared.info("Cultural context updated (preset: \(context.preset.displayName))")
    }

    /// Compute adjusted coaching thresholds by applying cultural context multipliers.
    ///
    /// Cultural context modifies:
    /// - `speechCooldown`: scaled by silence tolerance relative to the 5s Western baseline
    /// - `cooldownDuration`: scaled by the question pacing multiplier
    ///
    /// - Parameter base: The base coaching thresholds to adjust
    /// - Returns: New thresholds with cultural adjustments applied
    func adjustedThresholds(base: CoachingThresholds) -> CoachingThresholds {
        let adjustedSpeechCooldown = base.speechCooldown * (context.silenceToleranceSeconds / 5.0)
        let adjustedCooldownDuration = base.cooldownDuration * context.questionPacingMultiplier

        return CoachingThresholds(
            minimumConfidence: base.minimumConfidence,
            cooldownDuration: adjustedCooldownDuration,
            speechCooldown: adjustedSpeechCooldown,
            maxPromptsPerSession: base.maxPromptsPerSession,
            autoDismissDuration: base.autoDismissDuration,
            fadeInDuration: base.fadeInDuration,
            fadeOutDuration: base.fadeOutDuration,
            sensitivityMultiplier: base.sensitivityMultiplier
        )
    }

    // MARK: - Private Methods

    /// Load the cultural context from disk. Falls back to defaults if not found.
    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode(CulturalContext.self, from: data)
            self.context = decoded
            AppLogger.shared.info("Cultural context loaded from disk (preset: \(decoded.preset.displayName))")
        } catch {
            AppLogger.shared.warning("Failed to load cultural context: \(error.localizedDescription)")
        }
    }

    /// Persist the current cultural context to disk as JSON.
    private func save() {
        do {
            let data = try JSONEncoder().encode(context)
            try data.write(to: storageURL, options: .atomic)
            AppLogger.shared.debug("Cultural context saved to disk")
        } catch {
            AppLogger.shared.warning("Failed to save cultural context: \(error.localizedDescription)")
        }
    }
}
