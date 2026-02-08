/**
 * Follow-Up Suggester
 *
 * Generates contextual follow-up question suggestions based on utterance content,
 * detected emotions, and methodology (JTBD, usability, discovery).
 * Includes template-based suggestions.
 */

import { Speaker } from '../models/speaker';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** Methodology frameworks for research interviews */
export enum Methodology {
  /** Jobs to Be Done framework */
  JTBD = 'jtbd',
  /** Usability testing */
  Usability = 'usability',
  /** Discovery/generative research */
  Discovery = 'discovery',
  /** General interview */
  General = 'general',
}

/** A follow-up question suggestion */
export interface FollowUpSuggestion {
  /** Unique identifier */
  id: string;
  /** The suggested follow-up question text */
  text: string;
  /** Why this follow-up is suggested */
  reason: string;
  /** Relevance score (0.0 - 1.0) */
  relevance: number;
  /** Category of follow-up */
  category: FollowUpCategory;
}

/** Categories of follow-up suggestions */
export enum FollowUpCategory {
  /** Deeper exploration of a topic */
  DeepDive = 'deep_dive',
  /** Clarification of something said */
  Clarification = 'clarification',
  /** Emotional exploration */
  Emotional = 'emotional',
  /** Process/behavior exploration */
  Process = 'process',
  /** Comparison or contrast */
  Comparison = 'comparison',
  /** Impact or consequence */
  Impact = 'impact',
}

/** Minimal utterance input for follow-up suggestion */
export interface FollowUpUtterance {
  id: string;
  text: string;
  speaker: Speaker;
  timestampSeconds: number;
}

// ---------------------------------------------------------------------------
// Template-based suggestions
// ---------------------------------------------------------------------------

interface FollowUpTemplate {
  triggers: string[];
  suggestions: Array<{
    text: string;
    reason: string;
    category: FollowUpCategory;
    relevance: number;
  }>;
}

const GENERAL_TEMPLATES: FollowUpTemplate[] = [
  {
    triggers: ['difficult', 'hard', 'struggle', 'challenge', 'problem'],
    suggestions: [
      {
        text: 'Can you walk me through what happened step by step?',
        reason: 'Participant mentioned a difficulty - get the detailed story',
        category: FollowUpCategory.Process,
        relevance: 0.85,
      },
      {
        text: 'How did that make you feel in the moment?',
        reason: 'Explore emotional impact of the difficulty',
        category: FollowUpCategory.Emotional,
        relevance: 0.80,
      },
      {
        text: 'What did you try to do to work around it?',
        reason: 'Understand coping strategies and workarounds',
        category: FollowUpCategory.Process,
        relevance: 0.75,
      },
    ],
  },
  {
    triggers: ['like', 'love', 'enjoy', 'great', 'awesome', 'favorite'],
    suggestions: [
      {
        text: 'What specifically about that do you find most valuable?',
        reason: 'Dig deeper into what drives the positive reaction',
        category: FollowUpCategory.DeepDive,
        relevance: 0.85,
      },
      {
        text: 'How does that compare to other alternatives you\'ve tried?',
        reason: 'Get comparative context for the positive experience',
        category: FollowUpCategory.Comparison,
        relevance: 0.75,
      },
    ],
  },
  {
    triggers: ['confus', 'unclear', 'don\'t understand', 'lost', 'puzzl'],
    suggestions: [
      {
        text: 'What were you expecting to happen instead?',
        reason: 'Understand the mental model mismatch',
        category: FollowUpCategory.Clarification,
        relevance: 0.90,
      },
      {
        text: 'At what point did you first feel confused?',
        reason: 'Pinpoint the exact moment of confusion',
        category: FollowUpCategory.Process,
        relevance: 0.85,
      },
    ],
  },
  {
    triggers: ['frustrat', 'annoy', 'irritat', 'upset', 'angry'],
    suggestions: [
      {
        text: 'Tell me more about what triggered that feeling.',
        reason: 'Explore the root cause of frustration',
        category: FollowUpCategory.Emotional,
        relevance: 0.90,
      },
      {
        text: 'How often does this come up for you?',
        reason: 'Understand frequency and severity of the pain point',
        category: FollowUpCategory.Impact,
        relevance: 0.80,
      },
    ],
  },
  {
    triggers: ['wish', 'hope', 'want', 'need', 'would be nice'],
    suggestions: [
      {
        text: 'Can you describe what that would ideally look like for you?',
        reason: 'Capture the participant\'s ideal solution vision',
        category: FollowUpCategory.DeepDive,
        relevance: 0.85,
      },
      {
        text: 'What impact would that have on your workflow?',
        reason: 'Understand the downstream value of the desired change',
        category: FollowUpCategory.Impact,
        relevance: 0.80,
      },
    ],
  },
  {
    triggers: ['usually', 'typically', 'normally', 'always', 'every time'],
    suggestions: [
      {
        text: 'Can you give me a specific recent example?',
        reason: 'Move from general patterns to concrete instances',
        category: FollowUpCategory.Process,
        relevance: 0.85,
      },
      {
        text: 'Has there been a time when that wasn\'t the case?',
        reason: 'Find edge cases and exceptions to the pattern',
        category: FollowUpCategory.Comparison,
        relevance: 0.75,
      },
    ],
  },
];

const JTBD_TEMPLATES: FollowUpTemplate[] = [
  {
    triggers: ['switch', 'change', 'move', 'replace', 'start using'],
    suggestions: [
      {
        text: 'What was the moment that triggered you to make that switch?',
        reason: 'JTBD: Identify the triggering event',
        category: FollowUpCategory.Process,
        relevance: 0.90,
      },
      {
        text: 'What were you using before, and what wasn\'t working?',
        reason: 'JTBD: Understand the push from the old solution',
        category: FollowUpCategory.Comparison,
        relevance: 0.85,
      },
      {
        text: 'Were there any concerns or hesitations before making the change?',
        reason: 'JTBD: Identify anxieties and barriers to switching',
        category: FollowUpCategory.Emotional,
        relevance: 0.80,
      },
    ],
  },
  {
    triggers: ['trying to', 'goal', 'accomplish', 'get done', 'outcome'],
    suggestions: [
      {
        text: 'What does success look like when you\'re done?',
        reason: 'JTBD: Define the desired outcome',
        category: FollowUpCategory.DeepDive,
        relevance: 0.90,
      },
      {
        text: 'Who else is involved when you\'re trying to do this?',
        reason: 'JTBD: Map the social and functional context',
        category: FollowUpCategory.Process,
        relevance: 0.75,
      },
    ],
  },
];

const USABILITY_TEMPLATES: FollowUpTemplate[] = [
  {
    triggers: ['click', 'tap', 'press', 'button', 'link', 'menu'],
    suggestions: [
      {
        text: 'What did you expect to happen when you did that?',
        reason: 'Usability: Understand expectation vs. reality gap',
        category: FollowUpCategory.Clarification,
        relevance: 0.90,
      },
      {
        text: 'How did you know to look there?',
        reason: 'Usability: Understand navigation mental model',
        category: FollowUpCategory.Process,
        relevance: 0.85,
      },
    ],
  },
  {
    triggers: ['find', 'look for', 'search', 'where', 'locate'],
    suggestions: [
      {
        text: 'Where did you first try looking for that?',
        reason: 'Usability: Understand information architecture expectations',
        category: FollowUpCategory.Process,
        relevance: 0.90,
      },
      {
        text: 'On a scale of easy to difficult, how would you rate finding that?',
        reason: 'Usability: Get a findability rating',
        category: FollowUpCategory.Impact,
        relevance: 0.75,
      },
    ],
  },
];

const DISCOVERY_TEMPLATES: FollowUpTemplate[] = [
  {
    triggers: ['workflow', 'process', 'routine', 'day', 'morning', 'week'],
    suggestions: [
      {
        text: 'Can you walk me through a typical day when you do this?',
        reason: 'Discovery: Map the full workflow context',
        category: FollowUpCategory.Process,
        relevance: 0.90,
      },
      {
        text: 'What tools or resources do you rely on during this process?',
        reason: 'Discovery: Identify the ecosystem and dependencies',
        category: FollowUpCategory.DeepDive,
        relevance: 0.80,
      },
    ],
  },
  {
    triggers: ['team', 'colleague', 'manager', 'stakeholder', 'client'],
    suggestions: [
      {
        text: 'How do you currently communicate or collaborate on this?',
        reason: 'Discovery: Understand collaboration patterns',
        category: FollowUpCategory.Process,
        relevance: 0.85,
      },
      {
        text: 'What happens when there\'s a disagreement about this?',
        reason: 'Discovery: Surface friction in collaboration',
        category: FollowUpCategory.Impact,
        relevance: 0.80,
      },
    ],
  },
];

// ---------------------------------------------------------------------------
// Follow-Up Suggester
// ---------------------------------------------------------------------------

/** Configuration for FollowUpSuggester */
export interface FollowUpSuggesterConfig {
  /** Research methodology to use for contextual suggestions */
  methodology?: Methodology;
  /** Maximum number of suggestions to return */
  maxSuggestions?: number;
}

/**
 * Generates contextual follow-up question suggestions based on utterance content,
 * detected emotions, and research methodology.
 */
export class FollowUpSuggester {
  private _methodology: Methodology;
  private _maxSuggestions: number;

  constructor(config: FollowUpSuggesterConfig = {}) {
    this._methodology = config.methodology ?? Methodology.General;
    this._maxSuggestions = config.maxSuggestions ?? 3;
  }

  /** Get the current methodology */
  get methodology(): Methodology {
    return this._methodology;
  }

  /** Set the methodology */
  set methodology(value: Methodology) {
    this._methodology = value;
  }

  /**
   * Generate follow-up suggestions based on a participant utterance.
   *
   * @param utterance - The participant utterance to analyze
   * @param dominantEmotion - Optional detected dominant emotion
   * @returns Array of follow-up suggestions, sorted by relevance
   */
  suggest(
    utterance: FollowUpUtterance,
    dominantEmotion?: string,
  ): FollowUpSuggestion[] {
    // Only suggest follow-ups for participant utterances
    if (utterance.speaker !== Speaker.Participant) return [];

    const text = utterance.text.toLowerCase();
    const suggestions: FollowUpSuggestion[] = [];

    // Gather from general templates
    suggestions.push(...this.matchTemplates(text, GENERAL_TEMPLATES));

    // Gather from methodology-specific templates
    switch (this._methodology) {
      case Methodology.JTBD:
        suggestions.push(...this.matchTemplates(text, JTBD_TEMPLATES));
        break;
      case Methodology.Usability:
        suggestions.push(...this.matchTemplates(text, USABILITY_TEMPLATES));
        break;
      case Methodology.Discovery:
        suggestions.push(...this.matchTemplates(text, DISCOVERY_TEMPLATES));
        break;
      case Methodology.General:
      default:
        break;
    }

    // Add emotion-based suggestions if emotion detected
    if (dominantEmotion) {
      suggestions.push(...this.emotionBasedSuggestions(dominantEmotion));
    }

    // If no templates matched, provide a generic deep-dive follow-up
    if (suggestions.length === 0) {
      suggestions.push({
        id: crypto.randomUUID(),
        text: 'Can you tell me more about that?',
        reason: 'Encourage the participant to elaborate',
        relevance: 0.60,
        category: FollowUpCategory.DeepDive,
      });
    }

    // Deduplicate by text
    const seen = new Set<string>();
    const unique = suggestions.filter((s) => {
      if (seen.has(s.text)) return false;
      seen.add(s.text);
      return true;
    });

    // Sort by relevance descending and limit
    return unique
      .sort((a, b) => b.relevance - a.relevance)
      .slice(0, this._maxSuggestions);
  }

  /**
   * Generate follow-up suggestions from multiple recent utterances.
   *
   * @param utterances - Recent utterances (typically last 3-5)
   * @param dominantEmotion - Optional detected dominant emotion
   * @returns Array of follow-up suggestions
   */
  suggestFromContext(
    utterances: FollowUpUtterance[],
    dominantEmotion?: string,
  ): FollowUpSuggestion[] {
    // Focus on the most recent participant utterance
    const participantUtterances = utterances.filter(
      (u) => u.speaker === Speaker.Participant,
    );

    if (participantUtterances.length === 0) return [];

    const lastUtterance = participantUtterances[participantUtterances.length - 1];
    return this.suggest(lastUtterance, dominantEmotion);
  }

  // -------------------------------------------------------------------------
  // Private Methods
  // -------------------------------------------------------------------------

  private matchTemplates(
    text: string,
    templates: FollowUpTemplate[],
  ): FollowUpSuggestion[] {
    const results: FollowUpSuggestion[] = [];

    for (const template of templates) {
      const isTriggered = template.triggers.some((trigger) => text.includes(trigger));
      if (isTriggered) {
        for (const suggestion of template.suggestions) {
          results.push({
            id: crypto.randomUUID(),
            text: suggestion.text,
            reason: suggestion.reason,
            relevance: suggestion.relevance,
            category: suggestion.category,
          });
        }
      }
    }

    return results;
  }

  private emotionBasedSuggestions(emotion: string): FollowUpSuggestion[] {
    const suggestions: FollowUpSuggestion[] = [];

    switch (emotion.toLowerCase()) {
      case 'frustration':
        suggestions.push({
          id: crypto.randomUUID(),
          text: 'It sounds like that was frustrating. What would have made it better?',
          reason: 'Detected frustration - explore desired improvements',
          relevance: 0.85,
          category: FollowUpCategory.Emotional,
        });
        break;
      case 'delight':
        suggestions.push({
          id: crypto.randomUUID(),
          text: 'You seem really positive about that. What makes it stand out?',
          reason: 'Detected delight - understand the drivers',
          relevance: 0.80,
          category: FollowUpCategory.Emotional,
        });
        break;
      case 'confusion':
        suggestions.push({
          id: crypto.randomUUID(),
          text: 'It sounds like that wasn\'t clear. What would have helped you understand better?',
          reason: 'Detected confusion - identify clarity gaps',
          relevance: 0.85,
          category: FollowUpCategory.Clarification,
        });
        break;
      case 'anxiety':
        suggestions.push({
          id: crypto.randomUUID(),
          text: 'What\'s the biggest concern on your mind about this?',
          reason: 'Detected anxiety - surface specific worries',
          relevance: 0.85,
          category: FollowUpCategory.Emotional,
        });
        break;
      case 'satisfaction':
        suggestions.push({
          id: crypto.randomUUID(),
          text: 'What was the most important factor in making you feel that way?',
          reason: 'Detected satisfaction - identify key success factors',
          relevance: 0.75,
          category: FollowUpCategory.DeepDive,
        });
        break;
      case 'disappointment':
        suggestions.push({
          id: crypto.randomUUID(),
          text: 'What were you hoping for that didn\'t happen?',
          reason: 'Detected disappointment - understand unmet expectations',
          relevance: 0.85,
          category: FollowUpCategory.Emotional,
        });
        break;
      case 'excitement':
        suggestions.push({
          id: crypto.randomUUID(),
          text: 'What gets you most excited about this?',
          reason: 'Detected excitement - capture motivations',
          relevance: 0.80,
          category: FollowUpCategory.Emotional,
        });
        break;
      case 'relief':
        suggestions.push({
          id: crypto.randomUUID(),
          text: 'What was the situation like before that changed?',
          reason: 'Detected relief - understand the prior pain point',
          relevance: 0.80,
          category: FollowUpCategory.Comparison,
        });
        break;
      default:
        break;
    }

    return suggestions;
  }
}
