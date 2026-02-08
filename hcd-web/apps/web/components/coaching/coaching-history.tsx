'use client';

import React, { useState, useMemo } from 'react';
import { Badge } from '@hcd/ui';
import { cn } from '@hcd/ui';
import { History, Check, X, Clock, Timer, Filter } from 'lucide-react';
import { useCoachingStore, type CoachingResponseType } from '@/stores/coaching-store';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function formatSessionTime(isoString: string): string {
  const date = new Date(isoString);
  const h = date.getHours().toString().padStart(2, '0');
  const m = date.getMinutes().toString().padStart(2, '0');
  const s = date.getSeconds().toString().padStart(2, '0');
  return `${h}:${m}:${s}`;
}

const RESPONSE_CONFIG: Record<
  CoachingResponseType,
  { label: string; icon: React.ReactNode; badgeClass: string }
> = {
  accepted: {
    label: 'Accepted',
    icon: <Check className="h-3 w-3" />,
    badgeClass: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100',
  },
  dismissed: {
    label: 'Dismissed',
    icon: <X className="h-3 w-3" />,
    badgeClass: 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-100',
  },
  snoozed: {
    label: 'Snoozed',
    icon: <Clock className="h-3 w-3" />,
    badgeClass: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-100',
  },
  expired: {
    label: 'Expired',
    icon: <Timer className="h-3 w-3" />,
    badgeClass: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300',
  },
};

const FILTER_OPTIONS: { value: CoachingResponseType | 'all'; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'accepted', label: 'Accepted' },
  { value: 'dismissed', label: 'Dismissed' },
  { value: 'snoozed', label: 'Snoozed' },
  { value: 'expired', label: 'Expired' },
];

// ---------------------------------------------------------------------------
// Props
// ---------------------------------------------------------------------------

export interface CoachingHistoryProps {
  /** Called when user clicks a history entry to jump to the transcript timestamp */
  onTimestampClick?: (timestamp: string) => void;
  className?: string;
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function CoachingHistory({ onTimestampClick, className }: CoachingHistoryProps) {
  const history = useCoachingStore((s) => s.history);
  const [filter, setFilter] = useState<CoachingResponseType | 'all'>('all');

  const filteredHistory = useMemo(() => {
    if (filter === 'all') return history;
    return history.filter((entry) => entry.response === filter);
  }, [history, filter]);

  return (
    <div
      className={cn('flex flex-col h-full', className)}
      role="region"
      aria-label="Coaching history"
    >
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b">
        <div className="flex items-center gap-2">
          <History className="h-4 w-4 text-muted-foreground" />
          <h3 className="text-sm font-semibold">Coaching History</h3>
          <Badge variant="secondary" className="text-xs tabular-nums">
            {history.length}
          </Badge>
        </div>
      </div>

      {/* Filter row */}
      <div className="flex items-center gap-1 px-4 py-2 border-b overflow-x-auto">
        <Filter className="h-3.5 w-3.5 text-muted-foreground flex-shrink-0 mr-1" />
        {FILTER_OPTIONS.map((option) => (
          <button
            key={option.value}
            onClick={() => setFilter(option.value)}
            className={cn(
              'px-2.5 py-1 text-xs rounded-full font-medium transition-colors whitespace-nowrap',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
              filter === option.value
                ? 'bg-primary text-primary-foreground'
                : 'bg-muted text-muted-foreground hover:bg-muted/80',
            )}
            aria-pressed={filter === option.value}
            aria-label={`Filter by ${option.label}`}
          >
            {option.label}
          </button>
        ))}
      </div>

      {/* Scrollable list */}
      <div className="flex-1 overflow-y-auto" role="list" aria-label="Coaching events">
        {filteredHistory.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
            <History className="h-8 w-8 text-muted-foreground/40 mb-3" />
            <p className="text-sm text-muted-foreground">
              {history.length === 0
                ? 'No coaching prompts yet this session'
                : 'No prompts match the selected filter'}
            </p>
          </div>
        ) : (
          filteredHistory.map((entry) => {
            const responseConfig = RESPONSE_CONFIG[entry.response];
            const displayTime = formatSessionTime(entry.event.displayedAt);

            return (
              <button
                key={`${entry.event.id}-${entry.respondedAt}`}
                onClick={() => onTimestampClick?.(entry.event.displayedAt)}
                className={cn(
                  'w-full text-left px-4 py-3 border-b last:border-b-0',
                  'hover:bg-muted/50 transition-colors',
                  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring',
                )}
                role="listitem"
                aria-label={`${entry.event.promptType} prompt at ${displayTime}: ${entry.event.promptText}. Response: ${entry.response}`}
              >
                {/* Time and response badge */}
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-muted-foreground tabular-nums font-mono">
                    {displayTime}
                  </span>
                  <span
                    className={cn(
                      'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium',
                      responseConfig.badgeClass,
                    )}
                  >
                    {responseConfig.icon}
                    {responseConfig.label}
                  </span>
                </div>

                {/* Prompt text */}
                <p className="text-sm text-foreground line-clamp-2 mb-1">
                  {entry.event.promptText}
                </p>

                {/* Prompt type */}
                <span className="text-xs text-muted-foreground capitalize">
                  {entry.event.promptType}
                </span>
              </button>
            );
          })
        )}
      </div>
    </div>
  );
}
