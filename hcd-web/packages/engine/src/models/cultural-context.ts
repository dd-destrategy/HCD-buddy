/**
 * Cultural Context model - ported from Core/Models/CulturalContext.swift
 *
 * Cultural context configuration affecting coaching behavior.
 * Each property influences how the coaching engine adapts to different
 * cultural communication styles.
 */

// ---------------------------------------------------------------------------
// Cultural Preset
// ---------------------------------------------------------------------------

/** Predefined cultural communication style presets */
export enum CulturalPreset {
  /** Direct, low-context communication style typical of Western cultures */
  Western = 'western',
  /** High-context, indirect communication style typical of East Asian cultures */
  EastAsian = 'east_asian',
  /** Relational, warm communication style typical of Latin American cultures */
  LatinAmerican = 'latin_american',
  /** Formal, hierarchical communication style typical of Middle Eastern cultures */
  MiddleEastern = 'middle_eastern',
  /** User-defined values for full manual control */
  Custom = 'custom',
}

/** Human-readable display names for cultural presets */
export const CulturalPresetDisplayName: Record<CulturalPreset, string> = {
  [CulturalPreset.Western]: 'Western',
  [CulturalPreset.EastAsian]: 'East Asian',
  [CulturalPreset.LatinAmerican]: 'Latin American',
  [CulturalPreset.MiddleEastern]: 'Middle Eastern',
  [CulturalPreset.Custom]: 'Custom',
};

/** Descriptions of each cultural communication style */
export const CulturalPresetDescription: Record<CulturalPreset, string> = {
  [CulturalPreset.Western]:
    'Direct, low-context communication. Standard silence tolerance and question pacing.',
  [CulturalPreset.EastAsian]:
    'High-context, indirect communication. Extended silence tolerance and slower question pacing.',
  [CulturalPreset.LatinAmerican]:
    'Relational, warm communication. Shorter silence tolerance and faster conversational pacing.',
  [CulturalPreset.MiddleEastern]:
    'Formal, hierarchical communication. Moderate silence tolerance with respectful pacing.',
  [CulturalPreset.Custom]:
    'Fully customizable settings for unique research contexts.',
};

/** All cultural preset values */
export const allCulturalPresets: CulturalPreset[] = [
  CulturalPreset.Western,
  CulturalPreset.EastAsian,
  CulturalPreset.LatinAmerican,
  CulturalPreset.MiddleEastern,
  CulturalPreset.Custom,
];

// ---------------------------------------------------------------------------
// Formality Level
// ---------------------------------------------------------------------------

/** Levels of formality that influence coaching prompt language and tone */
export enum FormalityLevel {
  /** Relaxed, conversational tone in coaching prompts */
  Casual = 'casual',
  /** Balanced tone appropriate for most contexts */
  Neutral = 'neutral',
  /** Respectful, professional tone for hierarchical settings */
  Formal = 'formal',
}

/** Display names for formality levels */
export const FormalityLevelDisplayName: Record<FormalityLevel, string> = {
  [FormalityLevel.Casual]: 'Casual',
  [FormalityLevel.Neutral]: 'Neutral',
  [FormalityLevel.Formal]: 'Formal',
};

/** All formality level values */
export const allFormalityLevels: FormalityLevel[] = [
  FormalityLevel.Casual,
  FormalityLevel.Neutral,
  FormalityLevel.Formal,
];

// ---------------------------------------------------------------------------
// Cultural Context
// ---------------------------------------------------------------------------

/**
 * Cultural context configuration that affects coaching behavior.
 *
 * Each property influences how the coaching engine adapts to different
 * cultural communication styles. Presets provide sensible defaults,
 * while custom mode allows full manual control.
 */
export interface CulturalContext {
  /** The selected cultural preset */
  preset: CulturalPreset;
  /** How long to wait (in seconds) before considering silence significant */
  silenceToleranceSeconds: number;
  /** Multiplier for question cooldown timing (1.0 = default) */
  questionPacingMultiplier: number;
  /** Sensitivity to interruptions on a scale of 0.0 (ignore) to 1.0 (very sensitive) */
  interruptionSensitivity: number;
  /** The formality level for coaching prompt language */
  formalityLevel: FormalityLevel;
  /** Whether to display explanations for why each coaching prompt was triggered */
  showCoachingExplanations: boolean;
  /** Whether to alert the interviewer about detected bias patterns in questions */
  enableBiasAlerts: boolean;
}

/**
 * Create a CulturalContext configured for the specified preset.
 * @param preset - The cultural preset to configure for
 * @returns A fully configured CulturalContext
 */
export function createCulturalContextPreset(preset: CulturalPreset): CulturalContext {
  switch (preset) {
    case CulturalPreset.Western:
      return {
        preset: CulturalPreset.Western,
        silenceToleranceSeconds: 5.0,
        questionPacingMultiplier: 1.0,
        interruptionSensitivity: 0.5,
        formalityLevel: FormalityLevel.Casual,
        showCoachingExplanations: true,
        enableBiasAlerts: true,
      };
    case CulturalPreset.EastAsian:
      return {
        preset: CulturalPreset.EastAsian,
        silenceToleranceSeconds: 12.0,
        questionPacingMultiplier: 1.5,
        interruptionSensitivity: 0.8,
        formalityLevel: FormalityLevel.Formal,
        showCoachingExplanations: true,
        enableBiasAlerts: true,
      };
    case CulturalPreset.LatinAmerican:
      return {
        preset: CulturalPreset.LatinAmerican,
        silenceToleranceSeconds: 4.0,
        questionPacingMultiplier: 0.8,
        interruptionSensitivity: 0.3,
        formalityLevel: FormalityLevel.Casual,
        showCoachingExplanations: true,
        enableBiasAlerts: true,
      };
    case CulturalPreset.MiddleEastern:
      return {
        preset: CulturalPreset.MiddleEastern,
        silenceToleranceSeconds: 8.0,
        questionPacingMultiplier: 1.3,
        interruptionSensitivity: 0.7,
        formalityLevel: FormalityLevel.Formal,
        showCoachingExplanations: true,
        enableBiasAlerts: true,
      };
    case CulturalPreset.Custom:
    default:
      // Custom starts with Western defaults for a familiar baseline
      return {
        preset: CulturalPreset.Custom,
        silenceToleranceSeconds: 5.0,
        questionPacingMultiplier: 1.0,
        interruptionSensitivity: 0.5,
        formalityLevel: FormalityLevel.Casual,
        showCoachingExplanations: true,
        enableBiasAlerts: true,
      };
  }
}

/** Default cultural context using Western preset */
export const DEFAULT_CULTURAL_CONTEXT: CulturalContext =
  createCulturalContextPreset(CulturalPreset.Western);

/**
 * Compute adjusted coaching thresholds by applying cultural context multipliers.
 *
 * Cultural context modifies:
 * - `speechCooldown`: scaled by silence tolerance relative to the 5s Western baseline
 * - `cooldownDuration`: scaled by the question pacing multiplier
 *
 * @param base - The base coaching thresholds to adjust
 * @param context - The cultural context to apply
 * @returns New thresholds with cultural adjustments applied
 */
export function adjustThresholdsForCulture(
  base: {
    minimumConfidence: number;
    cooldownDuration: number;
    speechCooldown: number;
    maxPromptsPerSession: number;
    autoDismissDuration: number;
    fadeInDuration: number;
    fadeOutDuration: number;
    sensitivityMultiplier: number;
  },
  context: CulturalContext,
): {
  minimumConfidence: number;
  cooldownDuration: number;
  speechCooldown: number;
  maxPromptsPerSession: number;
  autoDismissDuration: number;
  fadeInDuration: number;
  fadeOutDuration: number;
  sensitivityMultiplier: number;
} {
  const adjustedSpeechCooldown = base.speechCooldown * (context.silenceToleranceSeconds / 5.0);
  const adjustedCooldownDuration = base.cooldownDuration * context.questionPacingMultiplier;

  return {
    minimumConfidence: base.minimumConfidence,
    cooldownDuration: adjustedCooldownDuration,
    speechCooldown: adjustedSpeechCooldown,
    maxPromptsPerSession: base.maxPromptsPerSession,
    autoDismissDuration: base.autoDismissDuration,
    fadeInDuration: base.fadeInDuration,
    fadeOutDuration: base.fadeOutDuration,
    sensitivityMultiplier: base.sensitivityMultiplier,
  };
}
