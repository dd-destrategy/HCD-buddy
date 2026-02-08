/**
 * Redaction Service - ported from Features/Transcript/RedactionService.swift
 *
 * Manages PII redaction state and consent tracking.
 * Pure logic class with no filesystem or framework dependencies.
 */

import {
  type PIIDetection,
  type PIIType,
  PIITypeRedactionLabel,
} from '../analysis/pii-detector';

// ---------------------------------------------------------------------------
// Consent Status
// ---------------------------------------------------------------------------

/** Status of consent for a session */
export enum ConsentStatus {
  NotObtained = 'not_obtained',
  VerbalConsent = 'verbal',
  WrittenConsent = 'written',
  Declined = 'declined',
}

/** Display names for consent statuses */
export const ConsentStatusDisplayName: Record<ConsentStatus, string> = {
  [ConsentStatus.NotObtained]: 'Not Obtained',
  [ConsentStatus.VerbalConsent]: 'Verbal Consent',
  [ConsentStatus.WrittenConsent]: 'Written Consent',
  [ConsentStatus.Declined]: 'Declined',
};

/** Color tokens for consent statuses */
export const ConsentStatusColor: Record<ConsentStatus, string> = {
  [ConsentStatus.NotObtained]: 'hcdWarning',
  [ConsentStatus.VerbalConsent]: 'hcdSuccess',
  [ConsentStatus.WrittenConsent]: 'hcdSuccess',
  [ConsentStatus.Declined]: 'hcdError',
};

/** All consent statuses */
export const allConsentStatuses: ConsentStatus[] = [
  ConsentStatus.NotObtained,
  ConsentStatus.VerbalConsent,
  ConsentStatus.WrittenConsent,
  ConsentStatus.Declined,
];

// ---------------------------------------------------------------------------
// Redaction Decision
// ---------------------------------------------------------------------------

/** The decision made for a detected PII instance */
export enum RedactionDecision {
  /** Replace with the PII type label (e.g., [EMAIL]) */
  Redact = 'redact',
  /** Keep the original text unchanged */
  Keep = 'keep',
  /** Replace with custom user-provided text */
  Replace = 'replace',
}

// ---------------------------------------------------------------------------
// Redaction Action
// ---------------------------------------------------------------------------

/** A redaction action taken on a detected PII instance */
export interface RedactionAction {
  id: string;
  detectionId: string;
  action: RedactionDecision;
  replacement: string;
  performedAt: string; // ISO 8601
  performedBy: string;
}

// ---------------------------------------------------------------------------
// Consent Record
// ---------------------------------------------------------------------------

/** Record of consent status for a specific session */
export interface ConsentRecord {
  id: string;
  sessionId: string;
  status: ConsentStatus;
  obtainedAt: string | null; // ISO 8601 or null
  notes: string | null;
}

// ---------------------------------------------------------------------------
// Redaction Service
// ---------------------------------------------------------------------------

/** Configuration for RedactionService */
export interface RedactionServiceConfig {
  /** Initial detections */
  detections?: PIIDetection[];
  /** Initial actions */
  actions?: RedactionAction[];
  /** Initial consent records */
  consentRecords?: ConsentRecord[];
}

/**
 * Manages PII redaction state and consent tracking.
 *
 * Pure logic class that maintains in-memory state. Persistence is handled
 * by the consuming application layer.
 */
export class RedactionService {
  private _detections: PIIDetection[] = [];
  private _actions: RedactionAction[] = [];
  private _consentRecords: ConsentRecord[] = [];

  constructor(config: RedactionServiceConfig = {}) {
    this._detections = config.detections ?? [];
    this._actions = config.actions ?? [];
    this._consentRecords = config.consentRecords ?? [];
  }

  // -------------------------------------------------------------------------
  // Accessors
  // -------------------------------------------------------------------------

  /** All PII detections from the most recent scan */
  get detections(): readonly PIIDetection[] {
    return this._detections;
  }

  /** All redaction actions taken */
  get actions(): readonly RedactionAction[] {
    return this._actions;
  }

  /** All consent records */
  get consentRecords(): readonly ConsentRecord[] {
    return this._consentRecords;
  }

  // -------------------------------------------------------------------------
  // Detection Management
  // -------------------------------------------------------------------------

  /**
   * Set the detections for the current session.
   * @param detections - Array of PII detections from scanning
   */
  setDetections(detections: PIIDetection[]): void {
    this._detections = [...detections];
  }

  /**
   * Add detections to the current set.
   * @param detections - Additional PII detections
   */
  addDetections(detections: PIIDetection[]): void {
    this._detections.push(...detections);
  }

  // -------------------------------------------------------------------------
  // Redaction Actions
  // -------------------------------------------------------------------------

  /**
   * Apply a redaction decision to a specific detection.
   * @param decision - The redaction decision
   * @param detection - The PII detection to act on
   * @param replacement - Optional custom replacement text (for Replace decision)
   */
  applyRedaction(
    decision: RedactionDecision,
    detection: PIIDetection,
    replacement?: string,
  ): void {
    let replacementText: string;
    switch (decision) {
      case RedactionDecision.Redact:
        replacementText = PIITypeRedactionLabel[detection.type];
        break;
      case RedactionDecision.Keep:
        replacementText = detection.matchedText;
        break;
      case RedactionDecision.Replace:
        replacementText = replacement ?? PIITypeRedactionLabel[detection.type];
        break;
    }

    const action: RedactionAction = {
      id: crypto.randomUUID(),
      detectionId: detection.id,
      action: decision,
      replacement: replacementText,
      performedAt: new Date().toISOString(),
      performedBy: 'user',
    };

    // Remove any existing action for this detection
    this._actions = this._actions.filter((a) => a.detectionId !== detection.id);
    this._actions.push(action);
  }

  /**
   * Apply redactions to a text string for a given utterance (used during export).
   *
   * Processes all redaction actions for the utterance in reverse order
   * to preserve character offsets while making replacements.
   *
   * @param text - The original text
   * @param utteranceId - The utterance ID whose actions should be applied
   * @returns The text with all redactions applied
   */
  applyRedactionsToText(text: string, utteranceId: string): string {
    // Find detections for this utterance
    const utteranceDetections = this._detections.filter(
      (d) => d.utteranceId === utteranceId,
    );

    // Build a map of detection ID to action
    const actionMap = new Map<string, RedactionAction>();
    for (const action of this._actions) {
      actionMap.set(action.detectionId, action);
    }

    // Collect applicable replacements
    const replacements: Array<{
      startOffset: number;
      endOffset: number;
      replacement: string;
    }> = [];

    for (const detection of utteranceDetections) {
      const action = actionMap.get(detection.id);
      if (!action) continue;
      // Only apply redact and replace; keep leaves text unchanged
      if (action.action === RedactionDecision.Keep) continue;
      replacements.push({
        startOffset: detection.startOffset,
        endOffset: detection.endOffset,
        replacement: action.replacement,
      });
    }

    // Sort descending by startOffset so we replace from end to start
    replacements.sort((a, b) => b.startOffset - a.startOffset);

    let result = text;
    for (const rep of replacements) {
      if (rep.startOffset >= 0 && rep.endOffset <= result.length && rep.startOffset <= rep.endOffset) {
        result = result.slice(0, rep.startOffset) + rep.replacement + result.slice(rep.endOffset);
      }
    }

    return result;
  }

  /**
   * Batch-redact all detections of a given PII type.
   * @param type - The PII type to redact
   */
  batchRedact(type: PIIType): void {
    const typeDetections = this._detections.filter((d) => d.type === type);
    for (const detection of typeDetections) {
      const hasAction = this._actions.some((a) => a.detectionId === detection.id);
      if (!hasAction) {
        this.applyRedaction(RedactionDecision.Redact, detection);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Consent Tracking
  // -------------------------------------------------------------------------

  /**
   * Get the consent record for a specific session.
   * @param sessionId - The session ID
   * @returns The consent record, or null if none exists
   */
  consentRecord(sessionId: string): ConsentRecord | null {
    return this._consentRecords.find((r) => r.sessionId === sessionId) ?? null;
  }

  /**
   * Set the consent status for a session.
   * @param status - The consent status
   * @param sessionId - The session ID
   * @param notes - Optional notes about the consent
   */
  setConsentStatus(
    status: ConsentStatus,
    sessionId: string,
    notes?: string,
  ): void {
    // Remove existing record for this session
    this._consentRecords = this._consentRecords.filter(
      (r) => r.sessionId !== sessionId,
    );

    const record: ConsentRecord = {
      id: crypto.randomUUID(),
      sessionId,
      status,
      obtainedAt:
        status === ConsentStatus.VerbalConsent ||
        status === ConsentStatus.WrittenConsent
          ? new Date().toISOString()
          : null,
      notes: notes ?? null,
    };

    this._consentRecords.push(record);
  }

  // -------------------------------------------------------------------------
  // Querying
  // -------------------------------------------------------------------------

  /**
   * Get all detections that have no redaction action taken yet.
   * @returns Array of unresolved detections
   */
  unresolvedDetections(): PIIDetection[] {
    const resolvedIds = new Set(this._actions.map((a) => a.detectionId));
    return this._detections.filter((d) => !resolvedIds.has(d.id));
  }

  /**
   * Get detection counts grouped by PII type.
   * @returns Map of PII type to count
   */
  detectionCounts(): Map<PIIType, number> {
    const counts = new Map<PIIType, number>();
    for (const detection of this._detections) {
      counts.set(detection.type, (counts.get(detection.type) ?? 0) + 1);
    }
    return counts;
  }

  /**
   * Export the current state as a serializable object.
   */
  exportState(): {
    detections: PIIDetection[];
    actions: RedactionAction[];
    consentRecords: ConsentRecord[];
  } {
    return {
      detections: [...this._detections],
      actions: [...this._actions],
      consentRecords: [...this._consentRecords],
    };
  }

  /**
   * Import state from a serialized object.
   */
  importState(state: {
    detections?: PIIDetection[];
    actions?: RedactionAction[];
    consentRecords?: ConsentRecord[];
  }): void {
    if (state.detections) this._detections = [...state.detections];
    if (state.actions) this._actions = [...state.actions];
    if (state.consentRecords) this._consentRecords = [...state.consentRecords];
  }

  /** Clear all state */
  reset(): void {
    this._detections = [];
    this._actions = [];
    this._consentRecords = [];
  }
}
