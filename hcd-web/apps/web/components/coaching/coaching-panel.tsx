'use client';

import React, { useCallback, useEffect, useRef } from 'react';
import { Button } from '@hcd/ui';
import { Badge } from '@hcd/ui';
import { cn } from '@hcd/ui';
import { Sparkles, ChevronRight } from 'lucide-react';
import { useCoachingStore } from '@/stores/coaching-store';
import { CoachingPromptCard } from './coaching-prompt-card';

// ---------------------------------------------------------------------------
// Props
// ---------------------------------------------------------------------------

export interface CoachingPanelProps {
  className?: string;
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function CoachingPanel({ className }: CoachingPanelProps) {
  const activePrompt = useCoachingStore((s) => s.activePrompt);
  const activePromptShownAt = useCoachingStore((s) => s.activePromptShownAt);
  const queue = useCoachingStore((s) => s.queue);
  const settings = useCoachingStore((s) => s.settings);
  const promptsShownCount = useCoachingStore((s) => s.promptsShownCount);

  const acceptPrompt = useCoachingStore((s) => s.acceptPrompt);
  const dismissPrompt = useCoachingStore((s) => s.dismissPrompt);
  const snoozePrompt = useCoachingStore((s) => s.snoozePrompt);
  const pullNext = useCoachingStore((s) => s.pullNext);

  const panelRef = useRef<HTMLDivElement>(null);

  // Focus management: when a new prompt appears, focus the panel
  useEffect(() => {
    if (activePrompt && panelRef.current) {
      const firstButton = panelRef.current.querySelector<HTMLButtonElement>('button');
      // Don't steal focus aggressively; use a short delay
      const timer = setTimeout(() => {
        firstButton?.focus({ preventScroll: true });
      }, 300);
      return () => clearTimeout(timer);
    }
  }, [activePrompt]);

  const handlePullNext = useCallback(() => {
    pullNext();
  }, [pullNext]);

  const isPullMode = settings.deliveryMode === 'pull';
  const remainingPrompts = Math.max(0, settings.maxPrompts - promptsShownCount);

  if (!settings.enabled) {
    return null;
  }

  return (
    <div
      ref={panelRef}
      className={cn('flex flex-col gap-3', className)}
      role="region"
      aria-label="Coaching panel"
    >
      {/* Active prompt */}
      {activePrompt && activePromptShownAt && (
        <div className="animate-slide-in">
          <CoachingPromptCard
            event={activePrompt}
            autoDismissDuration={settings.autoDismissDuration}
            shownAt={activePromptShownAt}
            onAccept={acceptPrompt}
            onDismiss={dismissPrompt}
            onSnooze={snoozePrompt}
          />
        </div>
      )}

      {/* Pull mode: show pull button when no active prompt */}
      {isPullMode && !activePrompt && queue.length > 0 && (
        <div className="flex items-center gap-2 animate-fade-in">
          <Button
            onClick={handlePullNext}
            variant="glass"
            className="flex-1 border-purple-500/30 hover:border-purple-500/50"
            disabled={remainingPrompts <= 0}
            aria-label={`Pull next coaching prompt. ${queue.length} prompts queued.`}
          >
            <Sparkles className="h-4 w-4 mr-2 text-purple-500" />
            Pull next prompt
            <ChevronRight className="h-4 w-4 ml-2" />
          </Button>

          <Badge
            variant="secondary"
            className="tabular-nums"
            aria-label={`${queue.length} prompts in queue`}
          >
            {queue.length}
          </Badge>
        </div>
      )}

      {/* Queue badge (shown in realtime mode when there is a queue behind an active prompt) */}
      {!isPullMode && activePrompt && queue.length > 0 && (
        <div className="flex items-center justify-end">
          <Badge
            variant="secondary"
            className="text-xs tabular-nums"
            aria-label={`${queue.length} more prompts queued`}
          >
            +{queue.length} queued
          </Badge>
        </div>
      )}

      {/* Empty state */}
      {!activePrompt && queue.length === 0 && (
        <div
          className={cn(
            'flex items-center gap-3 rounded-xl border border-dashed border-muted-foreground/25 p-4',
            'text-muted-foreground animate-fade-in',
          )}
          aria-live="polite"
        >
          <Sparkles className="h-5 w-5 text-purple-400 animate-pulse-subtle flex-shrink-0" />
          <div>
            <p className="text-sm font-medium">Coaching is listening...</p>
            <p className="text-xs mt-0.5">
              {remainingPrompts > 0
                ? `${remainingPrompts} prompt${remainingPrompts !== 1 ? 's' : ''} remaining this session`
                : 'Maximum prompts reached for this session'}
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
