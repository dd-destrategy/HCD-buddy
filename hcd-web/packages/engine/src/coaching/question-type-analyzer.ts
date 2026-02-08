/**
 * Question Type Analyzer - ported from Features/Coaching/QuestionTypeAnalyzer.swift
 *
 * Classifies interviewer questions into types using rules-based NLP.
 * Detects anti-patterns (leading, double-barreled, closed runs).
 */

import { Speaker } from '../models/speaker';

// ---------------------------------------------------------------------------
// Question Type
// ---------------------------------------------------------------------------

/** Classification types for interviewer questions */
export enum QuestionType {
  /** Open-ended questions that invite detailed responses */
  OpenEnded = 'open_ended',
  /** Yes/no or specific fact questions */
  Closed = 'closed',
  /** Questions containing assumptions or suggesting an answer */
  Leading = 'leading',
  /** Two questions combined into one */
  DoubleBarreled = 'double_barreled',
  /** Follow-up probes seeking deeper insight */
  Probing = 'probing',
  /** Questions seeking clarification of meaning */
  Clarifying = 'clarifying',
  /** Scenario-based questions about imagined situations */
  Hypothetical = 'hypothetical',
  /** Statements or non-questions misclassified as questions */
  NotAQuestion = 'not_a_question',
}

/** Display names for question types */
export const QuestionTypeDisplayName: Record<QuestionType, string> = {
  [QuestionType.OpenEnded]: 'Open-Ended',
  [QuestionType.Closed]: 'Closed',
  [QuestionType.Leading]: 'Leading',
  [QuestionType.DoubleBarreled]: 'Double-Barreled',
  [QuestionType.Probing]: 'Probing',
  [QuestionType.Clarifying]: 'Clarifying',
  [QuestionType.Hypothetical]: 'Hypothetical',
  [QuestionType.NotAQuestion]: 'Not a Question',
};

/** Color names for visual indicators */
export const QuestionTypeColor: Record<QuestionType, string> = {
  [QuestionType.OpenEnded]: 'green',
  [QuestionType.Closed]: 'blue',
  [QuestionType.Leading]: 'red',
  [QuestionType.DoubleBarreled]: 'orange',
  [QuestionType.Probing]: 'purple',
  [QuestionType.Clarifying]: 'cyan',
  [QuestionType.Hypothetical]: 'indigo',
  [QuestionType.NotAQuestion]: 'gray',
};

/** Whether this type is generally considered good practice in HCD interviews */
export const QuestionTypeIsDesirable: Record<QuestionType, boolean> = {
  [QuestionType.OpenEnded]: true,
  [QuestionType.Closed]: false,
  [QuestionType.Leading]: false,
  [QuestionType.DoubleBarreled]: false,
  [QuestionType.Probing]: true,
  [QuestionType.Clarifying]: true,
  [QuestionType.Hypothetical]: true,
  [QuestionType.NotAQuestion]: false,
};

// ---------------------------------------------------------------------------
// Anti-Pattern
// ---------------------------------------------------------------------------

/** Detected interview anti-patterns */
export enum AntiPattern {
  /** A question that leads the participant toward a specific answer */
  LeadingQuestion = 'leading_question',
  /** A question that asks about two things at once */
  DoubleBarreledQuestion = 'double_barreled_question',
  /** Three or more consecutive closed questions */
  ClosedQuestionRun = 'closed_question_run',
  /** Language that assumes participant's experience or opinion */
  AssumptiveLanguage = 'assumptive_language',
}

/** Display names for anti-patterns */
export const AntiPatternDisplayName: Record<AntiPattern, string> = {
  [AntiPattern.LeadingQuestion]: 'Leading Question',
  [AntiPattern.DoubleBarreledQuestion]: 'Double-Barreled',
  [AntiPattern.ClosedQuestionRun]: 'Closed Run',
  [AntiPattern.AssumptiveLanguage]: 'Assumptive Language',
};

/** Descriptions for anti-patterns */
export const AntiPatternDescription: Record<AntiPattern, string> = {
  [AntiPattern.LeadingQuestion]:
    'This question may guide the participant toward a particular answer. Try rephrasing neutrally.',
  [AntiPattern.DoubleBarreledQuestion]:
    'This asks about multiple things at once. Split into separate questions for clearer data.',
  [AntiPattern.ClosedQuestionRun]:
    'Multiple closed questions in a row. Consider an open-ended question to let the participant share freely.',
  [AntiPattern.AssumptiveLanguage]:
    'This language assumes something about the participant. Consider a more neutral framing.',
};

/** Severity for anti-patterns */
export const AntiPatternSeverity: Record<AntiPattern, number> = {
  [AntiPattern.LeadingQuestion]: 3,
  [AntiPattern.DoubleBarreledQuestion]: 2,
  [AntiPattern.ClosedQuestionRun]: 1,
  [AntiPattern.AssumptiveLanguage]: 2,
};

// ---------------------------------------------------------------------------
// Question Classification
// ---------------------------------------------------------------------------

/** Result of classifying an interviewer question */
export interface QuestionClassification {
  id: string;
  utteranceId: string;
  type: QuestionType;
  confidence: number;
  text: string;
  timestamp: number;
  antiPatterns: AntiPattern[];
}

// ---------------------------------------------------------------------------
// Question Stats
// ---------------------------------------------------------------------------

/** Aggregate statistics for question analysis */
export interface QuestionStats {
  totalQuestions: number;
  openEndedCount: number;
  closedCount: number;
  leadingCount: number;
  doubleBarreledCount: number;
  probingCount: number;
  openEndedPercentage: number;
  qualityScore: number;
}

/** Empty question stats */
export const EMPTY_QUESTION_STATS: QuestionStats = {
  totalQuestions: 0,
  openEndedCount: 0,
  closedCount: 0,
  leadingCount: 0,
  doubleBarreledCount: 0,
  probingCount: 0,
  openEndedPercentage: 0,
  qualityScore: 0,
};

// ---------------------------------------------------------------------------
// Utterance Input
// ---------------------------------------------------------------------------

/** Minimal utterance input for question analysis */
export interface UtteranceInput {
  id: string;
  text: string;
  speaker: Speaker;
  timestampSeconds: number;
}

// ---------------------------------------------------------------------------
// Question Type Analyzer
// ---------------------------------------------------------------------------

/** Configuration for QuestionTypeAnalyzer */
export interface QuestionTypeAnalyzerConfig {
  /** Threshold for detecting a closed question run (default: 3) */
  closedRunThreshold?: number;
}

/**
 * Classifies interviewer questions and detects anti-patterns using rules-based NLP.
 *
 * The analyzer processes each interviewer utterance to determine question type,
 * tracks patterns over time, and generates quality metrics for the interview session.
 */
export class QuestionTypeAnalyzer {
  private _classifications: QuestionClassification[] = [];
  private _sessionStats: QuestionStats = { ...EMPTY_QUESTION_STATS };
  private _currentAntiPatterns: AntiPattern[] = [];
  private _consecutiveClosedCount: number = 0;
  private readonly _closedRunThreshold: number;

  // -- Pattern Lists (exact match from Swift) --

  private readonly openEndedPrefixes: string[] = [
    'how ', 'how do ', 'how did ', 'how would ', 'how does ',
    'what ', 'what do ', 'what did ', 'what was ', 'what is ', 'what are ',
    'tell me about', 'tell me ', 'describe ', 'explain ',
    'walk me through', 'share with me', 'help me understand',
    'in what ways', 'what has been', 'what were',
  ];

  private readonly closedPrefixes: string[] = [
    'do you ', 'did you ', 'is it ', 'is that ', 'is there ',
    'are you ', 'are there ', 'have you ', 'has it ',
    'can you ', 'could you ', 'was it ', 'was that ',
    'will you ', 'would you ', 'were you ', 'should ',
    'does it ', 'does that ', "doesn't ", "isn't ",
  ];

  private readonly leadingPhrases: string[] = [
    "don't you think", "wouldn't you agree", "wouldn't you say",
    "isn't it true", "isn't it obvious", "isn't it clear",
    'surely ', 'obviously ', 'clearly ',
    'you would agree', 'you must think', 'you must feel',
    'most people think', 'everyone knows',
    "it's obvious that", "it's clear that",
    'right?', 'correct?', "isn't it?", "don't you?",
  ];

  private readonly assumptivePhrases: string[] = [
    'you must have felt', 'you probably think',
    "i'm sure you", 'i assume you', 'i bet you',
    'you obviously', 'you clearly', 'you definitely',
    'of course you', 'naturally you',
  ];

  private readonly probingPrefixes: string[] = [
    'why ', 'why do ', 'why did ', 'why is ', 'why was ',
    'tell me more', 'can you elaborate', 'could you elaborate',
    'what else', 'how so', 'in what way',
    'what makes you', 'what led you', 'what prompted',
    'can you give me an example', 'could you give me an example',
    'what do you mean when you say',
  ];

  private readonly clarifyingPhrases: string[] = [
    'what do you mean', 'what does that mean',
    'could you explain', 'can you explain',
    'what does that', 'what did you mean',
    'clarify', 'help me understand what',
    'when you say', 'by that do you mean',
    'i want to make sure i understand',
  ];

  private readonly hypotheticalPrefixes: string[] = [
    'what if ', 'what would ', 'imagine ',
    'suppose ', "let's say ", 'lets say ',
    'hypothetically', 'if you could ', 'if you were ',
    'in an ideal world', 'if there were no constraints',
  ];

  private readonly doubleBarrelConjunctions: string[] = [
    ' and do you ', ' and how ', ' and what ', ' and why ',
    ' and did you ', ' and are you ', ' and is it ',
    ' or do you ', ' or would you ', ' as well as ',
  ];

  constructor(config: QuestionTypeAnalyzerConfig = {}) {
    this._closedRunThreshold = config.closedRunThreshold ?? 3;
  }

  // -------------------------------------------------------------------------
  // Accessors
  // -------------------------------------------------------------------------

  /** All classifications from the current session */
  get classifications(): readonly QuestionClassification[] {
    return this._classifications;
  }

  /** Aggregate session statistics */
  get sessionStats(): QuestionStats {
    return this._sessionStats;
  }

  /** Currently active anti-patterns (recent detections) */
  get currentAntiPatterns(): readonly AntiPattern[] {
    return this._currentAntiPatterns;
  }

  // -------------------------------------------------------------------------
  // Public Methods
  // -------------------------------------------------------------------------

  /**
   * Classify an utterance and return its classification.
   *
   * Only processes interviewer utterances that appear to be questions.
   * Participant utterances and non-questions return null.
   *
   * @param utterance - The utterance to classify
   * @returns A classification result, or null if not an interviewer question
   */
  classify(utterance: UtteranceInput): QuestionClassification | null {
    // Only classify interviewer utterances
    if (utterance.speaker !== Speaker.Interviewer) return null;

    const text = utterance.text.trim();
    if (!text) return null;

    const lowercased = text.toLowerCase();

    // Determine if this is a question
    const isQuestion = this.detectIsQuestion(text, lowercased);

    if (!isQuestion) {
      // Reset consecutive closed count for non-questions
      this._consecutiveClosedCount = 0;
      return null;
    }

    // Classify the question type
    let detectedType = this.classifyQuestionType(lowercased);
    let confidence = this.calculateConfidence(detectedType, lowercased);
    const antiPatterns: AntiPattern[] = [];

    // Check for anti-patterns (these can override or supplement the type)
    const hasLeadingLanguage = this.detectLeadingLanguage(lowercased);
    const hasAssumptiveLanguage = this.detectAssumptiveLanguage(lowercased);
    const isDoubleBarreled = this.detectDoubleBarreled(lowercased);

    if (hasLeadingLanguage) {
      detectedType = QuestionType.Leading;
      confidence = Math.max(confidence, 0.85);
      antiPatterns.push(AntiPattern.LeadingQuestion);
    }

    if (hasAssumptiveLanguage) {
      antiPatterns.push(AntiPattern.AssumptiveLanguage);
      if (detectedType !== QuestionType.Leading) {
        confidence = Math.max(confidence, 0.75);
      }
    }

    if (isDoubleBarreled) {
      detectedType = QuestionType.DoubleBarreled;
      confidence = Math.max(confidence, 0.80);
      antiPatterns.push(AntiPattern.DoubleBarreledQuestion);
    }

    // Track consecutive closed questions
    if (detectedType === QuestionType.Closed) {
      this._consecutiveClosedCount++;
      if (this._consecutiveClosedCount >= this._closedRunThreshold) {
        antiPatterns.push(AntiPattern.ClosedQuestionRun);
      }
    } else {
      this._consecutiveClosedCount = 0;
    }

    const classification: QuestionClassification = {
      id: crypto.randomUUID(),
      utteranceId: utterance.id,
      type: detectedType,
      confidence,
      text,
      timestamp: utterance.timestampSeconds,
      antiPatterns,
    };

    // Update state
    this._classifications.push(classification);
    this.updateStats();
    this.updateCurrentAntiPatterns(classification);

    return classification;
  }

  /** Reset all analysis state for a new session */
  reset(): void {
    this._classifications = [];
    this._sessionStats = { ...EMPTY_QUESTION_STATS };
    this._currentAntiPatterns = [];
    this._consecutiveClosedCount = 0;
  }

  // -------------------------------------------------------------------------
  // Private Classification Methods
  // -------------------------------------------------------------------------

  /** Detect whether the text appears to be a question */
  private detectIsQuestion(text: string, lowercased: string): boolean {
    // Direct check: ends with question mark
    if (text.endsWith('?')) return true;

    // Check if it starts with an interrogative word or phrase
    const interrogativePrefixes = [
      'how ', 'what ', 'when ', 'where ', 'why ', 'who ', 'which ',
      'do ', 'did ', 'is ', 'are ', 'have ', 'has ', 'can ', 'could ',
      'was ', 'were ', 'will ', 'would ', 'should ', 'shall ',
      'does ', 'tell me', 'describe ', 'explain ',
    ];

    for (const prefix of interrogativePrefixes) {
      if (lowercased.startsWith(prefix)) return true;
    }

    return false;
  }

  /** Classify the question into its primary type */
  private classifyQuestionType(lowercased: string): QuestionType {
    // Check hypothetical first (very specific patterns)
    for (const prefix of this.hypotheticalPrefixes) {
      if (lowercased.startsWith(prefix) || lowercased.includes(prefix)) {
        return QuestionType.Hypothetical;
      }
    }

    // Check clarifying
    for (const phrase of this.clarifyingPhrases) {
      if (lowercased.includes(phrase)) {
        return QuestionType.Clarifying;
      }
    }

    // Check probing
    for (const prefix of this.probingPrefixes) {
      if (lowercased.startsWith(prefix) || lowercased.includes(prefix)) {
        return QuestionType.Probing;
      }
    }

    // Check open-ended
    for (const prefix of this.openEndedPrefixes) {
      if (lowercased.startsWith(prefix)) {
        return QuestionType.OpenEnded;
      }
    }

    // Check closed
    for (const prefix of this.closedPrefixes) {
      if (lowercased.startsWith(prefix)) {
        return QuestionType.Closed;
      }
    }

    // Default: if it's a question but doesn't match known patterns
    return QuestionType.Closed;
  }

  /** Calculate confidence score for the classification */
  private calculateConfidence(type: QuestionType, lowercased: string): number {
    switch (type) {
      case QuestionType.OpenEnded:
        if (lowercased.startsWith('tell me about') || lowercased.startsWith('walk me through')) {
          return 0.95;
        }
        if (lowercased.startsWith('how ') || lowercased.startsWith('what ')) {
          return 0.85;
        }
        return 0.75;

      case QuestionType.Closed:
        if (lowercased.startsWith('do you ') || lowercased.startsWith('did you ')) {
          return 0.90;
        }
        if (lowercased.startsWith('is ') || lowercased.startsWith('are ')) {
          return 0.85;
        }
        return 0.70;

      case QuestionType.Leading:
        return 0.90;

      case QuestionType.DoubleBarreled:
        return 0.80;

      case QuestionType.Probing:
        if (lowercased.startsWith('why ') || lowercased.includes('tell me more')) {
          return 0.90;
        }
        return 0.80;

      case QuestionType.Clarifying:
        if (lowercased.includes('what do you mean')) {
          return 0.95;
        }
        return 0.85;

      case QuestionType.Hypothetical:
        if (lowercased.startsWith('what if ') || lowercased.startsWith('imagine ')) {
          return 0.90;
        }
        return 0.80;

      case QuestionType.NotAQuestion:
        return 0.60;
    }
  }

  /** Detect leading language in the question */
  private detectLeadingLanguage(lowercased: string): boolean {
    return this.leadingPhrases.some((phrase) => lowercased.includes(phrase));
  }

  /** Detect assumptive language in the question */
  private detectAssumptiveLanguage(lowercased: string): boolean {
    return this.assumptivePhrases.some((phrase) => lowercased.includes(phrase));
  }

  /** Detect double-barreled question structure */
  private detectDoubleBarreled(lowercased: string): boolean {
    // Check for conjunction patterns that suggest two questions in one
    for (const conjunction of this.doubleBarrelConjunctions) {
      if (lowercased.includes(conjunction)) return true;
    }

    // Check for multiple question marks
    const questionMarkCount = (lowercased.match(/\?/g) || []).length;
    if (questionMarkCount >= 2) return true;

    // Check for " and " with question-like structure on both sides
    if (lowercased.includes(' and ')) {
      const parts = lowercased.split(' and ');
      if (parts.length >= 2) {
        const firstHasInterrogative = this.containsInterrogativeWord(parts[0]);
        const secondHasInterrogative = this.containsInterrogativeWord(parts[1]);
        if (firstHasInterrogative && secondHasInterrogative) return true;
      }
    }

    return false;
  }

  /** Check if text contains an interrogative word */
  private containsInterrogativeWord(text: string): boolean {
    const interrogatives = [
      'how', 'what', 'when', 'where', 'why', 'who', 'which',
      'do ', 'did ', 'is ', 'are ', 'have ', 'can ', 'could ',
      'would ', 'should ',
    ];
    const trimmed = text.trim();
    return interrogatives.some((word) => trimmed.includes(word));
  }

  // -------------------------------------------------------------------------
  // Stats Update
  // -------------------------------------------------------------------------

  /** Recalculate session statistics from all classifications */
  private updateStats(): void {
    const total = this._classifications.length;
    if (total === 0) {
      this._sessionStats = { ...EMPTY_QUESTION_STATS };
      return;
    }

    const openEnded = this._classifications.filter((c) => c.type === QuestionType.OpenEnded).length;
    const closed = this._classifications.filter((c) => c.type === QuestionType.Closed).length;
    const leading = this._classifications.filter((c) => c.type === QuestionType.Leading).length;
    const doubleBarreled = this._classifications.filter(
      (c) => c.type === QuestionType.DoubleBarreled,
    ).length;
    const probing = this._classifications.filter((c) => c.type === QuestionType.Probing).length;

    const openEndedPercentage = (openEnded / total) * 100.0;

    // Quality score: higher when more open-ended/probing, lower for leading/double-barreled
    const desirableCount = this._classifications.filter(
      (c) => QuestionTypeIsDesirable[c.type],
    ).length;
    const penaltyCount = leading + doubleBarreled;
    const baseScore = (desirableCount / total) * 100.0;
    const penalty = (penaltyCount / total) * 30.0;
    const qualityScore = Math.min(100.0, Math.max(0.0, baseScore - penalty));

    this._sessionStats = {
      totalQuestions: total,
      openEndedCount: openEnded,
      closedCount: closed,
      leadingCount: leading,
      doubleBarreledCount: doubleBarreled,
      probingCount: probing,
      openEndedPercentage,
      qualityScore,
    };
  }

  /** Update the list of current anti-patterns from the most recent classifications */
  private updateCurrentAntiPatterns(classification: QuestionClassification): void {
    // Show anti-patterns from the last few classifications (window of 5)
    const recentClassifications = this._classifications.slice(-5);
    const patternSet = new Set<AntiPattern>();

    for (const recent of recentClassifications) {
      for (const pattern of recent.antiPatterns) {
        patternSet.add(pattern);
      }
    }

    this._currentAntiPatterns = Array.from(patternSet).sort(
      (a, b) => AntiPatternSeverity[b] - AntiPatternSeverity[a],
    );
  }
}
