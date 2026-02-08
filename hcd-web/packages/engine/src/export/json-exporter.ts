/**
 * JSON Exporter
 *
 * Exports full session data as a structured JSON document.
 * Supports redaction and all session components.
 */

import { Speaker } from '../models/speaker';
import { RedactionService } from '../redaction/redaction-service';
import type {
  ExportUtterance,
  ExportInsight,
  ExportHighlight,
  ExportSessionMetadata,
} from './markdown-exporter';

// ---------------------------------------------------------------------------
// JSON Export Types
// ---------------------------------------------------------------------------

/** Full session data structure for JSON export */
export interface SessionExportData {
  /** Export format version */
  version: string;
  /** Export timestamp (ISO 8601) */
  exportedAt: string;
  /** Session metadata */
  metadata: ExportSessionMetadata;
  /** Full transcript utterances */
  transcript: ExportedUtterance[];
  /** Flagged insights */
  insights: ExportInsight[];
  /** Highlighted moments */
  highlights: ExportHighlight[];
  /** Session statistics */
  statistics: SessionStatistics;
}

/** An utterance in the exported JSON */
export interface ExportedUtterance {
  id: string;
  text: string;
  originalText?: string;
  speaker: Speaker;
  timestampSeconds: number;
  durationSeconds?: number;
  isRedacted: boolean;
}

/** Session statistics included in export */
export interface SessionStatistics {
  totalUtterances: number;
  interviewerUtterances: number;
  participantUtterances: number;
  totalDurationSeconds: number;
  averageUtteranceDuration: number;
  interviewerTalkRatio: number;
  participantTalkRatio: number;
}

/** JSON export options */
export interface JSONExportOptions {
  /** Apply redactions using the provided service */
  redactionService?: RedactionService;
  /** Include original (pre-redaction) text (default: false) */
  includeOriginalText?: boolean;
  /** Pretty-print the JSON (default: true) */
  prettyPrint?: boolean;
  /** Export format version (default: '1.0.0') */
  version?: string;
}

// ---------------------------------------------------------------------------
// JSON Exporter
// ---------------------------------------------------------------------------

/**
 * Exports full session data as structured JSON.
 *
 * Produces a complete, self-contained JSON document containing all session
 * data with optional PII redaction.
 */
export class JSONExporter {
  /**
   * Export session data as a JSON string.
   *
   * @param metadata - Session metadata
   * @param utterances - Session utterances
   * @param insights - Flagged insights
   * @param highlights - Highlighted moments
   * @param options - Export options
   * @returns JSON string of the session data
   */
  export(
    metadata: ExportSessionMetadata,
    utterances: ExportUtterance[],
    insights: ExportInsight[] = [],
    highlights: ExportHighlight[] = [],
    options: JSONExportOptions = {},
  ): string {
    const {
      redactionService,
      includeOriginalText = false,
      prettyPrint = true,
      version = '1.0.0',
    } = options;

    const exportData = this.buildExportData(
      metadata,
      utterances,
      insights,
      highlights,
      {
        redactionService,
        includeOriginalText,
        version,
      },
    );

    return prettyPrint
      ? JSON.stringify(exportData, null, 2)
      : JSON.stringify(exportData);
  }

  /**
   * Export session data as a structured object (not stringified).
   *
   * @param metadata - Session metadata
   * @param utterances - Session utterances
   * @param insights - Flagged insights
   * @param highlights - Highlighted moments
   * @param options - Export options
   * @returns The structured session export data
   */
  exportAsObject(
    metadata: ExportSessionMetadata,
    utterances: ExportUtterance[],
    insights: ExportInsight[] = [],
    highlights: ExportHighlight[] = [],
    options: JSONExportOptions = {},
  ): SessionExportData {
    const {
      redactionService,
      includeOriginalText = false,
      version = '1.0.0',
    } = options;

    return this.buildExportData(
      metadata,
      utterances,
      insights,
      highlights,
      {
        redactionService,
        includeOriginalText,
        version,
      },
    );
  }

  // -------------------------------------------------------------------------
  // Private Methods
  // -------------------------------------------------------------------------

  private buildExportData(
    metadata: ExportSessionMetadata,
    utterances: ExportUtterance[],
    insights: ExportInsight[],
    highlights: ExportHighlight[],
    options: {
      redactionService?: RedactionService;
      includeOriginalText: boolean;
      version: string;
    },
  ): SessionExportData {
    const { redactionService, includeOriginalText, version } = options;

    // Process utterances with optional redaction
    const transcript: ExportedUtterance[] = utterances.map((u) => {
      let text = u.text;
      let isRedacted = false;

      if (redactionService) {
        const redactedText = redactionService.applyRedactionsToText(text, u.id);
        isRedacted = redactedText !== text;
        text = redactedText;
      }

      const exported: ExportedUtterance = {
        id: u.id,
        text,
        speaker: u.speaker,
        timestampSeconds: u.timestampSeconds,
        durationSeconds: u.durationSeconds,
        isRedacted,
      };

      if (includeOriginalText && isRedacted) {
        exported.originalText = u.text;
      }

      return exported;
    });

    // Compute statistics
    const statistics = this.computeStatistics(utterances);

    return {
      version,
      exportedAt: new Date().toISOString(),
      metadata,
      transcript,
      insights,
      highlights,
      statistics,
    };
  }

  private computeStatistics(utterances: ExportUtterance[]): SessionStatistics {
    const totalUtterances = utterances.length;
    const interviewerUtterances = utterances.filter(
      (u) => u.speaker === Speaker.Interviewer,
    ).length;
    const participantUtterances = utterances.filter(
      (u) => u.speaker === Speaker.Participant,
    ).length;

    let interviewerTime = 0;
    let participantTime = 0;

    for (const u of utterances) {
      const duration = u.durationSeconds ?? 0;
      if (u.speaker === Speaker.Interviewer) {
        interviewerTime += duration;
      } else if (u.speaker === Speaker.Participant) {
        participantTime += duration;
      }
    }

    const totalDuration = interviewerTime + participantTime;
    const averageDuration = totalUtterances > 0
      ? totalDuration / totalUtterances
      : 0;

    return {
      totalUtterances,
      interviewerUtterances,
      participantUtterances,
      totalDurationSeconds: totalDuration,
      averageUtteranceDuration: averageDuration,
      interviewerTalkRatio: totalDuration > 0 ? interviewerTime / totalDuration : 0,
      participantTalkRatio: totalDuration > 0 ? participantTime / totalDuration : 0,
    };
  }
}
