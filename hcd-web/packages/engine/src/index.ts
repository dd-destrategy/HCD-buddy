/**
 * @hcd/engine - Core business logic for HCD Interview Coach
 *
 * Pure logic modules with NO UI or database dependencies.
 * Ported from the Swift macOS application to TypeScript.
 */

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

export {
  Speaker,
  SpeakerDisplayName,
  SpeakerIcon,
  allSpeakers,
  getSpeakerDisplayName,
  getSpeakerIcon,
} from './models/speaker';

export {
  CulturalPreset,
  CulturalPresetDisplayName,
  CulturalPresetDescription,
  allCulturalPresets,
  FormalityLevel,
  FormalityLevelDisplayName,
  allFormalityLevels,
  createCulturalContextPreset,
  DEFAULT_CULTURAL_CONTEXT,
  adjustThresholdsForCulture,
} from './models/cultural-context';
export type { CulturalContext } from './models/cultural-context';

export {
  ConsentLanguage,
  ConsentLanguageDisplayName,
  ConsentLanguageNativeName,
  allConsentLanguages,
  createConsentPermission,
  allRequiredAccepted,
  permissionCount,
  acceptedCount,
  defaultEnglishTemplate,
  defaultSpanishTemplate,
  defaultFrenchTemplate,
} from './models/consent-template';
export type {
  ConsentPermission,
  ConsentTemplate,
} from './models/consent-template';

export {
  createInterviewTopic,
  createInterviewTemplate,
} from './models/interview-template';
export type {
  InterviewTopic,
  CoachingPromptTemplate,
  InterviewTemplate,
} from './models/interview-template';

// ---------------------------------------------------------------------------
// Coaching
// ---------------------------------------------------------------------------

export {
  createCoachingThresholds,
  effectiveConfidenceThreshold,
  effectiveCooldown,
  DEFAULT_THRESHOLDS,
  MINIMAL_THRESHOLDS,
  BALANCED_THRESHOLDS,
  ACTIVE_THRESHOLDS,
  CoachingLevel,
  CoachingLevelDisplayName,
  CoachingLevelDescription,
  getThresholdsForLevel,
  allCoachingLevels,
  CoachingFunctionType,
  CoachingFunctionTypeDisplayName,
  CoachingFunctionTypeIcon,
  CoachingFunctionTypePriority,
  allCoachingFunctionTypes,
} from './coaching/coaching-thresholds';
export type { CoachingThresholds } from './coaching/coaching-thresholds';

export {
  CoachingResponse,
  CoachingResponseDisplayName,
  createCoachingPrompt,
  CoachingService,
} from './coaching/coaching-service';
export type {
  CoachingPrompt,
  FunctionCallEvent,
  CoachingEventListener,
  CoachingServiceConfig,
} from './coaching/coaching-service';

export {
  AutoDismissPreset,
  AutoDismissPresetDuration,
  AutoDismissPresetDisplayName,
  AutoDismissPresetDescription,
  allAutoDismissPresets,
  CoachingDeliveryMode,
  CoachingDeliveryModeDisplayName,
  CoachingDeliveryModeDescription,
  allCoachingDeliveryModes,
  CoachingTimingSettings,
} from './coaching/coaching-timing';
export type { CoachingTimingConfig } from './coaching/coaching-timing';

export {
  QuestionType,
  QuestionTypeDisplayName,
  QuestionTypeColor,
  QuestionTypeIsDesirable,
  AntiPattern,
  AntiPatternDisplayName,
  AntiPatternDescription,
  AntiPatternSeverity,
  EMPTY_QUESTION_STATS,
  QuestionTypeAnalyzer,
} from './coaching/question-type-analyzer';
export type {
  QuestionClassification,
  QuestionStats,
  UtteranceInput,
  QuestionTypeAnalyzerConfig,
} from './coaching/question-type-analyzer';

export {
  Methodology,
  FollowUpCategory,
  FollowUpSuggester,
} from './coaching/follow-up-suggester';
export type {
  FollowUpSuggestion,
  FollowUpUtterance,
  FollowUpSuggesterConfig,
} from './coaching/follow-up-suggester';

// ---------------------------------------------------------------------------
// Analysis
// ---------------------------------------------------------------------------

export {
  SentimentPolarity,
  SentimentPolarityDisplayName,
  SentimentPolarityColor,
  SentimentAnalyzer,
} from './analysis/sentiment-analyzer';
export type {
  SentimentResult,
  EmotionalShift,
  EmotionalArcSummary,
  SentimentUtterance,
  SentimentAnalyzerConfig,
} from './analysis/sentiment-analyzer';

export {
  BiasSeverity,
  BiasSeverityDisplayName,
  BiasType,
  BiasTypeDisplayName,
  BiasTypeDescription,
  BiasTypeDefaultSeverity,
  allBiasTypes,
  BiasDetector,
} from './analysis/bias-detector';
export type {
  BiasAlert,
  BiasClassificationInput,
  BiasDetectorConfig,
} from './analysis/bias-detector';

export {
  TalkTimeStatus,
  TalkTimeStatusDisplayName,
  TalkTimeStatusColor,
  TalkTimeAnalyzer,
} from './analysis/talk-time-analyzer';
export type {
  TalkTimeResult,
  TalkTimeWindowPoint,
  TalkTimeUtterance,
  TalkTimeAnalyzerConfig,
} from './analysis/talk-time-analyzer';

export {
  PIIType,
  PIITypeDisplayName,
  PIITypeRedactionLabel,
  allPIITypes,
  PIISeverity,
  PIISeverityDisplayName,
  PIITypeSeverity,
  PIIDetector,
} from './analysis/pii-detector';
export type {
  PIIDetection,
  PIIDetectorConfig,
} from './analysis/pii-detector';

// ---------------------------------------------------------------------------
// Redaction
// ---------------------------------------------------------------------------

export {
  ConsentStatus,
  ConsentStatusDisplayName,
  ConsentStatusColor,
  allConsentStatuses,
  RedactionDecision,
  RedactionService,
} from './redaction/redaction-service';
export type {
  RedactionAction,
  ConsentRecord,
  RedactionServiceConfig,
} from './redaction/redaction-service';

// ---------------------------------------------------------------------------
// Export
// ---------------------------------------------------------------------------

export { MarkdownExporter } from './export/markdown-exporter';
export type {
  ExportUtterance,
  ExportInsight,
  ExportHighlight,
  ExportSessionMetadata,
  MarkdownExportOptions,
} from './export/markdown-exporter';

export { JSONExporter } from './export/json-exporter';
export type {
  SessionExportData,
  ExportedUtterance,
  SessionStatistics,
  JSONExportOptions,
} from './export/json-exporter';
