'use client';

import React, { useMemo } from 'react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ReferenceLine,
  ReferenceArea,
  CartesianGrid,
} from 'recharts';
import { cn } from '@hcd/ui';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface SentimentDataPoint {
  /** Elapsed session time in seconds */
  time: number;
  /** Sentiment score, -1 (negative) to +1 (positive) */
  score: number;
  /** The utterance text preview for tooltip */
  utterancePreview?: string;
  /** Whether this point is an emotional shift */
  isShift?: boolean;
  /** Polarity label */
  polarity?: 'positive' | 'negative' | 'neutral' | 'mixed';
}

export interface EmotionalArcChartProps {
  data: SentimentDataPoint[];
  /** Threshold above which a score change is considered a shift. Default 0.3 */
  shiftThreshold?: number;
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

// ---------------------------------------------------------------------------
// Custom tooltip
// ---------------------------------------------------------------------------

interface TooltipPayload {
  time: number;
  score: number;
  utterancePreview?: string;
  polarity?: string;
}

function CustomTooltip({
  active,
  payload,
}: {
  active?: boolean;
  payload?: Array<{ payload: TooltipPayload }>;
}) {
  if (!active || !payload?.[0]) return null;
  const d = payload[0].payload;
  return (
    <div className="rounded-lg border bg-card p-3 shadow-md max-w-xs">
      <div className="flex items-center gap-2 mb-1">
        <span className="text-xs font-mono text-muted-foreground">{formatTime(d.time)}</span>
        <span
          className={cn(
            'text-xs font-semibold',
            d.score > 0.2 && 'text-green-600',
            d.score < -0.2 && 'text-red-600',
            d.score >= -0.2 && d.score <= 0.2 && 'text-gray-600',
          )}
        >
          {d.score > 0 ? '+' : ''}
          {d.score.toFixed(2)}
        </span>
      </div>
      {d.utterancePreview && (
        <p className="text-sm text-foreground line-clamp-3">&ldquo;{d.utterancePreview}&rdquo;</p>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Custom dot for shift points
// ---------------------------------------------------------------------------

interface DotProps {
  cx?: number;
  cy?: number;
  payload?: SentimentDataPoint;
}

function ShiftDot({ cx, cy, payload }: DotProps) {
  if (!payload?.isShift || cx == null || cy == null) return null;
  return (
    <circle
      cx={cx}
      cy={cy}
      r={6}
      fill="hsl(262 83% 58%)"
      stroke="white"
      strokeWidth={2}
      aria-label={`Emotional shift at ${formatTime(payload.time)}`}
    />
  );
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function EmotionalArcChart({
  data,
  shiftThreshold = 0.3,
  className,
}: EmotionalArcChartProps) {
  // Annotate shift points
  const chartData = useMemo(() => {
    return data.map((point, idx) => {
      if (idx === 0) return { ...point, isShift: false };
      const prev = data[idx - 1];
      const delta = Math.abs(point.score - prev.score);
      return {
        ...point,
        isShift: point.isShift ?? delta >= shiftThreshold,
      };
    });
  }, [data, shiftThreshold]);

  if (data.length === 0) {
    return (
      <div className={cn('flex items-center justify-center h-64 text-muted-foreground', className)}>
        <p className="text-sm">No sentiment data available yet</p>
      </div>
    );
  }

  return (
    <div
      className={cn('w-full', className)}
      role="img"
      aria-label="Emotional arc chart showing sentiment over session time"
    >
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={chartData} margin={{ top: 16, right: 16, bottom: 8, left: 8 }}>
          <CartesianGrid strokeDasharray="3 3" opacity={0.15} />

          {/* Color-coded background regions */}
          <ReferenceArea y1={0.2} y2={1} fill="hsl(142 71% 45%)" fillOpacity={0.06} />
          <ReferenceArea y1={-0.2} y2={0.2} fill="hsl(215 16% 47%)" fillOpacity={0.04} />
          <ReferenceArea y1={-1} y2={-0.2} fill="hsl(0 84% 60%)" fillOpacity={0.06} />

          <XAxis
            dataKey="time"
            tickFormatter={formatTime}
            tick={{ fontSize: 12 }}
            stroke="hsl(215 16% 47%)"
            label={{ value: 'Session Time', position: 'insideBottom', offset: -4, fontSize: 12 }}
          />
          <YAxis
            domain={[-1, 1]}
            ticks={[-1, -0.5, 0, 0.5, 1]}
            tick={{ fontSize: 12 }}
            stroke="hsl(215 16% 47%)"
            label={{
              value: 'Sentiment',
              angle: -90,
              position: 'insideLeft',
              offset: 10,
              fontSize: 12,
            }}
          />

          {/* Reference lines */}
          <ReferenceLine y={0} stroke="hsl(215 16% 47%)" strokeDasharray="4 4" />
          <ReferenceLine y={shiftThreshold} stroke="hsl(142 71% 45%)" strokeDasharray="2 4" opacity={0.4} />
          <ReferenceLine y={-shiftThreshold} stroke="hsl(0 84% 60%)" strokeDasharray="2 4" opacity={0.4} />

          <Tooltip content={<CustomTooltip />} />

          <Line
            type="monotone"
            dataKey="score"
            stroke="hsl(262 83% 58%)"
            strokeWidth={2}
            dot={<ShiftDot />}
            activeDot={{ r: 5, fill: 'hsl(262 83% 58%)', stroke: 'white', strokeWidth: 2 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
