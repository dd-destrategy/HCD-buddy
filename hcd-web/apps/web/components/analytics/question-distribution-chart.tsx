'use client';

import React, { useMemo, useCallback } from 'react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  Cell,
  LabelList,
} from 'recharts';
import { cn } from '@hcd/ui';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type QuestionType = 'open' | 'closed' | 'leading' | 'double_barreled' | 'follow_up';

export interface QuestionDistributionData {
  type: QuestionType;
  count: number;
}

export interface QuestionDistributionChartProps {
  data: QuestionDistributionData[];
  /** Called when the user clicks a segment to filter transcript */
  onSegmentClick?: (type: QuestionType) => void;
  className?: string;
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const TYPE_CONFIG: Record<QuestionType, { label: string; color: string }> = {
  open: { label: 'Open', color: 'hsl(142 71% 45%)' },
  closed: { label: 'Closed', color: 'hsl(217 91% 60%)' },
  leading: { label: 'Leading', color: 'hsl(0 84% 60%)' },
  double_barreled: { label: 'Double-barreled', color: 'hsl(38 92% 50%)' },
  follow_up: { label: 'Follow-up', color: 'hsl(262 83% 58%)' },
};

// ---------------------------------------------------------------------------
// Custom tooltip
// ---------------------------------------------------------------------------

interface TooltipPayloadItem {
  payload: { type: QuestionType; count: number; percentage: number; label: string };
}

function CustomTooltip({
  active,
  payload,
}: {
  active?: boolean;
  payload?: TooltipPayloadItem[];
}) {
  if (!active || !payload?.[0]) return null;
  const d = payload[0].payload;
  return (
    <div className="rounded-lg border bg-card p-3 shadow-md">
      <p className="text-sm font-medium">{d.label}</p>
      <p className="text-xs text-muted-foreground">
        {d.count} question{d.count !== 1 ? 's' : ''} ({d.percentage.toFixed(1)}%)
      </p>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function QuestionDistributionChart({
  data,
  onSegmentClick,
  className,
}: QuestionDistributionChartProps) {
  const chartData = useMemo(() => {
    const total = data.reduce((sum, d) => sum + d.count, 0);
    return data
      .map((d) => ({
        ...d,
        label: TYPE_CONFIG[d.type]?.label ?? d.type,
        color: TYPE_CONFIG[d.type]?.color ?? 'hsl(215 16% 47%)',
        percentage: total > 0 ? (d.count / total) * 100 : 0,
      }))
      .sort((a, b) => b.count - a.count);
  }, [data]);

  const handleBarClick = useCallback(
    (entry: { type: QuestionType }) => {
      onSegmentClick?.(entry.type);
    },
    [onSegmentClick],
  );

  if (data.length === 0) {
    return (
      <div className={cn('flex items-center justify-center h-64 text-muted-foreground', className)}>
        <p className="text-sm">No question data available yet</p>
      </div>
    );
  }

  return (
    <div
      className={cn('w-full', className)}
      role="img"
      aria-label="Question type distribution chart"
    >
      {/* Legend */}
      <div className="flex flex-wrap gap-3 mb-4 px-2" role="list" aria-label="Chart legend">
        {chartData.map((d) => (
          <button
            key={d.type}
            className={cn(
              'flex items-center gap-1.5 text-xs rounded-md px-2 py-1 transition-colors',
              'hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
              onSegmentClick && 'cursor-pointer',
            )}
            onClick={() => onSegmentClick?.(d.type)}
            role="listitem"
            aria-label={`${d.label}: ${d.count} (${d.percentage.toFixed(1)}%)`}
          >
            <span
              className="h-2.5 w-2.5 rounded-full flex-shrink-0"
              style={{ backgroundColor: d.color }}
            />
            <span className="text-foreground font-medium">{d.label}</span>
            <span className="text-muted-foreground tabular-nums">{d.percentage.toFixed(0)}%</span>
          </button>
        ))}
      </div>

      <ResponsiveContainer width="100%" height={Math.max(200, chartData.length * 48 + 40)}>
        <BarChart data={chartData} layout="vertical" margin={{ top: 8, right: 60, bottom: 8, left: 8 }}>
          <XAxis type="number" hide />
          <YAxis
            type="category"
            dataKey="label"
            width={110}
            tick={{ fontSize: 13 }}
            stroke="hsl(215 16% 47%)"
            axisLine={false}
            tickLine={false}
          />
          <Tooltip content={<CustomTooltip />} cursor={{ fill: 'hsl(215 16% 47% / 0.08)' }} />
          <Bar
            dataKey="count"
            radius={[0, 6, 6, 0]}
            onClick={handleBarClick}
            className={cn(onSegmentClick && 'cursor-pointer')}
            aria-label="Question count bar"
          >
            {chartData.map((entry) => (
              <Cell key={entry.type} fill={entry.color} />
            ))}
            <LabelList
              dataKey="percentage"
              position="right"
              formatter={(val: number) => `${val.toFixed(0)}%`}
              style={{ fontSize: 12, fill: 'hsl(215 16% 47%)' }}
            />
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
