'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { GlassCard } from '@hcd/ui';
import { Button } from '@hcd/ui';
import { Badge } from '@hcd/ui';
import {
  Check,
  X,
  Clock,
  ChevronDown,
  ChevronUp,
  Sparkles,
  MessageCircle,
  ArrowRight,
  Pause,
  Globe,
} from 'lucide-react';
import { cn } from '@hcd/ui';
import type { CoachingEvent } from '@hcd/ws-protocol';

// ---------------------------------------------------------------------------
// Prompt type config
// ---------------------------------------------------------------------------

const PROMPT_TYPE_CONFIG: Record<
  string,
  { label: string; icon: React.ReactNode; colorClass: string }
> = {
  'follow-up': {
    label: 'Follow-up',
    icon: <ArrowRight className="h-3 w-3" />,
    colorClass: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-100',
  },
  redirect: {
    label: 'Redirect',
    icon: <MessageCircle className="h-3 w-3" />,
    colorClass: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-100',
  },
  probe: {
    label: 'Probe',
    icon: <Sparkles className="h-3 w-3" />,
    colorClass: 'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-100',
  },
  silence: {
    label: 'Silence',
    icon: <Pause className="h-3 w-3" />,
    colorClass: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-100',
  },
};

// ---------------------------------------------------------------------------
// Props
// ---------------------------------------------------------------------------

export interface CoachingPromptCardProps {
  event: CoachingEvent;
  autoDismissDuration: number;
  shownAt: number;
  onAccept: (eventId: string) => void;
  onDismiss: (eventId: string) => void;
  onSnooze: (eventId: string) => void;
  className?: string;
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function CoachingPromptCard({
  event,
  autoDismissDuration,
  shownAt,
  onAccept,
  onDismiss,
  onSnooze,
  className,
}: CoachingPromptCardProps) {
  const [isExplanationOpen, setIsExplanationOpen] = useState(false);
  const [progress, setProgress] = useState(100);

  // Auto-dismiss countdown progress bar
  useEffect(() => {
    const totalMs = autoDismissDuration * 1000;
    const intervalMs = 50;

    const interval = setInterval(() => {
      const elapsed = Date.now() - shownAt;
      const remaining = Math.max(0, 1 - elapsed / totalMs);
      setProgress(remaining * 100);

      if (remaining <= 0) {
        clearInterval(interval);
      }
    }, intervalMs);

    return () => clearInterval(interval);
  }, [autoDismissDuration, shownAt]);

  const handleAccept = useCallback(() => onAccept(event.id), [onAccept, event.id]);
  const handleDismiss = useCallback(() => onDismiss(event.id), [onDismiss, event.id]);
  const handleSnooze = useCallback(() => onSnooze(event.id), [onSnooze, event.id]);

  const typeConfig = PROMPT_TYPE_CONFIG[event.promptType] ?? {
    label: event.promptType,
    icon: <Sparkles className="h-3 w-3" />,
    colorClass: 'bg-purple-100 text-purple-800',
  };

  const confidencePercent = event.confidence != null ? Math.round(event.confidence * 100) : null;

  return (
    <GlassCard
      className={cn(
        'relative overflow-hidden border-l-4 border-l-purple-500 p-4 animate-slide-in',
        className,
      )}
      role="alert"
      aria-label={`Coaching prompt: ${event.promptText}`}
      aria-live="polite"
    >
      {/* Auto-dismiss progress bar */}
      <div
        className="absolute top-0 left-0 h-1 bg-purple-500/60 transition-all duration-75 ease-linear"
        style={{ width: `${progress}%` }}
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={Math.round(progress)}
        aria-label="Auto-dismiss countdown"
      />

      {/* Header row: type badge + confidence */}
      <div className="flex items-center justify-between mb-3 mt-1">
        <div className="flex items-center gap-2">
          <span
            className={cn(
              'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold',
              typeConfig.colorClass,
            )}
          >
            {typeConfig.icon}
            {typeConfig.label}
          </span>

          {event.culturalContext && (
            <span className="inline-flex items-center gap-1 text-xs text-muted-foreground">
              <Globe className="h-3 w-3" />
              <span className="sr-only">Cultural context:</span>
              {event.culturalContext}
            </span>
          )}
        </div>

        {confidencePercent !== null && (
          <Badge
            variant="outline"
            className="text-xs tabular-nums"
            aria-label={`Confidence: ${confidencePercent}%`}
          >
            {confidencePercent}%
          </Badge>
        )}
      </div>

      {/* Prompt text */}
      <p className="text-base font-medium leading-relaxed text-foreground mb-3">
        {event.promptText}
      </p>

      {/* Explanation toggle */}
      {event.explanation && (
        <div className="mb-3">
          <button
            onClick={() => setIsExplanationOpen((prev) => !prev)}
            className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded"
            aria-expanded={isExplanationOpen}
            aria-controls={`explanation-${event.id}`}
          >
            {isExplanationOpen ? (
              <ChevronUp className="h-3.5 w-3.5" />
            ) : (
              <ChevronDown className="h-3.5 w-3.5" />
            )}
            {isExplanationOpen ? 'Hide explanation' : 'Why this prompt?'}
          </button>

          {isExplanationOpen && (
            <p
              id={`explanation-${event.id}`}
              className="mt-2 text-sm text-muted-foreground bg-muted/50 rounded-lg p-3 animate-fade-in"
            >
              {event.explanation}
            </p>
          )}
        </div>
      )}

      {/* Action buttons */}
      <div className="flex items-center gap-2" role="group" aria-label="Prompt actions">
        <Button
          size="sm"
          onClick={handleAccept}
          className="bg-purple-600 hover:bg-purple-700 text-white"
          aria-label="Accept this coaching prompt"
        >
          <Check className="h-4 w-4 mr-1" />
          Accept
        </Button>
        <Button
          size="sm"
          variant="outline"
          onClick={handleSnooze}
          aria-label="Snooze this prompt for later"
        >
          <Clock className="h-4 w-4 mr-1" />
          Snooze
        </Button>
        <Button
          size="sm"
          variant="ghost"
          onClick={handleDismiss}
          aria-label="Dismiss this coaching prompt"
        >
          <X className="h-4 w-4 mr-1" />
          Dismiss
        </Button>
      </div>
    </GlassCard>
  );
}
