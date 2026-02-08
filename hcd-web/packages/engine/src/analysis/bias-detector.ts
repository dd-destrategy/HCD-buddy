/**
 * Bias Detector - ported from Features/Coaching/BiasDetector.swift
 *
 * Detects systematic bias patterns in interview question sequences.
 * Analyzes interviewer questions for gender bias, age bias, confirmation bias,
 * leading patterns, closed question overuse, and assumptive language.
 */

// ---------------------------------------------------------------------------
// Bias Severity
// ---------------------------------------------------------------------------

/** Severity level of a detected bias */
export enum BiasSeverity {
  /** Minor concern; pattern is subtle or infrequent */
  Low = 'low',
  /** Moderate concern; pattern may affect data quality */
  Medium = 'medium',
  /** Serious concern; pattern likely compromises interview validity */
  High = 'high',
}

/** Display names for bias severities */
export const BiasSeverityDisplayName: Record<BiasSeverity, string> = {
  [BiasSeverity.Low]: 'Low',
  [BiasSeverity.Medium]: 'Medium',
  [BiasSeverity.High]: 'High',
};

// ---------------------------------------------------------------------------
// Bias Type
// ---------------------------------------------------------------------------

/** Types of bias that can be detected in interview question patterns */
export enum BiasType {
  /** Questions using gendered language */
  GenderBias = 'gender_bias',
  /** Questions making assumptions based on age or generation */
  AgeBias = 'age_bias',
  /** Repeated use of confirming language seeking agreement */
  ConfirmationBias = 'confirmation_bias',
  /** Systematic overuse of leading questions */
  LeadingPatternBias = 'leading_pattern',
  /** Excessive reliance on closed questions */
  ClosedQuestionOveruse = 'closed_overuse',
  /** Language that assumes facts without verification */
  AssumptiveLanguage = 'assumptive',
}

/** Display names for bias types */
export const BiasTypeDisplayName: Record<BiasType, string> = {
  [BiasType.GenderBias]: 'Gender Bias',
  [BiasType.AgeBias]: 'Age Bias',
  [BiasType.ConfirmationBias]: 'Confirmation Bias',
  [BiasType.LeadingPatternBias]: 'Leading Pattern',
  [BiasType.ClosedQuestionOveruse]: 'Closed Question Overuse',
  [BiasType.AssumptiveLanguage]: 'Assumptive Language',
};

/** Descriptions for bias types */
export const BiasTypeDescription: Record<BiasType, string> = {
  [BiasType.GenderBias]:
    'Questions contain gendered language that may influence responses or exclude participants.',
  [BiasType.AgeBias]:
    'Questions reference age groups or generational stereotypes that may bias responses.',
  [BiasType.ConfirmationBias]:
    'Repeated seeking of agreement rather than open exploration of the participant\'s perspective.',
  [BiasType.LeadingPatternBias]:
    'A pattern of questions that steer participants toward predetermined answers.',
  [BiasType.ClosedQuestionOveruse]:
    'Over 60% of questions are closed, limiting the depth of participant responses.',
  [BiasType.AssumptiveLanguage]:
    'Language assumes facts about the participant\'s experience without verification.',
};

/** Default severity for each bias type */
export const BiasTypeDefaultSeverity: Record<BiasType, BiasSeverity> = {
  [BiasType.GenderBias]: BiasSeverity.High,
  [BiasType.AgeBias]: BiasSeverity.Medium,
  [BiasType.ConfirmationBias]: BiasSeverity.High,
  [BiasType.LeadingPatternBias]: BiasSeverity.Medium,
  [BiasType.ClosedQuestionOveruse]: BiasSeverity.Low,
  [BiasType.AssumptiveLanguage]: BiasSeverity.Medium,
};

/** All bias types */
export const allBiasTypes: BiasType[] = [
  BiasType.GenderBias,
  BiasType.AgeBias,
  BiasType.ConfirmationBias,
  BiasType.LeadingPatternBias,
  BiasType.ClosedQuestionOveruse,
  BiasType.AssumptiveLanguage,
];

// ---------------------------------------------------------------------------
// Bias Alert
// ---------------------------------------------------------------------------

/** A detected bias instance with context and actionable suggestion */
export interface BiasAlert {
  id: string;
  type: BiasType;
  /** Human-readable description of the specific bias instance */
  description: string;
  /** IDs of utterances that contributed to this detection */
  utteranceIds: string[];
  /** Confidence level of the detection (0.0-1.0) */
  confidence: number;
  /** Actionable suggestion for what to do differently */
  suggestion: string;
  /** When the bias was detected */
  detectedAt: string; // ISO 8601
}

// ---------------------------------------------------------------------------
// Classification Input
// ---------------------------------------------------------------------------

/** Input tuple for bias analysis: (utteranceId, text, questionType) */
export interface BiasClassificationInput {
  utteranceId: string;
  text: string;
  type: string;
}

// ---------------------------------------------------------------------------
// Bias Detector
// ---------------------------------------------------------------------------

/** Configuration for BiasDetector */
export interface BiasDetectorConfig {
  /** Minimum confirmations for confirmation bias (default: 3) */
  confirmationThreshold?: number;
  /** Minimum total questions for pattern-based detection (default: 3) */
  minQuestionsForPattern?: number;
  /** Leading question ratio threshold (default: 0.3) */
  leadingRatioThreshold?: number;
  /** Closed question ratio threshold (default: 0.6) */
  closedRatioThreshold?: number;
}

/**
 * Detects systematic bias patterns in interview question sequences.
 *
 * Operates on simple tuples of (utteranceId, text, type) to avoid
 * tight coupling with the QuestionTypeAnalyzer.
 */
export class BiasDetector {
  private _alerts: BiasAlert[] = [];
  private _isAnalyzing: boolean = false;

  private readonly confirmationThreshold: number;
  private readonly minQuestionsForPattern: number;
  private readonly leadingRatioThreshold: number;
  private readonly closedRatioThreshold: number;

  // -- Detection Keywords (exact from Swift) --

  private readonly genderKeywords: string[] = [
    'he ', 'she ', ' he ', ' she ',
    ' guys ', 'guys ', ' girls ', 'girls ',
    ' men ', 'men ', ' women ', 'women ',
    ' his ', 'his ', ' her ', ' her ',
    ' him ', 'him ', ' himself ', ' herself ',
    ' man ', ' woman ', ' boy ', ' girl ',
    ' boys ', ' gentlemen ', ' ladies ',
  ];

  private readonly ageKeywords: string[] = [
    'young people', 'older users', 'old people', 'elderly',
    'millennials', 'boomers', 'gen z', 'gen x',
    'your generation', 'your age group', 'kids these days',
    'back in your day', 'at your age', 'senior citizens',
    'the younger generation', 'the older generation',
  ];

  private readonly confirmationPhrases: string[] = [
    'right?', "isn't it?", "don't you think?",
    "wouldn't you agree?", 'correct?', "isn't that so?",
    "you'd agree that", 'surely you', 'obviously ',
  ];

  private readonly assumptivePhrases: string[] = [
    'obviously', 'clearly', 'of course',
    'everyone knows', 'most people',
    'as you know', 'naturally',
    "it's clear that", "it's obvious that",
    'without a doubt', 'undoubtedly',
    'as we all know', 'everybody thinks',
  ];

  constructor(config: BiasDetectorConfig = {}) {
    this.confirmationThreshold = config.confirmationThreshold ?? 3;
    this.minQuestionsForPattern = config.minQuestionsForPattern ?? 3;
    this.leadingRatioThreshold = config.leadingRatioThreshold ?? 0.3;
    this.closedRatioThreshold = config.closedRatioThreshold ?? 0.6;
  }

  // -------------------------------------------------------------------------
  // Accessors
  // -------------------------------------------------------------------------

  /** All bias alerts detected in the current session */
  get alerts(): readonly BiasAlert[] {
    return this._alerts;
  }

  /** Whether the detector is currently analyzing */
  get isAnalyzing(): boolean {
    return this._isAnalyzing;
  }

  // -------------------------------------------------------------------------
  // Public Methods
  // -------------------------------------------------------------------------

  /**
   * Analyze a sequence of question classifications for bias patterns.
   *
   * Runs all bias detection algorithms against the provided questions
   * and populates the alerts array with any detected patterns.
   *
   * @param classifications - Array of classification inputs
   */
  analyze(classifications: BiasClassificationInput[]): void {
    if (classifications.length === 0) return;

    this._isAnalyzing = true;
    const detectedAlerts: BiasAlert[] = [];

    const texts = classifications.map((c) => ({
      id: c.utteranceId,
      text: c.text,
    }));

    detectedAlerts.push(...this.detectGenderBias(texts));
    detectedAlerts.push(...this.detectAgeBias(texts));
    detectedAlerts.push(...this.detectConfirmationBias(texts));
    detectedAlerts.push(
      ...this.detectLeadingPatternBias(
        classifications.map((c) => ({ id: c.utteranceId, type: c.type })),
      ),
    );
    detectedAlerts.push(
      ...this.detectClosedQuestionOveruse(
        classifications.map((c) => ({ id: c.utteranceId, type: c.type })),
      ),
    );
    detectedAlerts.push(...this.detectAssumptiveLanguage(texts));

    this._alerts = detectedAlerts;
    this._isAnalyzing = false;
  }

  /** Remove all detected alerts */
  clearAlerts(): void {
    this._alerts = [];
  }

  // -------------------------------------------------------------------------
  // Private Detection Methods
  // -------------------------------------------------------------------------

  /** Check for gender-biased language in question texts */
  private detectGenderBias(
    texts: Array<{ id: string; text: string }>,
  ): BiasAlert[] {
    const matchedIds: string[] = [];

    for (const { id, text } of texts) {
      const lowercased = ' ' + text.toLowerCase() + ' ';
      for (const keyword of this.genderKeywords) {
        if (lowercased.includes(keyword)) {
          matchedIds.push(id);
          break;
        }
      }
    }

    if (matchedIds.length === 0) return [];

    return [
      {
        id: crypto.randomUUID(),
        type: BiasType.GenderBias,
        description: `Gendered language detected in ${matchedIds.length} question(s). This may unconsciously frame responses around gender assumptions.`,
        utteranceIds: matchedIds,
        confidence: Math.min(1.0, matchedIds.length / texts.length + 0.5),
        suggestion:
          "Use gender-neutral language in questions. Replace gendered pronouns with 'they/them' or 'the user/participant' when not quoting.",
        detectedAt: new Date().toISOString(),
      },
    ];
  }

  /** Check for age-biased assumptions in question texts */
  private detectAgeBias(
    texts: Array<{ id: string; text: string }>,
  ): BiasAlert[] {
    const matchedIds: string[] = [];

    for (const { id, text } of texts) {
      const lowercased = text.toLowerCase();
      for (const keyword of this.ageKeywords) {
        if (lowercased.includes(keyword)) {
          matchedIds.push(id);
          break;
        }
      }
    }

    if (matchedIds.length === 0) return [];

    return [
      {
        id: crypto.randomUUID(),
        type: BiasType.AgeBias,
        description: `Age-related assumptions detected in ${matchedIds.length} question(s). Generational references may introduce stereotyping.`,
        utteranceIds: matchedIds,
        confidence: Math.min(1.0, matchedIds.length / texts.length + 0.4),
        suggestion:
          'Avoid referencing age groups or generations. Ask about individual experiences rather than generational traits.',
        detectedAt: new Date().toISOString(),
      },
    ];
  }

  /** Check for confirmation bias through repeated agreement-seeking patterns */
  private detectConfirmationBias(
    texts: Array<{ id: string; text: string }>,
  ): BiasAlert[] {
    const matchedIds: string[] = [];

    for (const { id, text } of texts) {
      const lowercased = text.toLowerCase();
      for (const phrase of this.confirmationPhrases) {
        if (lowercased.includes(phrase)) {
          matchedIds.push(id);
          break;
        }
      }
    }

    // Threshold: 3+ confirmation-seeking questions
    if (matchedIds.length < this.confirmationThreshold) return [];

    return [
      {
        id: crypto.randomUUID(),
        type: BiasType.ConfirmationBias,
        description: `Confirmation-seeking language detected in ${matchedIds.length} question(s). Repeated agreement-seeking may bias participant responses.`,
        utteranceIds: matchedIds,
        confidence: Math.min(1.0, matchedIds.length / texts.length + 0.3),
        suggestion:
          "Replace confirmation-seeking phrases with open-ended alternatives. Instead of 'This is better, right?' try 'How does this compare to your previous experience?'",
        detectedAt: new Date().toISOString(),
      },
    ];
  }

  /** Check for a pattern of leading questions */
  private detectLeadingPatternBias(
    classifications: Array<{ id: string; type: string }>,
  ): BiasAlert[] {
    const leadingIds = classifications
      .filter((c) => c.type === 'leading')
      .map((c) => c.id);
    const total = classifications.length;

    if (total < this.minQuestionsForPattern) return [];

    const leadingRatio = leadingIds.length / total;
    if (leadingRatio <= this.leadingRatioThreshold) return [];

    return [
      {
        id: crypto.randomUUID(),
        type: BiasType.LeadingPatternBias,
        description: `${leadingIds.length} of ${total} questions (${Math.round(leadingRatio * 100)}%) are leading. This systematic pattern may steer participant responses.`,
        utteranceIds: leadingIds,
        confidence: Math.min(1.0, leadingRatio + 0.3),
        suggestion:
          "Rephrase leading questions as neutral, open-ended inquiries. Instead of 'Don't you think X is better?' try 'How do you compare X and Y?'",
        detectedAt: new Date().toISOString(),
      },
    ];
  }

  /** Check for excessive use of closed questions */
  private detectClosedQuestionOveruse(
    classifications: Array<{ id: string; type: string }>,
  ): BiasAlert[] {
    const closedIds = classifications
      .filter((c) => c.type === 'closed')
      .map((c) => c.id);
    const total = classifications.length;

    if (total < this.minQuestionsForPattern) return [];

    const closedRatio = closedIds.length / total;
    if (closedRatio <= this.closedRatioThreshold) return [];

    return [
      {
        id: crypto.randomUUID(),
        type: BiasType.ClosedQuestionOveruse,
        description: `${closedIds.length} of ${total} questions (${Math.round(closedRatio * 100)}%) are closed. This limits the depth of participant responses.`,
        utteranceIds: closedIds,
        confidence: Math.min(1.0, closedRatio),
        suggestion:
          "Balance closed questions with open-ended ones. For every closed question, follow up with 'Tell me more about that' or 'How did that make you feel?'",
        detectedAt: new Date().toISOString(),
      },
    ];
  }

  /** Check for assumptive language in question texts */
  private detectAssumptiveLanguage(
    texts: Array<{ id: string; text: string }>,
  ): BiasAlert[] {
    const matchedIds: string[] = [];

    for (const { id, text } of texts) {
      const lowercased = text.toLowerCase();
      for (const phrase of this.assumptivePhrases) {
        if (lowercased.includes(phrase)) {
          matchedIds.push(id);
          break;
        }
      }
    }

    if (matchedIds.length === 0) return [];

    return [
      {
        id: crypto.randomUUID(),
        type: BiasType.AssumptiveLanguage,
        description: `Assumptive language detected in ${matchedIds.length} question(s). Words like 'obviously' or 'everyone knows' presume shared understanding.`,
        utteranceIds: matchedIds,
        confidence: Math.min(1.0, matchedIds.length / texts.length + 0.4),
        suggestion:
          "Remove assumptive qualifiers from questions. Instead of 'Obviously this is frustrating, how do you cope?' try 'Can you describe your experience with this?'",
        detectedAt: new Date().toISOString(),
      },
    ];
  }
}
