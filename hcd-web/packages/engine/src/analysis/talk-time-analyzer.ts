/**
 * Talk Time Analyzer
 *
 * Computes interviewer vs participant speaking ratios from utterance timestamps.
 * Includes rolling window calculation and status thresholds.
 *
 * Status thresholds:
 * - Good:    Interviewer talk ratio < 30%
 * - Warning: Interviewer talk ratio 30-40%
 * - Over:    Interviewer talk ratio > 40%
 */

import { Speaker } from '../models/speaker';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** Status of interviewer talk time */
export enum TalkTimeStatus {
  /** Interviewer talk ratio < 30% - ideal balance */
  Good = 'good',
  /** Interviewer talk ratio 30-40% - slightly high */
  Warning = 'warning',
  /** Interviewer talk ratio > 40% - talking too much */
  Over = 'over',
  /** No data available */
  NoData = 'no_data',
}

/** Display names for talk time status */
export const TalkTimeStatusDisplayName: Record<TalkTimeStatus, string> = {
  [TalkTimeStatus.Good]: 'Good',
  [TalkTimeStatus.Warning]: 'Warning',
  [TalkTimeStatus.Over]: 'Over',
  [TalkTimeStatus.NoData]: 'No Data',
};

/** Color tokens for talk time status */
export const TalkTimeStatusColor: Record<TalkTimeStatus, string> = {
  [TalkTimeStatus.Good]: 'hcdSuccess',
  [TalkTimeStatus.Warning]: 'hcdWarning',
  [TalkTimeStatus.Over]: 'hcdError',
  [TalkTimeStatus.NoData]: 'hcdTextSecondary',
};

/** Talk time analysis result */
export interface TalkTimeResult {
  /** Total speaking time for the interviewer (seconds) */
  interviewerTime: number;
  /** Total speaking time for the participant (seconds) */
  participantTime: number;
  /** Total speaking time (seconds) */
  totalTime: number;
  /** Interviewer talk ratio (0.0-1.0) */
  interviewerRatio: number;
  /** Participant talk ratio (0.0-1.0) */
  participantRatio: number;
  /** Status based on interviewer ratio thresholds */
  status: TalkTimeStatus;
}

/** A rolling window data point */
export interface TalkTimeWindowPoint {
  /** Timestamp of this window (seconds from session start) */
  timestamp: number;
  /** Interviewer ratio within this window */
  interviewerRatio: number;
  /** Participant ratio within this window */
  participantRatio: number;
  /** Status at this point */
  status: TalkTimeStatus;
}

/** Minimal utterance input for talk time analysis */
export interface TalkTimeUtterance {
  id: string;
  speaker: Speaker;
  /** Start time in seconds from session start */
  timestampSeconds: number;
  /** Duration of the utterance in seconds */
  durationSeconds: number;
}

// ---------------------------------------------------------------------------
// Talk Time Analyzer
// ---------------------------------------------------------------------------

/** Configuration for TalkTimeAnalyzer */
export interface TalkTimeAnalyzerConfig {
  /** Threshold for good status (default: 0.30) */
  goodThreshold?: number;
  /** Threshold for warning status (default: 0.40) */
  warningThreshold?: number;
  /** Rolling window size in seconds (default: 300 = 5 minutes) */
  rollingWindowSize?: number;
  /** Step size for rolling window calculation in seconds (default: 30) */
  rollingWindowStep?: number;
}

/**
 * Analyzes interviewer vs participant speaking ratios from utterance data.
 *
 * Provides overall session statistics and rolling window calculation
 * for tracking talk time balance over the course of an interview.
 */
export class TalkTimeAnalyzer {
  private readonly goodThreshold: number;
  private readonly warningThreshold: number;
  private readonly rollingWindowSize: number;
  private readonly rollingWindowStep: number;

  constructor(config: TalkTimeAnalyzerConfig = {}) {
    this.goodThreshold = config.goodThreshold ?? 0.30;
    this.warningThreshold = config.warningThreshold ?? 0.40;
    this.rollingWindowSize = config.rollingWindowSize ?? 300;
    this.rollingWindowStep = config.rollingWindowStep ?? 30;
  }

  // -------------------------------------------------------------------------
  // Public Methods
  // -------------------------------------------------------------------------

  /**
   * Compute overall talk time statistics for a set of utterances.
   *
   * @param utterances - The utterances to analyze
   * @returns Talk time result with ratios and status
   */
  analyze(utterances: TalkTimeUtterance[]): TalkTimeResult {
    if (utterances.length === 0) {
      return {
        interviewerTime: 0,
        participantTime: 0,
        totalTime: 0,
        interviewerRatio: 0,
        participantRatio: 0,
        status: TalkTimeStatus.NoData,
      };
    }

    let interviewerTime = 0;
    let participantTime = 0;

    for (const utterance of utterances) {
      const duration = Math.max(0, utterance.durationSeconds);
      if (utterance.speaker === Speaker.Interviewer) {
        interviewerTime += duration;
      } else if (utterance.speaker === Speaker.Participant) {
        participantTime += duration;
      }
    }

    const totalTime = interviewerTime + participantTime;

    if (totalTime === 0) {
      return {
        interviewerTime: 0,
        participantTime: 0,
        totalTime: 0,
        interviewerRatio: 0,
        participantRatio: 0,
        status: TalkTimeStatus.NoData,
      };
    }

    const interviewerRatio = interviewerTime / totalTime;
    const participantRatio = participantTime / totalTime;
    const status = this.getStatus(interviewerRatio);

    return {
      interviewerTime,
      participantTime,
      totalTime,
      interviewerRatio,
      participantRatio,
      status,
    };
  }

  /**
   * Compute rolling window talk time ratios over the session.
   *
   * @param utterances - The utterances to analyze
   * @returns Array of window data points for charting
   */
  rollingWindowAnalysis(utterances: TalkTimeUtterance[]): TalkTimeWindowPoint[] {
    if (utterances.length === 0) return [];

    // Determine session time range
    const minTime = Math.min(...utterances.map((u) => u.timestampSeconds));
    const maxTime = Math.max(
      ...utterances.map((u) => u.timestampSeconds + u.durationSeconds),
    );

    const points: TalkTimeWindowPoint[] = [];

    for (
      let windowEnd = minTime + this.rollingWindowStep;
      windowEnd <= maxTime;
      windowEnd += this.rollingWindowStep
    ) {
      const windowStart = Math.max(minTime, windowEnd - this.rollingWindowSize);

      // Filter utterances that overlap with this window
      const windowUtterances = utterances.filter((u) => {
        const uStart = u.timestampSeconds;
        const uEnd = u.timestampSeconds + u.durationSeconds;
        return uStart < windowEnd && uEnd > windowStart;
      });

      // Calculate talk time within the window
      let interviewerTime = 0;
      let participantTime = 0;

      for (const u of windowUtterances) {
        const overlapStart = Math.max(windowStart, u.timestampSeconds);
        const overlapEnd = Math.min(windowEnd, u.timestampSeconds + u.durationSeconds);
        const overlapDuration = Math.max(0, overlapEnd - overlapStart);

        if (u.speaker === Speaker.Interviewer) {
          interviewerTime += overlapDuration;
        } else if (u.speaker === Speaker.Participant) {
          participantTime += overlapDuration;
        }
      }

      const total = interviewerTime + participantTime;
      const interviewerRatio = total > 0 ? interviewerTime / total : 0;
      const participantRatio = total > 0 ? participantTime / total : 0;

      points.push({
        timestamp: windowEnd,
        interviewerRatio,
        participantRatio,
        status: this.getStatus(interviewerRatio),
      });
    }

    return points;
  }

  /**
   * Get a human-readable summary of the talk time balance.
   *
   * @param result - The talk time result to summarize
   * @returns Description string
   */
  summarize(result: TalkTimeResult): string {
    if (result.status === TalkTimeStatus.NoData) {
      return 'No talk time data available yet.';
    }

    const interviewerPct = Math.round(result.interviewerRatio * 100);
    const participantPct = Math.round(result.participantRatio * 100);

    switch (result.status) {
      case TalkTimeStatus.Good:
        return `Good balance: interviewer ${interviewerPct}%, participant ${participantPct}%. The participant is driving the conversation.`;
      case TalkTimeStatus.Warning:
        return `Slightly high: interviewer ${interviewerPct}%, participant ${participantPct}%. Consider asking more open-ended questions.`;
      case TalkTimeStatus.Over:
        return `Interviewer talking too much: ${interviewerPct}% vs participant ${participantPct}%. Let the participant lead more.`;
      default:
        return `Interviewer: ${interviewerPct}%, Participant: ${participantPct}%.`;
    }
  }

  // -------------------------------------------------------------------------
  // Private Methods
  // -------------------------------------------------------------------------

  /** Determine status from interviewer ratio */
  private getStatus(interviewerRatio: number): TalkTimeStatus {
    if (interviewerRatio <= this.goodThreshold) return TalkTimeStatus.Good;
    if (interviewerRatio <= this.warningThreshold) return TalkTimeStatus.Warning;
    return TalkTimeStatus.Over;
  }
}
