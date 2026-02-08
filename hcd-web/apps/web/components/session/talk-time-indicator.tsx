'use client';

import type { TalkTimeRatio } from '@hcd/ws-protocol';

// =============================================================================
// TalkTimeIndicator — Horizontal bar showing interviewer vs participant ratio
// =============================================================================

interface TalkTimeIndicatorProps {
  /** Talk time ratio data from server */
  ratio: TalkTimeRatio | null;
  /** Additional CSS classes */
  className?: string;
}

export function TalkTimeIndicator({ ratio, className = '' }: TalkTimeIndicatorProps) {
  if (!ratio) {
    return (
      <div className={`flex flex-col gap-1 ${className}`} aria-label="Talk time ratio: no data yet">
        <div className="flex items-center justify-between text-xs text-muted-foreground">
          <span>Interviewer</span>
          <span>Participant</span>
        </div>
        <div className="h-3 w-full rounded-full bg-muted overflow-hidden">
          <div className="h-full w-1/2 bg-gray-300 dark:bg-gray-600" />
        </div>
        <p className="text-xs text-muted-foreground text-center">Waiting for data...</p>
      </div>
    );
  }

  const interviewerPct = Math.round(ratio.interviewer * 100);
  const participantPct = Math.round(ratio.participant * 100);

  // Color coding based on interviewer talk-time percentage
  // green: <30%, yellow: 30-40%, red: >40%
  const statusColor = (() => {
    if (interviewerPct > 40) return 'text-red-600 dark:text-red-400';
    if (interviewerPct >= 30) return 'text-yellow-600 dark:text-yellow-400';
    return 'text-green-600 dark:text-green-400';
  })();

  const interviewerBarColor = (() => {
    if (interviewerPct > 40) return 'bg-red-500';
    if (interviewerPct >= 30) return 'bg-yellow-500';
    return 'bg-green-500';
  })();

  const tooltipText = `Interviewer: ${interviewerPct}% | Participant: ${participantPct}% | Status: ${ratio.status}`;

  return (
    <div
      className={`flex flex-col gap-1 ${className}`}
      role="img"
      aria-label={tooltipText}
      title={tooltipText}
    >
      {/* Labels */}
      <div className="flex items-center justify-between text-xs">
        <span className="text-blue-600 dark:text-blue-400 font-medium">
          You: {interviewerPct}%
        </span>
        <span className={`text-xs font-semibold ${statusColor}`}>
          {ratio.status === 'good'
            ? 'Good balance'
            : ratio.status === 'warning'
            ? 'Watch balance'
            : 'Over-talking'}
        </span>
        <span className="text-emerald-600 dark:text-emerald-400 font-medium">
          Them: {participantPct}%
        </span>
      </div>

      {/* Bar */}
      <div className="h-3 w-full rounded-full bg-emerald-200 dark:bg-emerald-900 overflow-hidden flex">
        <div
          className={`h-full transition-all duration-500 ease-out ${interviewerBarColor}`}
          style={{ width: `${interviewerPct}%` }}
        />
      </div>
    </div>
  );
}
