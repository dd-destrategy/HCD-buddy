'use client';

import React, { useState, useMemo, useCallback } from 'react';
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@hcd/ui';
import { Badge } from '@hcd/ui';
import { Button } from '@hcd/ui';
import { Input } from '@hcd/ui';
import { cn } from '@hcd/ui';
import {
  BarChart3,
  TrendingUp,
  Clock,
  Lightbulb,
  Highlighter,
  Calendar,
  Filter,
  ChevronDown,
  Activity,
  Tag,
  MessageSquare,
} from 'lucide-react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  Legend,
  Cell,
} from 'recharts';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface StudyOption {
  id: string;
  name: string;
}

interface SessionOverTimeEntry {
  date: string;
  count: number;
}

interface TalkTimeRatioTrend {
  date: string;
  ratio: number;
}

interface QuestionTypeAcrossSessions {
  type: string;
  count: number;
  color: string;
}

interface TagUsage {
  tag: string;
  count: number;
}

interface ThemeEntry {
  theme: string;
  count: number;
}

interface RecentActivityItem {
  id: string;
  type: 'session' | 'insight' | 'highlight' | 'export';
  description: string;
  timestamp: string;
}

interface AnalyticsData {
  // Stats
  totalSessions: number;
  avgDurationMinutes: number;
  totalInsights: number;
  totalHighlights: number;
  // Charts
  sessionsOverTime: SessionOverTimeEntry[];
  talkTimeRatioTrend: TalkTimeRatioTrend[];
  questionTypeDistribution: QuestionTypeAcrossSessions[];
  topTags: TagUsage[];
  topThemes: ThemeEntry[];
  // Activity
  recentActivity: RecentActivityItem[];
}

// ---------------------------------------------------------------------------
// Demo data
// ---------------------------------------------------------------------------

function getDemoData(): AnalyticsData {
  return {
    totalSessions: 47,
    avgDurationMinutes: 38,
    totalInsights: 156,
    totalHighlights: 89,
    sessionsOverTime: [
      { date: 'Jan 6', count: 4 },
      { date: 'Jan 13', count: 6 },
      { date: 'Jan 20', count: 8 },
      { date: 'Jan 27', count: 5 },
      { date: 'Feb 3', count: 7 },
      { date: 'Feb 10', count: 9 },
      { date: 'Feb 17', count: 4 },
      { date: 'Feb 24', count: 4 },
    ],
    talkTimeRatioTrend: [
      { date: 'Jan 6', ratio: 35 },
      { date: 'Jan 13', ratio: 32 },
      { date: 'Jan 20', ratio: 28 },
      { date: 'Jan 27', ratio: 25 },
      { date: 'Feb 3', ratio: 27 },
      { date: 'Feb 10', ratio: 23 },
      { date: 'Feb 17', ratio: 22 },
      { date: 'Feb 24', ratio: 21 },
    ],
    questionTypeDistribution: [
      { type: 'Open', count: 128, color: 'hsl(142 71% 45%)' },
      { type: 'Closed', count: 54, color: 'hsl(217 91% 60%)' },
      { type: 'Follow-up', count: 73, color: 'hsl(262 83% 58%)' },
      { type: 'Leading', count: 12, color: 'hsl(0 84% 60%)' },
      { type: 'Double-barreled', count: 5, color: 'hsl(38 92% 50%)' },
    ],
    topTags: [
      { tag: 'Usability', count: 34 },
      { tag: 'Pain point', count: 28 },
      { tag: 'Feature request', count: 22 },
      { tag: 'Onboarding', count: 18 },
      { tag: 'Navigation', count: 15 },
      { tag: 'Delight', count: 12 },
      { tag: 'Frustration', count: 10 },
      { tag: 'Accessibility', count: 8 },
    ],
    topThemes: [
      { theme: 'Complex navigation patterns', count: 14 },
      { theme: 'Onboarding confusion', count: 12 },
      { theme: 'Mobile responsiveness issues', count: 10 },
      { theme: 'Feature discoverability', count: 9 },
      { theme: 'Data export needs', count: 7 },
    ],
    recentActivity: [
      {
        id: '1',
        type: 'session',
        description: 'Completed session with P-042',
        timestamp: '2 hours ago',
      },
      {
        id: '2',
        type: 'insight',
        description: 'Flagged insight in "Checkout Flow" session',
        timestamp: '3 hours ago',
      },
      {
        id: '3',
        type: 'export',
        description: 'Exported "Navigation Study" report',
        timestamp: '5 hours ago',
      },
      {
        id: '4',
        type: 'highlight',
        description: 'Created highlight reel for sprint review',
        timestamp: '1 day ago',
      },
      {
        id: '5',
        type: 'session',
        description: 'Completed session with P-041',
        timestamp: '1 day ago',
      },
    ],
  };
}

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------

function StatCard({
  title,
  value,
  icon,
  description,
}: {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  description?: string;
}) {
  return (
    <Card>
      <CardContent className="p-5">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-sm text-muted-foreground">{title}</p>
            <p className="text-2xl font-bold tabular-nums mt-1">{value}</p>
            {description && (
              <p className="text-xs text-muted-foreground mt-1">{description}</p>
            )}
          </div>
          <div className="p-2 rounded-lg bg-muted">{icon}</div>
        </div>
      </CardContent>
    </Card>
  );
}

// ---------------------------------------------------------------------------
// Activity type icon
// ---------------------------------------------------------------------------

function ActivityIcon({ type }: { type: RecentActivityItem['type'] }) {
  switch (type) {
    case 'session':
      return <Clock className="h-4 w-4 text-blue-500" />;
    case 'insight':
      return <Lightbulb className="h-4 w-4 text-amber-500" />;
    case 'highlight':
      return <Highlighter className="h-4 w-4 text-purple-500" />;
    case 'export':
      return <BarChart3 className="h-4 w-4 text-green-500" />;
  }
}

// ---------------------------------------------------------------------------
// Tooltip for charts
// ---------------------------------------------------------------------------

interface ChartTooltipPayload {
  dataKey: string;
  value: number;
  name?: string;
  color?: string;
  payload?: Record<string, unknown>;
}

function ChartTooltip({
  active,
  payload,
  label,
}: {
  active?: boolean;
  payload?: ChartTooltipPayload[];
  label?: string;
}) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-lg border bg-card p-3 shadow-md">
      <p className="text-xs font-medium text-muted-foreground mb-1">{label}</p>
      {payload.map((entry, i) => (
        <div key={i} className="flex items-center gap-2 text-sm">
          {entry.color && (
            <span className="h-2 w-2 rounded-full" style={{ backgroundColor: entry.color }} />
          )}
          <span>{entry.name ?? entry.dataKey}:</span>
          <span className="font-semibold tabular-nums">{entry.value}</span>
        </div>
      ))}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------

export default function AnalyticsPage() {
  const [dateRange, setDateRange] = useState({ from: '', to: '' });
  const [selectedStudy, setSelectedStudy] = useState<string>('all');
  const [isFilterOpen, setIsFilterOpen] = useState(false);

  // In a real app, this would come from an API call filtered by dateRange and study
  const data = useMemo(() => getDemoData(), []);

  const studies: StudyOption[] = useMemo(
    () => [
      { id: 'all', name: 'All Studies' },
      { id: 'nav-study', name: 'Navigation Study' },
      { id: 'checkout', name: 'Checkout Flow' },
      { id: 'onboarding', name: 'Onboarding Experience' },
    ],
    [],
  );

  const handleDateFromChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) =>
      setDateRange((prev) => ({ ...prev, from: e.target.value })),
    [],
  );

  const handleDateToChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) =>
      setDateRange((prev) => ({ ...prev, to: e.target.value })),
    [],
  );

  // Max count for tag bar widths
  const maxTagCount = useMemo(
    () => Math.max(...data.topTags.map((t) => t.count), 1),
    [data.topTags],
  );

  return (
    <div className="container mx-auto p-6 space-y-6 max-w-7xl">
      {/* Page header */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Analytics</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Cross-session insights and research metrics
          </p>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setIsFilterOpen((prev) => !prev)}
            aria-expanded={isFilterOpen}
            aria-controls="analytics-filters"
          >
            <Filter className="h-4 w-4 mr-1" />
            Filters
            <ChevronDown
              className={cn(
                'h-4 w-4 ml-1 transition-transform',
                isFilterOpen && 'rotate-180',
              )}
            />
          </Button>
        </div>
      </div>

      {/* Collapsible filter row */}
      {isFilterOpen && (
        <div
          id="analytics-filters"
          className="flex flex-wrap items-end gap-4 p-4 border rounded-lg bg-muted/30 animate-fade-in"
          role="group"
          aria-label="Analytics filters"
        >
          <div className="space-y-1">
            <label htmlFor="date-from" className="text-xs font-medium text-muted-foreground">
              From
            </label>
            <Input
              id="date-from"
              type="date"
              value={dateRange.from}
              onChange={handleDateFromChange}
              className="h-9 w-40"
            />
          </div>
          <div className="space-y-1">
            <label htmlFor="date-to" className="text-xs font-medium text-muted-foreground">
              To
            </label>
            <Input
              id="date-to"
              type="date"
              value={dateRange.to}
              onChange={handleDateToChange}
              className="h-9 w-40"
            />
          </div>
          <div className="space-y-1">
            <label htmlFor="study-filter" className="text-xs font-medium text-muted-foreground">
              Study
            </label>
            <select
              id="study-filter"
              value={selectedStudy}
              onChange={(e) => setSelectedStudy(e.target.value)}
              className="h-9 rounded-lg border border-input bg-background px-3 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              aria-label="Filter by study"
            >
              {studies.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>
          </div>
        </div>
      )}

      {/* Stats cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Total Sessions"
          value={data.totalSessions}
          icon={<BarChart3 className="h-5 w-5 text-blue-500" />}
        />
        <StatCard
          title="Avg Duration"
          value={`${data.avgDurationMinutes}m`}
          icon={<Clock className="h-5 w-5 text-green-500" />}
          description="Per session"
        />
        <StatCard
          title="Total Insights"
          value={data.totalInsights}
          icon={<Lightbulb className="h-5 w-5 text-amber-500" />}
        />
        <StatCard
          title="Total Highlights"
          value={data.totalHighlights}
          icon={<Highlighter className="h-5 w-5 text-purple-500" />}
        />
      </div>

      {/* Chart grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Sessions over time */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Calendar className="h-4 w-4 text-blue-500" />
              Sessions Over Time
            </CardTitle>
            <CardDescription>Weekly session counts</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={data.sessionsOverTime} margin={{ top: 8, right: 8, bottom: 8, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
                <XAxis dataKey="date" tick={{ fontSize: 12 }} stroke="hsl(215 16% 47%)" />
                <YAxis tick={{ fontSize: 12 }} stroke="hsl(215 16% 47%)" allowDecimals={false} />
                <Tooltip content={<ChartTooltip />} />
                <Bar dataKey="count" name="Sessions" fill="hsl(217 91% 60%)" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Talk-time ratio trend */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <TrendingUp className="h-4 w-4 text-green-500" />
              Interviewer Talk-Time Trend
            </CardTitle>
            <CardDescription>Average interviewer talk percentage over time</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <LineChart data={data.talkTimeRatioTrend} margin={{ top: 8, right: 8, bottom: 8, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
                <XAxis dataKey="date" tick={{ fontSize: 12 }} stroke="hsl(215 16% 47%)" />
                <YAxis
                  domain={[0, 50]}
                  tickFormatter={(v: number) => `${v}%`}
                  tick={{ fontSize: 12 }}
                  stroke="hsl(215 16% 47%)"
                />
                <Tooltip content={<ChartTooltip />} />
                <Line
                  type="monotone"
                  dataKey="ratio"
                  name="Interviewer %"
                  stroke="hsl(217 91% 60%)"
                  strokeWidth={2}
                  dot={{ fill: 'hsl(217 91% 60%)', r: 4 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Question type distribution */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <MessageSquare className="h-4 w-4 text-purple-500" />
              Question Type Distribution
            </CardTitle>
            <CardDescription>Across all sessions</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart
                data={data.questionTypeDistribution}
                layout="vertical"
                margin={{ top: 8, right: 40, bottom: 8, left: 8 }}
              >
                <XAxis type="number" hide />
                <YAxis
                  type="category"
                  dataKey="type"
                  width={100}
                  tick={{ fontSize: 12 }}
                  stroke="hsl(215 16% 47%)"
                  axisLine={false}
                  tickLine={false}
                />
                <Tooltip content={<ChartTooltip />} />
                <Bar dataKey="count" name="Questions" radius={[0, 6, 6, 0]}>
                  {data.questionTypeDistribution.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Top tags */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Tag className="h-4 w-4 text-amber-500" />
              Most Used Tags
            </CardTitle>
            <CardDescription>Tag frequency across sessions</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3" role="list" aria-label="Tag usage">
              {data.topTags.map((tag) => (
                <div key={tag.tag} className="flex items-center gap-3" role="listitem">
                  <span className="text-sm text-foreground w-24 flex-shrink-0 truncate">
                    {tag.tag}
                  </span>
                  <div className="flex-1 h-5 bg-muted rounded-full overflow-hidden">
                    <div
                      className="h-full bg-amber-400 rounded-full transition-all"
                      style={{ width: `${(tag.count / maxTagCount) * 100}%` }}
                    />
                  </div>
                  <span className="text-xs text-muted-foreground tabular-nums w-8 text-right">
                    {tag.count}
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Bottom section: themes + activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top themes */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Lightbulb className="h-4 w-4 text-amber-500" />
              Top Themes
            </CardTitle>
            <CardDescription>Most frequent themes from AI summaries</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3" role="list" aria-label="Top themes">
              {data.topThemes.map((theme, i) => (
                <div
                  key={i}
                  className="flex items-center justify-between p-2 rounded-lg hover:bg-muted/50 transition-colors"
                  role="listitem"
                >
                  <span className="text-sm text-foreground">{theme.theme}</span>
                  <Badge variant="secondary" className="text-xs tabular-nums">
                    {theme.count} sessions
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Recent activity */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Activity className="h-4 w-4 text-blue-500" />
              Recent Activity
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-1" role="list" aria-label="Recent activity">
              {data.recentActivity.map((item) => (
                <div
                  key={item.id}
                  className="flex items-center gap-3 p-2 rounded-lg hover:bg-muted/50 transition-colors"
                  role="listitem"
                >
                  <ActivityIcon type={item.type} />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-foreground truncate">{item.description}</p>
                    <p className="text-xs text-muted-foreground">{item.timestamp}</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
