/**
 * PII Detector - ported from Features/Transcript/PIIDetector.swift
 *
 * Detects personally identifiable information in text using regex patterns
 * and heuristics. Supports email, phone, SSN, credit card, name, company,
 * and address detection.
 */

// ---------------------------------------------------------------------------
// PII Types
// ---------------------------------------------------------------------------

/** Types of personally identifiable information that can be detected */
export enum PIIType {
  Email = 'email',
  Phone = 'phone',
  SSN = 'ssn',
  Name = 'name',
  Company = 'company',
  Address = 'address',
  CreditCard = 'credit_card',
}

/** Display names for PII types */
export const PIITypeDisplayName: Record<PIIType, string> = {
  [PIIType.Email]: 'Email Address',
  [PIIType.Phone]: 'Phone Number',
  [PIIType.SSN]: 'Social Security Number',
  [PIIType.Name]: 'Person Name',
  [PIIType.Company]: 'Company Name',
  [PIIType.Address]: 'Street Address',
  [PIIType.CreditCard]: 'Credit Card Number',
};

/** Redaction labels for PII types */
export const PIITypeRedactionLabel: Record<PIIType, string> = {
  [PIIType.Email]: '[EMAIL]',
  [PIIType.Phone]: '[PHONE]',
  [PIIType.SSN]: '[SSN]',
  [PIIType.Name]: '[NAME]',
  [PIIType.Company]: '[COMPANY]',
  [PIIType.Address]: '[ADDRESS]',
  [PIIType.CreditCard]: '[CREDIT_CARD]',
};

/** All PII types */
export const allPIITypes: PIIType[] = [
  PIIType.Email,
  PIIType.Phone,
  PIIType.SSN,
  PIIType.Name,
  PIIType.Company,
  PIIType.Address,
  PIIType.CreditCard,
];

// ---------------------------------------------------------------------------
// PII Severity
// ---------------------------------------------------------------------------

/** Severity levels for PII detections */
export enum PIISeverity {
  /** Company names, general locations */
  Low = 1,
  /** Email addresses, phone numbers */
  Medium = 2,
  /** SSN, credit card numbers */
  High = 3,
  /** Combined PII that could identify someone */
  Critical = 4,
}

/** Display names for PII severity */
export const PIISeverityDisplayName: Record<PIISeverity, string> = {
  [PIISeverity.Low]: 'Low',
  [PIISeverity.Medium]: 'Medium',
  [PIISeverity.High]: 'High',
  [PIISeverity.Critical]: 'Critical',
};

/** Severity for each PII type */
export const PIITypeSeverity: Record<PIIType, PIISeverity> = {
  [PIIType.SSN]: PIISeverity.High,
  [PIIType.CreditCard]: PIISeverity.High,
  [PIIType.Email]: PIISeverity.Medium,
  [PIIType.Phone]: PIISeverity.Medium,
  [PIIType.Name]: PIISeverity.Medium,
  [PIIType.Address]: PIISeverity.Medium,
  [PIIType.Company]: PIISeverity.Low,
};

// ---------------------------------------------------------------------------
// PII Detection
// ---------------------------------------------------------------------------

/** A single detected PII instance in text */
export interface PIIDetection {
  id: string;
  type: PIIType;
  matchedText: string;
  startOffset: number;
  endOffset: number;
  confidence: number;
  utteranceId?: string;
  sessionId?: string;
}

// ---------------------------------------------------------------------------
// PII Detector
// ---------------------------------------------------------------------------

/** Configuration for PIIDetector */
export interface PIIDetectorConfig {
  /** Which PII types to scan for (defaults to all types) */
  enabledTypes?: Set<PIIType>;
}

/**
 * Detects PII in text using regex patterns and heuristics.
 *
 * Scans text for email addresses, phone numbers, SSNs, credit card numbers,
 * person names, company names, and street addresses.
 */
export class PIIDetector {
  private _enabledTypes: Set<PIIType>;

  constructor(config: PIIDetectorConfig = {}) {
    this._enabledTypes = config.enabledTypes ?? new Set(allPIITypes);
  }

  /** Get enabled PII types */
  get enabledTypes(): Set<PIIType> {
    return this._enabledTypes;
  }

  /** Set enabled PII types */
  set enabledTypes(types: Set<PIIType>) {
    this._enabledTypes = types;
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /**
   * Scan a single text string for PII.
   * @param text - The text to scan
   * @param utteranceId - Optional utterance ID to associate
   * @param sessionId - Optional session ID to associate
   * @returns Array of PII detections found in the text
   */
  detect(
    text: string,
    utteranceId?: string,
    sessionId?: string,
  ): PIIDetection[] {
    const detections: PIIDetection[] = [];

    if (this._enabledTypes.has(PIIType.Email)) {
      detections.push(...this.detectEmails(text, utteranceId, sessionId));
    }
    if (this._enabledTypes.has(PIIType.Phone)) {
      detections.push(...this.detectPhones(text, utteranceId, sessionId));
    }
    if (this._enabledTypes.has(PIIType.SSN)) {
      detections.push(...this.detectSSNs(text, utteranceId, sessionId));
    }
    if (this._enabledTypes.has(PIIType.CreditCard)) {
      detections.push(...this.detectCreditCards(text, utteranceId, sessionId));
    }
    if (this._enabledTypes.has(PIIType.Name)) {
      detections.push(...this.detectNames(text, utteranceId, sessionId));
    }
    if (this._enabledTypes.has(PIIType.Company)) {
      detections.push(...this.detectCompanies(text, utteranceId, sessionId));
    }
    if (this._enabledTypes.has(PIIType.Address)) {
      detections.push(...this.detectAddresses(text, utteranceId, sessionId));
    }

    // Sort by position in text
    return detections.sort((a, b) => a.startOffset - b.startOffset);
  }

  /**
   * Quick check whether text contains any PII.
   * @param text - The text to check
   * @returns true if any PII is detected
   */
  containsPII(text: string): boolean {
    return this.detect(text).length > 0;
  }

  /**
   * Redact all detected PII in text, replacing with type labels.
   * @param text - The text to redact
   * @returns The redacted text
   */
  redact(text: string): string {
    const detections = this.detect(text);
    if (detections.length === 0) return text;

    // Apply from end to start to preserve offsets
    const sorted = [...detections].sort((a, b) => b.startOffset - a.startOffset);
    let result = text;
    for (const detection of sorted) {
      const before = result.slice(0, detection.startOffset);
      const after = result.slice(detection.endOffset);
      result = before + PIITypeRedactionLabel[detection.type] + after;
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Private Detection Methods
  // -------------------------------------------------------------------------

  /** Detect email addresses */
  private detectEmails(
    text: string,
    utteranceId?: string,
    sessionId?: string,
  ): PIIDetection[] {
    const pattern = /[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/g;
    return this.matchPattern(pattern, text, PIIType.Email, 0.95, utteranceId, sessionId);
  }

  /** Detect US phone numbers in various formats */
  private detectPhones(
    text: string,
    utteranceId?: string,
    sessionId?: string,
  ): PIIDetection[] {
    const pattern = /\b(\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b/g;
    return this.matchPattern(pattern, text, PIIType.Phone, 0.9, utteranceId, sessionId);
  }

  /** Detect Social Security Numbers (XXX-XX-XXXX) */
  private detectSSNs(
    text: string,
    utteranceId?: string,
    sessionId?: string,
  ): PIIDetection[] {
    const pattern = /\b\d{3}-\d{2}-\d{4}\b/g;
    return this.matchPattern(pattern, text, PIIType.SSN, 0.95, utteranceId, sessionId);
  }

  /** Detect credit card numbers (4 groups of 4 digits) */
  private detectCreditCards(
    text: string,
    utteranceId?: string,
    sessionId?: string,
  ): PIIDetection[] {
    const pattern = /\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b/g;
    return this.matchPattern(pattern, text, PIIType.CreditCard, 0.9, utteranceId, sessionId);
  }

  /**
   * Detect person names using heuristics:
   * - Phrases like "I'm John", "my name is Sarah Smith", etc.
   * - Two or more consecutive capitalized words not at sentence start
   */
  private detectNames(
    text: string,
    utteranceId?: string,
    sessionId?: string,
  ): PIIDetection[] {
    const detections: PIIDetection[] = [];

    // Pattern 1: "I'm <Name>", "my name is <Name>", etc.
    const introPatterns = [
      /(?:I'm|I am|my name is|name's|they call me|called)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/g,
      /(?:this is|meet|introducing)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/g,
    ];

    for (const pattern of introPatterns) {
      let match: RegExpExecArray | null;
      while ((match = pattern.exec(text)) !== null) {
        if (match[1]) {
          const matchedName = match[1];
          const startOffset = match.index + match[0].indexOf(matchedName);
          const endOffset = startOffset + matchedName.length;
          const confidence = matchedName.includes(' ') ? 0.8 : 0.7;

          detections.push({
            id: crypto.randomUUID(),
            type: PIIType.Name,
            matchedText: matchedName,
            startOffset,
            endOffset,
            confidence,
            utteranceId,
            sessionId,
          });
        }
      }
    }

    // Pattern 2: Two or more consecutive capitalized words mid-sentence
    const multiCapPattern = /(?<=[a-z,;:]\s)([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)/g;
    const commonPhrases = new Set([
      'United States', 'New York', 'San Francisco', 'Los Angeles',
      'United Kingdom', 'New Zealand', 'South Africa',
    ]);

    let match: RegExpExecArray | null;
    while ((match = multiCapPattern.exec(text)) !== null) {
      const matchedText = match[1];
      if (commonPhrases.has(matchedText)) continue;

      const startOffset = match.index + match[0].indexOf(matchedText);
      const endOffset = startOffset + matchedText.length;

      // Check not already captured
      const alreadyCaptured = detections.some(
        (d) => d.startOffset === startOffset && d.endOffset === endOffset,
      );
      if (alreadyCaptured) continue;

      detections.push({
        id: crypto.randomUUID(),
        type: PIIType.Name,
        matchedText,
        startOffset,
        endOffset,
        confidence: 0.6,
        utteranceId,
        sessionId,
      });
    }

    return detections;
  }

  /**
   * Detect company names using heuristics:
   * - Words followed by corporate suffixes (Inc, Corp, LLC, etc.)
   * - Words preceded by "at", "work for", "work at"
   */
  private detectCompanies(
    text: string,
    utteranceId?: string,
    sessionId?: string,
  ): PIIDetection[] {
    const detections: PIIDetection[] = [];

    // Pattern 1: Company with suffix
    const suffixPattern =
      /([A-Z][A-Za-z&.']+(?:\s+[A-Z][A-Za-z&.']+)*)\s+(?:Inc\.?|Corp\.?|LLC|Ltd\.?|Company|Co\.?|Corporation|Incorporated|Limited|Group|Holdings|Partners|Associates)/g;
    let match: RegExpExecArray | null;
    while ((match = suffixPattern.exec(text)) !== null) {
      const matchedText = match[0];
      const startOffset = match.index;
      const endOffset = startOffset + matchedText.length;

      detections.push({
        id: crypto.randomUUID(),
        type: PIIType.Company,
        matchedText,
        startOffset,
        endOffset,
        confidence: 0.7,
        utteranceId,
        sessionId,
      });
    }

    // Pattern 2: "at <Company>", "work for <Company>", etc.
    const contextPattern =
      /(?:work (?:at|for)|employed (?:at|by)|join(?:ed)?|at)\s+([A-Z][A-Za-z&.']+(?:\s+[A-Z][A-Za-z&.']+)*)/g;
    while ((match = contextPattern.exec(text)) !== null) {
      if (match[1]) {
        const matchedText = match[1];
        const startOffset = match.index + match[0].indexOf(matchedText);
        const endOffset = startOffset + matchedText.length;

        const alreadyCaptured = detections.some(
          (d) => d.startOffset === startOffset && d.endOffset === endOffset,
        );
        if (alreadyCaptured) continue;

        detections.push({
          id: crypto.randomUUID(),
          type: PIIType.Company,
          matchedText,
          startOffset,
          endOffset,
          confidence: 0.5,
          utteranceId,
          sessionId,
        });
      }
    }

    return detections;
  }

  /** Detect street addresses */
  private detectAddresses(
    text: string,
    utteranceId?: string,
    sessionId?: string,
  ): PIIDetection[] {
    const pattern =
      /\b\d{1,5}\s+[A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*\s+(?:Street|St\.?|Avenue|Ave\.?|Boulevard|Blvd\.?|Drive|Dr\.?|Road|Rd\.?|Lane|Ln\.?|Court|Ct\.?|Place|Pl\.?|Way|Circle|Cir\.?|Trail|Trl\.?)(?:\s+(?:Apt\.?|Suite|Ste\.?|Unit|#)\s*\w+)?\b/g;
    return this.matchPattern(pattern, text, PIIType.Address, 0.85, utteranceId, sessionId);
  }

  // -------------------------------------------------------------------------
  // Private Helpers
  // -------------------------------------------------------------------------

  /** Generic regex pattern matcher */
  private matchPattern(
    pattern: RegExp,
    text: string,
    type: PIIType,
    confidence: number,
    utteranceId?: string,
    sessionId?: string,
  ): PIIDetection[] {
    const detections: PIIDetection[] = [];
    let match: RegExpExecArray | null;

    while ((match = pattern.exec(text)) !== null) {
      const matchedText = match[0];
      const startOffset = match.index;
      const endOffset = startOffset + matchedText.length;

      detections.push({
        id: crypto.randomUUID(),
        type,
        matchedText,
        startOffset,
        endOffset,
        confidence,
        utteranceId,
        sessionId,
      });
    }

    return detections;
  }
}
