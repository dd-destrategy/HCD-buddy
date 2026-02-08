'use client';

import React, { useState, useMemo, useCallback } from 'react';
import { Badge } from '@hcd/ui';
import { Button } from '@hcd/ui';
import { cn } from '@hcd/ui';
import {
  AlertTriangle,
  X,
  ExternalLink,
  Shield,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';
import type { BiasAlert } from '@hcd/ws-protocol';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface BiasAlertEntry extends BiasAlert {
  /** The utterance text that triggered this alert */
  utteranceText?: string;
  /** ID of the related utterance for linking */
  utteranceId?: string;
}

export interface BiasAlertsPanelProps {
  alerts: BiasAlertEntry[];
  /** Called when user clicks to view the related utterance */
  onUtteranceClick?: (utteranceId: string) => void;
  /** Called when user dismisses an alert */
  onDismiss?: (alertId: string) => void;
  className?: string;
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const SEVERITY_CONFIG: Record<
  BiasAlert['severity'],
  { label: string; badgeVariant: 'success' | 'warning' | 'destructive'; ringColor: string }
> = {
  low: { label: 'Low', badgeVariant: 'success', ringColor: 'border-l-green-400' },
  medium: { label: 'Medium', badgeVariant: 'warning', ringColor: 'border-l-amber-400' },
  high: { label: 'High', badgeVariant: 'destructive', ringColor: 'border-l-red-400' },
};

const BIAS_TYPE_LABELS: Record<string, string> = {
  leading: 'Leading Question',
  confirmation: 'Confirmation Bias',
  anchoring: 'Anchoring Bias',
  social_desirability: 'Social Desirability',
  priming: 'Priming Effect',
  framing: 'Framing Bias',
  loaded: 'Loaded Language',
  double_barreled: 'Double-barreled',
};

// ---------------------------------------------------------------------------
// Individual alert card
// ---------------------------------------------------------------------------

interface AlertCardProps {
  alert: BiasAlertEntry;
  onUtteranceClick?: (utteranceId: string) => void;
  onDismiss?: (alertId: string) => void;
}

function AlertCard({ alert, onUtteranceClick, onDismiss }: AlertCardProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const severity = SEVERITY_CONFIG[alert.severity];
  const biasLabel = BIAS_TYPE_LABELS[alert.biasType] ?? alert.biasType;

  const handleDismiss = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation();
      onDismiss?.(alert.id);
    },
    [alert.id, onDismiss],
  );

  return (
    <div
      className={cn(
        'border rounded-lg border-l-4 bg-card transition-colors',
        severity.ringColor,
      )}
      role="alert"
      aria-label={`${severity.label} severity bias alert: ${biasLabel}`}
    >
      <div className="p-3">
        {/* Header row */}
        <div className="flex items-start justify-between gap-2 mb-2">
          <div className="flex items-center gap-2 flex-wrap">
            <AlertTriangle
              className={cn(
                'h-4 w-4 flex-shrink-0',
                alert.severity === 'high' && 'text-red-500',
                alert.severity === 'medium' && 'text-amber-500',
                alert.severity === 'low' && 'text-green-500',
              )}
            />
            <span className="text-sm font-medium">{biasLabel}</span>
            <Badge variant={severity.badgeVariant} className="text-xs">
              {severity.label}
            </Badge>
          </div>
          {onDismiss && (
            <button
              onClick={handleDismiss}
              className="text-muted-foreground hover:text-foreground transition-colors p-0.5 rounded focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              aria-label="Dismiss this alert"
            >
              <X className="h-4 w-4" />
            </button>
          )}
        </div>

        {/* Message */}
        <p className="text-sm text-foreground mb-2">{alert.message}</p>

        {/* Expand/collapse for suggestion */}
        <button
          onClick={() => setIsExpanded((prev) => !prev)}
          className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded"
          aria-expanded={isExpanded}
        >
          {isExpanded ? (
            <ChevronUp className="h-3 w-3" />
          ) : (
            <ChevronDown className="h-3 w-3" />
          )}
          {isExpanded ? 'Hide suggestion' : 'Show suggestion'}
        </button>

        {isExpanded && (
          <div className="mt-2 p-2 rounded-md bg-muted/50 text-sm text-muted-foreground animate-fade-in">
            <p className="flex items-start gap-1.5">
              <Shield className="h-4 w-4 text-blue-500 flex-shrink-0 mt-0.5" />
              {alert.suggestion}
            </p>
          </div>
        )}

        {/* Utterance link */}
        {alert.utteranceId && (
          <div className="mt-2 flex items-center gap-2">
            {alert.utteranceText && (
              <p className="text-xs text-muted-foreground italic line-clamp-1 flex-1">
                &ldquo;{alert.utteranceText}&rdquo;
              </p>
            )}
            <button
              onClick={() => onUtteranceClick?.(alert.utteranceId!)}
              className="inline-flex items-center gap-1 text-xs text-blue-500 hover:text-blue-700 transition-colors whitespace-nowrap focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded"
              aria-label="Jump to related utterance in transcript"
            >
              <ExternalLink className="h-3 w-3" />
              View in transcript
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Panel component
// ---------------------------------------------------------------------------

export function BiasAlertsPanel({
  alerts,
  onUtteranceClick,
  onDismiss,
  className,
}: BiasAlertsPanelProps) {
  const [dismissedIds, setDismissedIds] = useState<Set<string>>(new Set());

  const handleDismiss = useCallback(
    (alertId: string) => {
      setDismissedIds((prev) => new Set(prev).add(alertId));
      onDismiss?.(alertId);
    },
    [onDismiss],
  );

  const visibleAlerts = useMemo(() => {
    return alerts.filter((a) => !dismissedIds.has(a.id));
  }, [alerts, dismissedIds]);

  // Sort by severity (high first)
  const sortedAlerts = useMemo(() => {
    const order: Record<string, number> = { high: 0, medium: 1, low: 2 };
    return [...visibleAlerts].sort(
      (a, b) => (order[a.severity] ?? 3) - (order[b.severity] ?? 3),
    );
  }, [visibleAlerts]);

  const counts = useMemo(() => {
    return {
      high: visibleAlerts.filter((a) => a.severity === 'high').length,
      medium: visibleAlerts.filter((a) => a.severity === 'medium').length,
      low: visibleAlerts.filter((a) => a.severity === 'low').length,
    };
  }, [visibleAlerts]);

  return (
    <div
      className={cn('flex flex-col gap-3', className)}
      role="region"
      aria-label="Bias detection alerts"
    >
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Shield className="h-4 w-4 text-muted-foreground" />
          <h3 className="text-sm font-semibold">Bias Alerts</h3>
          {visibleAlerts.length > 0 && (
            <Badge variant="secondary" className="text-xs tabular-nums">
              {visibleAlerts.length}
            </Badge>
          )}
        </div>
        <div className="flex items-center gap-1.5">
          {counts.high > 0 && (
            <Badge variant="destructive" className="text-xs tabular-nums">
              {counts.high} high
            </Badge>
          )}
          {counts.medium > 0 && (
            <Badge variant="warning" className="text-xs tabular-nums">
              {counts.medium} med
            </Badge>
          )}
        </div>
      </div>

      {/* Alerts list */}
      {sortedAlerts.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-8 text-center">
          <Shield className="h-8 w-8 text-green-400/60 mb-3" />
          <p className="text-sm text-muted-foreground">No bias patterns detected</p>
          <p className="text-xs text-muted-foreground mt-1">
            The AI monitors for leading questions, confirmation bias, and more
          </p>
        </div>
      ) : (
        <div className="space-y-2" role="list" aria-label="Bias alerts list">
          {sortedAlerts.map((alert) => (
            <AlertCard
              key={alert.id}
              alert={alert}
              onUtteranceClick={onUtteranceClick}
              onDismiss={handleDismiss}
            />
          ))}
        </div>
      )}
    </div>
  );
}
