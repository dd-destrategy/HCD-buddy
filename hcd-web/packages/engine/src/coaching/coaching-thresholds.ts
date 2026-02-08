/**
 * Coaching Thresholds - ported from Features/Coaching/CoachingThresholds.swift
 *
 * Configurable thresholds for the coaching engine.
 * Following the silence-first philosophy, these defaults are intentionally
 * conservative to minimize interruptions during interviews.
 */

// ---------------------------------------------------------------------------
// Coaching Thresholds
// ---------------------------------------------------------------------------

/**
 * Configurable thresholds for the coaching engine.
 */
export interface CoachingThresholds {
  /**
   * Minimum confidence level (0.0-1.0) required before showing a prompt.
   * Default: 0.85 (85%) - Only show highly confident suggestions
   */
  minimumConfidence: number;

  /**
   * Cooldown period in seconds between coaching prompts.
   * Default: 120 seconds (2 minutes) - Prevents prompt fatigue
   */
  cooldownDuration: number;

  /**
   * Delay in seconds to wait after any speech before showing a prompt.
   * Default: 5 seconds - Ensures natural conversation flow isn't interrupted
   */
  speechCooldown: number;

  /**
   * Maximum number of prompts allowed per session.
   * Default: 3 - Maintains focus on the interview, not the coach
   */
  maxPromptsPerSession: number;

  /**
   * Auto-dismiss duration in seconds for prompts.
   * Default: 8 seconds - Prompts fade naturally if not interacted with
   */
  autoDismissDuration: number;

  /** Duration for fade-in animation in seconds */
  fadeInDuration: number;

  /** Duration for fade-out animation in seconds */
  fadeOutDuration: number;

  /**
   * Sensitivity adjustment factor (0.5 = half as sensitive, 2.0 = twice as sensitive).
   * Affects how readily the system shows prompts.
   */
  sensitivityMultiplier: number;
}

/**
 * Create a CoachingThresholds with validated/clamped values.
 * Mirrors the Swift initializer clamping logic exactly.
 */
export function createCoachingThresholds(
  params: Partial<CoachingThresholds> = {},
): CoachingThresholds {
  return {
    minimumConfidence: Math.min(1.0, Math.max(0.0, params.minimumConfidence ?? 0.85)),
    cooldownDuration: Math.max(0, params.cooldownDuration ?? 120.0),
    speechCooldown: Math.max(0, params.speechCooldown ?? 5.0),
    maxPromptsPerSession: Math.max(0, params.maxPromptsPerSession ?? 3),
    autoDismissDuration: Math.max(1, params.autoDismissDuration ?? 8.0),
    fadeInDuration: Math.max(0.1, params.fadeInDuration ?? 0.3),
    fadeOutDuration: Math.max(0.1, params.fadeOutDuration ?? 0.25),
    sensitivityMultiplier: Math.min(3.0, Math.max(0.1, params.sensitivityMultiplier ?? 1.0)),
  };
}

/**
 * Effective confidence threshold after applying sensitivity multiplier.
 * Higher sensitivity = lower threshold (easier to trigger).
 * sensitivityMultiplier of 2.0 halves the threshold.
 */
export function effectiveConfidenceThreshold(thresholds: CoachingThresholds): number {
  const adjusted = thresholds.minimumConfidence / thresholds.sensitivityMultiplier;
  return Math.min(1.0, Math.max(0.5, adjusted));
}

/**
 * Effective cooldown after applying sensitivity multiplier.
 * Higher sensitivity = shorter cooldown.
 */
export function effectiveCooldown(thresholds: CoachingThresholds): number {
  return thresholds.cooldownDuration / thresholds.sensitivityMultiplier;
}

// ---------------------------------------------------------------------------
// Preset Configurations
// ---------------------------------------------------------------------------

/** Default conservative thresholds following silence-first philosophy */
export const DEFAULT_THRESHOLDS: CoachingThresholds = createCoachingThresholds();

/** Minimal intervention - for experienced researchers */
export const MINIMAL_THRESHOLDS: CoachingThresholds = createCoachingThresholds({
  minimumConfidence: 0.95,
  cooldownDuration: 180.0,
  speechCooldown: 8.0,
  maxPromptsPerSession: 2,
  autoDismissDuration: 6.0,
  sensitivityMultiplier: 0.5,
});

/** Balanced - moderate intervention level */
export const BALANCED_THRESHOLDS: CoachingThresholds = createCoachingThresholds({
  minimumConfidence: 0.80,
  cooldownDuration: 90.0,
  speechCooldown: 4.0,
  maxPromptsPerSession: 4,
  autoDismissDuration: 10.0,
  sensitivityMultiplier: 1.0,
});

/** Active - for new researchers who want more guidance */
export const ACTIVE_THRESHOLDS: CoachingThresholds = createCoachingThresholds({
  minimumConfidence: 0.70,
  cooldownDuration: 60.0,
  speechCooldown: 3.0,
  maxPromptsPerSession: 6,
  autoDismissDuration: 12.0,
  sensitivityMultiplier: 1.5,
});

// ---------------------------------------------------------------------------
// Coaching Level
// ---------------------------------------------------------------------------

/** Predefined coaching sensitivity levels */
export enum CoachingLevel {
  Off = 'off',
  Minimal = 'minimal',
  Balanced = 'balanced',
  Active = 'active',
}

/** Display names for coaching levels */
export const CoachingLevelDisplayName: Record<CoachingLevel, string> = {
  [CoachingLevel.Off]: 'Off',
  [CoachingLevel.Minimal]: 'Minimal',
  [CoachingLevel.Balanced]: 'Balanced',
  [CoachingLevel.Active]: 'Active',
};

/** Descriptions for coaching levels */
export const CoachingLevelDescription: Record<CoachingLevel, string> = {
  [CoachingLevel.Off]: 'No coaching prompts will be shown',
  [CoachingLevel.Minimal]: 'Only essential prompts for experienced researchers',
  [CoachingLevel.Balanced]: 'Moderate guidance for most situations',
  [CoachingLevel.Active]: 'More frequent prompts for learning researchers',
};

/** Get the thresholds for a coaching level */
export function getThresholdsForLevel(level: CoachingLevel): CoachingThresholds {
  switch (level) {
    case CoachingLevel.Off:
      return createCoachingThresholds({ maxPromptsPerSession: 0 });
    case CoachingLevel.Minimal:
      return MINIMAL_THRESHOLDS;
    case CoachingLevel.Balanced:
      return BALANCED_THRESHOLDS;
    case CoachingLevel.Active:
      return ACTIVE_THRESHOLDS;
  }
}

/** All coaching levels */
export const allCoachingLevels: CoachingLevel[] = [
  CoachingLevel.Off,
  CoachingLevel.Minimal,
  CoachingLevel.Balanced,
  CoachingLevel.Active,
];

// ---------------------------------------------------------------------------
// Coaching Function Type
// ---------------------------------------------------------------------------

/** Types of coaching function calls that can be received from the AI */
export enum CoachingFunctionType {
  /** Suggest a follow-up question */
  SuggestFollowUp = 'suggest_follow_up',
  /** Prompt to explore a topic deeper */
  ExploreDeeper = 'explore_deeper',
  /** Remind about an uncovered topic */
  UncoveredTopic = 'uncovered_topic',
  /** Suggest a pivot to maintain engagement */
  SuggestPivot = 'suggest_pivot',
  /** Encourage the researcher */
  Encouragement = 'encouragement',
  /** General coaching tip */
  GeneralTip = 'general_tip',
}

/** Display names for coaching function types */
export const CoachingFunctionTypeDisplayName: Record<CoachingFunctionType, string> = {
  [CoachingFunctionType.SuggestFollowUp]: 'Follow-up Suggestion',
  [CoachingFunctionType.ExploreDeeper]: 'Explore Deeper',
  [CoachingFunctionType.UncoveredTopic]: 'Uncovered Topic',
  [CoachingFunctionType.SuggestPivot]: 'Suggested Pivot',
  [CoachingFunctionType.Encouragement]: 'Encouragement',
  [CoachingFunctionType.GeneralTip]: 'Tip',
};

/** Icon identifiers for coaching function types */
export const CoachingFunctionTypeIcon: Record<CoachingFunctionType, string> = {
  [CoachingFunctionType.SuggestFollowUp]: 'bubble.right',
  [CoachingFunctionType.ExploreDeeper]: 'arrow.down.right.circle',
  [CoachingFunctionType.UncoveredTopic]: 'exclamationmark.circle',
  [CoachingFunctionType.SuggestPivot]: 'arrow.triangle.branch',
  [CoachingFunctionType.Encouragement]: 'hand.thumbsup',
  [CoachingFunctionType.GeneralTip]: 'lightbulb',
};

/** Priority levels for coaching function types (lower = higher priority) */
export const CoachingFunctionTypePriority: Record<CoachingFunctionType, number> = {
  [CoachingFunctionType.UncoveredTopic]: 1,
  [CoachingFunctionType.SuggestFollowUp]: 2,
  [CoachingFunctionType.ExploreDeeper]: 3,
  [CoachingFunctionType.SuggestPivot]: 4,
  [CoachingFunctionType.Encouragement]: 5,
  [CoachingFunctionType.GeneralTip]: 6,
};

/** All coaching function types */
export const allCoachingFunctionTypes: CoachingFunctionType[] = [
  CoachingFunctionType.SuggestFollowUp,
  CoachingFunctionType.ExploreDeeper,
  CoachingFunctionType.UncoveredTopic,
  CoachingFunctionType.SuggestPivot,
  CoachingFunctionType.Encouragement,
  CoachingFunctionType.GeneralTip,
];
