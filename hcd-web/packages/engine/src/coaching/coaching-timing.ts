/**
 * Coaching Timing Settings - ported from Features/Coaching/CoachingTimingSettings.swift
 *
 * Advanced timing configuration and delivery mode management.
 * Manages auto-dismiss presets, delivery modes (real-time, pull, preview),
 * and pull-mode queue.
 */

import type { CoachingPrompt } from './coaching-service';
import { CoachingFunctionTypePriority } from './coaching-thresholds';

// ---------------------------------------------------------------------------
// Auto-Dismiss Preset
// ---------------------------------------------------------------------------

/**
 * Preset options for how long a coaching prompt remains visible
 * before auto-dismissing.
 */
export enum AutoDismissPreset {
  /** 5-second auto-dismiss for experienced researchers who glance quickly */
  Quick = 'quick',
  /** 8-second auto-dismiss matching the system default */
  Standard = 'standard',
  /** 15-second auto-dismiss for those who prefer more reading time */
  Relaxed = 'relaxed',
  /** 30-second auto-dismiss for thorough review of suggestions */
  Extended = 'extended',
  /** No auto-dismiss; user must manually dismiss each prompt */
  Manual = 'manual',
}

/** Auto-dismiss durations in seconds (null for manual mode) */
export const AutoDismissPresetDuration: Record<AutoDismissPreset, number | null> = {
  [AutoDismissPreset.Quick]: 5.0,
  [AutoDismissPreset.Standard]: 8.0,
  [AutoDismissPreset.Relaxed]: 15.0,
  [AutoDismissPreset.Extended]: 30.0,
  [AutoDismissPreset.Manual]: null,
};

/** Display names for auto-dismiss presets */
export const AutoDismissPresetDisplayName: Record<AutoDismissPreset, string> = {
  [AutoDismissPreset.Quick]: 'Quick',
  [AutoDismissPreset.Standard]: 'Standard',
  [AutoDismissPreset.Relaxed]: 'Relaxed',
  [AutoDismissPreset.Extended]: 'Extended',
  [AutoDismissPreset.Manual]: 'Manual',
};

/** Descriptions for auto-dismiss presets */
export const AutoDismissPresetDescription: Record<AutoDismissPreset, string> = {
  [AutoDismissPreset.Quick]: 'Dismiss after 5 seconds',
  [AutoDismissPreset.Standard]: 'Dismiss after 8 seconds (default)',
  [AutoDismissPreset.Relaxed]: 'Dismiss after 15 seconds',
  [AutoDismissPreset.Extended]: 'Dismiss after 30 seconds',
  [AutoDismissPreset.Manual]: 'You dismiss prompts manually',
};

/** All auto-dismiss presets */
export const allAutoDismissPresets: AutoDismissPreset[] = [
  AutoDismissPreset.Quick,
  AutoDismissPreset.Standard,
  AutoDismissPreset.Relaxed,
  AutoDismissPreset.Extended,
  AutoDismissPreset.Manual,
];

// ---------------------------------------------------------------------------
// Coaching Delivery Mode
// ---------------------------------------------------------------------------

/** Controls how coaching prompts are delivered to the researcher */
export enum CoachingDeliveryMode {
  /** Prompts appear immediately when triggered (default behavior) */
  Realtime = 'realtime',
  /** Prompts are queued silently; user pulls them via shortcut when ready */
  Pull = 'pull',
  /** Prompts are logged but never displayed; useful for reviewing what would trigger */
  Preview = 'preview',
}

/** Display names for delivery modes */
export const CoachingDeliveryModeDisplayName: Record<CoachingDeliveryMode, string> = {
  [CoachingDeliveryMode.Realtime]: 'Real-time',
  [CoachingDeliveryMode.Pull]: 'Pull',
  [CoachingDeliveryMode.Preview]: 'Preview',
};

/** Descriptions for delivery modes */
export const CoachingDeliveryModeDescription: Record<CoachingDeliveryMode, string> = {
  [CoachingDeliveryMode.Realtime]: 'Prompts appear automatically when triggered',
  [CoachingDeliveryMode.Pull]: 'Prompts queue silently; pull them when you\'re ready',
  [CoachingDeliveryMode.Preview]: 'See what would trigger without interruptions',
};

/** All delivery modes */
export const allCoachingDeliveryModes: CoachingDeliveryMode[] = [
  CoachingDeliveryMode.Realtime,
  CoachingDeliveryMode.Pull,
  CoachingDeliveryMode.Preview,
];

// ---------------------------------------------------------------------------
// Coaching Timing Settings
// ---------------------------------------------------------------------------

/** Configuration for CoachingTimingSettings */
export interface CoachingTimingConfig {
  autoDismissPreset?: AutoDismissPreset;
  deliveryMode?: CoachingDeliveryMode;
}

/**
 * Manages advanced coaching timing preferences including auto-dismiss
 * presets and delivery modes (real-time, pull, preview).
 *
 * Provides queue management for pull mode and logging for preview mode.
 */
export class CoachingTimingSettings {
  private _autoDismissPreset: AutoDismissPreset;
  private _deliveryMode: CoachingDeliveryMode;
  private _pullModeQueue: CoachingPrompt[] = [];
  private _previewLog: CoachingPrompt[] = [];

  constructor(config: CoachingTimingConfig = {}) {
    this._autoDismissPreset = config.autoDismissPreset ?? AutoDismissPreset.Standard;
    this._deliveryMode = config.deliveryMode ?? CoachingDeliveryMode.Realtime;
  }

  // -------------------------------------------------------------------------
  // Accessors
  // -------------------------------------------------------------------------

  /** The selected auto-dismiss preset */
  get autoDismissPreset(): AutoDismissPreset {
    return this._autoDismissPreset;
  }

  set autoDismissPreset(value: AutoDismissPreset) {
    this._autoDismissPreset = value;
  }

  /** The coaching delivery mode */
  get deliveryMode(): CoachingDeliveryMode {
    return this._deliveryMode;
  }

  set deliveryMode(value: CoachingDeliveryMode) {
    this._deliveryMode = value;
  }

  /** Queue of prompts waiting to be pulled (pull mode only) */
  get pullModeQueue(): readonly CoachingPrompt[] {
    return this._pullModeQueue;
  }

  /** Log of prompts that would have been shown (preview mode only) */
  get previewLog(): readonly CoachingPrompt[] {
    return this._previewLog;
  }

  /**
   * The effective auto-dismiss duration based on the current preset.
   * Returns null when in manual mode (no auto-dismiss).
   */
  get effectiveAutoDismissDuration(): number | null {
    return AutoDismissPresetDuration[this._autoDismissPreset];
  }

  /** The number of prompts currently queued in pull mode */
  get pullQueueCount(): number {
    return this._pullModeQueue.length;
  }

  /** The number of prompts logged in preview mode */
  get previewLogCount(): number {
    return this._previewLog.length;
  }

  /** Whether there are prompts available to pull */
  get hasPendingPullPrompts(): boolean {
    return this._pullModeQueue.length > 0;
  }

  // -------------------------------------------------------------------------
  // Pull Mode Methods
  // -------------------------------------------------------------------------

  /**
   * Retrieve and remove the next queued prompt in pull mode.
   * @returns The highest-priority prompt from the queue, or null if empty
   */
  pullNextPrompt(): CoachingPrompt | null {
    if (this._pullModeQueue.length === 0) return null;
    return this._pullModeQueue.shift()!;
  }

  /**
   * Add a prompt to the pull queue.
   * Prompts are sorted by priority (type priority ascending, then timestamp ascending).
   * @param prompt - The coaching prompt to enqueue
   */
  enqueueForPull(prompt: CoachingPrompt): void {
    this._pullModeQueue.push(prompt);
    this.sortPullQueue();
  }

  /** Clear all prompts from the pull queue */
  clearPullQueue(): void {
    this._pullModeQueue = [];
  }

  // -------------------------------------------------------------------------
  // Preview Mode Methods
  // -------------------------------------------------------------------------

  /**
   * Log a prompt that would have been shown in real-time mode.
   * @param prompt - The coaching prompt to log
   */
  logPreview(prompt: CoachingPrompt): void {
    this._previewLog.push(prompt);
  }

  /** Clear the preview log */
  clearPreviewLog(): void {
    this._previewLog = [];
  }

  // -------------------------------------------------------------------------
  // Reset
  // -------------------------------------------------------------------------

  /** Reset all timing settings to defaults and clear queues */
  resetToDefaults(): void {
    this._autoDismissPreset = AutoDismissPreset.Standard;
    this._deliveryMode = CoachingDeliveryMode.Realtime;
    this.clearPullQueue();
    this.clearPreviewLog();
  }

  // -------------------------------------------------------------------------
  // Private
  // -------------------------------------------------------------------------

  private sortPullQueue(): void {
    this._pullModeQueue.sort((a, b) => {
      const priorityA = CoachingFunctionTypePriority[a.type];
      const priorityB = CoachingFunctionTypePriority[b.type];
      if (priorityA !== priorityB) {
        return priorityA - priorityB;
      }
      return a.timestamp - b.timestamp;
    });
  }
}
