/**
 * Sentiment Analyzer - ported from Features/Session/Services/SentimentAnalyzer.swift
 *
 * Rules-based sentiment analysis service that scores utterances for polarity,
 * intensity, and dominant emotion without external ML dependencies.
 *
 * The scoring algorithm:
 * 1. Tokenizes text into lowercase words
 * 2. Checks each word against positive/negative lexicons for a base score
 * 3. Applies negator inversion (within 3 words) to flip polarity
 * 4. Applies intensifier multiplication (within 2 words) at 1.5x
 * 5. Weights the final clause of each sentence by 1.3x (recency effect)
 * 6. Aggregates the average of all scored words into a final score
 * 7. Classifies polarity based on score thresholds
 */

// ---------------------------------------------------------------------------
// Sentiment Polarity
// ---------------------------------------------------------------------------

/** Sentiment polarity classification for an utterance */
export enum SentimentPolarity {
  Positive = 'positive',
  Neutral = 'neutral',
  Negative = 'negative',
  Mixed = 'mixed',
}

/** Display names for sentiment polarities */
export const SentimentPolarityDisplayName: Record<SentimentPolarity, string> = {
  [SentimentPolarity.Positive]: 'Positive',
  [SentimentPolarity.Neutral]: 'Neutral',
  [SentimentPolarity.Negative]: 'Negative',
  [SentimentPolarity.Mixed]: 'Mixed',
};

/** Color token names for sentiment polarities */
export const SentimentPolarityColor: Record<SentimentPolarity, string> = {
  [SentimentPolarity.Positive]: 'hcdSuccess',
  [SentimentPolarity.Neutral]: 'hcdTextSecondary',
  [SentimentPolarity.Negative]: 'hcdError',
  [SentimentPolarity.Mixed]: 'hcdWarning',
};

// ---------------------------------------------------------------------------
// Sentiment Result
// ---------------------------------------------------------------------------

/** Sentiment analysis result for a single utterance */
export interface SentimentResult {
  id: string;
  utteranceId: string;
  polarity: SentimentPolarity;
  /** Score from -1.0 (very negative) to +1.0 (very positive) */
  score: number;
  /** Intensity from 0.0 (neutral) to 1.0 (very intense) */
  intensity: number;
  /** Dominant emotion label, e.g., "frustration", "delight", "confusion" */
  dominantEmotion: string | null;
  /** Timestamp from utterance */
  timestamp: number;
}

// ---------------------------------------------------------------------------
// Emotional Shift
// ---------------------------------------------------------------------------

/** A significant emotional shift between consecutive utterances */
export interface EmotionalShift {
  id: string;
  fromResult: SentimentResult;
  toResult: SentimentResult;
  /** Absolute change in score */
  shiftMagnitude: number;
  /** Description e.g., "Positive -> Negative (frustration)" */
  description: string;
}

// ---------------------------------------------------------------------------
// Emotional Arc Summary
// ---------------------------------------------------------------------------

/** Emotional arc summary for a session, providing aggregate sentiment metrics */
export interface EmotionalArcSummary {
  averageSentiment: number;
  minSentiment: number;
  maxSentiment: number;
  emotionalShifts: EmotionalShift[];
  dominantPolarity: SentimentPolarity;
  /** Top 3 most intense moments */
  intensityPeaks: SentimentResult[];
  /** Arc trajectory description */
  arcDescription: string;
}

// ---------------------------------------------------------------------------
// Utterance Input
// ---------------------------------------------------------------------------

/** Minimal utterance input for sentiment analysis */
export interface SentimentUtterance {
  id: string;
  text: string;
  timestampSeconds: number;
}

// ---------------------------------------------------------------------------
// Lexicons (exact from Swift)
// ---------------------------------------------------------------------------

/** Positive word lexicon (~55 words) */
const POSITIVE_WORDS: Record<string, number> = {
  love: 0.9, great: 0.7, amazing: 0.9, perfect: 0.85, helpful: 0.6,
  enjoy: 0.7, easy: 0.5, awesome: 0.8, fantastic: 0.85, wonderful: 0.8,
  excellent: 0.85, intuitive: 0.6, smooth: 0.5, fast: 0.4, efficient: 0.5,
  simple: 0.4, convenient: 0.5, nice: 0.4, happy: 0.7, pleased: 0.6,
  satisfied: 0.6, impressed: 0.7, favorite: 0.7, comfortable: 0.5,
  appreciate: 0.6, glad: 0.6, excited: 0.8, delighted: 0.85,
  relieved: 0.5, confident: 0.5, trust: 0.5, recommend: 0.6,
  better: 0.4, best: 0.7, good: 0.4, like: 0.3, prefer: 0.3,
  clear: 0.4, useful: 0.5, valuable: 0.6, straightforward: 0.5,
  reliable: 0.5, beautiful: 0.7, elegant: 0.6, powerful: 0.5,
  quick: 0.4, responsive: 0.5, seamless: 0.6, brilliant: 0.8,
  outstanding: 0.85, superb: 0.85, terrific: 0.8, lovely: 0.6,
  pleasant: 0.5, enjoyable: 0.6, handy: 0.4,
};

/** Negative word lexicon (~55 words) */
const NEGATIVE_WORDS: Record<string, number> = {
  hate: -0.9, terrible: -0.85, awful: -0.85, frustrate: -0.8,
  frustrating: -0.8, frustrated: -0.8, difficult: -0.6, confuse: -0.6,
  confusing: -0.6, confused: -0.6, annoying: -0.7, annoyed: -0.7,
  problem: -0.5, issue: -0.4, broken: -0.7, slow: -0.5,
  complicated: -0.6, tedious: -0.6, cumbersome: -0.6, overwhelming: -0.7,
  stressful: -0.7, nightmare: -0.9, impossible: -0.8, worst: -0.85,
  pain: -0.6, struggle: -0.6, hard: -0.5, worry: -0.5, worried: -0.5,
  concern: -0.4, disappointed: -0.7, ugly: -0.6, useless: -0.8,
  fail: -0.7, failed: -0.7, bad: -0.5, wrong: -0.5, poor: -0.5,
  clunky: -0.6, buggy: -0.7, unreliable: -0.6, error: -0.5,
  crash: -0.7, lag: -0.5, laggy: -0.6, awkward: -0.5,
  unintuitive: -0.6, cluttered: -0.5, messy: -0.5, dislike: -0.6,
  horrible: -0.85, dreadful: -0.8, miserable: -0.7, painful: -0.6,
  tiresome: -0.5, boring: -0.4,
};

/** Intensifier words */
const INTENSIFIERS = new Set<string>([
  'very', 'extremely', 'absolutely', 'totally', 'completely', 'really',
  'incredibly', 'exceptionally', 'tremendously', 'utterly', 'highly',
  'super', 'seriously', 'genuinely', 'truly', 'remarkably',
]);

/** Negator words */
const NEGATORS = new Set<string>([
  'not', 'never', "don't", "doesn't", "didn't", "can't", 'cannot',
  "won't", "wouldn't", "couldn't", "shouldn't", "isn't", "aren't",
  "wasn't", "weren't", 'hardly', 'barely', 'scarcely', 'no', 'nor',
]);

/** Emotion keyword mappings */
const EMOTION_KEYWORDS: Record<string, string> = {
  // Frustration
  frustrate: 'frustration', frustrating: 'frustration', frustrated: 'frustration',
  annoying: 'frustration', annoyed: 'frustration', irritating: 'frustration',
  // Delight
  love: 'delight', amazing: 'delight', wonderful: 'delight',
  delighted: 'delight', fantastic: 'delight', awesome: 'delight',
  // Confusion
  confuse: 'confusion', confusing: 'confusion', confused: 'confusion',
  unclear: 'confusion', lost: 'confusion', puzzled: 'confusion',
  // Anxiety
  worry: 'anxiety', worried: 'anxiety', nervous: 'anxiety',
  anxious: 'anxiety', stressful: 'anxiety', overwhelm: 'anxiety',
  overwhelming: 'anxiety',
  // Satisfaction
  satisfied: 'satisfaction', pleased: 'satisfaction', happy: 'satisfaction',
  glad: 'satisfaction', content: 'satisfaction',
  // Disappointment
  disappointed: 'disappointment', letdown: 'disappointment',
  underwhelming: 'disappointment', expected: 'disappointment',
  // Relief
  relieved: 'relief', finally: 'relief', phew: 'relief',
  // Excitement
  excited: 'excitement', thrilled: 'excitement', eager: 'excitement',
  "can't wait": 'excitement',
};

// ---------------------------------------------------------------------------
// Sentiment Analyzer
// ---------------------------------------------------------------------------

/** Configuration for SentimentAnalyzer */
export interface SentimentAnalyzerConfig {
  /** Score threshold above which sentiment is classified as positive (default: 0.15) */
  positiveThreshold?: number;
  /** Score threshold below which sentiment is classified as negative (default: -0.15) */
  negativeThreshold?: number;
  /** Threshold for mixed sentiment detection (default: 0.3) */
  mixedStrengthThreshold?: number;
  /** Emotional shift detection threshold (default: 0.4) */
  shiftThreshold?: number;
}

/**
 * Rules-based sentiment analysis service.
 *
 * Scores utterances for polarity, intensity, and dominant emotion
 * without external ML dependencies.
 */
export class SentimentAnalyzer {
  private _results: SentimentResult[] = [];
  private _emotionalShifts: EmotionalShift[] = [];
  private _arcSummary: EmotionalArcSummary | null = null;

  private readonly positiveThreshold: number;
  private readonly negativeThreshold: number;
  private readonly mixedStrengthThreshold: number;
  private readonly shiftThreshold: number;

  constructor(config: SentimentAnalyzerConfig = {}) {
    this.positiveThreshold = config.positiveThreshold ?? 0.15;
    this.negativeThreshold = config.negativeThreshold ?? -0.15;
    this.mixedStrengthThreshold = config.mixedStrengthThreshold ?? 0.3;
    this.shiftThreshold = config.shiftThreshold ?? 0.4;
  }

  // -------------------------------------------------------------------------
  // Accessors
  // -------------------------------------------------------------------------

  /** All analysis results */
  get results(): readonly SentimentResult[] {
    return this._results;
  }

  /** Detected emotional shifts */
  get emotionalShifts(): readonly EmotionalShift[] {
    return this._emotionalShifts;
  }

  /** Arc summary (null until analyzeSession called) */
  get arcSummary(): EmotionalArcSummary | null {
    return this._arcSummary;
  }

  // -------------------------------------------------------------------------
  // Public Methods
  // -------------------------------------------------------------------------

  /**
   * Analyze a single utterance and return the sentiment result.
   * @param utterance - The utterance to analyze
   * @returns A SentimentResult with polarity, score, intensity, and dominant emotion
   */
  analyze(utterance: SentimentUtterance): SentimentResult {
    const text = utterance.text;
    const { score, intensity, hasMixed } = this.scoreSentiment(text);
    const polarity = this.classifyPolarity(score, hasMixed);
    const dominantEmotion = this.detectDominantEmotion(text, score);

    return {
      id: crypto.randomUUID(),
      utteranceId: utterance.id,
      polarity,
      score,
      intensity,
      dominantEmotion,
      timestamp: utterance.timestampSeconds,
    };
  }

  /**
   * Analyze a sequence of utterances for a full session.
   * Updates results, detects emotional shifts, and generates arc summary.
   * @param utterances - The ordered list of utterances to analyze
   */
  analyzeSession(utterances: SentimentUtterance[]): void {
    this._results = utterances.map((u) => this.analyze(u));
    this.detectShifts();
    this._arcSummary = this.generateArcSummary();
  }

  /**
   * Generate an emotional arc summary from the current results.
   * @returns An EmotionalArcSummary, or null if no results
   */
  generateArcSummary(): EmotionalArcSummary | null {
    if (this._results.length === 0) return null;

    const scores = this._results.map((r) => r.score);
    const avgSentiment = scores.reduce((a, b) => a + b, 0) / scores.length;
    const minScore = Math.min(...scores);
    const maxScore = Math.max(...scores);

    // Determine dominant polarity from average
    let dominantPolarity: SentimentPolarity;
    if (avgSentiment > this.positiveThreshold) {
      dominantPolarity = SentimentPolarity.Positive;
    } else if (avgSentiment < this.negativeThreshold) {
      dominantPolarity = SentimentPolarity.Negative;
    } else {
      dominantPolarity = SentimentPolarity.Neutral;
    }

    // Find top 3 intensity peaks
    const sortedByIntensity = [...this._results].sort((a, b) => b.intensity - a.intensity);
    const peaks = sortedByIntensity.slice(0, 3);

    // Describe the arc
    const arcDescription = this.describeArc(this._results);

    return {
      averageSentiment: avgSentiment,
      minSentiment: minScore,
      maxSentiment: maxScore,
      emotionalShifts: [...this._emotionalShifts],
      dominantPolarity,
      intensityPeaks: peaks,
      arcDescription,
    };
  }

  /** Reset all analysis state */
  reset(): void {
    this._results = [];
    this._emotionalShifts = [];
    this._arcSummary = null;
  }

  // -------------------------------------------------------------------------
  // Static Lexicon Accessors (for testing/inspection)
  // -------------------------------------------------------------------------

  static get positiveWords(): Readonly<Record<string, number>> {
    return POSITIVE_WORDS;
  }

  static get negativeWords(): Readonly<Record<string, number>> {
    return NEGATIVE_WORDS;
  }

  static get intensifiers(): ReadonlySet<string> {
    return INTENSIFIERS;
  }

  static get negators(): ReadonlySet<string> {
    return NEGATORS;
  }

  static get emotionKeywords(): Readonly<Record<string, string>> {
    return EMOTION_KEYWORDS;
  }

  // -------------------------------------------------------------------------
  // Private Methods
  // -------------------------------------------------------------------------

  /**
   * Score the sentiment of a text string
   * @returns (score, intensity, hasMixed)
   */
  private scoreSentiment(text: string): {
    score: number;
    intensity: number;
    hasMixed: boolean;
  } {
    if (!text) {
      return { score: 0.0, intensity: 0.0, hasMixed: false };
    }

    const cleaned = text.toLowerCase();
    const words = this.tokenize(cleaned);

    if (words.length === 0) {
      return { score: 0.0, intensity: 0.0, hasMixed: false };
    }

    // Split into sentences for final-clause weighting
    const sentences = cleaned
      .split(/[.!?]/)
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    // Determine which words belong to the final clause
    let finalClauseWords: Set<number>;
    if (sentences.length > 1) {
      const lastSentence = sentences[sentences.length - 1];
      const lastTokens = this.tokenize(lastSentence);
      const matchIndices = new Set<number>();
      let searchIdx = words.length - 1;
      for (let i = lastTokens.length - 1; i >= 0; i--) {
        while (searchIdx >= 0) {
          if (words[searchIdx] === lastTokens[i]) {
            matchIndices.add(searchIdx);
            searchIdx--;
            break;
          }
          searchIdx--;
        }
      }
      finalClauseWords = matchIndices;
    } else {
      // Single sentence: all words are in the final clause
      finalClauseWords = new Set(Array.from({ length: words.length }, (_, i) => i));
    }

    const scoredValues: number[] = [];
    let maxPositive = 0.0;
    let maxNegative = 0.0;

    for (let index = 0; index < words.length; index++) {
      const word = words[index];
      let baseScore: number | undefined;

      // Check positive lexicon
      if (POSITIVE_WORDS[word] !== undefined) {
        baseScore = POSITIVE_WORDS[word];
      }
      // Check negative lexicon (negative overrides positive if both match)
      if (NEGATIVE_WORDS[word] !== undefined) {
        baseScore = NEGATIVE_WORDS[word];
      }

      if (baseScore === undefined) continue;

      let wordScore = baseScore;

      // Check for negator within preceding 3 words
      const negatorStart = Math.max(0, index - 3);
      let hasNegator = false;
      for (let i = negatorStart; i < index; i++) {
        if (NEGATORS.has(words[i])) {
          hasNegator = true;
          break;
        }
      }
      if (hasNegator) {
        wordScore = -wordScore;
      }

      // Check for intensifier within preceding 2 words
      const intensifierStart = Math.max(0, index - 2);
      let hasIntensifier = false;
      for (let i = intensifierStart; i < index; i++) {
        if (INTENSIFIERS.has(words[i])) {
          hasIntensifier = true;
          break;
        }
      }
      if (hasIntensifier) {
        wordScore *= 1.5;
      }

      // Apply final clause weight (1.3x) for recency effect
      if (finalClauseWords.has(index)) {
        wordScore *= 1.3;
      }

      // Clamp to valid range
      wordScore = Math.max(-1.0, Math.min(1.0, wordScore));

      scoredValues.push(wordScore);

      // Track max positive and negative for mixed detection
      if (wordScore > 0) {
        maxPositive = Math.max(maxPositive, wordScore);
      } else if (wordScore < 0) {
        maxNegative = Math.max(maxNegative, Math.abs(wordScore));
      }
    }

    if (scoredValues.length === 0) {
      return { score: 0.0, intensity: 0.0, hasMixed: false };
    }

    const rawScore = scoredValues.reduce((a, b) => a + b, 0) / scoredValues.length;
    const clampedScore = Math.max(-1.0, Math.min(1.0, rawScore));
    const intensity = Math.min(1.0, Math.abs(clampedScore));
    const hasMixed =
      maxPositive >= this.mixedStrengthThreshold &&
      maxNegative >= this.mixedStrengthThreshold;

    return { score: clampedScore, intensity, hasMixed };
  }

  /** Detect the dominant emotion from text and score */
  private detectDominantEmotion(text: string, score: number): string | null {
    const words = this.tokenize(text.toLowerCase());

    // Count emotion occurrences
    const emotionCounts: Record<string, number> = {};
    for (const word of words) {
      const emotion = EMOTION_KEYWORDS[word];
      if (emotion) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
    }

    // Return the most frequent emotion
    let maxCount = 0;
    let dominantEmotion: string | null = null;
    for (const [emotion, count] of Object.entries(emotionCounts)) {
      if (count > maxCount) {
        maxCount = count;
        dominantEmotion = emotion;
      }
    }

    if (dominantEmotion) return dominantEmotion;

    // Fallback: infer from score if strong enough
    if (score > 0.5) return 'delight';
    if (score < -0.5) return 'frustration';

    return null;
  }

  /** Classify the polarity from a score and mixed status */
  private classifyPolarity(score: number, hasMixed: boolean): SentimentPolarity {
    if (hasMixed) return SentimentPolarity.Mixed;
    if (score > this.positiveThreshold) return SentimentPolarity.Positive;
    if (score < this.negativeThreshold) return SentimentPolarity.Negative;
    return SentimentPolarity.Neutral;
  }

  /** Detect emotional shifts between consecutive results */
  private detectShifts(): void {
    this._emotionalShifts = [];

    if (this._results.length < 2) return;

    for (let i = 1; i < this._results.length; i++) {
      const previous = this._results[i - 1];
      const current = this._results[i];
      const magnitude = Math.abs(current.score - previous.score);

      if (magnitude >= this.shiftThreshold) {
        const emotionSuffix = current.dominantEmotion
          ? ` (${current.dominantEmotion})`
          : '';
        const desc = `${SentimentPolarityDisplayName[previous.polarity]} -> ${SentimentPolarityDisplayName[current.polarity]}${emotionSuffix}`;

        this._emotionalShifts.push({
          id: crypto.randomUUID(),
          fromResult: previous,
          toResult: current,
          shiftMagnitude: magnitude,
          description: desc,
        });
      }
    }
  }

  /** Generate a human-readable description of the emotional arc */
  private describeArc(results: SentimentResult[]): string {
    if (results.length === 0) return 'No data available';

    if (results.length < 2) {
      return `Single data point: ${SentimentPolarityDisplayName[results[0].polarity].toLowerCase()} sentiment`;
    }

    // Divide into thirds
    const thirdSize = Math.max(1, Math.floor(results.length / 3));
    const startSlice = results.slice(0, thirdSize);
    let midSlice: SentimentResult[];
    let endSlice: SentimentResult[];

    if (results.length >= 3) {
      midSlice = results.slice(thirdSize, Math.min(thirdSize * 2, results.length));
      endSlice = results.slice(Math.min(thirdSize * 2, results.length));
    } else {
      midSlice = results.slice(1, results.length);
      endSlice = results.slice(results.length - 1);
    }

    const averageScore = (slice: SentimentResult[]): number => {
      if (slice.length === 0) return 0.0;
      return slice.map((r) => r.score).reduce((a, b) => a + b, 0) / slice.length;
    };

    const startAvg = averageScore(startSlice);
    const midAvg = averageScore(midSlice);
    const endAvg = averageScore(endSlice);

    const describeLevel = (score: number): string => {
      if (score > 0.3) return 'positive';
      if (score > this.positiveThreshold) return 'slightly positive';
      if (score < -0.3) return 'negative';
      if (score < this.negativeThreshold) return 'slightly negative';
      return 'neutral';
    };

    const startDesc = describeLevel(startAvg);
    const midDesc = describeLevel(midAvg);
    const endDesc = describeLevel(endAvg);

    // Build arc narrative
    const parts: string[] = [];
    parts.push(`Started ${startDesc}`);

    if (midDesc !== startDesc) {
      parts.push(`shifted ${midDesc} mid-session`);
    } else {
      parts.push(`remained ${midDesc} mid-session`);
    }

    if (endDesc !== midDesc) {
      if (endAvg > midAvg + 0.1) {
        parts.push(`recovered to ${endDesc}`);
      } else if (endAvg < midAvg - 0.1) {
        parts.push(`declined to ${endDesc}`);
      } else {
        parts.push(`ended ${endDesc}`);
      }
    } else {
      parts.push(`ended ${endDesc}`);
    }

    return parts.join(', ');
  }

  /**
   * Tokenize text into an array of lowercase words with punctuation removed.
   * Allows apostrophes within words.
   */
  private tokenize(text: string): string[] {
    return text
      .replace(/[^a-zA-Z']/g, ' ')
      .split(/\s+/)
      .map((w) => w.toLowerCase())
      .filter((w) => w.length > 0);
  }
}
