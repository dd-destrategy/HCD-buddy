'use client';

import { useCallback } from 'react';
import { CheckCircle, Circle, Minus } from 'lucide-react';
import type { TopicUpdate } from '@hcd/ws-protocol';

// =============================================================================
// TopicTracker — List of topics with coverage status
// =============================================================================

interface TopicTrackerProps {
  /** Current topic states */
  topics: TopicUpdate[];
  /** Callback when user manually updates a topic status */
  onTopicUpdate?: (topicName: string, status: 'not_covered' | 'partial' | 'covered') => void;
  /** Whether manual edits are allowed (true during live session) */
  editable?: boolean;
  /** Additional CSS classes */
  className?: string;
}

export function TopicTracker({
  topics,
  onTopicUpdate,
  editable = false,
  className = '',
}: TopicTrackerProps) {
  const cycleStatus = useCallback(
    (topicName: string, currentStatus: string) => {
      if (!editable || !onTopicUpdate) return;

      const nextStatus: Record<string, 'not_covered' | 'partial' | 'covered'> = {
        not_covered: 'partial',
        partial: 'covered',
        covered: 'not_covered',
      };

      onTopicUpdate(topicName, nextStatus[currentStatus] || 'partial');
    },
    [editable, onTopicUpdate]
  );

  const coveredCount = topics.filter((t) => t.status === 'covered').length;
  const partialCount = topics.filter((t) => t.status === 'partial').length;
  const totalCount = topics.length;

  if (totalCount === 0) {
    return (
      <div className={`flex flex-col items-center justify-center py-8 text-muted-foreground ${className}`}>
        <Circle className="h-8 w-8 mb-2 opacity-40" aria-hidden="true" />
        <p className="text-sm">No topics defined</p>
        <p className="text-xs mt-1">Topics will appear when a template is loaded</p>
      </div>
    );
  }

  return (
    <div className={`flex flex-col gap-2 ${className}`} role="list" aria-label="Topic coverage tracker">
      {/* Summary bar */}
      <div className="flex items-center justify-between text-xs text-muted-foreground px-1">
        <span>
          {coveredCount}/{totalCount} covered
          {partialCount > 0 && `, ${partialCount} partial`}
        </span>
        <span className="text-xs">
          {Math.round(((coveredCount + partialCount * 0.5) / totalCount) * 100)}%
        </span>
      </div>

      {/* Progress bar */}
      <div className="h-1.5 w-full rounded-full bg-muted overflow-hidden flex">
        <div
          className="h-full bg-green-500 transition-all duration-300"
          style={{ width: `${(coveredCount / totalCount) * 100}%` }}
        />
        <div
          className="h-full bg-yellow-500 transition-all duration-300"
          style={{ width: `${(partialCount / totalCount) * 100}%` }}
        />
      </div>

      {/* Topic list */}
      <ul className="flex flex-col gap-0.5 mt-1">
        {topics.map((topic) => {
          const isCovered = topic.status === 'covered';
          const isPartial = topic.status === 'partial';

          return (
            <li key={topic.topicName} role="listitem">
              <button
                type="button"
                onClick={() => cycleStatus(topic.topicName, topic.status)}
                disabled={!editable}
                className={`
                  flex items-center gap-2 w-full rounded-md px-2 py-1.5 text-sm text-left
                  transition-colors
                  ${editable ? 'hover:bg-muted cursor-pointer' : 'cursor-default'}
                  ${isCovered ? 'text-green-700 dark:text-green-400' : ''}
                  ${isPartial ? 'text-yellow-700 dark:text-yellow-400' : ''}
                  ${!isCovered && !isPartial ? 'text-muted-foreground' : ''}
                `}
                aria-label={`${topic.topicName}: ${topic.status.replace('_', ' ')}${editable ? '. Click to cycle status.' : ''}`}
              >
                {isCovered ? (
                  <CheckCircle className="h-4 w-4 shrink-0 text-green-500" aria-hidden="true" />
                ) : isPartial ? (
                  <Minus className="h-4 w-4 shrink-0 text-yellow-500" aria-hidden="true" />
                ) : (
                  <Circle className="h-4 w-4 shrink-0 text-gray-400" aria-hidden="true" />
                )}
                <span className="truncate">{topic.topicName}</span>
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
