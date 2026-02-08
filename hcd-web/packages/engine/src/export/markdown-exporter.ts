/**
 * Markdown Exporter
 *
 * Generates Markdown from session data including utterances, insights,
 * highlights, and metadata. Supports redaction.
 */

import { Speaker, SpeakerDisplayName } from '../models/speaker';
import { RedactionService } from '../redaction/redaction-service';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** An utterance for export */
export interface ExportUtterance {
  id: string;
  text: string;
  speaker: Speaker;
  timestampSeconds: number;
  /** Optional duration in seconds */
  durationSeconds?: number;
}

/** An insight/flagged moment */
export interface ExportInsight {
  id: string;
  text: string;
  timestampSeconds: number;
  /** Whether this was manually flagged */
  isManual: boolean;
  /** Optional category */
  category?: string;
}

/** A highlight */
export interface ExportHighlight {
  id: string;
  text: string;
  note?: string;
  timestampSeconds: number;
  color?: string;
}

/** Session metadata for export */
export interface ExportSessionMetadata {
  id: string;
  title: string;
  date: string; // ISO 8601
  duration: number; // seconds
  participantCount?: number;
  templateName?: string;
  methodology?: string;
  notes?: string;
}

/** Export options */
export interface MarkdownExportOptions {
  /** Include timestamps with each utterance (default: true) */
  includeTimestamps?: boolean;
  /** Include insights section (default: true) */
  includeInsights?: boolean;
  /** Include highlights section (default: true) */
  includeHighlights?: boolean;
  /** Include session metadata header (default: true) */
  includeMetadata?: boolean;
  /** Apply redactions using the provided service */
  redactionService?: RedactionService;
  /** Include speaker labels (default: true) */
  includeSpeakerLabels?: boolean;
}

// ---------------------------------------------------------------------------
// Markdown Exporter
// ---------------------------------------------------------------------------

/**
 * Generates Markdown documents from interview session data.
 *
 * Supports full session export with utterances, insights, highlights,
 * metadata, and PII redaction.
 */
export class MarkdownExporter {
  /**
   * Export a complete session to Markdown.
   *
   * @param metadata - Session metadata
   * @param utterances - Session utterances
   * @param insights - Flagged insights
   * @param highlights - Highlighted text
   * @param options - Export options
   * @returns Formatted Markdown string
   */
  export(
    metadata: ExportSessionMetadata,
    utterances: ExportUtterance[],
    insights: ExportInsight[] = [],
    highlights: ExportHighlight[] = [],
    options: MarkdownExportOptions = {},
  ): string {
    const {
      includeTimestamps = true,
      includeInsights = true,
      includeHighlights = true,
      includeMetadata = true,
      redactionService,
      includeSpeakerLabels = true,
    } = options;

    const sections: string[] = [];

    // Title
    sections.push(`# ${metadata.title}\n`);

    // Metadata
    if (includeMetadata) {
      sections.push(this.formatMetadata(metadata));
    }

    // Transcript
    sections.push('## Transcript\n');
    sections.push(
      this.formatTranscript(utterances, {
        includeTimestamps,
        includeSpeakerLabels,
        redactionService,
      }),
    );

    // Insights
    if (includeInsights && insights.length > 0) {
      sections.push('## Insights\n');
      sections.push(this.formatInsights(insights));
    }

    // Highlights
    if (includeHighlights && highlights.length > 0) {
      sections.push('## Highlights\n');
      sections.push(this.formatHighlights(highlights));
    }

    // Footer
    sections.push('---\n');
    sections.push(
      `*Exported on ${new Date().toLocaleDateString()} by HCD Interview Coach*\n`,
    );

    return sections.join('\n');
  }

  /**
   * Export just the transcript portion.
   *
   * @param utterances - Session utterances
   * @param options - Export options
   * @returns Formatted Markdown transcript
   */
  exportTranscript(
    utterances: ExportUtterance[],
    options: MarkdownExportOptions = {},
  ): string {
    const {
      includeTimestamps = true,
      includeSpeakerLabels = true,
      redactionService,
    } = options;

    return this.formatTranscript(utterances, {
      includeTimestamps,
      includeSpeakerLabels,
      redactionService,
    });
  }

  // -------------------------------------------------------------------------
  // Private Methods
  // -------------------------------------------------------------------------

  private formatMetadata(metadata: ExportSessionMetadata): string {
    const lines: string[] = [];
    lines.push('| Field | Value |');
    lines.push('|-------|-------|');
    lines.push(`| **Date** | ${new Date(metadata.date).toLocaleDateString()} |`);
    lines.push(`| **Duration** | ${this.formatDuration(metadata.duration)} |`);

    if (metadata.participantCount !== undefined) {
      lines.push(`| **Participants** | ${metadata.participantCount} |`);
    }
    if (metadata.templateName) {
      lines.push(`| **Template** | ${metadata.templateName} |`);
    }
    if (metadata.methodology) {
      lines.push(`| **Methodology** | ${metadata.methodology} |`);
    }
    if (metadata.notes) {
      lines.push(`| **Notes** | ${metadata.notes} |`);
    }

    lines.push('');
    return lines.join('\n');
  }

  private formatTranscript(
    utterances: ExportUtterance[],
    options: {
      includeTimestamps: boolean;
      includeSpeakerLabels: boolean;
      redactionService?: RedactionService;
    },
  ): string {
    if (utterances.length === 0) return '*No transcript data available.*\n';

    const lines: string[] = [];

    for (const utterance of utterances) {
      let text = utterance.text;

      // Apply redactions if service provided
      if (options.redactionService) {
        text = options.redactionService.applyRedactionsToText(
          text,
          utterance.id,
        );
      }

      const parts: string[] = [];

      // Timestamp
      if (options.includeTimestamps) {
        parts.push(`\`${this.formatTimestamp(utterance.timestampSeconds)}\``);
      }

      // Speaker label
      if (options.includeSpeakerLabels) {
        const speakerName = SpeakerDisplayName[utterance.speaker];
        parts.push(`**${speakerName}:**`);
      }

      // Text
      parts.push(text);

      lines.push(parts.join(' '));
      lines.push('');
    }

    return lines.join('\n');
  }

  private formatInsights(insights: ExportInsight[]): string {
    const lines: string[] = [];

    for (const insight of insights) {
      const timestamp = this.formatTimestamp(insight.timestampSeconds);
      const flag = insight.isManual ? '[Manual]' : '[Auto]';
      const category = insight.category ? ` (${insight.category})` : '';
      lines.push(`- \`${timestamp}\` ${flag}${category} ${insight.text}`);
    }

    lines.push('');
    return lines.join('\n');
  }

  private formatHighlights(highlights: ExportHighlight[]): string {
    const lines: string[] = [];

    for (const highlight of highlights) {
      const timestamp = this.formatTimestamp(highlight.timestampSeconds);
      lines.push(`> \`${timestamp}\` ${highlight.text}`);
      if (highlight.note) {
        lines.push(`> *Note: ${highlight.note}*`);
      }
      lines.push('');
    }

    return lines.join('\n');
  }

  /**
   * Format seconds as MM:SS or HH:MM:SS
   */
  private formatTimestamp(seconds: number): string {
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);

    if (hrs > 0) {
      return `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  /**
   * Format duration in seconds as human-readable string
   */
  private formatDuration(seconds: number): string {
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);

    const parts: string[] = [];
    if (hrs > 0) parts.push(`${hrs}h`);
    if (mins > 0) parts.push(`${mins}m`);
    if (secs > 0 || parts.length === 0) parts.push(`${secs}s`);

    return parts.join(' ');
  }
}
