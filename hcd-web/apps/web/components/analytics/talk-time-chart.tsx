'use client';

import React, { useMemo } from 'react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ReferenceLine,
  CartesianGrid,
  Legend,
} from 'recharts';
import { cn } from '@hcd/ui';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface TalkTimeDataPoint {
  /** Elapsed session time in seconds (start of the 30-second window) */
  time: number;
  /** Interviewer talk percentage for this window (0-100) */
  interviewer: number;
  /** Participant talk percentage for this window (0-100) */
  participant: number;
}

export interface TalkTimeSummary {
  /** Overall interviewer talk percentage */
  overallInterviewer: number;
  /** Overall participant talk percentage */
  overallParticipant: number;
  /** Longest continuous interviewer speaking stretch in seconds */
  longestInterviewerMonologue: number;
}

export interface TalkTimeChartProps {
  data: TalkTimeDataPoint[];
  summary?: TalkTimeSummary;
  /** Interviewer talk time warning threshold (percentage). Default 30 */
  warningThreshold?: number;
  className?: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
}

function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return s > 0 ? `${m}m ${s}s` : `${m}m`;
}

// ---------------------------------------------------------------------------
// Custom tooltip
// ---------------------------------------------------------------------------

interface TooltipPayloadItem {
  dataKey: string;
  value: number;
  color: string;
}

function CustomTooltip({
  active,
  payload,
  label,
}: {
  active?: boolean;
  payload?: TooltipPayloadItem[];
  label?: number;
}) {
  if (!active || !payload?.length || label == null) return null;

  return (
    <div className="rounded-lg border bg-card p-3 shadow-md">
      <p className="text-xs font-mono text-muted-foreground mb-1.5">{formatTime(label)}</p>
      {payload.map((entry) => (
        <div key={entry.dataKey} className="flex items-center gap-2 text-sm">
          <span className="h-2 w-2 rounded-full" style={{ backgroundColor: entry.color }} />
          <span className="capitalize">{entry.dataKey}</span>
          <span className="tabular-nums font-medium ml-auto">{entry.value.toFixed(0)}%</span>
        </div>
      ))}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function TalkTimeChart({
  data,
  summary,
  warningThreshold = 30,
  className,
}: TalkTimeChartProps) {
  // Ensure data sums to 100 for stacked area
  const normalizedData = useMemo(() => {
    return data.map((d) => {
      const total = d.interviewer + d.participant;
      if (total === 0) return { ...d, interviewer: 0, participant: 0 };
      return {
        time: d.time,
        interviewer: (d.interviewer / total) * 100,
        participant: (d.participant / total) * 100,
      };
    });
  }, [data]);

  if (data.length === 0) {
    return (
      <div className={cn('flex items-center justify-center h-64 text-muted-foreground', className)}>
        <p className="text-sm">No talk time data available yet</p>
      </div>
    );
  }

  return (
    <div className={cn('w-full', className)} role="img" aria-label="Talk time distribution chart">
      {/* Summary stats */}
      {summary && (
        <div className="flex gap-4 mb-4 px-2 flex-wrap">
          <div className="text-sm">
            <span className="text-muted-foreground">Interviewer: </span>
            <span
              className={cn(
                'font-semibold tabular-nums',
                summary.overallInterviewer > warningThreshold
                  ? 'text-amber-600'
                  : 'text-blue-600',
              )}
            >
              {summary.overallInterviewer.toFixed(0)}%
            </span>
          </div>
          <div className="text-sm">
            <span className="text-muted-foreground">Participant: </span>
            <span className="font-semibold tabular-nums text-green-600">
              {summary.overallParticipant.toFixed(0)}%
            </span>
          </div>
          <div className="text-sm">
            <span className="text-muted-foreground">Longest monologue: </span>
            <span className="font-semibold tabular-nums">
              {formatDuration(summary.longestInterviewerMonologue)}
            </span>
          </div>
        </div>
      )}

      <ResponsiveContainer width="100%" height={280}>
        <AreaChart data={normalizedData} margin={{ top: 8, right: 16, bottom: 8, left: 8 }}>
          <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
          <XAxis
            dataKey="time"
            tickFormatter={formatTime}
            tick={{ fontSize: 12 }}
            stroke="hsl(215 16% 47%)"
          />
          <YAxis
            domain={[0, 100]}
            ticks={[0, 25, 50, 75, 100]}
            tickFormatter={(v: number) => `${v}%`}
            tick={{ fontSize: 12 }}
            stroke="hsl(215 16% 47%)"
          />

          {/* Warning threshold reference line */}
          <ReferenceLine
            y={warningThreshold}
            stroke="hsl(38 92% 50%)"
            strokeDasharray="4 4"
            label={{
              value: `${warningThreshold}% threshold`,
              position: 'right',
              fontSize: 11,
              fill: 'hsl(38 92% 50%)',
            }}
          />

          <Tooltip content={<CustomTooltip />} />
          <Legend
            verticalAlign="top"
            height={36}
            formatter={(value: string) => (
              <span className="text-sm capitalize">{value}</span>
            )}
          />

          <Area
            type="monotone"
            dataKey="interviewer"
            stackId="1"
            stroke="hsl(217 91% 60%)"
            fill="hsl(217 91% 60%)"
            fillOpacity={0.4}
            name="interviewer"
          />
          <Area
            type="monotone"
            dataKey="participant"
            stackId="1"
            stroke="hsl(142 71% 45%)"
            fill="hsl(142 71% 45%)"
            fillOpacity={0.4}
            name="participant"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
