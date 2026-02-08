'use client';

import React, { useState, useCallback } from 'react';
import { Badge } from '@hcd/ui';
import { cn } from '@hcd/ui';
import { Wifi, WifiOff, Loader2, ChevronDown, ChevronUp, Signal } from 'lucide-react';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type ConnectionState = 'connected' | 'reconnecting' | 'disconnected';

export interface ConnectionStatusProps {
  state: ConnectionState;
  /** Latency in milliseconds */
  latency?: number | null;
  /** Number of reconnection attempts so far */
  reconnectAttempts?: number;
  /** Maximum reconnection attempts before giving up */
  maxReconnectAttempts?: number;
  /** WebSocket URL or server name for details view */
  serverUrl?: string;
  /** Session duration for details view */
  sessionDuration?: string;
  className?: string;
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const STATE_CONFIG: Record<
  ConnectionState,
  {
    label: string;
    badgeClass: string;
    dotColor: string;
    icon: React.ReactNode;
  }
> = {
  connected: {
    label: 'Connected',
    badgeClass: 'bg-green-100 text-green-800 border-green-200 dark:bg-green-900/50 dark:text-green-200 dark:border-green-800',
    dotColor: 'bg-green-500',
    icon: <Wifi className="h-3.5 w-3.5" />,
  },
  reconnecting: {
    label: 'Reconnecting',
    badgeClass: 'bg-yellow-100 text-yellow-800 border-yellow-200 dark:bg-yellow-900/50 dark:text-yellow-200 dark:border-yellow-800',
    dotColor: 'bg-yellow-500',
    icon: <Loader2 className="h-3.5 w-3.5 animate-spin" />,
  },
  disconnected: {
    label: 'Disconnected',
    badgeClass: 'bg-red-100 text-red-800 border-red-200 dark:bg-red-900/50 dark:text-red-200 dark:border-red-800',
    dotColor: 'bg-red-500',
    icon: <WifiOff className="h-3.5 w-3.5" />,
  },
};

function latencyQuality(latency: number): { label: string; color: string } {
  if (latency < 100) return { label: 'Excellent', color: 'text-green-600' };
  if (latency < 250) return { label: 'Good', color: 'text-green-500' };
  if (latency < 500) return { label: 'Fair', color: 'text-yellow-500' };
  return { label: 'Poor', color: 'text-red-500' };
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function ConnectionStatus({
  state,
  latency,
  reconnectAttempts = 0,
  maxReconnectAttempts = 5,
  serverUrl,
  sessionDuration,
  className,
}: ConnectionStatusProps) {
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const config = STATE_CONFIG[state];

  const handleToggleDetails = useCallback(() => {
    setIsDetailsOpen((prev) => !prev);
  }, []);

  const quality = latency != null ? latencyQuality(latency) : null;

  return (
    <div className={cn('relative', className)}>
      <button
        onClick={handleToggleDetails}
        className={cn(
          'inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition-colors',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
          config.badgeClass,
        )}
        aria-expanded={isDetailsOpen}
        aria-controls="connection-details"
        aria-label={`Connection status: ${config.label}${latency != null ? `. Latency: ${latency}ms` : ''}`}
      >
        {/* Animated status dot */}
        <span className="relative flex h-2 w-2">
          {state === 'connected' && (
            <span
              className={cn(
                'absolute inline-flex h-full w-full rounded-full opacity-75 animate-ping',
                config.dotColor,
              )}
            />
          )}
          <span className={cn('relative inline-flex rounded-full h-2 w-2', config.dotColor)} />
        </span>

        {config.icon}
        <span>{config.label}</span>

        {/* Latency */}
        {latency != null && state === 'connected' && (
          <span className="tabular-nums ml-0.5">{latency}ms</span>
        )}

        {/* Reconnect indicator */}
        {state === 'reconnecting' && (
          <span className="tabular-nums">
            ({reconnectAttempts}/{maxReconnectAttempts})
          </span>
        )}

        {isDetailsOpen ? (
          <ChevronUp className="h-3 w-3" />
        ) : (
          <ChevronDown className="h-3 w-3" />
        )}
      </button>

      {/* Details dropdown */}
      {isDetailsOpen && (
        <div
          id="connection-details"
          className="absolute top-full mt-2 right-0 z-50 min-w-[240px] rounded-lg border bg-card shadow-lg p-3 space-y-2 animate-fade-in"
          role="region"
          aria-label="Connection details"
        >
          <h4 className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">
            Connection Details
          </h4>

          <div className="space-y-1.5 text-sm">
            {/* Status */}
            <div className="flex items-center justify-between">
              <span className="text-muted-foreground">Status</span>
              <span className="font-medium">{config.label}</span>
            </div>

            {/* Latency */}
            {latency != null && (
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Latency</span>
                <span className={cn('font-medium tabular-nums', quality?.color)}>
                  {latency}ms ({quality?.label})
                </span>
              </div>
            )}

            {/* Signal quality indicator */}
            {latency != null && state === 'connected' && (
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Quality</span>
                <div className="flex items-center gap-1">
                  <Signal className={cn('h-4 w-4', quality?.color)} />
                  <span className={cn('text-xs font-medium', quality?.color)}>
                    {quality?.label}
                  </span>
                </div>
              </div>
            )}

            {/* Reconnect attempts */}
            {state === 'reconnecting' && (
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Attempts</span>
                <span className="font-medium tabular-nums">
                  {reconnectAttempts} / {maxReconnectAttempts}
                </span>
              </div>
            )}

            {/* Server URL */}
            {serverUrl && (
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Server</span>
                <span className="text-xs font-mono truncate max-w-[140px]" title={serverUrl}>
                  {serverUrl}
                </span>
              </div>
            )}

            {/* Session duration */}
            {sessionDuration && (
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Duration</span>
                <span className="font-medium tabular-nums">{sessionDuration}</span>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
