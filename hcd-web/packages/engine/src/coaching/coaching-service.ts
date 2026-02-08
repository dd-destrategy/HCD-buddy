/**
 * Coaching Service - ported from Features/Coaching/CoachingService.swift
 *
 * Main coaching service implementing silence-first philosophy.
 *
 * Core Rules:
 * - DEFAULT OFF for first session - user must explicitly enable
 * - Minimum 85% confidence before showing prompt
 * - 2-minute cooldown between prompts
 * - Wait 5 seconds after any speech before showing
 * - Maximum 3 prompts per session
 * - Auto-dismiss after 8 seconds
 */

import {
  type CoachingThresholds,
  CoachingFunctionType,
  CoachingFunctionTypePriority,
  createCoachingThresholds,
  effectiveConfidenceThreshold,
  effectiveCooldown,
  DEFAULT_THRESHOLDS,
} from './coaching-thresholds';

// ---------------------------------------------------------------------------
// Coaching Response
// ---------------------------------------------------------------------------

/** User response to a coaching prompt */
export enum CoachingResponse {
  /** Prompt was accepted/used */
  Accepted = 'accepted',
  /** Prompt was dismissed without action */
  Dismissed = 'dismissed',
  /** Prompt was snoozed (extends cooldown) */
  Snoozed = 'snoozed',
  /** Prompt auto-dismissed after timeout */
  AutoDismissed = 'auto_dismissed',
}

/** Display names for coaching responses */
export const CoachingResponseDisplayName: Record<CoachingResponse, string> = {
  [CoachingResponse.Accepted]: 'Accepted',
  [CoachingResponse.Dismissed]: 'Dismissed',
  [CoachingResponse.Snoozed]: 'Snoozed',
  [CoachingResponse.AutoDismissed]: 'Auto-Dismissed',
};

// ---------------------------------------------------------------------------
// Coaching Prompt
// ---------------------------------------------------------------------------

/** Represents a coaching prompt to be displayed to the user */
export interface CoachingPrompt {
  id: string;
  type: CoachingFunctionType;
  text: string;
  reason: string;
  confidence: number;
  timestamp: number;
  createdAt: string; // ISO 8601
}

/**
 * Create a new coaching prompt
 */
export function createCoachingPrompt(params: Omit<CoachingPrompt, 'id' | 'createdAt'> & {
  id?: string;
  createdAt?: string;
}): CoachingPrompt {
  return {
    id: params.id ?? crypto.randomUUID(),
    type: params.type,
    text: params.text,
    reason: params.reason,
    confidence: params.confidence,
    timestamp: params.timestamp,
    createdAt: params.createdAt ?? new Date().toISOString(),
  };
}

// ---------------------------------------------------------------------------
// Function Call Event
// ---------------------------------------------------------------------------

/** A function call event from the AI */
export interface FunctionCallEvent {
  name: string;
  arguments: Record<string, string>;
  timestamp: number;
}

// ---------------------------------------------------------------------------
// Coaching Event Listener
// ---------------------------------------------------------------------------

/** Listener for coaching service events */
export interface CoachingEventListener {
  onPromptShown?(prompt: CoachingPrompt): void;
  onPromptDismissed?(promptId: string, response: CoachingResponse): void;
  onPromptAutoDismissed?(promptId: string): void;
  onCoachingEnabled?(): void;
  onCoachingDisabled?(): void;
}

// ---------------------------------------------------------------------------
// Coaching Service
// ---------------------------------------------------------------------------

/** Configuration options for CoachingService */
export interface CoachingServiceConfig {
  thresholds?: CoachingThresholds;
  isEnabled?: boolean;
  listener?: CoachingEventListener;
}

/**
 * Main coaching service implementing silence-first philosophy.
 *
 * Pure logic class with no framework dependencies.
 * Manages coaching prompts, cooldown tracking, confidence gating,
 * speech delay, max prompts per session, and cultural context adjustments.
 */
export class CoachingService {
  // -- State --
  private _currentPrompt: CoachingPrompt | null = null;
  private _isEnabled: boolean;
  private _pendingPrompts: CoachingPrompt[] = [];
  private _currentTimestamp: number = 0;
  private _promptsShown: number = 0;

  private _thresholds: CoachingThresholds;
  private _lastPromptTime: number | null = null;
  private _lastSpeechTime: number | null = null;
  private _autoDismissTimer: ReturnType<typeof setTimeout> | null = null;
  private _listener: CoachingEventListener | null;

  constructor(config: CoachingServiceConfig = {}) {
    this._thresholds = config.thresholds ?? { ...DEFAULT_THRESHOLDS };
    this._isEnabled = config.isEnabled ?? false;
    this._listener = config.listener ?? null;
  }

  // -------------------------------------------------------------------------
  // Public Accessors
  // -------------------------------------------------------------------------

  /** Currently displayed coaching prompt (null if none) */
  get currentPrompt(): CoachingPrompt | null {
    return this._currentPrompt;
  }

  /** Whether coaching is enabled for this session */
  get isEnabled(): boolean {
    return this._isEnabled;
  }

  /** Queue of pending prompts */
  get pendingPrompts(): readonly CoachingPrompt[] {
    return this._pendingPrompts;
  }

  /** Current session timestamp (updated externally) */
  get currentTimestamp(): number {
    return this._currentTimestamp;
  }

  /** Number of prompts shown in the current session */
  get promptCount(): number {
    return this._promptsShown;
  }

  /** Whether we've reached the maximum prompts for this session */
  get hasReachedMaxPrompts(): boolean {
    return this._promptsShown >= this._thresholds.maxPromptsPerSession;
  }

  /** Whether a prompt is currently being displayed */
  get isShowingPrompt(): boolean {
    return this._currentPrompt !== null;
  }

  /** Current thresholds */
  get thresholds(): CoachingThresholds {
    return this._thresholds;
  }

  /** Time until cooldown expires (0 if not in cooldown) */
  get cooldownRemaining(): number {
    if (this._lastPromptTime === null) return 0;
    const elapsed = Date.now() - this._lastPromptTime;
    return Math.max(0, effectiveCooldown(this._thresholds) * 1000 - elapsed) / 1000;
  }

  /** Whether we're currently in cooldown period */
  get isInCooldown(): boolean {
    return this.cooldownRemaining > 0;
  }

  // -------------------------------------------------------------------------
  // Configuration
  // -------------------------------------------------------------------------

  /** Update the coaching thresholds */
  updateThresholds(thresholds: Partial<CoachingThresholds>): void {
    this._thresholds = createCoachingThresholds({
      ...this._thresholds,
      ...thresholds,
    });
  }

  /** Set the event listener */
  setListener(listener: CoachingEventListener | null): void {
    this._listener = listener;
  }

  // -------------------------------------------------------------------------
  // Session Lifecycle
  // -------------------------------------------------------------------------

  /**
   * Start coaching for a new session.
   * Resets all state.
   */
  startSession(options?: { isEnabled?: boolean }): void {
    this._currentPrompt = null;
    this._pendingPrompts = [];
    this._lastPromptTime = null;
    this._lastSpeechTime = null;
    this._currentTimestamp = 0;
    this._promptsShown = 0;
    this.clearAutoDismissTimer();

    // SILENCE-FIRST: default off unless explicitly enabled
    this._isEnabled = options?.isEnabled ?? this._isEnabled;
  }

  /** End the current coaching session */
  endSession(): void {
    this.clearAutoDismissTimer();
    this._currentPrompt = null;
    this._pendingPrompts = [];
  }

  // -------------------------------------------------------------------------
  // Enable/Disable
  // -------------------------------------------------------------------------

  /** Enable coaching for the current session */
  enable(): void {
    if (this._isEnabled) return;
    this._isEnabled = true;
    this._listener?.onCoachingEnabled?.();
    this.processNextPendingPrompt();
  }

  /** Disable coaching for the current session */
  disable(): void {
    if (!this._isEnabled) return;
    this._isEnabled = false;

    if (this._currentPrompt !== null) {
      this.dismiss(CoachingResponse.Dismissed);
    }

    this._pendingPrompts = [];
    this._listener?.onCoachingDisabled?.();
  }

  // -------------------------------------------------------------------------
  // Prompt Management
  // -------------------------------------------------------------------------

  /**
   * Dismiss the current prompt.
   * @param response - The user's response (default: dismissed)
   */
  dismiss(response: CoachingResponse = CoachingResponse.Dismissed): void {
    const prompt = this._currentPrompt;
    if (!prompt) return;

    this.clearAutoDismissTimer();
    this._listener?.onPromptDismissed?.(prompt.id, response);
    this._currentPrompt = null;

    // Process next pending prompt after brief delay
    setTimeout(() => this.processNextPendingPrompt(), 500);
  }

  /** Accept the current prompt */
  accept(): void {
    this.dismiss(CoachingResponse.Accepted);
  }

  /** Snooze the current prompt (extends cooldown) */
  snooze(): void {
    this._lastPromptTime = Date.now();
    this.dismiss(CoachingResponse.Snoozed);
  }

  /**
   * Process a function call event from the AI.
   * @param event - The function call event containing coaching data
   */
  processFunctionCall(event: FunctionCallEvent): void {
    // SILENCE-FIRST: Check if coaching is active
    if (!this._isEnabled) return;

    const prompt = this.parsePromptFromFunctionCall(event);
    if (!prompt) return;

    this.queuePrompt(prompt);
  }

  /** Notify the service that speech was detected */
  notifySpeechDetected(): void {
    this._lastSpeechTime = Date.now();
  }

  /** Update the current session timestamp */
  updateTimestamp(timestamp: number): void {
    this._currentTimestamp = timestamp;
  }

  /**
   * Directly submit a coaching prompt for display.
   * Validates and queues the prompt according to the rules.
   */
  submitPrompt(prompt: CoachingPrompt): void {
    if (!this._isEnabled) return;
    this.queuePrompt(prompt);
  }

  // -------------------------------------------------------------------------
  // Private Methods
  // -------------------------------------------------------------------------

  private parsePromptFromFunctionCall(event: FunctionCallEvent): CoachingPrompt | null {
    // Determine prompt type from function name
    let type: CoachingFunctionType | null =
      Object.values(CoachingFunctionType).includes(event.name as CoachingFunctionType)
        ? (event.name as CoachingFunctionType)
        : null;

    if (!type) {
      type = this.inferPromptType(event.name);
      if (!type) return null;
    }

    return this.createPromptFromArgs(type, event.arguments, event.timestamp);
  }

  private inferPromptType(name: string): CoachingFunctionType | null {
    const lowercased = name.toLowerCase();

    if (lowercased.includes('follow') || lowercased.includes('question')) {
      return CoachingFunctionType.SuggestFollowUp;
    } else if (lowercased.includes('deep') || lowercased.includes('explore')) {
      return CoachingFunctionType.ExploreDeeper;
    } else if (lowercased.includes('topic') || lowercased.includes('uncovered')) {
      return CoachingFunctionType.UncoveredTopic;
    } else if (lowercased.includes('pivot') || lowercased.includes('redirect')) {
      return CoachingFunctionType.SuggestPivot;
    } else if (lowercased.includes('encourage') || lowercased.includes('good')) {
      return CoachingFunctionType.Encouragement;
    } else if (lowercased.includes('tip') || lowercased.includes('hint')) {
      return CoachingFunctionType.GeneralTip;
    }

    return null;
  }

  private createPromptFromArgs(
    type: CoachingFunctionType,
    args: Record<string, string>,
    timestamp: number,
  ): CoachingPrompt {
    const text = args['text'] ?? args['prompt'] ?? args['message'] ?? 'Consider this approach...';
    const reason = args['reason'] ?? args['context'] ?? '';
    const confidenceString = args['confidence'] ?? '0.85';
    const confidence = parseFloat(confidenceString) || 0.85;

    return createCoachingPrompt({
      type,
      text,
      reason,
      confidence,
      timestamp,
    });
  }

  private queuePrompt(prompt: CoachingPrompt): void {
    if (!this.validatePrompt(prompt)) return;

    if (this.canShowPromptNow()) {
      this.showPrompt(prompt);
    } else {
      this._pendingPrompts.push(prompt);
      this.sortPendingPrompts();
    }
  }

  private validatePrompt(prompt: CoachingPrompt): boolean {
    // RULE: Maximum prompts per session
    if (this.hasReachedMaxPrompts) return false;

    // RULE: Minimum confidence threshold
    if (prompt.confidence < effectiveConfidenceThreshold(this._thresholds)) return false;

    return true;
  }

  private canShowPromptNow(): boolean {
    // Already showing a prompt
    if (this._currentPrompt !== null) return false;

    // RULE: 2-minute cooldown between prompts
    if (this.isInCooldown) return false;

    // RULE: Wait 5 seconds after speech
    if (this._lastSpeechTime !== null) {
      const timeSinceSpeech = (Date.now() - this._lastSpeechTime) / 1000;
      if (timeSinceSpeech < this._thresholds.speechCooldown) return false;
    }

    return true;
  }

  private showPrompt(prompt: CoachingPrompt): void {
    this._promptsShown++;
    this._lastPromptTime = Date.now();
    this._currentPrompt = prompt;

    this._listener?.onPromptShown?.(prompt);

    this.startAutoDismissTimer();
  }

  private startAutoDismissTimer(): void {
    this.clearAutoDismissTimer();

    const duration = this._thresholds.autoDismissDuration;

    this._autoDismissTimer = setTimeout(() => {
      if (this._currentPrompt) {
        const promptId = this._currentPrompt.id;
        this._listener?.onPromptAutoDismissed?.(promptId);
        this._currentPrompt = null;
        this.processNextPendingPrompt();
      }
    }, duration * 1000);
  }

  private clearAutoDismissTimer(): void {
    if (this._autoDismissTimer !== null) {
      clearTimeout(this._autoDismissTimer);
      this._autoDismissTimer = null;
    }
  }

  private processNextPendingPrompt(): void {
    if (!this._isEnabled) return;
    if (this._pendingPrompts.length === 0) return;
    if (!this.canShowPromptNow()) return;

    const prompt = this._pendingPrompts.shift()!;

    // Re-validate (conditions may have changed)
    if (this.validatePrompt(prompt)) {
      this.showPrompt(prompt);
    } else {
      // Try next prompt
      this.processNextPendingPrompt();
    }
  }

  private sortPendingPrompts(): void {
    this._pendingPrompts.sort((a, b) => {
      const priorityA = CoachingFunctionTypePriority[a.type];
      const priorityB = CoachingFunctionTypePriority[b.type];
      if (priorityA !== priorityB) {
        return priorityA - priorityB;
      }
      return a.timestamp - b.timestamp;
    });
  }
}
