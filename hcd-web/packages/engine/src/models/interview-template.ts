/**
 * Interview Template model
 *
 * Simple interface for interview templates with topics, coaching prompts,
 * name, and description.
 */

// ---------------------------------------------------------------------------
// Topic
// ---------------------------------------------------------------------------

/** A topic to cover during an interview */
export interface InterviewTopic {
  /** Unique identifier for the topic */
  id: string;
  /** Topic name */
  name: string;
  /** Optional description or guiding questions */
  description?: string;
  /** Whether this topic has been covered during the session */
  isCovered: boolean;
  /** Display order */
  sortOrder: number;
}

// ---------------------------------------------------------------------------
// Coaching Prompt Template
// ---------------------------------------------------------------------------

/** A pre-configured coaching prompt associated with a template */
export interface CoachingPromptTemplate {
  /** Unique identifier */
  id: string;
  /** The coaching prompt text */
  text: string;
  /** When to trigger this prompt (e.g., topic keyword, time-based) */
  triggerCondition?: string;
  /** Category of coaching prompt */
  category: string;
}

// ---------------------------------------------------------------------------
// Interview Template
// ---------------------------------------------------------------------------

/**
 * An interview template containing topics, coaching prompts, and metadata.
 *
 * Templates provide structured guidance for interview sessions, including
 * pre-defined topics to cover and contextual coaching prompts.
 */
export interface InterviewTemplate {
  /** Unique identifier */
  id: string;
  /** Template name */
  name: string;
  /** Description of the template and its intended use */
  description: string;
  /** Topics to cover during the interview */
  topics: InterviewTopic[];
  /** Pre-configured coaching prompts */
  coachingPrompts: CoachingPromptTemplate[];
  /** Methodology (e.g., 'usability', 'discovery', 'JTBD') */
  methodology?: string;
  /** Estimated duration in minutes */
  estimatedDuration?: number;
  /** Whether this is a built-in template */
  isBuiltIn: boolean;
  /** Creation timestamp (ISO 8601) */
  createdAt: string;
  /** Last updated timestamp (ISO 8601) */
  updatedAt: string;
}

/**
 * Create a new interview topic
 */
export function createInterviewTopic(
  params: Omit<InterviewTopic, 'id' | 'isCovered'> & {
    id?: string;
    isCovered?: boolean;
  },
): InterviewTopic {
  return {
    id: params.id ?? crypto.randomUUID(),
    name: params.name,
    description: params.description,
    isCovered: params.isCovered ?? false,
    sortOrder: params.sortOrder,
  };
}

/**
 * Create a new interview template
 */
export function createInterviewTemplate(
  params: Omit<InterviewTemplate, 'id' | 'isBuiltIn' | 'createdAt' | 'updatedAt'> & {
    id?: string;
    isBuiltIn?: boolean;
    createdAt?: string;
    updatedAt?: string;
  },
): InterviewTemplate {
  const now = new Date().toISOString();
  return {
    id: params.id ?? crypto.randomUUID(),
    name: params.name,
    description: params.description,
    topics: params.topics,
    coachingPrompts: params.coachingPrompts,
    methodology: params.methodology,
    estimatedDuration: params.estimatedDuration,
    isBuiltIn: params.isBuiltIn ?? false,
    createdAt: params.createdAt ?? now,
    updatedAt: params.updatedAt ?? now,
  };
}
