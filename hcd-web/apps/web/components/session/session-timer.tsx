'use client';

import { useEffect, useState, useCallback } from 'react';

// =============================================================================
// SessionTimer — Live session timer with recording indicator
// =============================================================================

interface SessionTimerProps {
  /** ISO date string when the session started */
  startedAt: string | null;
  /** Whether the session is currently paused */
  isPaused: boolean;
  /** Whether the session has ended */
  isEnded: boolean;
  /** Additional CSS classes */
  className?: string;
}

export function SessionTimer({ startedAt, isPaused, isEnded, className = '' }: SessionTimerProps) {
  const [elapsed, setElapsed] = useState(0);

  const formatTime = useCallback((totalSeconds: number): string => {
    const h = Math.floor(totalSeconds / 3600);
    const m = Math.floor((totalSeconds % 3600) / 60);
    const s = totalSeconds % 60;

    if (h > 0) {
      return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    }
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }, []);

  useEffect(() => {
    if (!startedAt || isEnded) return;

    const start = new Date(startedAt).getTime();

    // Initialize with current elapsed time
    setElapsed(Math.floor((Date.now() - start) / 1000));

    if (isPaused) return;

    const interval = setInterval(() => {
      setElapsed(Math.floor((Date.now() - start) / 1000));
    }, 1000);

    return () => clearInterval(interval);
  }, [startedAt, isPaused, isEnded]);

  const isRecording = !!startedAt && !isPaused && !isEnded;

  return (
    <div
      className={`inline-flex items-center gap-2 rounded-lg border px-3 py-1.5 font-mono text-sm ${className}`}
      role="timer"
      aria-label={`Session timer: ${formatTime(elapsed)}`}
      aria-live="polite"
    >
      {/* Recording indicator dot */}
      <span
        className={`inline-block h-2.5 w-2.5 rounded-full ${
          isRecording
            ? 'bg-red-500 animate-pulse-subtle'
            : isPaused
            ? 'bg-yellow-500'
            : isEnded
            ? 'bg-gray-400'
            : 'bg-gray-300'
        }`}
        aria-hidden="true"
      />

      {/* Time display */}
      <span className="tabular-nums">{formatTime(elapsed)}</span>

      {/* Status label */}
      {isPaused && (
        <span className="text-xs text-yellow-600 dark:text-yellow-400 uppercase font-semibold">
          Paused
        </span>
      )}
      {isEnded && (
        <span className="text-xs text-muted-foreground uppercase font-semibold">
          Ended
        </span>
      )}
    </div>
  );
}
